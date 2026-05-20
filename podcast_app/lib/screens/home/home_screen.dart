import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart' as xml;
import '../../theme/app_theme.dart';
import '../../dataconnect-generated/example.dart';
import '../../data/themes_data.dart';
import '../../services/audio_service.dart' as custom_audio;
import '../../services/podcast_repository.dart';
import '../podcast_details_screen.dart';
import '../../models/episode_model.dart';
import '../../widgets/episode_list_tile.dart';
// Pour l'instance globale globalAudioHandler
// Pour MediaItem

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

    final cacheKey = 'theme_${genreId}_$lang';
    final cachedData = await _getCachedPodcasts(cacheKey);
    if (cachedData != null) {
      setState(() {
        _podcasts = cachedData;
        _isLoading = false;
      });
      return;
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
              final finalPodcasts = results.take(20).toList();
              setState(() {
                _podcasts = finalPodcasts;
              });
              _savePodcastsToCache(cacheKey, finalPodcasts);
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
              _savePodcastsToCache(cacheKey, validPodcasts);
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
    custom_audio.AudioService()
        .listRefreshNotifier
        .addListener(_onRefreshRequired);
  }

  DateTime? _lastRefreshTime;

  void _onRefreshRequired() {
    if (mounted) {
      final now = DateTime.now();
      if (_lastRefreshTime == null ||
          now.difference(_lastRefreshTime!) > const Duration(minutes: 5)) {
        _lastRefreshTime = now;
        setState(() {
          _loadData();
        });
      }
    }
  }

  @override
  void dispose() {
    custom_audio.AudioService()
        .listRefreshNotifier
        .removeListener(_onRefreshRequired);
    super.dispose();
  }

  void _loadData() {
    final uid = userId;
    if (uid != null) {
      _subsFuture = PodcastRepository.fetchPodcasts(uid);
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
          _episodesFuture = PodcastRepository.fetchEpisodesToListen(googleId);
        });
      }
    });

    // 2. Lire ce qui est déjà en DB pour afficher tout de suite
    return PodcastRepository.fetchEpisodesToListen(googleId);
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
              height: 210,
              child: FutureBuilder(
                future: _subsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting ||
                      snapshot.connectionState == ConnectionState.active) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Erreur de chargement : ${snapshot.error}',
                          style: const TextStyle(color: Colors.red)),
                    );
                  }
                  if (!snapshot.hasData ||
                      snapshot.data == null ||
                      (snapshot.data as List).isEmpty) {
                    return const Center(
                      child: Text(
                        'Aucun podcast trouvé. Ajoutez-en un !',
                        style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontStyle: FontStyle.italic),
                      ),
                    );
                  }

                  final subs = snapshot.data!;

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
                if (snapshot.connectionState == ConnectionState.waiting ||
                    snapshot.connectionState == ConnectionState.active) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erreur de chargement : ${snapshot.error}',
                        style: const TextStyle(color: Colors.red)),
                  );
                }
                if (!snapshot.hasData ||
                    snapshot.data == null ||
                    (snapshot.data as List).isEmpty) {
                  return const Center(
                    child: Text(
                      'Pas d\'épisodes à écouter pour le moment.',
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic),
                    ),
                  );
                }

                final history = snapshot.data!;

                if (history.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("Aucun épisode récent"),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final episode = EpisodeModel.fromRawData(history[index]);
                    if (episode.id.isEmpty || episode.audioUrl.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return EpisodeListTile(episode: episode);
                  },
                );
              },
            ),
        ],
      ),
    );
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
                      'isSubscribed': true,
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
    final prefs = await SharedPreferences.getInstance();
    final userOrder = prefs.getString('podstream_order') ?? 'desc';

    for (var sub in subs) {
      final feedUrl = sub.podcast.feedUrl;
      if (feedUrl.isEmpty) continue;

      try {
        final response = await http
            .get(Uri.parse(feedUrl))
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final document =
              xml.XmlDocument.parse(utf8.decode(response.bodyBytes));

          final itunesType = document
                  .findAllElements('itunes:type')
                  .firstOrNull
                  ?.innerText
                  .toLowerCase() ??
              'episodic';
          final isSerial = itunesType == 'serial';

          final items = document.findAllElements('item');
          final parsedItems = <Map<String, dynamic>>[];

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
                    } catch (_) {
                      try {
                        final cleaned = pubDateStr
                            .replaceAll(RegExp(r'[+-]\d{4}\s*$'), 'GMT')
                            .trim();
                        pubDate = HttpDate.parse(cleaned);
                      } catch (_) {}
                    }
                  }
                }

                final itunesEpStr =
                    item.findElements('itunes:episode').firstOrNull?.innerText;
                final itunesEp =
                    itunesEpStr != null ? int.tryParse(itunesEpStr) : null;

                final itunesOrderStr =
                    item.findElements('itunes:order').firstOrNull?.innerText;
                final itunesOrder = itunesOrderStr != null
                    ? int.tryParse(itunesOrderStr)
                    : null;

                parsedItems.add({
                  'item': item,
                  'title': title,
                  'audioUrl': audioUrl,
                  'pubDate': pubDate,
                  'itunesEpisode': itunesEp,
                  'itunesOrder': itunesOrder,
                });
              }
            }
          }

          // Tri des épisodes
          // NE PAS MODIFIER CETTE LOGIQUE DE TRI SANS DEMANDE EXPRESSE DU DÉVELOPPEUR
          parsedItems.sort((a, b) {
            int cmp = 0;

            final matchA = RegExp(r'#(\d+)').firstMatch(a['title']);
            final matchB = RegExp(r'#(\d+)').firstMatch(b['title']);

            if (isSerial &&
                a['itunesEpisode'] != null &&
                b['itunesEpisode'] != null) {
              cmp = (a['itunesEpisode'] as int)
                  .compareTo(b['itunesEpisode'] as int);
            } else if (matchA != null && matchB != null) {
              final numA = int.parse(matchA.group(1)!);
              final numB = int.parse(matchB.group(1)!);
              cmp = numA.compareTo(numB);
            } else if (a['itunesOrder'] != null && b['itunesOrder'] != null) {
              cmp =
                  (a['itunesOrder'] as int).compareTo(b['itunesOrder'] as int);
            } else {
              cmp = (a['pubDate'] as DateTime)
                  .compareTo(b['pubDate'] as DateTime);
            }

            if (cmp == 0) {
              cmp = (a['title'] as String).compareTo(b['title'] as String);
            }
            if (userOrder == 'asc') {
              return cmp;
            } else {
              return -cmp;
            }
          });

          // Ne pas limiter pour que l'épisode #1 soit toujours accessible
          final topItems = parsedItems;

          for (var parsed in topItems) {
            final item = parsed['item'] as xml.XmlElement;
            final audioUrl = parsed['audioUrl'] as String;
            final title = parsed['title'] as String;
            final pubDate = parsed['pubDate'] as DateTime;

            final stableId = _generateStableUuid(audioUrl);

            await ExampleConnector.instance
                .upsertEpisode(
                  podcastId: sub.podcast.id,
                  title: title,
                  audioUrl: audioUrl,
                  duration: BigInt.zero,
                  publishedAt:
                      Timestamp(pubDate.millisecondsSinceEpoch ~/ 1000, 0),
                )
                .id(stableId)
                .description(
                    item.findElements('description').firstOrNull?.innerText)
                .imageUrl(sub.podcast.imageUrl)
                .execute();
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

Future<List<dynamic>?> _getCachedPodcasts(String cacheKey) async {
  try {
    final cacheResult =
        await ExampleConnector.instance.getAppCache(id: cacheKey).execute();
    if (cacheResult.data.appCache != null) {
      final updatedAt = cacheResult.data.appCache!.updatedAt.toDateTime();
      if (DateTime.now().difference(updatedAt).inDays < 7) {
        return json.decode(cacheResult.data.appCache!.data.toJson() as String);
      }
    }
  } catch (e) {
    print('Cache check error for $cacheKey: $e');
  }
  return null;
}

Future<void> _savePodcastsToCache(
    String cacheKey, List<dynamic> podcasts) async {
  try {
    await ExampleConnector.instance
        .upsertAppCache(
          id: cacheKey,
          data: AnyValue(json.encode(podcasts)),
          updatedAt:
              Timestamp(DateTime.now().millisecondsSinceEpoch ~/ 1000, 0),
        )
        .execute();
  } catch (e) {
    print('Error saving cache for $cacheKey: $e');
  }
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

    final cacheKey = 'popular_$lang';
    final cachedData = await _getCachedPodcasts(cacheKey);
    if (cachedData != null) {
      setState(() {
        _podcasts = cachedData;
        _isLoading = false;
      });
      return;
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
              final finalPodcasts = results.take(20).toList();
              setState(() {
                _podcasts = finalPodcasts;
              });
              _savePodcastsToCache(cacheKey, finalPodcasts);
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
              _savePodcastsToCache(cacheKey, validPodcasts);
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
