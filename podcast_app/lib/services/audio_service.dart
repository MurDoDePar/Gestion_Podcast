import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';
import '../dataconnect-generated/example.dart';

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
  final ValueNotifier<AudioEpisode?> currentEpisodeNotifier =
      ValueNotifier(null);
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);
  final ValueNotifier<Duration> progressNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> totalDurationNotifier =
      ValueNotifier(Duration.zero);

  List<AudioEpisode> currentPlaylist = [];
  int currentPlaylistIndex = -1;

  Future<void> _init() async {
    // Configuration de la session audio (comportement avec d'autres apps, appels, etc.)
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());

    // Écoute de l'état de lecture
    _player.playerStateStream.listen((state) {
      final isPlaying = state.playing;
      final processingState = state.processingState;

      if (processingState == ProcessingState.completed) {
        playNextEpisode();
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

  Future<void> playNextEpisode() async {
    if (currentPlaylistIndex != -1 &&
        currentPlaylistIndex < currentPlaylist.length - 1) {
      final nextEpisode = currentPlaylist[currentPlaylistIndex + 1];
      await playEpisode(nextEpisode, playlist: currentPlaylist);
    } else {
      isPlayingNotifier.value = false;
      await _player.stop();
    }
  }

  /// Jouer un nouvel épisode
  Future<void> playEpisode(AudioEpisode episode,
      {List<AudioEpisode>? playlist}) async {
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
      if (_player.playing) {
        await _player.stop();
      }
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

  Future<void> seekForward30() async {
    final currentPosition = _player.position;
    final newPosition = currentPosition + const Duration(seconds: 30);
    await _player.seek(newPosition);
  }

  Future<void> seekBackward30() async {
    final currentPosition = _player.position;
    final newPosition = currentPosition - const Duration(seconds: 30);
    await _player
        .seek(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  String _formatUuid(String rawId) {
    if (rawId.contains('-')) return rawId;
    if (rawId.length == 32) {
      return '${rawId.substring(0, 8)}-${rawId.substring(8, 12)}-${rawId.substring(12, 16)}-${rawId.substring(16, 20)}-${rawId.substring(20, 32)}';
    }
    return rawId;
  }

  Future<bool> markAsRead() async {
    final episode = currentEpisodeNotifier.value;
    if (episode == null) return false;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userResult = await ExampleConnector.instance
            .findUserByGoogleId(googleId: user.uid)
            .execute();
        if (userResult.data.users.isNotEmpty) {
          final postgresUuid = userResult.data.users.first.id;
          final formattedEpisodeId = _formatUuid(episode.id);

          await ExampleConnector.instance
              .updateListenHistory(
                userId: postgresUuid,
                episodeId: formattedEpisodeId,
                progressSeconds:
                    BigInt.from(totalDurationNotifier.value.inSeconds),
                finishedListening: true,
                listenedAt:
                    Timestamp(DateTime.now().millisecondsSinceEpoch ~/ 1000, 0),
              )
              .execute();
        }
      } catch (e) {
        print("Erreur markAsRead historisation ignorée: $e");
      }
    }

    // On passe directement à l'épisode suivant sans faire planter le lecteur audio natif
    await playNextEpisode();
    return true;
  }

  void dispose() {
    _player.dispose();
    currentEpisodeNotifier.dispose();
    isPlayingNotifier.dispose();
    progressNotifier.dispose();
    totalDurationNotifier.dispose();
  }
}
