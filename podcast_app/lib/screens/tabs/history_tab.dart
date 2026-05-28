import 'package:flutter/material.dart';
import '../../models/episode_model.dart';
import '../../services/database_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/episode_list_tile.dart';

class HistoryTab extends StatefulWidget {
  /// Le repository d'accès aux données.
  ///
  /// Injecté via le constructeur pour permettre l'injection de dépendances (DI).
  /// Cela permet de tester le widget en isolation en fournissant un mock du repository
  /// (ex: `MockDatabaseRepository`) plutôt que d'utiliser la base de données réelle SQLite/Firebase.
  final DatabaseRepository repository;

  /// Crée un onglet pour afficher l'historique des épisodes lus.
  ///
  /// Si [repository] n'est pas fourni, utilise [DatabaseRepository] par défaut.
  HistoryTab({
    super.key,
    DatabaseRepository? repository,
  }) : repository = repository ?? DatabaseRepository();

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  final ScrollController _scrollController = ScrollController();
  final List<EpisodeModel> _episodes = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  static const int _limit = 20;

  @override
  void initState() {
    super.initState();
    _loadMoreEpisodes();
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
        !_isLoading &&
        _hasMore) {
      _loadMoreEpisodes();
    }
  }

  Future<void> _loadMoreEpisodes({bool refresh = false}) async {
    if (_isLoading) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        if (refresh) {
          _episodes.clear();
          _offset = 0;
          _hasMore = true;
        }
      });
    }

    try {
      final newEpisodes = await widget.repository
          .getReadEpisodesHistory(limit: _limit, offset: _offset);

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (newEpisodes.length < _limit) {
            _hasMore = false;
          }
          _episodes.addAll(newEpisodes);
          _offset += newEpisodes.length;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint("Error loading history in HistoryTab: $e");
    }
  }

  Future<void> _handleRefresh() async {
    await _loadMoreEpisodes(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppTheme.primaryColor,
        child: _episodes.isEmpty && !_isLoading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
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
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text(
                            'Les podcasts que vous écoutez apparaîtront ici dans l\'historique.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:
                                  AppTheme.textSecondary.withValues(alpha: 0.7),
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
                itemCount: _episodes.length + (_hasMore ? 1 : 0),
                separatorBuilder: (context, index) => const Divider(
                  color: AppTheme.surfaceColor,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  if (index == _episodes.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    );
                  }
                  final episode = _episodes[index];
                  return EpisodeListTile(episode: episode);
                },
              ),
      ),
    );
  }
}
