import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../dataconnect-generated/example.dart';
import '../../models/podcast_model.dart';
import '../../models/episode_model.dart';
import '../../screens/podcast_details_screen.dart';
import '../../services/database_repository.dart';
import '../../services/rss_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/episode_list_tile.dart';
import '../../services/audio_service.dart' as app_audio;

class MyPodcastsTab extends StatefulWidget {
  const MyPodcastsTab({super.key});

  @override
  State<MyPodcastsTab> createState() => _MyPodcastsTabState();
}

class _MyPodcastsTabState extends State<MyPodcastsTab> {
  Future<List<PodcastModel>>? _podcastsFuture;
  List<PodcastModel>? _myPodcastsList;
  Future<List<EpisodeModel>>? _episodesFuture;

  @override
  void initState() {
    super.initState();
    _podcastsFuture = DatabaseRepository().getMySubscribedPodcasts();
    app_audio.AudioService().listRefreshNotifier.addListener(_onListRefresh);
  }

  @override
  void dispose() {
    app_audio.AudioService().listRefreshNotifier.removeListener(_onListRefresh);
    super.dispose();
  }

  void _onListRefresh() {
    if (mounted) {
      setState(() {
        _triggerEpisodesRefresh();
      });
    }
  }

  /// Compare si deux listes de podcasts contiennent exactement les mêmes éléments (sans se soucier de l'ordre)
  bool _areSetsEqual(List<PodcastModel> a, List<PodcastModel> b) {
    if (a.length != b.length) return false;
    final setA = a.map((p) => p.feedUrl).toSet();
    final setB = b.map((p) => p.feedUrl).toSet();
    return setA.containsAll(setB);
  }

  void _triggerEpisodesRefresh() {
    if (_myPodcastsList != null && _myPodcastsList!.isNotEmpty) {
      _episodesFuture = _fetchAndAggregateEpisodes(_myPodcastsList!);
    } else {
      _episodesFuture = Future.value(<EpisodeModel>[]);
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (_myPodcastsList == null) return;
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _myPodcastsList!.removeAt(oldIndex);
      _myPodcastsList!.insert(newIndex, item);

      // Déclenche un rafraîchissement immédiat de la section "À écouter" selon le nouvel ordre
      _triggerEpisodesRefresh();
    });

