import 'package:flutter/material.dart';
import '../../models/episode_model.dart';
import '../../services/database_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/episode_list_tile.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  late Future<List<EpisodeModel>> _futureHistory;

  @override
  void initState() {
    super.initState();
    _refreshHistory();
  }

  void _refreshHistory() {
    setState(() {
      _futureHistory = DatabaseRepository().getReadEpisodesHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshHistory();
        },
        color: AppTheme.primaryColor,
        child: FutureBuilder<List<EpisodeModel>>(
          future: _futureHistory,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Erreur lors du chargement de l\'historique',
                  style: TextStyle(color: Colors.red[300]),
                ),
              );
            }

            final history = snapshot.data ?? [];

            if (history.isEmpty) {
              return ListView(
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
                              color: AppTheme.textSecondary.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              itemCount: history.length,
              separatorBuilder: (context, index) => const Divider(
                color: AppTheme.surfaceColor,
                height: 1,
              ),
              itemBuilder: (context, index) {
                final episode = history[index];
                return EpisodeListTile(episode: episode);
              },
            );
          },
        ),
      ),
    );
  }
}
