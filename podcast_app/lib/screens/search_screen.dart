import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'podcast_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<dynamic> _podcasts = [];
  bool _isLoading = false;
  String _lastQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _podcasts = [];
        _lastQuery = '';
      });
      return;
    }
    
    if (query == _lastQuery && _podcasts.isNotEmpty) return;

    setState(() {
      _isLoading = true;
      _lastQuery = query;
      _podcasts = [];
    });

    final term = Uri.encodeComponent(query);
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('podstream_lang') ?? 'fr';

    String countryParam = '';
    if (lang != 'all') {
      final langToCountry = {'fr': 'FR', 'en': 'US', 'es': 'ES', 'de': 'DE'};
      if (langToCountry.containsKey(lang)) {
        countryParam = '&country=${langToCountry[lang]}';
      }
    }

    final url = Uri.parse('https://itunes.apple.com/search?media=podcast&term=$term&limit=50$countryParam');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> results = data['results'] ?? [];

        if (lang == 'all') {
          setState(() {
            _podcasts = results.take(20).toList();
          });
        } else {
           // Filtrage strict par langue via RSS (Identique à HomeScreen)
           List<dynamic> validPodcasts = [];
           
           for (var p in results) {
             if (validPodcasts.length >= 15) break; 
             final feedUrl = p['feedUrl'];
             if (feedUrl == null) continue;

             try {
               final feedRes = await http.get(Uri.parse(feedUrl)).timeout(const Duration(seconds: 3));
               if (feedRes.statusCode == 200) {
                 final body = feedRes.body.toLowerCase();
                 final langMatch = RegExp(r'<language>\s*([^<\s]+)\s*<\/language>').firstMatch(body);
                 if (langMatch != null) {
                   final podcastLang = langMatch.group(1)?.toLowerCase() ?? '';
                   if (podcastLang.startsWith(lang)) {
                     validPodcasts.add(p);
                   }
                 } else {
                   validPodcasts.add(p);
                 }
               }
             } catch (e) {
               // Ignorer l'erreur réseau pour un feed spécifique
             }
           }
           
           setState(() {
             _podcasts = validPodcasts;
           });
        }
      }
    } catch (e) {
      print('Erreur recherche: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onChanged: _onSearchChanged,
            onSubmitted: _performSearch,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Rechercher un podcast, un auteur...',
              hintStyle: TextStyle(color: AppTheme.textSecondary),
              prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  _searchController.clear();
                  _performSearch('');
                },
              ),
              filled: true,
              fillColor: AppTheme.surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _podcasts.isEmpty
                  ? Center(
                      child: Text(
                        _lastQuery.isEmpty
                            ? 'Saisissez un terme pour rechercher.'
                            : 'Aucun résultat trouvé pour "$_lastQuery".',
                        style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _podcasts.length,
                      itemBuilder: (context, index) {
                        final p = _podcasts[index];
                        final imageUrl = p['artworkUrl600'] ?? p['artworkUrl100'];
                        final title = p['collectionName'] ?? 'Sans titre';
                        final author = p['artistName'] ?? 'Inconnu';

                        return Card(
                          color: AppTheme.surfaceColor,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: AppTheme.bgColor,
                                image: imageUrl != null
                                    ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                                    : null,
                              ),
                              child: imageUrl == null ? const Icon(Icons.podcasts) : null,
                            ),
                            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: Text(author, style: TextStyle(color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: const Icon(Icons.chevron_right, color: AppTheme.primaryColor),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PodcastDetailsScreen(podcast: p),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
