import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:audio_service/audio_service.dart';
import '../dataconnect-generated/example.dart';
import '../main.dart'; // Pour accéder à audioHandler

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

  List<AudioEpisode> currentPlaylist = [];
  int currentPlaylistIndex = -1;

  Future<void> _init() async {
    // Écoute de l'état de lecture depuis audioHandler
    audioHandler.playbackState.listen((state) {
      final isPlaying = state.playing;
      final processingState = state.processingState;

      if (processingState == AudioProcessingState.completed) {
        playNextEpisode();
      } else {
        isPlayingNotifier.value = isPlaying;
      }
    });

    // Écoute de la position en continu (seconde par seconde)
    audioHandler.positionStream.listen((position) {
      progressNotifier.value = position;
    });

    // Update current episode from mediaItem
    audioHandler.mediaItem.listen((item) {
      if (item != null) {
        currentEpisodeNotifier.value = AudioEpisode(
          id: item.id,
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
    if (currentPlaylistIndex != -1 &&
        currentPlaylistIndex < currentPlaylist.length - 1) {
      final nextEpisode = currentPlaylist[currentPlaylistIndex + 1];
      await playEpisode(nextEpisode, playlist: currentPlaylist);
    } else {
      isPlayingNotifier.value = false;
      await audioHandler.stop();
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

    if (currentEpisodeNotifier.value?.audioUrl == episode.audioUrl) {
      if (isPlayingNotifier.value) {
        await audioHandler.pause();
      } else {
        await audioHandler.play();
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
      );

      await audioHandler.playMediaItem(mediaItem);

      // Update library for Android Auto based on the current playlist
      final libraryItems = currentPlaylist
          .map((e) => MediaItem(
                id: e.audioUrl,
                title: e.title,
                artist: e.podcastName,
                artUri: e.imageUrl != null ? Uri.parse(e.imageUrl!) : null,
              ))
          .toList();
      audioHandler.updateLibrary(libraryItems);
    } catch (e) {
      print("Erreur de chargement audio: $e");
      isPlayingNotifier.value = false;
    }
  }

  /// Reprendre ou Mettre en pause
  Future<void> togglePlayPause() async {
    if (isPlayingNotifier.value) {
      await audioHandler.pause();
    } else {
      if (currentEpisodeNotifier.value != null) {
        await audioHandler.play();
      }
    }
  }

  /// Chercher une position (Seek)
  Future<void> seek(Duration position) async {
    await audioHandler.seek(position);
  }

  Future<void> seekForward30() async {
    final currentPosition = progressNotifier.value;
    final newPosition = currentPosition + const Duration(seconds: 30);
    await audioHandler.seek(newPosition);
  }

  Future<void> seekBackward30() async {
    final currentPosition = progressNotifier.value;
    final newPosition = currentPosition - const Duration(seconds: 30);
    await audioHandler
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
                    Timestamp(0, DateTime.now().millisecondsSinceEpoch ~/ 1000),
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
    currentEpisodeNotifier.dispose();
    isPlayingNotifier.dispose();
    progressNotifier.dispose();
    totalDurationNotifier.dispose();
  }
}
