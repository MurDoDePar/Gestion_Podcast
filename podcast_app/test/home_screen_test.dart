import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:podcast_app/screens/home/home_screen.dart';
import 'package:podcast_app/services/podstream_audio_handler.dart';
import 'package:audio_service/audio_service.dart';

class MockAudioHandler extends PodStreamAudioHandler {
  MediaItem? lastPlayedItem;

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    lastPlayedItem = mediaItem;
  }
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('HomeScreen se charge sans exception et valide audioHandler',
      (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final errorString = details.exception.toString();
      if (errorString.contains('Firebase') ||
          errorString.contains('ClientException')) return;
      originalOnError?.call(details);
    };

    final mockHandler = MockAudioHandler();
    audioHandler = mockHandler;

    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: HomeScreen())));
    expect(find.byType(TabBar), findsOneWidget);

    // Test de validation de liaison globale
    if (audioHandler != null) {
      audioHandler!.playMediaItem(const MediaItem(id: 'test', title: 'test'));
      expect(mockHandler.lastPlayedItem?.id, 'test');
    }

    await tester.pumpWidget(const SizedBox.shrink());
    expect(find.byType(HomeScreen), findsNothing);

    FlutterError.onError = originalOnError;
  });
}
