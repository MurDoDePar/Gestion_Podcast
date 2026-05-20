import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:audio_service/audio_service.dart';
import '../dataconnect-generated/example.dart';
import 'podstream_audio_handler.dart'; // Pour accéder à podstreamAudioHandler
import 'package:podcast_app/services/audio_handler_locator.dart'; // Pour accéder à l'instance globale globalAudioHandler
import 'package:shared_preferences/shared_preferences.dart';

class AudioEpisode {
  final String id;
  final String title;
  final String podcastName;
  final String? imageUrl;
  final String audioUrl;

  AudioEpisode({
    required this.id,
    required this.title,
    required this.podcastName,
    this.imageUrl,
    required this.audioUrl,
  });
}

class AudioService {
  // Singleton
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal() {
    _init();
  }

  // State Notifiers for UI
  final ValueNotifier<AudioEpisode?> currentEpisodeNotifier =
      ValueNotifier(null);
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);
  final ValueNotifier<Duration> progressNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> totalDurationNotifier =
      ValueNotifier(Duration.zero);
  final ValueNotifier<int> listRefreshNotifier = ValueNotifier(0);

  List<AudioEpisode> currentPlaylist = [];
  int currentPlaylistIndex = -1;

  final Set<String> _processingReadEpisodes = {};

  Future<void> _init() async {
    if (globalAudioHandler == null || podstreamAudioHandler == null) return;

    // Écoute de l'état de lecture depuis globalAudioHandler
    globalAudioHandler!.playbackState.listen((state) {
      final isPlaying = state.playing;
      final processingState = state.processingState;

      if (processingState == AudioProcessingState.completed) {
        markAsRead();
      } else {
        isPlayingNotifier.value = isPlaying;
      }
    });

    // Écoute de la position en continu (seconde par seconde)
    podstreamAudioHandler!.positionStream.listen((position) {
      progressNotifier.value = position;
    });

    // Update current episode from mediaItem
    globalAudioHandler!.mediaItem.listen((item) {
      if (item != null) {
        currentEpisodeNotifier.value = AudioEpisode(
          id: item.extras?['episodeId'] as String? ?? item.id,
          title: item.title,
          podcastName: item.artist ?? '',
          imageUrl: item.artUri?.toString(),
          audioUrl: item.id, // Assuming URL is used as ID
        );
        totalDurationNotifier.value = item.duration ?? Duration.zero;
      }
    });
  }

  Future<void> playNextEpisode() async {
    if (globalAudioHandler == null) return;
    if (currentPlaylistIndex != -1 &&
        currentPlaylistIndex < currentPlaylist.length - 1) {
      final nextEpisode = currentPlaylist[currentPlaylistIndex + 1];
      await playEpisode(nextEpisode, playlist: currentPlaylist);
    } else {
      isPlayingNotifier.value = false;
      await globalAudioHandler!.stop();
    }
  }

  /// Jouer un nouvel épisode
  Future<void> playEpisode(AudioEpisode episode,
      {List<AudioEpisode>? playlist}) async {
    if (globalAudioHandler == null || podstreamAudioHandler == null) return;
    if (playlist != null) {
      currentPlaylist = playlist;
      currentPlaylistIndex =
          currentPlaylist.indexWhere((e) => e.audioUrl == episode.audioUrl);
      if (currentPlaylistIndex == -1) {
        currentPlaylist = [episode];
        currentPlaylistIndex = 0;
      }
    } else {
      currentPlaylist = [episode];
      currentPlaylistIndex = 0;
    }

    if (currentEpisodeNotifier.value?.audioUrl == episode.audioUrl) {
      if (isPlayingNotifier.value) {
        await globalAudioHandler!.pause();
      } else {
        await globalAudioHandler!.play();
      }
      return;
    }

    // Sinon on charge un nouvel épisode
    currentEpisodeNotifier.value = episode;
    isPlayingNotifier.value = true; // Optimistic UI

    try {
      final mediaItem = MediaItem(
        id: episode.audioUrl,
        title: episode.title,
        artist: episode.podcastName,
        artUri: episode.imageUrl != null ? Uri.parse(episode.imageUrl!) : null,
        extras: {'episodeId': episode.id},
      );

      await globalAudioHandler!.playMediaItem(mediaItem);

      // Update library for Android Auto based on the current playlist
      final libraryItems = currentPlaylist
          .map((e) => MediaItem(
                id: e.audioUrl,
                title: e.title,
                artist: e.podcastName,
                artUri: e.imageUrl != null ? Uri.parse(e.imageUrl!) : null,
                extras: {'episodeId': e.id},
              ))
          .toList();
      podstreamAudioHandler!.updateLibrary(libraryItems);
    } catch (e) {
      print("Erreur de chargement audio: $e");
      isPlayingNotifier.value = false;
    }
  }

  /// Reprendre ou Mettre en pause
  Future<void> togglePlayPause() async {
    if (globalAudioHandler == null) return;
    if (isPlayingNotifier.value) {
      await globalAudioHandler!.pause();
    } else {
      if (currentEpisodeNotifier.value != null) {
        await globalAudioHandler!.play();
      }
    }
  }

  /// Chercher une position (Seek)
  Future<void> seek(Duration position) async {
    await globalAudioHandler?.seek(position);
  }

  Future<void> seekForward30() async {
    if (globalAudioHandler == null) return;
    final currentPosition = progressNotifier.value;
    final newPosition = currentPosition + const Duration(seconds: 30);
    await globalAudioHandler!.seek(newPosition);
  }

  Future<void> seekBackward30() async {
    if (globalAudioHandler == null) return;
    final currentPosition = progressNotifier.value;
    final newPosition = currentPosition - const Duration(seconds: 30);
    await globalAudioHandler!
        .seek(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  String _formatUuid(String rawId) {
    if (rawId.contains('-')) return rawId;
    if (rawId.length == 32) {
      return '${rawId.substring(0, 8)}-${rawId.substring(8, 12)}-${rawId.substring(12, 16)}-${rawId.substring(16, 20)}-${rawId.substring(20, 32)}';
    }
    return rawId;
  }

  /// Marque l'épisode actuellement actif comme lu
  Future<bool> markAsRead() async {
    final episode = currentEpisodeNotifier.value;
    if (episode == null) return false;
    await markEpisodeAsRead(
      episode.id,
      episode.audioUrl,
      episode.title,
      episode.podcastName,
      episode.imageUrl ?? '',
    );
    return true;
  }

  /// Marque un épisode spécifique comme lu, avec synchronisation du lecteur s'il est actif
  Future<void> markEpisodeAsRead(
    String episodeId,
    String audioUrl,
    String title,
    String podcastName,
    String imageUrl,
  ) async {
    if (_processingReadEpisodes.contains(episodeId)) return;
    _processingReadEpisodes.add(episodeId);

    try {
      // 1. Si c'est l'épisode en cours de lecture, on avance instantanément le curseur à la fin
      if (globalAudioHandler != null) {
        final currentMedia = globalAudioHandler!.mediaItem.value;
        if (currentMedia != null &&
            (currentMedia.id == episodeId ||
                currentMedia.id == audioUrl ||
                (currentMedia.extras?['episodeId'] as String? ?? '') ==
                    episodeId)) {
          if (currentMedia.duration != null) {
            try {
              final seekPos =
                  currentMedia.duration! - const Duration(milliseconds: 500);
              await globalAudioHandler!
                  .seek(seekPos > Duration.zero ? seekPos : Duration.zero);
            } catch (seekError) {
              print('Seek failed, stopping player: $seekError');
              try {
                await globalAudioHandler!.stop();
              } catch (_) {}
            }
          }
        }
      }

      // 2. Persistance dans Firestore (finishedListening = true)
      final user = FirebaseAuth.instance.currentUser;
      bool useMockFallback = episodeId.startsWith('mock_');

      if (user != null && !useMockFallback) {
        try {
          final userResult = await ExampleConnector.instance
              .findUserByGoogleId(googleId: user.uid)
              .execute();
          if (userResult.data.users.isNotEmpty) {
            final postgresUuid = userResult.data.users.first.id;
            final formattedEpisodeId = _formatUuid(episodeId);

            int durationSeconds = 600;
            if (globalAudioHandler != null) {
              final activeMediaItem = globalAudioHandler!.mediaItem.value;
              if (activeMediaItem != null) {
                final activeEpisodeId =
                    activeMediaItem.extras?['episodeId'] as String? ??
                        activeMediaItem.id;
                if (activeEpisodeId == episodeId ||
                    activeMediaItem.id == audioUrl) {
                  durationSeconds = activeMediaItem.duration?.inSeconds ?? 600;
                }
              }
            }

            await ExampleConnector.instance
                .updateListenHistory(
                  userId: postgresUuid,
                  episodeId: formattedEpisodeId,
                  progressSeconds: BigInt.from(durationSeconds),
                  finishedListening: true,
                  listenedAt: Timestamp(
                      DateTime.now().millisecondsSinceEpoch ~/ 1000, 0),
                )
                .execute();
          }
        } catch (e) {
          print('AA_DEBUG_GRAPHQL_ERROR: updateListenHistory failed: $e');
        }
      } else {
        useMockFallback = true;
      }

      // 3. Sauvegarde locale dans les SharedPreferences (inconditionnelle pour masquage instantané)
      try {
        final prefs = await SharedPreferences.getInstance();
        final localReadList = prefs.getStringList('local_read_episodes') ?? [];
        if (!localReadList.contains(episodeId)) {
          localReadList.add(episodeId);
          await prefs.setStringList('local_read_episodes', localReadList);
        }
      } catch (e) {
        print("Erreur SharedPreferences markEpisodeAsRead: $e");
      }

      // Déclencher le rafraîchissement des listes
      listRefreshNotifier.value++;
    } finally {
      Future.delayed(const Duration(seconds: 2), () {
        _processingReadEpisodes.remove(episodeId);
      });
    }
  }

  void dispose() {
    currentEpisodeNotifier.dispose();
    isPlayingNotifier.dispose();
    progressNotifier.dispose();
    totalDurationNotifier.dispose();
    listRefreshNotifier.dispose();
  }
}
