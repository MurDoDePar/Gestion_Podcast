import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart' as xml;
import '../../theme/app_theme.dart';
import '../../dataconnect-generated/example.dart';
import '../../data/themes_data.dart';
import '../../services/audio_service.dart';
import '../podcast_details_screen.dart';
import 'package:flutter_html/flutter_html.dart';

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

    final currentSubTheme =
        themesList[_selectedCategoryIndex].subThemes[_selectedSubThemeIndex];
    final genreId = currentSubTheme.genreId;

    // Obtenir la langue depuis les paramètres
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('podstream_lang') ?? 'fr';

    String rssCountry = 'fr';
    if (lang != 'all') {
      final langToCountry = {'fr': 'fr', 'en': 'us', 'es': 'es', 'de': 'de'};
      if (langToCountry.containsKey(lang)) {
        rssCountry = langToCountry[lang]!;
      }
    } else {
      rssCountry = 'us';
    }

    final topUrl = Uri.parse(
        'https://itunes.apple.com/$rssCountry/rss/toppodcasts/limit=50/genre=$genreId/json');

    try {
      final topResponse = await http.get(topUrl);
      if (topResponse.statusCode == 200) {
        final topData = json.decode(topResponse.body);
        final entries = topData['feed']['entry'] as List<dynamic>? ?? [];

        List<String> ids = [];
        for (var entry in entries) {
          final id = entry['id']?['attributes']?['im:id'];
          if (id != null) {
            ids.add(id.toString());
          }
        }

        if (ids.isNotEmpty) {
          final lookupUrl =
              Uri.parse('https://itunes.apple.com/lookup?id=${ids.join(',')}');
          final lookupResponse = await http.get(lookupUrl);

          if (lookupResponse.statusCode == 200) {
            final lookupData = json.decode(lookupResponse.body);
            List<dynamic> results = lookupData['results'] ?? [];

            if (lang == 'all') {
              setState(() {
                _podcasts = results.take(20).toList();
              });
            } else {
              // Filtrage strict par langue via RSS
              List<dynamic> validPodcasts = [];

              for (var p in results) {
                if (validPodcasts.length >= 20) {
                  break; // Limite à 20 résultats
                }
                final feedUrl = p['feedUrl'];
                if (feedUrl == null) continue;

                try {
                  final feedRes = await http
                      .get(Uri.parse(feedUrl))
                      .timeout(const Duration(seconds: 3));
                  if (feedRes.statusCode == 200) {
                    final body = feedRes.body.toLowerCase();
                    final langMatch =
                        RegExp(r'<language>\s*([^<\s]+)\s*<\/language>')
                            .firstMatch(body);
                    if (langMatch != null) {
                      final podcastLang =
                          langMatch.group(1)?.toLowerCase() ?? '';
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
                      Icon(category.icon,
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(category.name),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryColor,
                  backgroundColor: AppTheme.surfaceColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
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
                      Icon(subTheme.icon,
                          size: 14,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textSecondary),
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
                  ? const Center(
                      child: Text(
                        'Aucun podcast trouvé.',
                        style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontStyle: FontStyle.italic),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _podcasts.length,
                      itemBuilder: (context, index) {
                        final p = _podcasts[index];
                        final imageUrl =
                            p['artworkUrl600'] ?? p['artworkUrl100'];
                        final title = p['collectionName'] ?? 'Sans titre';
                        final author = p['artistName'] ?? 'Inconnu';

                        return Card(
                          color: AppTheme.surfaceColor,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: AppTheme.bgColor,
                                image: imageUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(imageUrl),
                                        fit: BoxFit.cover)
                                    : null,
                              ),
                              child: imageUrl == null
                                  ? const Icon(Icons.podcasts)
                                  : null,
                            ),
                            title: Text(title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            subtitle: Text(author,
                                style: const TextStyle(
                                    color: AppTheme.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            trailing: const Icon(Icons.add_circle_outline,
                                color: AppTheme.primaryColor),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PodcastDetailsScreen(podcast: p),
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
  late Future<List<GetMySubscriptionsSubscriptionTypes>> _subsFuture;
  late Future<List<Map<String, dynamic>>> _episodesFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final uid = userId;
    if (uid != null) {
      _subsFuture = _fetchSubscriptions(uid);
      _episodesFuture = _fetchNewEpisodesAndSync(uid);
    } else {
      _subsFuture = Future.value([]);
      _episodesFuture = Future.value([]);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchNewEpisodesAndSync(
      String googleId) async {
    // 1. Démarrer la synchro en arrière plan et rafraîchir quand c'est fini
    _syncPodcastsBackground(googleId).then((_) {
      if (mounted) {
        setState(() {
          _episodesFuture = _fetchNewEpisodes(googleId);
        });
      }
    });

    // 2. Lire ce qui est déjà en DB pour afficher tout de suite
    return _fetchNewEpisodes(googleId);
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _loadData();
    });
    if (userId != null) {
      await Future.wait([_subsFuture, _episodesFuture]);
    }
  }

  String? get userId {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAuth.instance.currentUser?.uid;
  }

  // En l'absence de login forcé pour l'instant, on met un ID de test ou on gère le null
  // Dans la version finale, FirebaseAuth garantira que l'utilisateur est connecté

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Section: Mes Podcasts
          const Text(
            'Mes Podcasts',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          if (userId == null)
            const SizedBox(
              height: 140,
              child: Center(
                child: Text(
                  'Veuillez vous connecter pour voir vos podcasts.',
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic),
                ),
              ),
            )
          else
            SizedBox(
              height: 180,
              child: FutureBuilder(
                future: _subsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Erreur: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red)),
                    );
                  }

                  final subs = snapshot.data ?? [];

                  if (subs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aucun podcast. Ajoutez-en un !',
                        style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontStyle: FontStyle.italic),
                      ),
                    );
                  }

                  return _DraggablePodcastList(
                    initialSubs: subs,
                    googleId: userId!,
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
            const Center(
              child: Text(
                'Connectez-vous pour voir votre historique.',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
              ),
            )
          else
            FutureBuilder(
              future: _episodesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Erreur: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red));
                }

                final history = snapshot.data ?? [];

                if (history.isEmpty) {
                  return const Center(
                    child: Text(
                      'Pas d\'épisodes à écouter pour le moment.',
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic),
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
                    final fallbackTitle = item['audioUrl']
                        .toString()
                        .split('/')
                        .last
                        .split('?')
                        .first;

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
                            ? const Icon(Icons.play_circle_fill,
                                color: AppTheme.primaryColor)
                            : null,
                      ),
                      title: Text(item['title'] ?? fallbackTitle,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(item['podcastName'] ?? '',
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert,
                            color: AppTheme.textSecondary),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(item['title'] ?? fallbackTitle),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: SingleChildScrollView(
                                  child: item['description'] == null
                                      ? const Text(
                                          'Aucune description disponible.')
                                      : Html(data: item['description']),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Fermer'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      onTap: () {
                        final playlist = history
                            .map((e) => AudioEpisode(
                                  id: e['audioUrl'],
                                  title: e['title'] ?? fallbackTitle,
                                  podcastName:
                                      e['podcastName'] ?? 'Mon Podcast',
                                  imageUrl: e['imageUrl'],
                                  audioUrl: e['audioUrl'],
                                ))
                            .toList();

                        AudioService()
                            .playEpisode(playlist[index], playlist: playlist);
                      },
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Future<List<GetMySubscriptionsSubscriptionTypes>> _fetchSubscriptions(
      String googleId) async {
    final userResult = await ExampleConnector.instance
        .findUserByGoogleId(googleId: googleId)
        .execute();
    final users = userResult.data.users;
    if (users.isEmpty) return [];
    final postgresUuid = users.first.id;
    final subsResult = await ExampleConnector.instance
        .getMySubscriptions(userId: postgresUuid)
        .execute();
    final subs = subsResult.data.subscriptionTypes.toList();
    subs.sort((a, b) {
      final orderA = a.listOrder ?? 9999;
      final orderB = b.listOrder ?? 9999;
      if (orderA == orderB) return a.podcast.title.compareTo(b.podcast.title);
      return orderA.compareTo(orderB);
    });
    return subs;
  }
}

class _DraggablePodcastList extends StatefulWidget {
  final List<GetMySubscriptionsSubscriptionTypes> initialSubs;
  final String googleId;

  const _DraggablePodcastList(
      {required this.initialSubs, required this.googleId});

  @override
  State<_DraggablePodcastList> createState() => _DraggablePodcastListState();
}

class _DraggablePodcastListState extends State<_DraggablePodcastList> {
  late List<GetMySubscriptionsSubscriptionTypes> _subs;

  @override
  void initState() {
    super.initState();
    _subs = List.from(widget.initialSubs);
  }

  @override
  void didUpdateWidget(covariant _DraggablePodcastList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSubs.length != widget.initialSubs.length) {
      _subs = List.from(widget.initialSubs);
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    setState(() {
      final item = _subs.removeAt(oldIndex);
      _subs.insert(newIndex, item);
    });

    try {
      final userResult = await ExampleConnector.instance
          .findUserByGoogleId(googleId: widget.googleId)
          .execute();
      if (userResult.data.users.isEmpty) return;
      final postgresUuid = userResult.data.users.first.id;

      for (int i = 0; i < _subs.length; i++) {
        final sub = _subs[i];
        await ExampleConnector.instance
            .updateSubscriptionOrder(
              userId: postgresUuid,
              podcastId: sub.podcast.id,
              listOrder: i,
            )
            .execute();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ordre des podcasts sauvegardé'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print("Erreur update order: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Un proxyDecorator peut être utilisé pour customiser l'apparence de l'élément pendant le drag.
    // Par défaut, ReorderableListView fait le job très bien.
    return ReorderableListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _subs.length,
      onReorder: _onReorder,
      itemBuilder: (context, index) {
        final sub = _subs[index];
        return Container(
          key: ValueKey(sub.podcast.id),
          width: 140,
          margin: const EdgeInsets.only(right: 16),
          child: GestureDetector(
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
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  sub.podcast.author ?? 'Inconnu',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<List<Map<String, dynamic>>> _fetchNewEpisodes(String googleId) async {
  // Lire depuis DataConnect
  try {
    final userResult = await ExampleConnector.instance
        .findUserByGoogleId(googleId: googleId)
        .execute();
    if (userResult.data.users.isEmpty) return [];
    final postgresUuid = userResult.data.users.first.id;

    final result = await ExampleConnector.instance
        .getLatestSubscribedEpisodes(userId: postgresUuid)
        .execute();

    final prefs = await SharedPreferences.getInstance();
    final order = prefs.getString('podstream_order') ?? 'desc';

    List<Map<String, dynamic>> allEpisodes = [];

    // 1) Prendre la liste de tous les épisodes de tous 'mes podcasts'
    final subs = result.data.subscriptionTypes.toList();
    for (var sub in subs) {
      final podcastName = sub.podcast.title;
      final podcastImageUrl = sub.podcast.imageUrl;
      final listOrder = sub.listOrder ?? 9999;

      for (var ep in sub.podcast.episodes_on_podcast) {
        allEpisodes.add({
          'title': ep.title,
          'audioUrl': ep.audioUrl,
          'imageUrl': ep.imageUrl ?? podcastImageUrl,
          'podcastName': podcastName,
          'publishedAt': ep.publishedAt.toDateTime(),
          'listOrder': listOrder,
          'description': ep.description,
        });
      }
    }

    // 2) Trier et regrouper (Tri principal: 'mes podcasts', Tri secondaire: date)
    allEpisodes.sort((a, b) {
      // Tri principal : l'ordre de 'mes podcasts'
      int orderComparison =
          (a['listOrder'] as int).compareTo(b['listOrder'] as int);
      if (orderComparison == 0) {
        orderComparison =
            (a['podcastName'] as String).compareTo(b['podcastName'] as String);
      }
      if (orderComparison != 0) {
        return orderComparison;
      }

      // Tri secondaire : date de parution
      final dateA = a['publishedAt'] as DateTime;
      final dateB = b['publishedAt'] as DateTime;
      return order == 'asc' ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
    });

    return allEpisodes;
  } catch (e) {
    print("Erreur _fetchNewEpisodes DB: $e");
    return [];
  }
}

Future<void> _syncPodcastsBackground(String googleId) async {
  try {
    final userResult = await ExampleConnector.instance
        .findUserByGoogleId(googleId: googleId)
        .execute();
    if (userResult.data.users.isEmpty) return;
    final postgresUuid = userResult.data.users.first.id;

    final subsResult = await ExampleConnector.instance
        .getMySubscriptions(userId: postgresUuid)
        .execute();
    final subs = subsResult.data.subscriptionTypes;

    for (var sub in subs) {
      final feedUrl = sub.podcast.feedUrl;
      if (feedUrl.isEmpty) continue;

      try {
        final response = await http
            .get(Uri.parse(feedUrl))
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final document = xml.XmlDocument.parse(response.body);
          final items = document
              .findAllElements('item')
              .take(5); // On synchro juste les 5 derniers pour l'accueil

          for (var item in items) {
            final title = item.findElements('title').firstOrNull?.innerText ??
                'Épisode inconnu';
            final enclosure = item.findElements('enclosure').firstOrNull;

            if (enclosure != null) {
              final audioUrl = enclosure.getAttribute('url');
              if (audioUrl != null) {
                DateTime pubDate = DateTime.now();
                final pubDateStr =
                    item.findElements('pubDate').firstOrNull?.innerText;
                if (pubDateStr != null && pubDateStr.isNotEmpty) {
                  try {
                    pubDate = HttpDate.parse(pubDateStr);
                  } catch (_) {
                    try {
                      pubDate = DateTime.parse(pubDateStr);
                    } catch (_) {}
                  }
                }

                final stableId = _generateStableUuid(audioUrl);

                await ExampleConnector.instance
                    .upsertEpisode(
                      podcastId: sub.podcast.id,
                      title: title,
                      audioUrl: audioUrl,
                      duration: BigInt.zero,
                      publishedAt:
                          Timestamp(0, pubDate.millisecondsSinceEpoch ~/ 1000),
                    )
                    .id(stableId)
                    .description(
                        item.findElements('description').firstOrNull?.innerText)
                    .imageUrl(sub.podcast.imageUrl)
                    .execute();
              }
            }
          }
        }
      } catch (e) {
        print("Erreur background sync pour ${sub.podcast.title}: $e");
      }
    }
  } catch (e) {
    print("Erreur générale _syncPodcastsBackground: $e");
  }
}

String _generateStableUuid(String input) {
  String hash = input.hashCode.abs().toString().padLeft(12, '0');
  if (hash.length > 12) hash = hash.substring(0, 12);
  String hash2 = (input.length * 31).toString().padLeft(3, '0');
  if (hash2.length > 3) hash2 = hash2.substring(0, 3);
  return '11111111-2222-4000-8$hash2-$hash';
}

class _PopularTab extends StatefulWidget {
  const _PopularTab();

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

    String rssCountry = 'fr';
    if (lang != 'all') {
      final langToCountry = {'fr': 'fr', 'en': 'us', 'es': 'es', 'de': 'de'};
      if (langToCountry.containsKey(lang)) {
        rssCountry = langToCountry[lang]!;
      }
    } else {
      rssCountry = 'us';
    }

    // Récupérer les top podcasts d'iTunes pour le pays donné
    final topUrl = Uri.parse(
        'https://itunes.apple.com/$rssCountry/rss/toppodcasts/limit=50/json');

    try {
      final topResponse = await http.get(topUrl);
      if (topResponse.statusCode == 200) {
        final topData = json.decode(topResponse.body);
        final entries = topData['feed']['entry'] as List<dynamic>? ?? [];

        List<String> ids = [];
        for (var entry in entries) {
          final id = entry['id']?['attributes']?['im:id'];
          if (id != null) {
            ids.add(id.toString());
          }
        }

        if (ids.isNotEmpty) {
          final lookupUrl =
              Uri.parse('https://itunes.apple.com/lookup?id=${ids.join(',')}');
          final lookupResponse = await http.get(lookupUrl);

          if (lookupResponse.statusCode == 200) {
            final lookupData = json.decode(lookupResponse.body);
            List<dynamic> results = lookupData['results'] ?? [];

            // On garde l'ordre de popularité d'iTunes

            if (lang == 'all') {
              setState(() {
                _podcasts = results.take(20).toList();
              });
            } else {
              // Filtrage strict par langue via RSS (Identique à l'ancienne version JS)
              List<dynamic> validPodcasts = [];

              for (var p in results) {
                if (validPodcasts.length >= 20) {
                  break; // Limite à 20 résultats
                }
                final feedUrl = p['feedUrl'];
                if (feedUrl == null) continue;

                try {
                  final feedRes = await http
                      .get(Uri.parse(feedUrl))
                      .timeout(const Duration(seconds: 3));
                  if (feedRes.statusCode == 200) {
                    final body = feedRes.body.toLowerCase();
                    // Recherche simple de la balise language
                    final langMatch =
                        RegExp(r'<language>\s*([^<\s]+)\s*<\/language>')
                            .firstMatch(body);
                    if (langMatch != null) {
                      final podcastLang =
                          langMatch.group(1)?.toLowerCase() ?? '';
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
      return const Center(
        child: Text(
          'Impossible de charger les suggestions.',
          style: TextStyle(
              color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
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
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      image: imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(imageUrl), fit: BoxFit.cover)
                          : null,
                      color: AppTheme.bgColor,
                    ),
                    child: imageUrl == null
                        ? const Center(
                            child: Icon(Icons.podcasts,
                                size: 40, color: Colors.grey))
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
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          genre,
                          style: const TextStyle(
                              color: AppTheme.primaryColor, fontSize: 10),
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
  const _AffinitiesTab();

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
      final userResult = await ExampleConnector.instance
          .findUserByGoogleId(googleId: googleId)
          .execute();
      if (userResult.data.users.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }
      final postgresUuid = userResult.data.users.first.id;

      // 2. Obtenir ses propres abonnements
      final subsResult = await ExampleConnector.instance
          .getMySubscriptions(userId: postgresUuid)
          .execute();
      final mySubs = subsResult.data.subscriptionTypes;

      if (mySubs.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final mySubFeeds = mySubs
          .map((s) => s.podcast.feedUrl.toLowerCase())
          .where((u) => u.isNotEmpty)
          .toSet();

      // 3. Obtenir les recommandations pour les 5 premiers abonnements
      final topSubs = mySubs.take(5).toList();

      Map<String, Map<String, dynamic>> recommendationCounts = {};

      for (var sub in topSubs) {
        final feedUrl = sub.podcast.feedUrl;
        if (feedUrl.isEmpty) continue;

        final recResult = await ExampleConnector.instance
            .getRecommendations(feedUrl: feedUrl)
            .execute();

        for (var st in recResult.data.subscriptionTypes) {
          for (var userSub in st.user.subscriptionTypes_on_user) {
            final recPodcast = userSub.podcast;
            final recFeedUrl = recPodcast.feedUrl.toLowerCase();

            // Exclure les podcasts qu'on a déjà (comparaison sur feedUrl)
            if (recFeedUrl.isNotEmpty && !mySubFeeds.contains(recFeedUrl)) {
              if (recommendationCounts.containsKey(recFeedUrl)) {
                recommendationCounts[recFeedUrl]!['count'] =
                    (recommendationCounts[recFeedUrl]!['count'] as int) + 1;
              } else {
                recommendationCounts[recFeedUrl] = {
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
          if (feedUrl == null) {
            continue;
          }

          try {
            final feedRes = await http
                .get(Uri.parse(feedUrl))
                .timeout(const Duration(seconds: 3));
            if (feedRes.statusCode == 200) {
              final body = feedRes.body.toLowerCase();
              final langMatch = RegExp(r'<language>\s*([^<\s]+)\s*<\/language>')
                  .firstMatch(body);
              if (langMatch != null) {
                final podcastLang = langMatch.group(1)?.toLowerCase() ?? '';
                if (podcastLang.startsWith(lang)) {
                  validPodcasts.add(p);
                }
              } else {
                validPodcasts.add(p);
              }
            } else {
              // On accepte par défaut si le flux n'est pas accessible (ex: test)
              validPodcasts.add(p);
            }
          } catch (e) {
            // Ignorer l'erreur réseau mais accepter le podcast par défaut
            validPodcasts.add(p);
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
      return const Center(
        child: Text(
          'Connectez-vous pour voir les recommandations basées sur vos goûts.',
          style: TextStyle(
              color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recommendedPodcasts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Abonnez-vous à plus de podcasts pour voir ce que d\'autres auditeurs aux mêmes goûts écoutent !',
            style: TextStyle(
                color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
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
        final p = _recommendedPodcasts[index]
            as GetRecommendationsSubscriptionTypesUserSubscriptionTypesOnUserPodcast;
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
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      image: imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(imageUrl), fit: BoxFit.cover)
                          : null,
                      color: AppTheme.bgColor,
                    ),
                    child: imageUrl == null
                        ? const Center(
                            child: Icon(Icons.podcasts,
                                size: 40, color: Colors.grey))
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
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        author,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11),
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
