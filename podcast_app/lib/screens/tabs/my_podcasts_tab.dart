import 'package:flutter/material.dart';
import '../../models/podcast_model.dart';
import '../../screens/podcast_details_screen.dart';
import '../../services/podcasts_tab_service.dart';
import '../../services/podcast_cache_manager.dart';
import '../../core/services/service_locator.dart';
import '../../theme/app_theme.dart';
import '../../widgets/episode_list_tile.dart';
import '../../services/audio_service.dart' as app_audio;
import '../../services/app_state_notifier.dart';

class MyPodcastsTab extends StatefulWidget {
  final PodcastsTabService service;

  MyPodcastsTab({
    super.key,
    PodcastsTabService? service,
  }) : service = service ?? locator<PodcastsTabService>();

  @override
  State<MyPodcastsTab> createState() => _MyPodcastsTabState();
}

class _MyPodcastsTabState extends State<MyPodcastsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.service.refresh();
    });
    app_audio.AudioService().listRefreshNotifier.addListener(_onListRefresh);
    locator<PodcastCacheManager>().addListener(_onCacheRefresh);
  }

  @override
  void dispose() {
    app_audio.AudioService().listRefreshNotifier.removeListener(_onListRefresh);
    locator<PodcastCacheManager>().removeListener(_onCacheRefresh);
    super.dispose();
  }

  void _onListRefresh() {
    if (mounted) {
      widget.service.refresh();
    }
  }

  void _onCacheRefresh() {
    if (mounted) {
      widget.service.refresh();
    }
  }

  void _onReorderItem(int oldIndex, int newIndex) {
    final list = List<PodcastModel>.from(widget.service.subscribedPodcasts);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    widget.service.updatePodcastsOrder(list).then((_) {
      AppStateNotifier().notifyCacheUpdate();
    }).catchError((_) {});
  }

  Future<void> _onRefreshEpisodes() async {
    try {
      await widget.service.refresh(forceRefresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Épisodes rafraîchis avec succès."),
            backgroundColor: AppTheme.primaryColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Impossible de rafraîchir : ${e.toString()}"),
            backgroundColor: AppTheme.dangerColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.service,
      builder: (context, _) {
        if (widget.service.isLoading &&
            widget.service.subscribedPodcasts.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          );
        }

        if (widget.service.errorMessage != null &&
            widget.service.subscribedPodcasts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Erreur lors du chargement des podcasts : ${widget.service.errorMessage}',
                style: const TextStyle(color: AppTheme.dangerColor),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final podcasts = widget.service.subscribedPodcasts;
        final episodes = widget.service.episodesToListen;

        return RefreshIndicator(
          onRefresh: _onRefreshEpisodes,
          color: AppTheme.primaryColor,
          backgroundColor: AppTheme.surfaceColor,
          child: SingleChildScrollView(
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
                      onReorderItem: _onReorderItem,
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
                                            image: NetworkImage(
                                                podcast.artworkUrl),
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
                  child: episodes.isEmpty
                      ? const Center(
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
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount:
                              episodes.length > 20 ? 20 : episodes.length,
                          itemBuilder: (context, index) {
                            return EpisodeListTile(episode: episodes[index]);
                          },
                        ),
                ),

                // Marge inférieure pour éviter que le mini player ne masque les derniers éléments
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }
}
