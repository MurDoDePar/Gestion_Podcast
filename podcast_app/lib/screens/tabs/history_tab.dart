import 'package:flutter/material.dart';
import '../../services/history_tab_service.dart';
import '../../core/services/service_locator.dart';
import '../../theme/app_theme.dart';
import '../../widgets/episode_list_tile.dart';

class HistoryTab extends StatefulWidget {
  /// Le service d'accès aux données de l'historique.
  ///
  /// Injecté via le constructeur pour permettre l'injection de dépendances (DI).
  /// Cela permet de tester le widget en isolation en fournissant un mock du service
  /// (ex: `MockHistoryTabService`) plutôt que d'utiliser la base de données réelle.
  final HistoryTabService service;

  /// Crée un onglet pour afficher l'historique des épisodes lus.
  ///
  /// Si [service] n'est pas fourni, utilise [HistoryTabService] résolu par le locator par défaut.
  HistoryTab({
    super.key,
    HistoryTabService? service,
  }) : service = service ?? locator<HistoryTabService>();

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.service.refresh();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Déclenche le chargement de la page suivante à 200 pixels du bas de la liste (padding de sécurité)
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !widget.service.isLoading &&
        widget.service.hasMore) {
      widget.service.loadMore();
    }
  }

  Future<void> _handleRefresh() async {
    await widget.service.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: ListenableBuilder(
        listenable: widget.service,
        builder: (context, _) {
          final episodes = widget.service.episodes;
          final isLoading = widget.service.isLoading;
          final hasMore = widget.service.hasMore;

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            color: AppTheme.primaryColor,
            child: episodes.isEmpty && !isLoading
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.2),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.history,
                              size: 64,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Aucun épisode lu pour le moment',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 32.0),
                              child: Text(
                                'Les podcasts que vous écoutez apparaîtront ici dans l\'historique.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.textSecondary
                                      .withValues(alpha: 0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    itemCount: episodes.length + (hasMore ? 1 : 0),
                    separatorBuilder: (context, index) => const Divider(
                      color: AppTheme.surfaceColor,
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      if (index == episodes.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        );
                      }
                      final episode = episodes[index];
                      return EpisodeListTile(episode: episode);
                    },
                  ),
          );
        },
      ),
    );
  }
}
