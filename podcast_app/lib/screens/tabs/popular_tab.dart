import 'package:flutter/material.dart';
import '../../models/podcast_model.dart';
import '../../services/itunes_service.dart';
import '../../theme/app_theme.dart';
import '../podcast_details_screen.dart';

class PopularTab extends StatelessWidget {
  const PopularTab({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PodcastModel>>(
      future: ItunesService().getTopPodcasts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Erreur lors du chargement',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          );
        }

        final podcasts = snapshot.data ?? [];

        if (podcasts.isEmpty) {
          return const Center(
            child: Text(
              'Aucun podcast populaire trouvé',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 0.72,
          ),
          itemCount: podcasts.length,
          itemBuilder: (context, index) {
            final podcast = podcasts[index];
            return GestureDetector(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8.0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        image: podcast.artworkUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(podcast.artworkUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: podcast.artworkUrl.isEmpty
                          ? const Center(
                              child: Icon(
                                Icons.podcasts,
                                size: 48,
                                color: AppTheme.textSecondary,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    podcast.collectionName,
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    podcast.artistName,
                    style: const TextStyle(
                      fontSize: 12.0,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
