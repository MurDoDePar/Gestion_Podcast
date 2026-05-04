import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

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

  final AudioPlayer _player = AudioPlayer();

  // State Notifiers for UI
  final ValueNotifier<AudioEpisode?> currentEpisodeNotifier = ValueNotifier(null);
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);
  final ValueNotifier<Duration> progressNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> totalDurationNotifier = ValueNotifier(Duration.zero);

  Future<void> _init() async {
    // Configuration de la session audio (comportement avec d'autres apps, appels, etc.)
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());

    // Écoute de l'état de lecture
    _player.playerStateStream.listen((state) {
      final isPlaying = state.playing;
      final processingState = state.processingState;
      
      if (processingState == ProcessingState.completed) {
        isPlayingNotifier.value = false;
        _player.pause();
        _player.seek(Duration.zero);
      } else {
        isPlayingNotifier.value = isPlaying;
      }
    });

    // Écoute de la position courante
    _player.positionStream.listen((position) {
      progressNotifier.value = position;
    });

    // Écoute de la durée totale
    _player.durationStream.listen((duration) {
      totalDurationNotifier.value = duration ?? Duration.zero;
    });
  }

  /// Jouer un nouvel épisode
  Future<void> playEpisode(AudioEpisode episode) async {
    // Si c'est le même épisode, on fait juste Play/Pause
    if (currentEpisodeNotifier.value?.audioUrl == episode.audioUrl) {
      if (_player.playing) {
        await _player.pause();
      } else {
        await _player.play();
      }
      return;
    }

    // Sinon on charge un nouvel épisode
    currentEpisodeNotifier.value = episode;
    isPlayingNotifier.value = true; // Optimistic UI
    
    try {
      await _player.setUrl(episode.audioUrl);
      await _player.play();
    } catch (e) {
      print("Erreur de chargement audio: $e");
      isPlayingNotifier.value = false;
    }
  }

  /// Reprendre ou Mettre en pause
  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      if (currentEpisodeNotifier.value != null) {
        await _player.play();
      }
    }
  }

  /// Chercher une position (Seek)
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  void dispose() {
    _player.dispose();
    currentEpisodeNotifier.dispose();
    isPlayingNotifier.dispose();
    progressNotifier.dispose();
    totalDurationNotifier.dispose();
  }
}
