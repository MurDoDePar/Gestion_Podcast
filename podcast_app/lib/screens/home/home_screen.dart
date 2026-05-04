import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../dataconnect-generated/example.dart';
import '../../data/themes_data.dart';
import '../../services/audio_service.dart';
import '../podcast_details_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Container(
            color: AppTheme.bgColor,
            child: const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              tabs: [
                Tab(text: 'Mes podcasts'),
                Tab(text: 'Par thème'),
                Tab(text: 'Populaires'),
                Tab(text: 'Affinités'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _MyPodcastsTab(),
                _ByThemeTab(),
                _PopularTab(),
                _AffinitiesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ByThemeTab extends StatefulWidget {
  const _ByThemeTab();

  @override
  State<_ByThemeTab> createState() => _ByThemeTabState();
}

class _ByThemeTabState extends State<_ByThemeTab> {
  int _selectedCategoryIndex = 0;
  int _selectedSubThemeIndex = 0;
  List<dynamic> _podcasts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPodcasts();
  }

  Future<void> _fetchPodcasts() async {
    setState(() {
      _isLoading = true;
      _podcasts = [];
    });

    final currentSubTheme = themesList[_selectedCategoryIndex].subThemes[_selectedSubThemeIndex];
    final term = Uri.encodeComponent(currentSubTheme.name);
    
    // Obtenir la langue depuis les paramètres
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('podstream_lang') ?? 'fr';
    
    String countryParam = '';
    if (lang != 'all') {
      final langToCountry = {
        'fr': 'FR',
        'en': 'US',
        'es': 'ES',
        'de': 'DE',
      };
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
           // Filtrage strict par langue via RSS
           List<dynamic> validPodcasts = [];
           
           for (var p in results) {
             if (validPodcasts.length >= 20) break; // Limite à 20 résultats
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
      print('Error fetching podcasts: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCategory = themesList[_selectedCategoryIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grand Themes
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: themesList.length,
            itemBuilder: (context, index) {
              final category = themesList[index];
              final isSelected = index == _selectedCategoryIndex;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(category.icon, size: 16, color: isSelected ? Colors.white : AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(category.name),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryColor,
                  backgroundColor: AppTheme.surfaceColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (!isSelected) {
                      setState(() {
                        _selectedCategoryIndex = index;
                        _selectedSubThemeIndex = 0;
                      });
                      _fetchPodcasts();
                    }
                  },
                ),
              );
            },
          ),
        ),
        
        // Sub-Themes
        Container(
          height: 50,
          padding: const EdgeInsets.only(bottom: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: currentCategory.subThemes.length,
            itemBuilder: (context, index) {
              final subTheme = currentCategory.subThemes[index];
              final isSelected = index == _selectedSubThemeIndex;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(subTheme.icon, size: 14, color: isSelected ? Colors.white : AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(subTheme.name, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryColor.withOpacity(0.8),
                  backgroundColor: AppTheme.bgColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                  ),
                  onSelected: (selected) {
                    if (!isSelected) {
                      setState(() {
                        _selectedSubThemeIndex = index;
                      });
                      _fetchPodcasts();
                    }
                  },
                ),
              );
            },
          ),
        ),

        // Podcasts List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _podcasts.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun podcast trouvé.',
                        style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
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
                            trailing: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
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

class _MyPodcastsTab extends StatefulWidget {
  const _MyPodcastsTab();

  @override
  State<_MyPodcastsTab> createState() => _MyPodcastsTabState();
}

class _MyPodcastsTabState extends State<_MyPodcastsTab> {
  String? get userId {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAuth.instance.currentUser?.uid;
  }

  // En l'absence de login forcé pour l'instant, on met un ID de test ou on gère le null
  // Dans la version finale, FirebaseAuth garantira que l'utilisateur est connecté

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Section: Mes Podcasts
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mes Podcasts',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: () {
                // Action pour ajouter un podcast
              },
              icon: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (userId == null)
          SizedBox(
            height: 140,
            child: Center(
              child: Text(
                'Veuillez vous connecter pour voir vos podcasts.',
                style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
              ),
            ),
          )
        else
          SizedBox(
            height: 180,
            child: FutureBuilder(
              future: _fetchSubscriptions(userId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erreur: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                  );
                }
                
                final subs = snapshot.data ?? [];

                if (subs.isEmpty) {
                  return Center(
                    child: Text(
                      'Aucun podcast. Ajoutez-en un !',
                      style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
                    ),
                  );
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: subs.length,
                  itemBuilder: (context, index) {
                    final sub = subs[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PodcastDetailsScreen(
                              podcast: {
                                'collectionId': sub.podcast.id,
                                'collectionName': sub.podcast.title,
                                'artistName': sub.podcast.author,
                                'artworkUrl600': sub.podcast.imageUrl,
                                'feedUrl': sub.podcast.feedUrl,
                              },
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 140,
                        margin: const EdgeInsets.only(right: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(20),
                                image: sub.podcast.imageUrl != null 
                                    ? DecorationImage(
                                        image: NetworkImage(sub.podcast.imageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: sub.podcast.imageUrl == null 
                                  ? const Icon(Icons.podcasts, size: 50, color: Colors.grey)
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              sub.podcast.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              sub.podcast.author ?? 'Inconnu',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

        const SizedBox(height: 32),
        // Section: A écouter
        const Text(
          'A écouter',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        if (userId == null)
          Center(
            child: Text(
              'Connectez-vous pour voir votre historique.',
              style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
            ),
          )
        else
          FutureBuilder(
            future: _fetchNewEpisodes(userId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text('Erreur: ${snapshot.error}', style: const TextStyle(color: Colors.red));
              }

              final history = snapshot.data ?? [];

              if (history.isEmpty) {
                return Center(
                  child: Text(
                    'Pas d\'épisodes à écouter pour le moment.',
                    style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];
                  // Extraction d'un nom de fichier approximatif depuis l'URL audio si le titre n'est pas dispo
                  final fallbackTitle = item['audioUrl'].toString().split('/').last.split('?').first;
                  
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                        image: item['imageUrl'] != null
                            ? DecorationImage(
                                image: NetworkImage(item['imageUrl']),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: item['imageUrl'] == null
                          ? const Icon(Icons.play_circle_fill, color: AppTheme.primaryColor)
                          : null,
                    ),
                    title: Text(item['title'] ?? fallbackTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(item['podcastName'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
                    onTap: () {
                      final audioEpisode = AudioEpisode(
                        id: item['audioUrl'],
                        title: item['title'] ?? fallbackTitle,
                        podcastName: item['podcastName'] ?? 'Mon Podcast',
                        imageUrl: item['imageUrl'],
                        audioUrl: item['audioUrl'],
                      );
                      AudioService().playEpisode(audioEpisode);
                    },
                  );
                },
              );
            },
          ),
      ],
    );
  }

  Future<List<GetMySubscriptionsSubscriptionTypes>> _fetchSubscriptions(String googleId) async {
    final userResult = await ExampleConnector.instance.findUserByGoogleId(googleId: googleId).execute();
    final users = userResult.data.users;
    if (users.isEmpty) return [];
    final postgresUuid = users.first.id;
    final subsResult = await ExampleConnector.instance.getMySubscriptions(userId: postgresUuid).execute();
    return subsResult.data.subscriptionTypes;
  }

  Future<List<Map<String, dynamic>>> _fetchNewEpisodes(String googleId) async {
    // 1. Obtenir les abonnements
    final subs = await _fetchSubscriptions(googleId);
    if (subs.isEmpty) return [];
    
    // Prendre les 3 premiers pour ne pas trop ralentir
    final topSubs = subs.take(3).toList();
    List<Map<String, dynamic>> allEpisodes = [];

    // 2. Parser le flux RSS pour chaque podcast
    for (var sub in topSubs) {
      final feedUrl = sub.podcast.feedUrl;
      if (feedUrl == null || feedUrl.isEmpty) continue;

      try {
        final response = await http.get(Uri.parse(feedUrl)).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          // Utilisation d'une regex simple au lieu d'un parseur XML lourd pour aller vite
          final body = response.body;
          
          // Chercher le premier <item>
          final itemStart = body.indexOf('<item>');
          final itemEnd = body.indexOf('</item>', itemStart);
          
          if (itemStart != -1 && itemEnd != -1) {
            final itemBlock = body.substring(itemStart, itemEnd);
            
            // Extraire le titre de l'épisode
            String? title;
            final titleMatch = RegExp(r'<title>(.*?)<\/title>', dotAll: true).firstMatch(itemBlock);
            if (titleMatch != null) {
              title = titleMatch.group(1)?.replaceAll('<![CDATA[', '').replaceAll(']]>', '').trim();
            }

            // Extraire l'URL audio (enclosure)
            String? audioUrl;
            final encMatch = RegExp(r'<enclosure[^>]+url="([^"]+)"').firstMatch(itemBlock);
            if (encMatch != null) {
              audioUrl = encMatch.group(1);
            } else {
              // Parfois media:content
              final mediaMatch = RegExp(r'<media:content[^>]+url="([^"]+)"').firstMatch(itemBlock);
              if (mediaMatch != null) {
                audioUrl = mediaMatch.group(1);
              }
            }

            if (audioUrl != null) {
              allEpisodes.add({
                'title': title ?? 'Nouvel épisode',
                'audioUrl': audioUrl,
                'imageUrl': sub.podcast.imageUrl,
                'podcastName': sub.podcast.title,
              });
            }
          }
        }
      } catch (e) {
        print("Erreur de parsing RSS pour ${sub.podcast.title}: $e");
      }
    }

    return allEpisodes;
  }
}

class _PopularTab extends StatefulWidget {
  const _PopularTab({super.key});

  @override
  State<_PopularTab> createState() => _PopularTabState();
}

class _PopularTabState extends State<_PopularTab> {
  List<dynamic> _podcasts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPopular();
  }

  Future<void> _fetchPopular() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('podstream_lang') ?? 'fr';

    String countryParam = '';
    if (lang != 'all') {
      final langToCountry = {'fr': 'FR', 'en': 'US', 'es': 'ES', 'de': 'DE'};
      if (langToCountry.containsKey(lang)) {
        countryParam = '&country=${langToCountry[lang]}';
      }
    }

    // Requête iTunes large avec limit 50 pour avoir un bon échantillon de "populaires"
    final url = Uri.parse('https://itunes.apple.com/search?media=podcast&term=podcast&limit=50$countryParam');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> results = data['results'] ?? [];
        
        // Mélanger un peu les résultats
        results.shuffle();

        if (lang == 'all') {
           setState(() {
             _podcasts = results.take(20).toList();
           });
        } else {
           // Filtrage strict par langue via RSS (Identique à l'ancienne version JS)
           List<dynamic> validPodcasts = [];
           
           for (var p in results) {
             if (validPodcasts.length >= 10) break; // Limite à 10 pour ne pas surcharger le réseau
             final feedUrl = p['feedUrl'];
             if (feedUrl == null) continue;

             try {
               final feedRes = await http.get(Uri.parse(feedUrl)).timeout(const Duration(seconds: 3));
               if (feedRes.statusCode == 200) {
                 final body = feedRes.body.toLowerCase();
                 // Recherche simple de la balise language
                 final langMatch = RegExp(r'<language>\s*([^<\s]+)\s*<\/language>').firstMatch(body);
                 if (langMatch != null) {
                   final podcastLang = langMatch.group(1)?.toLowerCase() ?? '';
                   if (podcastLang.startsWith(lang)) {
                     validPodcasts.add(p);
                   }
                 } else {
                   // Si pas de balise language, on l'accepte par défaut
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
      print('Erreur fetch populaire: $e');
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_podcasts.isEmpty) {
      return Center(
        child: Text(
          'Impossible de charger les suggestions.',
          style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.65,
      ),
      itemCount: _podcasts.length,
      itemBuilder: (context, index) {
        final p = _podcasts[index];
        final imageUrl = p['artworkUrl600'] ?? p['artworkUrl100'];
        final title = p['collectionName'] ?? 'Podcast';
        final genre = p['primaryGenreName'] ?? 'Podcast';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PodcastDetailsScreen(podcast: p),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      image: imageUrl != null
                          ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                          : null,
                      color: AppTheme.bgColor,
                    ),
                    child: imageUrl == null
                        ? const Center(child: Icon(Icons.podcasts, size: 40, color: Colors.grey))
                        : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          genre,
                          style: const TextStyle(color: AppTheme.primaryColor, fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AffinitiesTab extends StatefulWidget {
  const _AffinitiesTab({super.key});

  @override
  State<_AffinitiesTab> createState() => _AffinitiesTabState();
}

class _AffinitiesTabState extends State<_AffinitiesTab> {
  List<dynamic> _recommendedPodcasts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAffinities();
  }

  Future<void> _fetchAffinities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString('podstream_lang') ?? 'fr';

      final googleId = FirebaseAuth.instance.currentUser?.uid;
      if (googleId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // 1. Récupérer l'ID Postgres de l'utilisateur
      final userResult = await ExampleConnector.instance.findUserByGoogleId(googleId: googleId).execute();
      if (userResult.data.users.isEmpty) {
         setState(() => _isLoading = false);
         return;
      }
      final postgresUuid = userResult.data.users.first.id;

      // 2. Obtenir ses propres abonnements
      final subsResult = await ExampleConnector.instance.getMySubscriptions(userId: postgresUuid).execute();
      final mySubs = subsResult.data.subscriptionTypes;
      
      if (mySubs.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final mySubIds = mySubs.map((s) => s.podcast.id).toSet();
      
      // 3. Obtenir les recommandations pour les 5 premiers abonnements
      final topSubs = mySubs.take(5).toList();
      Map<String, Map<String, dynamic>> recommendationCounts = {};

      for (var sub in topSubs) {
        final recResult = await ExampleConnector.instance.getRecommendations(podcastId: sub.podcast.id).execute();
        
        for (var st in recResult.data.subscriptionTypes) {
          for (var userSub in st.user.subscriptionTypes_on_user) {
            final recPodcast = userSub.podcast;
            
            // Exclure les podcasts qu'on a déjà
            if (!mySubIds.contains(recPodcast.id)) {
              if (recommendationCounts.containsKey(recPodcast.id)) {
                recommendationCounts[recPodcast.id]!['count'] = (recommendationCounts[recPodcast.id]!['count'] as int) + 1;
              } else {
                recommendationCounts[recPodcast.id] = {
                  'count': 1,
                  'podcast': recPodcast,
                };
              }
            }
          }
        }
      }

      // 4. Trier par nombre d'occurrences
      final sortedRecs = recommendationCounts.values.toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      List<dynamic> validPodcasts = [];
      if (lang == 'all') {
         validPodcasts = sortedRecs.map((e) => e['podcast']).take(15).toList();
      } else {
         for (var rec in sortedRecs) {
           if (validPodcasts.length >= 15) break;
           final p = rec['podcast'];
           final feedUrl = p.feedUrl;
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
             // Ignorer l'erreur réseau
           }
         }
      }

      setState(() {
        _recommendedPodcasts = validPodcasts;
        _isLoading = false;
      });

    } catch (e) {
      print("Erreur Affinités: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      return Center(
        child: Text(
          'Connectez-vous pour voir les recommandations basées sur vos goûts.',
          style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recommendedPodcasts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Abonnez-vous à plus de podcasts pour voir ce que d\'autres auditeurs aux mêmes goûts écoutent !',
            style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.65,
      ),
      itemCount: _recommendedPodcasts.length,
      itemBuilder: (context, index) {
        final p = _recommendedPodcasts[index] as GetRecommendationsSubscriptionTypesUserSubscriptionTypesOnUserPodcast;
        final imageUrl = p.imageUrl;
        final title = p.title;
        final author = p.author ?? 'Recommandé pour vous';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PodcastDetailsScreen(
                  podcast: {
                    'collectionId': p.id,
                    'collectionName': p.title,
                    'artistName': p.author,
                    'artworkUrl600': p.imageUrl,
                    'feedUrl': p.feedUrl,
                  },
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      image: imageUrl != null
                          ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                          : null,
                      color: AppTheme.bgColor,
                    ),
                    child: imageUrl == null
                        ? const Center(child: Icon(Icons.podcasts, size: 40, color: Colors.grey))
                        : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        author,
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
