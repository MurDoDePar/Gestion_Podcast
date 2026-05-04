import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/audio_service.dart';

class AudioPlayerWidget extends StatefulWidget {
  const AudioPlayerWidget({super.key});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioService _audioService = AudioService();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AudioEpisode?>(
      valueListenable: _audioService.currentEpisodeNotifier,
      builder: (context, episode, child) {
        if (episode == null) return const SizedBox.shrink();

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Barre de progression
              ValueListenableBuilder<Duration>(
                valueListenable: _audioService.progressNotifier,
                builder: (context, progress, child) {
                  return ValueListenableBuilder<Duration>(
                    valueListenable: _audioService.totalDurationNotifier,
                    builder: (context, total, child) {
                      final progressValue = total.inMilliseconds > 0
                          ? progress.inMilliseconds / total.inMilliseconds
                          : 0.0;
                      return LinearProgressIndicator(
                        value: progressValue.clamp(0.0, 1.0),
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        minHeight: 3,
                      );
                    },
                  );
                },
              ),
              
              // Contenu du lecteur
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    // Image
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.bgColor,
                        borderRadius: BorderRadius.circular(8),
                        image: episode.imageUrl != null
                            ? DecorationImage(
                                image: NetworkImage(episode.imageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: episode.imageUrl == null
                          ? const Icon(Icons.podcasts, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    
                    // Infos
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            episode.title,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            episode.podcastName,
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
                    
                    // Contrôles
                    ValueListenableBuilder<bool>(
                      valueListenable: _audioService.isPlayingNotifier,
                      builder: (context, isPlaying, child) {
                        return IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                            color: AppTheme.primaryColor,
                            size: 40,
                          ),
                          onPressed: () {
                            _audioService.togglePlayPause();
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

