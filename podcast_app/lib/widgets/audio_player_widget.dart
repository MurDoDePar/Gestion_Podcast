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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

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
              // Barre de progression avec Slider et temps
              ValueListenableBuilder<Duration>(
                valueListenable: _audioService.progressNotifier,
                builder: (context, progress, child) {
                  return ValueListenableBuilder<Duration>(
                    valueListenable: _audioService.totalDurationNotifier,
                    builder: (context, total, child) {
                      final progressValue = total.inMilliseconds > 0
                          ? progress.inMilliseconds / total.inMilliseconds
                          : 0.0;
                      final remaining =
                          total.inMilliseconds > progress.inMilliseconds
                              ? total - progress
                              : Duration.zero;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3.0,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6.0),
                              overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 14.0),
                              trackShape: const RectangularSliderTrackShape(),
                            ),
                            child: SizedBox(
                              height: 20,
                              child: Slider(
                                value: progressValue.clamp(0.0, 1.0),
                                onChanged: (value) {
                                  final newPosition = Duration(
                                      milliseconds:
                                          (value * total.inMilliseconds)
                                              .round());
                                  _audioService.seek(newPosition);
                                },
                                activeColor: AppTheme.primaryColor,
                                inactiveColor:
                                    AppTheme.primaryColor.withOpacity(0.3),
                              ),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(progress),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary),
                                ),
                                Text(
                                  _formatDuration(remaining),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),

              // Contenu du lecteur
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.replay_30,
                              color: AppTheme.primaryColor, size: 28),
                          onPressed: () => _audioService.seekBackward30(),
                        ),
                        const SizedBox(width: 8),
                        ValueListenableBuilder<bool>(
                          valueListenable: _audioService.isPlayingNotifier,
                          builder: (context, isPlaying, child) {
                            return IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                                color: AppTheme.primaryColor,
                                size: 40,
                              ),
                              onPressed: () {
                                _audioService.togglePlayPause();
                              },
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.forward_30,
                              color: AppTheme.primaryColor, size: 28),
                          onPressed: () => _audioService.seekForward30(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Marquer comme lu',
                          icon: const Icon(Icons.check_circle_outline,
                              color: AppTheme.primaryColor, size: 28),
                          onPressed: () async {
                            final success = await _audioService.markAsRead();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success
                                      ? 'Épisode marqué comme lu'
                                      : 'Impossible de marquer comme lu (êtes-vous abonné à ce podcast ?)'),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          },
                        ),
                      ],
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