    // Sauvegarde asynchrone en tâche de fond dans Firestore
    DatabaseRepository().updatePodcastsOrder(_myPodcastsList!);
  }

  /// Récupère, filtre et trie les épisodes en respectant l'ordre des abonnements
  Future<List<EpisodeModel>> _fetchAndAggregateEpisodes(
      List<PodcastModel> subscribedPodcasts) async {
    if (subscribedPodcasts.isEmpty) return [];

    try {
      // 1. Charger tous les flux RSS en parallèle pour optimiser les performances réseau
      final List<Future<List<EpisodeModel>>> futures = subscribedPodcasts
          .map((podcast) => RssService().getEpisodesFromFeed(podcast.feedUrl))
          .toList();

      final List<List<EpisodeModel>> results = await Future.wait(futures);

      // 2. Récupérer l'historique de lecture (Data Connect) et les préférences locales (SharedPreferences)
      final Set<String> readEpisodeIds = {};
      final List<String> localReadList = [];
      String order = 'asc';

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final userResult = await ExampleConnector.instance
              .findUserByGoogleId(googleId: user.uid)
              .execute();
          if (userResult.data.users.isNotEmpty) {
            final postgresUuid = userResult.data.users.first.id;
            final historyResult = await ExampleConnector.instance
                .getListenHistory(userId: postgresUuid)
                .execute();
            readEpisodeIds.addAll(
              historyResult.data.listenHistories
                  .where((h) => h.finishedListening == true)
                  .map((h) => h.episode.id),
            );
          }
        } catch (e) {
          print("Error fetching listen history in MyPodcastsTab: $e");
        }
      }

      try {
        final prefs = await SharedPreferences.getInstance();
        localReadList.addAll(prefs.getStringList('local_read_episodes') ?? []);
        order = prefs.getString('podstream_order') ?? 'asc';
      } catch (e) {
        print("Error fetching settings in MyPodcastsTab: $e");
      }

      // 3. Traiter les épisodes dans l'ordre exact des abonnements
      final List<EpisodeModel> orderedEpisodes = [];

      for (int i = 0; i < subscribedPodcasts.length; i++) {
        final podcast = subscribedPodcasts[i];
        final podcastEpisodes = results[i];

        // A. Filtrer pour ne garder que les épisodes non lus de ce podcast
        final List<EpisodeModel> unreadEpisodes = [];
        for (var episode in podcastEpisodes) {
          if (!readEpisodeIds.contains(episode.id) &&
              !localReadList.contains(episode.id)) {
            unreadEpisodes.add(
              EpisodeModel(
                id: episode.id,
                audioUrl: episode.audioUrl,
                title: episode.title,
                podcastName: episode.podcastName.isNotEmpty
                    ? episode.podcastName
                    : podcast.collectionName,
                imageUrl: podcast
                    .artworkUrl, // Associe la pochette du podcast correspondant
                description: episode.description,
                pubDate: episode.pubDate,
              ),
            );
          }
        }

        // B. Trier les épisodes de ce podcast (le tri ascendant place les plus anciens en premier)
        unreadEpisodes.sort((a, b) {
          if (a.pubDate == null && b.pubDate == null) return 0;
          if (a.pubDate == null) return 1;
          if (b.pubDate == null) return -1;

          final cmp = a.pubDate!.compareTo(b.pubDate!);
          return order == 'asc' ? cmp : -cmp;
        });

        // C. Ajouter à la liste globale
        orderedEpisodes.addAll(unreadEpisodes);
      }

      return orderedEpisodes;
    } catch (e) {
      print('Erreur lors de l\'agrégation ordonnée des épisodes : $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PodcastModel>>(
      future: _podcastsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _myPodcastsList == null) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          );
        }

        if (snapshot.hasError && _myPodcastsList == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Erreur lors du chargement des podcasts : ${snapshot.error}',
                style: const TextStyle(color: AppTheme.dangerColor),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          final fetched = snapshot.data!;
          if (_myPodcastsList == null ||
              !_areSetsEqual(_myPodcastsList!, fetched)) {
            _myPodcastsList = List.from(fetched);
            _triggerEpisodesRefresh();
          }
        }

        final podcasts = _myPodcastsList ?? [];

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1 : Titre "Mes Podcasts"
              const Padding(
                padding: EdgeInsets.only(
                    left: 16.0, top: 16.0, right: 16.0, bottom: 8.0),
                child: Text(
                  'Mes Podcasts',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),

              // Section 1 : Carrousel horizontal réorganisable
              if (podcasts.isEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Aucun podcast abonné. Recherchez et abonnez-vous à un podcast !',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                SizedBox(
                  height: 220,
                  child: ReorderableListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: podcasts.length,
                    onReorder: _onReorder,
                    itemBuilder: (context, index) {
                      final podcast = podcasts[index];
                      return GestureDetector(
                        key: ValueKey(podcast.feedUrl),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PodcastDetailsScreen(
                                podcast: podcast.toMap(),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 140,
                          margin: const EdgeInsets.only(right: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Pochette
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceColor,
                                  borderRadius: BorderRadius.circular(16),
                                  image: podcast.artworkUrl.isNotEmpty
                                      ? DecorationImage(
                                          image:
                                              NetworkImage(podcast.artworkUrl),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: podcast.artworkUrl.isEmpty
                                    ? const Icon(
                                        Icons.podcasts,
                                        size: 40,
                                        color: AppTheme.textSecondary,
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 8),
                              // Titre
                              Text(
                                podcast.collectionName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              // Auteur
                              Text(
                                podcast.artistName,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Espacement entre les deux sections
              const SizedBox(height: 24),

              // Section 2 : Titre "A écouter"
              const Padding(
                padding: EdgeInsets.only(
                    left: 16.0, top: 8.0, right: 16.0, bottom: 8.0),
                child: Text(
                  'A écouter',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),

              // Section 2 : Liste verticale dynamique issue de tous les abonnements triés/filtrés par priorité
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: FutureBuilder<List<EpisodeModel>>(
                  future: _episodesFuture,
                  builder: (context, episodeSnapshot) {
                    if (episodeSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryColor),
                          ),
                        ),
                      );
                    }

                    if (episodeSnapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            'Erreur lors du chargement des épisodes : ${episodeSnapshot.error}',
                            style: const TextStyle(color: AppTheme.dangerColor),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    final episodes = episodeSnapshot.data ?? [];
                    if (episodes.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Text(
                            'Aucun épisode disponible.',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: episodes.length > 20 ? 20 : episodes.length,
                      itemBuilder: (context, index) {
                        return EpisodeListTile(episode: episodes[index]);
                      },
                    );
                  },
                ),
              ),

              // Marge inférieure pour éviter que le mini player ne masque les derniers éléments
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }
}
