import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:podcast_app/widgets/audio_player_widget.dart';
import 'package:podcast_app/services/podstream_audio_handler.dart'
    as handler_service;

void main() {
  testWidgets(
      'AudioPlayerWidget ne crashe pas si audioHandler est null au démarrage (Asynchrone)',
      (WidgetTester tester) async {
    // 1. On s'assure que audioHandler est explicitement null (comme si l'init prenait du temps)
    handler_service.audioHandler = null;

    // 2. On tente de dessiner le widget audio
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: AudioPlayerWidget(),
      ),
    ));

    // 3. Le widget doit retourner un SizedBox.shrink() silencieux sans lever d'exception (LateInitializationError)
    // On vérifie qu'on n'a pas d'erreur graphique. S'il y a un écran gris, le test échouera ici.
    expect(tester.takeException(), isNull);

    // On vérifie qu'aucun contrôleur (Play, Pause, etc.) n'est visible car le service n'est pas prêt
    expect(find.byIcon(Icons.play_circle_filled), findsNothing);
  });
}
