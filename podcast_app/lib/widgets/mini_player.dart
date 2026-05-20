import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart' as package_audio_service;
import 'package:podcast_app/services/audio_handler_locator.dart';
import '../theme/app_theme.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  String _formatDuration(Duration? duration) {
    if (duration == null) return "00:00";
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
    if (globalAudioHandler == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<package_audio_service.MediaItem?>(
      stream: globalAudioHandler!.mediaItem,
      builder: (context, mediaSnapshot) {
        final item = mediaSnapshot.data;

        // Si aucun média n'est en cours, ou si c'est un leurre/chargement, on n'affiche rien
        if (item == null ||
            item.id == 'root' ||
            item.id.startsWith('loading_')) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: const Color(
                0xFF24163B), // Elegant dark violet for contrast with AppTheme.primaryColor
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Miniature de l'épisode (à gauche)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(8),
                      image: item.artUri != null
                          ? DecorationImage(
                              image: NetworkImage(item.artUri!.toString()),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: item.artUri == null
                        ? const Icon(Icons.podcasts,
                            color: Colors.white, size: 24)
                        : null,
                  ),
                  const SizedBox(width: 12),

                  // Titre de l'épisode et nom du podcast (au centre)
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.artist ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Boutons de contrôle (à droite)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Reculer de 30s
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.replay_30,
                            color: Colors.white, size: 26),
                        onPressed: () => globalAudioHandler?.rewind(),
                      ),
                      const SizedBox(width: 10),

                      // Play/Pause dynamique
                      StreamBuilder<package_audio_service.PlaybackState>(
                        stream: globalAudioHandler!.playbackState,
                        builder: (context, playbackSnapshot) {
                          final isPlaying =
                              playbackSnapshot.data?.playing ?? false;
                          return IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                              color: Colors.white,
                              size: 36,
                            ),
                            onPressed: () {
                              if (isPlaying) {
                                globalAudioHandler?.pause();
                              } else {
                                globalAudioHandler?.play();
                              }
                            },
                          );
                        },
                      ),
                      const SizedBox(width: 10),

                      // Avancer de 30s
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.forward_30,
                            color: Colors.white, size: 26),
                        onPressed: () => globalAudioHandler?.fastForward(),
                      ),
                      const SizedBox(width: 10),

                      // Coche "Marquer comme lu"
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.check_circle_outline,
                            color: Colors.white, size: 24),
                        onPressed: () async {
                          final episodeId =
                              item.extras?['episodeId'] as String? ?? item.id;
                          try {
                            if (globalAudioHandler != null) {
                              final currentMedia =
                                  globalAudioHandler!.mediaItem.value;
                              if (currentMedia?.duration != null) {
                                try {
                                  await globalAudioHandler!.seek(
                                    currentMedia!.duration! -
                                        const Duration(milliseconds: 500),
                                  );
                                } catch (seekError) {
                                  print(
                                      'Seek failed in mini player: $seekError');
                                }
                              }
                            }

                            // Conserve la persistance
                            await globalAudioHandler?.customAction(
                                'mark_as_read', {'episodeId': episodeId});
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Épisode marqué comme lu'),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }
                          } catch (e) {
                            print('AA_DEBUG_UI_CRASH_CATCH: $e');
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Barre de progression en temps réel
              StreamBuilder<Duration>(
                stream: package_audio_service.AudioService.position,
                builder: (context, positionSnapshot) {
                  final progress = positionSnapshot.data ?? Duration.zero;
                  final total = item.duration ?? Duration.zero;

                  // Validation et clamp des valeurs pour éviter les divisions par zéro
                  final totalMs = total.inMilliseconds;
                  final progressMs = progress.inMilliseconds;
                  final progressValue = totalMs > 0
                      ? (progressMs / totalMs).clamp(0.0, 1.0)
                      : 0.0;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2.0,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 5.0),
                          overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 10.0),
                          activeTrackColor: AppTheme.primaryColor,
                          inactiveTrackColor:
                              AppTheme.primaryColor.withOpacity(0.2),
                          thumbColor: AppTheme.primaryColor,
                        ),
                        child: SizedBox(
                          height: 12,
                          child: Slider(
                            value: progressValue,
                            onChanged: (value) {
                              final newPosition = Duration(
                                  milliseconds: (value * totalMs).round());
                              globalAudioHandler?.seek(newPosition);
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(progress),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              _formatDuration(total),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
