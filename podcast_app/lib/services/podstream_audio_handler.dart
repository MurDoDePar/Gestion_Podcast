import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'mark_as_read_service.dart';
import 'database_repository.dart';
import 'download_service.dart';

// Instance globale du service audio pour toute l'application
AudioHandler? audioHandler;
PodStreamAudioHandler? podstreamAudioHandler;

// The new background audio handler that will replace the old AudioService
class PodStreamAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  String? _lastMarkedEpisodeId;
  bool _prefetchedNext =
      false; // Flag pour éviter le multi-déclenchement du prefetch

  // A simple representation of our episodes for Android Auto to browse
  final Map<String, MediaItem> _mediaLibrary = {};

  // Définition de l'ordre souhaité (ton "objet unique")
  final List<Map<String, dynamic>> myControls = [
    {'label': '-30s', 'icon': 'drawable/ic_rewind_30', 'action': 'rewind_30'},
    {
      'label': 'Play',
      'icon': 'drawable/ic_play',
      'action': 'play'
    }, // Ou 'Pause'
    {
      'label': '+30s',
      'icon': 'drawable/ic_fast_forward_30',
      'action': 'fast_forward_30'
    },
  ];

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

    // Écouter la position de lecture pour le préchargement à 80%
    _player.positionStream.listen((position) {
      final duration = _player.duration;
      if (duration != null && duration > Duration.zero && !_prefetchedNext) {
        final ratio = position.inMilliseconds / duration.inMilliseconds;
        if (ratio >= 0.8) {
          _prefetchedNext = true;
          _prefetchNextEpisode();
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

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;

    // Calcul de l'état de lecture
    final AudioProcessingState aaProcessingState = const {
          ProcessingState.idle: AudioProcessingState.ready,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState] ??
        AudioProcessingState.ready;

    playbackState.add(playbackState.value.copyWith(
      controls: [
        // 1. -30s (Custom)
        const MediaControl(
          androidIcon: 'drawable/ic_rewind_30',
          label: '-30s',
          action: MediaAction.custom,
        ),
        // 2. Play/Pause (On garde le système standard pour la stabilité Android Auto)
        playing ? MediaControl.pause : MediaControl.play,
        // 3. +30s (Custom)
        const MediaControl(
          androidIcon: 'drawable/ic_fast_forward_30',
          label: '+30s',
          action: MediaAction.custom,
        ),
      ],
      // CRUCIAL : Déclare les actions système ici pour éviter le mode simplifié
      systemActions: const {
        MediaAction.seek,
        MediaAction.play,
        MediaAction.pause,
        //MediaAction.skipToNext,
        //MediaAction.skipToPrevious,
        //MediaAction.custom,
      },
      // Indique les index (0, 1, 2) pour la barre compacte
      androidCompactActionIndices: const [0, 1, 2],
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
    final episodeId = mediaItem.extras?['episodeId'] as String? ?? mediaItem.id;
    print(
        'AA_DEBUG_HANDLER: playMediaItem reçu pour ${mediaItem.title} - URL: $audioUrl');

    this.mediaItem.add(mediaItem);
    _prefetchedNext = false; // Réinitialiser le flag de préchargement

    // Essayer de lire le fichier local s'il existe, sinon fallback en streaming
    final localPath = await DownloadService().getLocalFilePath(episodeId);
    if (localPath != null && localPath.isNotEmpty) {
      print('AA_DEBUG_PLAYER: Lecture locale depuis $localPath');
      await _player.setAudioSource(AudioSource.file(localPath));
    } else {
      print('AA_DEBUG_PLAYER: Fallback en streaming sur $audioUrl');
      await _player.setAudioSource(AudioSource.uri(Uri.parse(audioUrl)));
    }

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
    _logAA("_playNextOrStop: Recherche...");
    try {
      final nextEpisodes = await DatabaseRepository().getEpisodesToListen();

      if (nextEpisodes.isNotEmpty) {
        final next = nextEpisodes.first;
        _logAA("_playNextOrStop: Prochain épisode légitime : ${next.title}");

        final media = MediaItem(
          id: next.audioUrl,
          title: next.title,
          artist: next.podcastName,
          artUri: next.imageUrl.isNotEmpty ? Uri.parse(next.imageUrl) : null,
          extras: {'episodeId': next.id, 'url': next.audioUrl},
        );

        // 1. On nettoie la file avant d'ajouter
        queue.add([]);

        // 2. On utilise playMediaItem pour charger ET jouer proprement
        await playMediaItem(media);
      } else {
        _logAA("_playNextOrStop: File vide, arrêt.");
        await stop();
      }
    } catch (e) {
      _logAA("_playNextOrStop ERREUR: $e");
      await stop();
    }
  }

  Future<void> _prefetchNextEpisode() async {
    _logAA(
        "_prefetchNextEpisode: Début de la détection de l'épisode suivant...");
    try {
      final nextEpisodes = await DatabaseRepository().getEpisodesToListen();

      if (nextEpisodes.isNotEmpty) {
        final next = nextEpisodes.first;
        _logAA(
            "_prefetchNextEpisode: Épisode trouvé pour le préchargement : ${next.title}");

        // Démarrer le téléchargement en tâche de fond pour qu'il soit disponible localement
        // Cela sert de mécanisme de préchargement sans coupure audio
        DownloadService().downloadEpisode(next.id, next.audioUrl);
      } else {
        _logAA(
            "_prefetchNextEpisode: Aucun épisode suivant disponible pour le préchargement.");
      }
    } catch (e) {
      _logAA("_prefetchNextEpisode ERREUR: $e");
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
    _prefetchedNext = false; // Réinitialiser le flag de préchargement

    final audioUrl = mediaItem.extras?['url'] as String? ?? mediaItem.id;
    final episodeId = mediaItem.extras?['episodeId'] as String? ?? mediaItem.id;

    final localPath = await DownloadService().getLocalFilePath(episodeId);
    if (localPath != null && localPath.isNotEmpty) {
      await _player.setAudioSource(AudioSource.file(localPath));
    } else {
      await _player.setAudioSource(AudioSource.uri(Uri.parse(audioUrl)));
    }
    await _player.setVolume(1.0);
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    _logAA("customAction reçu: $name");

    switch (name) {
      case 'Lu':
        final currentMediaId =
            mediaItem.value?.extras?['episodeId'] as String? ??
                mediaItem.value?.id;
        if (currentMediaId != null) {
          await MarkAsReadService().markAsRead(currentMediaId);
          await _playNextOrStop();
        }
        break;

      case '-30s':
        await rewind();
        break;

      case '+30s':
        await fastForward();
        break;

      case 'Play':
        await play();
        break;

      case 'Pause':
        await pause();
        break;

      default:
        _logAA("Action inconnue reçue: $name");
        break;
    }

    return super.customAction(name, extras);
  }

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
