import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:audio_service/audio_service.dart' as package_audio_service;
import 'package:podcast_app/services/audio_handler_locator.dart'; // Pour l'instance globale globalAudioHandler
import 'package:firebase_auth/firebase_auth.dart';

class AudioPlayerWidget extends StatefulWidget {
  const AudioPlayerWidget({super.key});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  //final AudioService _audioService = AudioService();

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
    if (globalAudioHandler == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<package_audio_service.MediaItem?>(
      stream: globalAudioHandler!.mediaItem,
      builder: (context, mediaSnapshot) {
        final item = mediaSnapshot.data;
        // SECURE: On empêche l'affichage si l'élément est null ou un leurre de chargement Android Auto
        if (item == null ||
            item.id == 'root' ||
            item.id.startsWith('loading_')) {
          return const SizedBox.shrink();
        }

        final total = item.duration ?? Duration.zero;

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
              StreamBuilder<Duration>(
                stream: package_audio_service.AudioService.position,
                builder: (context, snapshot) {
                  // SECURE: Valeur par défaut robuste
                  final progress = snapshot.data ?? Duration.zero;

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
                            // SECURE: Clamp indispensable pour éviter l'erreur de rendu Flutter (écran gris)
                            value: progressValue.clamp(0.0, 1.0),
                            onChanged: (value) {
                              final newPosition = Duration(
                                  milliseconds:
                                      (value * total.inMilliseconds).round());
                              globalAudioHandler!.seek(newPosition);
                            },
                            activeColor: AppTheme.primaryColor,
                            inactiveColor:
                                AppTheme.primaryColor.withOpacity(0.3),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(progress),
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.textSecondary),
                            ),
                            Text(
                              _formatDuration(remaining),
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                        image: item.artUri != null
                            ? DecorationImage(
                                image: NetworkImage(item.artUri!.toString()),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: item.artUri == null
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
                            item.title,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            item.artist ?? '',
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
                          onPressed: () => globalAudioHandler!.rewind(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.forward_30,
                              color: AppTheme.primaryColor, size: 28),
                          onPressed: () => globalAudioHandler!.fastForward(),
                        ),
                        const SizedBox(width: 8),
                        StreamBuilder<package_audio_service.PlaybackState>(
                          stream: globalAudioHandler!.playbackState,
                          builder: (context, snapshot) {
                            // SECURE: Fallback propre
                            final state = snapshot.data;
                            final isPlaying = state?.playing ?? false;
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
                                if (isPlaying) {
                                  globalAudioHandler!.pause();
                                } else {
                                  globalAudioHandler!.play();
                                }
                              },
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Marquer comme lu',
                          icon: const Icon(Icons.check_circle_outline,
                              color: AppTheme.primaryColor, size: 28),
                          onPressed: () async {
                            print(
                                'AA_DEBUG_CLICK_LU: Clic physique détecté sur la coche violette !');
                            final episodeId =
                                item.extras?['episodeId'] as String? ?? item.id;

                            print(
                                'AA_DEBUG_GRAPHQL_VARIABLES: userId (UUID) = Non disponible dans l UI');
                            print(
                                'AA_DEBUG_GRAPHQL_VARIABLES: googleId actuel = ${FirebaseAuth.instance.currentUser?.uid ?? 'NULL Auth'}');
                            print(
                                'AA_DEBUG_GRAPHQL_VARIABLES: episodeId (UUID) = $episodeId');

                            try {
                              // ENFIN CONNECTÉ : On envoie l'ID directement au Handler global
                              globalAudioHandler?.customAction(
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
                              print(
                                  'AA_DEBUG_UI_CRASH_CATCH: Le clic a généré une exception : $e');
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
