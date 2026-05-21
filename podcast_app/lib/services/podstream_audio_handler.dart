import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'audio_service.dart' as app_audio;
import 'package:flutter/foundation.dart';
import 'mark_as_read_service.dart';
import 'database_repository.dart';

// Instance globale du service audio pour toute l'application
AudioHandler? audioHandler;
PodStreamAudioHandler? podstreamAudioHandler;

// The new background audio handler that will replace the old AudioService
class PodStreamAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  String? _lastMarkedEpisodeId;

  // A simple representation of our episodes for Android Auto to browse
  final Map<String, MediaItem> _mediaLibrary = {};

  void _logAA(String message) {
    try {
      final now = DateTime.now();
      final timestamp =
          "${now.toIso8601String()}.${now.microsecond.toString().padLeft(3, '0')}";
      debugPrint("AA_DEBUG: $timestamp: $message");
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
    await session.configure(const AudioSessionConfiguration.music());

    final focusAccorde = await session.setActive(true);
    print(
        'AA_DEBUG_SESSION: Demande d Audio Focus native. Accordé = $focusAccorde');

    session.interruptionEventStream.listen((event) {
      print(
          'AA_DEBUG_SESSION_INTERRUPTION: Interruption détectée, type: ${event.type}');
    });

    // Broadcast playback state changes to the system (lock screen, Android Auto)
    _player.playbackEventStream.listen(_broadcastState,
        onError: (Object e, StackTrace st) {
      print('AA_DEBUG_PLAYER_ERROR: Erreur de lecture matérielle: $e');
    });

    // Écouter les changements de durée (récupérée dans les métadonnées du flux audio)
    _player.durationStream.listen((duration) {
      if (duration != null && mediaItem.value != null) {
        final currentMediaItem = mediaItem.value!;
        if (currentMediaItem.duration != duration) {
          mediaItem.add(currentMediaItem.copyWith(duration: duration));
        }
      }
    });

    // Réinitialise _lastMarkedEpisodeId quand un nouvel épisode est chargé
    mediaItem.listen((item) {
      if (item != null) {
        final episodeId = item.extras?['episodeId'] as String? ?? item.id;
        if (episodeId != _lastMarkedEpisodeId) {
          _lastMarkedEpisodeId = null;
        }
      }
    });

    _initPlaybackListeners();
  }

  // Écouteur pour l'Auto-Play et le marquage automatique
  void _initPlaybackListeners() {
    playbackState.listen((state) async {
      final currentMediaId = mediaItem.value?.extras?['episodeId'] as String? ??
          mediaItem.value?.id;

      if (state.processingState == AudioProcessingState.completed &&
          currentMediaId != null &&
          currentMediaId != _lastMarkedEpisodeId) {
        _lastMarkedEpisodeId = currentMediaId;
        _logAA("Auto-marquage et enchaînement pour : $currentMediaId");

        // 1. Marquer comme lu
        await MarkAsReadService().markAsRead(currentMediaId);

        // 2. Attente de persistance
        await Future.delayed(const Duration(milliseconds: 500));

        // 3. Orchestration du suivant
        await _playNextOrStop();
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
        MediaControl.rewind,
        MediaControl.play,
        MediaControl.pause,
        MediaControl.fastForward,
        // AJOUT COMPLÉMENTAIRE POUR ANDROID AUTO :
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
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
    final audioUrl = mediaItem.extras?['url'] as String? ?? mediaItem.id;
    print(
        'AA_DEBUG_HANDLER: playMediaItem reçu pour ${mediaItem.title} - URL: $audioUrl');
    this.mediaItem.add(mediaItem);
    await _player.setAudioSource(AudioSource.uri(Uri.parse(audioUrl)));
    await _player.setVolume(1.0);
    print('AA_DEBUG_PLAYER: Lancement de _player.play()');
    _player.play();
  }

  @override
  Future<void> fastForward() async {
    final currentPosition = _player.position;
    final duration = _player.duration ?? Duration.zero;
    final newPosition = currentPosition + const Duration(seconds: 30);
    await _player.seek(newPosition < duration ? newPosition : duration);
  }

  @override
  Future<void> rewind() async {
    final currentPosition = _player.position;
    final newPosition = currentPosition - const Duration(seconds: 30);
    await _player
        .seek(newPosition > Duration.zero ? newPosition : Duration.zero);
  }

  Future<void> _playNextOrStop() async {
    _logAA("_playNextOrStop: Recherche du prochain épisode...");
    try {
      final nextEpisodes = await DatabaseRepository().getEpisodesToListen();

      if (nextEpisodes.isNotEmpty) {
        final next = nextEpisodes.first;
        _logAA("_playNextOrStop: Prochain épisode trouvé : ${next.title}");

        final media = MediaItem(
          id: next.audioUrl,
          title: next.title,
          artist: next.podcastName,
          artUri: next.imageUrl.isNotEmpty ? Uri.parse(next.imageUrl) : null,
          extras: {'episodeId': next.id},
        );

        await addQueueItem(media);
        await play();
      } else {
        _logAA("_playNextOrStop: File d'attente vide, arrêt.");
        await stop();
      }
    } catch (e) {
      _logAA("_playNextOrStop ERREUR CRITIQUE: $e");
      await stop();
    }
  }

  @override
  Future<void> skipToNext() async {
    _logAA("skipToNext: Triggering _playNextOrStop...");
    await _playNextOrStop();
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    // Mise à jour de la queue pour que Android Auto/Lockscreen soient au courant
    final currentQueue = queue.value;
    final newQueue = List<MediaItem>.from(currentQueue)..add(mediaItem);
    queue.add(newQueue);

    // Chargement dans le player
    this.mediaItem.add(mediaItem);
    final audioUrl = mediaItem.extras?['url'] as String? ?? mediaItem.id;
    await _player.setAudioSource(AudioSource.uri(Uri.parse(audioUrl)));
    await _player.setVolume(1.0);
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'mark_as_read') {
      await app_audio.AudioService().markAsRead();
    } else if (name == 'rewind_30') {
      await app_audio.AudioService().seekBackward30();
    } else if (name == 'fast_forward_30') {
      await app_audio.AudioService().seekForward30();
    }
    return super.customAction(name, extras);
  }

  // --- Android Auto Integration (MediaBrowserService) ---

  @override
  Future<List<MediaItem>> getChildren(String parentMediaId,
      [Map<String, dynamic>? options]) async {
    _logAA('[AA] getChildren - parentMediaId: $parentMediaId');

    if (parentMediaId == 'a_ecouter' || parentMediaId == 'mes_podcasts') {
      if (_mediaLibrary.isNotEmpty) {
        return _mediaLibrary.values.toList();
      }
      return [
        const MediaItem(
          id: 'loading',
          title: 'Sélectionnez un podcast sur le téléphone',
          playable: false,
        )
      ];
    }

    // DEBLOCAGE RADICAL D'ANDROID AUTO (onLoadChildren)
    // Retour IMMEDIAT sans await de la liste des dossiers racines
    return [
      const MediaItem(
        id: 'mes_podcasts',
        album: '',
        title: 'Mes Podcasts',
        playable: false,
      ),
      const MediaItem(
        id: 'a_ecouter',
        album: '',
        title: 'À écouter',
        playable: false,
      ),
    ];
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
