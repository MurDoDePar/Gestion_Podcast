import 'package:flutter/material.dart';
import '../../models/podcast_model.dart';
import '../../services/database_repository.dart';
import '../../theme/app_theme.dart';
import '../podcast_details_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  late Future<List<PodcastModel>> _recommendationsFuture;

  @override
  void initState() {
    super.initState();
    _recommendationsFuture = DatabaseRepository().getRecommendations();
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _recommendationsFuture = DatabaseRepository().getRecommendations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.primaryColor,
      backgroundColor: AppTheme.surfaceColor,
      onRefresh: _handleRefresh,
      child: FutureBuilder<List<PodcastModel>>(
        future: _recommendationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: AppTheme.dangerColor,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Erreur de chargement',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Impossible de charger vos découvertes pour le moment.',
                      style: TextStyle(color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _handleRefresh,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          final list = snapshot.data ?? [];

          if (list.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                padding: const EdgeInsets.all(24.0),
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: AppTheme.surfaceColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        size: 50,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Aucune recommandation',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Abonnez-vous à des podcasts pour que nous puissions identifier vos genres préférés et vous suggérer des nouveautés.',
                      style:
                          TextStyle(color: AppTheme.textSecondary, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            itemCount: list.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                // En-tête expliquant les suggestions par thèmes
                return Container(
                  margin: const EdgeInsets.only(bottom: 16.0, top: 8.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withValues(alpha: 0.15),
                        const Color(0xFF24163B).withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.25),
                      width: 1.0,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          color: AppTheme.primaryColor, size: 28),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Découvertes par Thèmes',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Suggestions basées sur les thématiques des podcasts de votre bibliothèque.',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              final podcast = list[index - 1];

              return Card(
                color: AppTheme.surfaceColor,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
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
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        // Image / Logo
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: podcast.artworkUrl.isNotEmpty
                              ? Image.network(
                                  podcast.artworkUrl,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: 64,
                                    height: 64,
                                    color: AppTheme.bgColor,
                                    child: const Icon(Icons.podcasts,
                                        color: AppTheme.textSecondary),
                                  ),
                                )
                              : Container(
                                  width: 64,
                                  height: 64,
                                  color: AppTheme.bgColor,
                                  child: const Icon(Icons.podcasts,
                                      color: AppTheme.textSecondary),
                                ),
                        ),
                        const SizedBox(width: 16),

                        // Textes & Genres associés
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Badge indiquant le genre déclencheur
                              if (podcast.recommendedByGenre != null &&
                                  podcast.recommendedByGenre!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.tag,
                                          size: 10,
                                          color: AppTheme.primaryColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        podcast.recommendedByGenre!,
                                        style: const TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 6),
                              Text(
                                podcast.collectionName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
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

                        const Icon(
                          Icons.chevron_right,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
