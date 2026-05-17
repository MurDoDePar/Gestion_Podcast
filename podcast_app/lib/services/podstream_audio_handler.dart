import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'audio_service.dart' as app_audio;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'package:flutter/foundation.dart';

// The new background audio handler that will replace the old AudioService
class PodStreamAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  // A simple representation of our episodes for Android Auto to browse
  final Map<String, MediaItem> _mediaLibrary = {};

  void _logAA(String message) {
    try {
      final now = DateTime.now();
      final timestamp =
          "${now.toIso8601String()}.${now.microsecond.toString().padLeft(3, '0')}";
      debugPrint("AA_DEBUG: $timestamp: $message");

      getApplicationDocumentsDirectory().then((directory) {
        final logFile = File('${directory.path}/logs_android_auto.txt');
        logFile
            .writeAsString('$timestamp: $message\n', mode: FileMode.append)
            .catchError((e) {
          debugPrint("AA_DEBUG_ERROR (File write): $e");
          return logFile;
        });
      }).catchError((e) {
        debugPrint("AA_DEBUG_ERROR (Directory): $e");
      });
    } catch (e) {
      debugPrint("AA_DEBUG_ERROR: Could not log: $e");
    }
  }

  Stream<Duration> get positionStream => _player.positionStream;

  PodStreamAudioHandler() {
    _logAA(
        "[INIT] Application lancée - Système de log opérationnel (PodStreamAudioHandler constructor)");

    // Initialisation immédiate du PlaybackState pour Android Auto
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.play,
        MediaControl.pause,
        MediaControl.skipToNext,
        MediaControl.skipToPrevious
      ],
      systemActions: const {
        MediaAction.play,
        MediaAction.pause,
        MediaAction.seek
      },
      processingState: AudioProcessingState.ready,
      playing: false,
    ));

    // Initialisation de la Queue (Liste de lecture)
    queue.add([]);

    // Métadonnées Fantômes (Le Leurre Android Auto)
    mediaItem.add(const MediaItem(
      id: 'root',
      album: 'PodStream',
      title: 'Chargement...',
      artist: '',
    ));
    _init();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());

    // Broadcast playback state changes to the system (lock screen, Android Auto)
    _player.playbackEventStream.listen(_broadcastState);

    // Écouter les changements de durée (récupérée dans les métadonnées du flux audio)
    _player.durationStream.listen((duration) {
      if (duration != null && mediaItem.value != null) {
        final currentMediaItem = mediaItem.value!;
        if (currentMediaItem.duration != duration) {
          mediaItem.add(currentMediaItem.copyWith(duration: duration));
        }
      }
    });

    // Listen for completion
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        skipToNext();
      }
    });
  }

  // This method converts the just_audio state into the audio_service state
  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;

    // TRICHE ANDROID AUTO : Ne jamais envoyer 'idle', on le force en 'ready'
    final AudioProcessingState aaProcessingState =
        _player.processingState == ProcessingState.idle
            ? AudioProcessingState.ready
            : const {
                ProcessingState.idle:
                    AudioProcessingState.ready, // Fallback par sécurité
                ProcessingState.loading: AudioProcessingState.loading,
                ProcessingState.buffering: AudioProcessingState.buffering,
                ProcessingState.ready: AudioProcessingState.ready,
                ProcessingState.completed: AudioProcessingState.completed,
              }[_player.processingState]!;

    _logAA(
        "[AA] _broadcastState: processingState=$aaProcessingState, playing=$playing");

    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.rewind,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.fastForward,
        MediaControl.skipToNext,
        MediaControl.custom(
          androidIcon: 'drawable/ic_check',
          label: 'Marquer lu',
          name: 'mark_as_read',
        ),
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.play,
        MediaAction.pause,
        MediaAction.stop,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
      },
      androidCompactActionIndices: const [1, 2, 3],
      processingState: aaProcessingState,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    ));
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    this.mediaItem.add(mediaItem);
    await _player.setAudioSource(AudioSource.uri(Uri.parse(mediaItem.id)));
    _player.play();
  }

  @override
  Future<void> fastForward() async {
    await app_audio.AudioService().seekForward30();
  }

  @override
  Future<void> rewind() async {
    await app_audio.AudioService().seekBackward30();
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'mark_as_read') {
      await app_audio.AudioService().markAsRead();
    }
    return super.customAction(name, extras);
  }

  // --- Android Auto Integration (MediaBrowserService) ---

  @override
  Future<List<MediaItem>> getChildren(String parentMediaId,
      [Map<String, dynamic>? options]) async {
    _logAA('[AA] onGetRoot / onLoadChildren - parentMediaId: $parentMediaId');
    if (parentMediaId == 'root' ||
        parentMediaId == AudioService.browsableRootId ||
        parentMediaId == AudioService.recentRootId) {
      _logAA("Returning root folders for $parentMediaId");
      return [
        const MediaItem(
          id: 'podstream_browse_root',
          title: 'Mes Podcasts',
          playable: false,
          extras: {
            'android.media.browse.CONTENT_STYLE_BROWSABLE_HINT': 1,
            'android.media.browse.CONTENT_STYLE_PLAYABLE_HINT': 1,
          },
        ),
        const MediaItem(
          id: 'a_ecouter',
          title: 'À écouter',
          playable: false,
          extras: {
            'android.media.browse.CONTENT_STYLE_BROWSABLE_HINT': 1,
            'android.media.browse.CONTENT_STYLE_PLAYABLE_HINT': 1,
          },
        ),
      ];
    } else if (parentMediaId == 'podstream_browse_root') {
      _logAA(
          "Returning library items for 'podstream_browse_root' synchronously");
      if (_mediaLibrary.isEmpty) {
        return [
          const MediaItem(
            id: 'loading_mes_podcasts',
            title: 'Chargement des podcasts...',
            playable: false,
          )
        ];
      }
      return _mediaLibrary.values.toList();
    } else if (parentMediaId == 'a_ecouter') {
      _logAA("Returning loading state for 'a_ecouter' synchronously");
      // Retour immédiat et synchrone comme demandé pour éviter le timeout
      return [
        const MediaItem(
          id: 'loading_a_ecouter',
          title: 'Chargement des épisodes...',
          playable: false,
        )
      ];
    } else if (parentMediaId == 'mes_podcasts') {
      _logAA("Returning library items for 'mes_podcasts' synchronously");
      if (_mediaLibrary.isEmpty) {
        return [
          const MediaItem(
            id: 'loading_mes_podcasts',
            title: 'Chargement des podcasts...',
            playable: false,
          )
        ];
      }
      return _mediaLibrary.values.toList();
    }
    return [];
  }

  @override
  Future<MediaItem?> getMediaItem(String mediaId) async {
    return _mediaLibrary[mediaId];
  }

  // Helper method for the UI to update the Android Auto library
  void updateLibrary(List<MediaItem> items) {
    _mediaLibrary.clear();
    for (var item in items) {
      _mediaLibrary[item.id] = item;
    }
  }
}
