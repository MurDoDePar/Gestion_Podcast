import 'package:flutter_test/flutter_test.dart';
import 'package:podcast_app/services/podstream_audio_handler.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';

class MockJustAudioPlatform extends JustAudioPlatform {
  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async =>
      MockAudioPlayerPlatform(request.id);
  @override
  Future<DisposePlayerResponse> disposePlayer(
          DisposePlayerRequest request) async =>
      DisposePlayerResponse();
  @override
  Future<DisposeAllPlayersResponse> disposeAllPlayers(
          DisposeAllPlayersRequest request) async =>
      DisposeAllPlayersResponse();
}

class MockAudioPlayerPlatform extends AudioPlayerPlatform {
  MockAudioPlayerPlatform(super.id);
  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream =>
      const Stream.empty();
  @override
  Future<LoadResponse> load(LoadRequest request) async =>
      LoadResponse(duration: const Duration(minutes: 45));
  @override
  Future<PlayResponse> play(PlayRequest request) async => PlayResponse();
  @override
  Future<PauseResponse> pause(PauseRequest request) async => PauseResponse();
  @override
  Future<SeekResponse> seek(SeekRequest request) async => SeekResponse();
  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) async =>
      SetVolumeResponse();
  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest request) async =>
      SetSpeedResponse();
  @override
  Future<SetLoopModeResponse> setLoopMode(SetLoopModeRequest request) async =>
      SetLoopModeResponse();
  @override
  Future<SetShuffleModeResponse> setShuffleMode(
          SetShuffleModeRequest request) async =>
      SetShuffleModeResponse();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    JustAudioPlatform.instance = MockJustAudioPlatform();
  });
  test('test playing', () async {
    final audioHandler = PodStreamAudioHandler();
    audioHandler.playMediaItem(const MediaItem(id: 'a', title: 'a'));
    await Future.delayed(const Duration(milliseconds: 50));
    print(audioHandler.mediaItem.value?.id);
  });
}
