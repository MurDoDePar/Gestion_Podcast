import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'audio_service.dart' as app_audio;

// The new background audio handler that will replace the old AudioService
class PodStreamAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  // A simple representation of our episodes for Android Auto to browse
  final Map<String, MediaItem> _mediaLibrary = {};

  Stream<Duration> get positionStream => _player.positionStream;

  PodStreamAudioHandler() {
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
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.rewind,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.fastForward,
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
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
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
    // For now, return a simple static structure or empty list
    // You can fetch this from a local DB or Data Connect
    if (parentMediaId == AudioService.browsableRootId) {
      return [
        const MediaItem(
          id: 'mes_podcasts',
          title: 'Mes Podcasts',
          playable: false,
        ),
      ];
    } else if (parentMediaId == 'mes_podcasts') {
      // Returns items in library. We would populate _mediaLibrary from the UI.
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
