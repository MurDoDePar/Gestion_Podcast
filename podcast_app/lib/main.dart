import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

import 'package:audio_service/audio_service.dart';
import 'package:podcast_app/services/podstream_audio_handler.dart';
import 'package:podcast_app/services/audio_handler_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('--- DEBUT INITIALISATION ---');

  debugPrint(
      '--- Initialisation AudioService (PRIORITÉ MAX POUR ANDROID AUTO) ---');
  try {
    globalAudioHandler = await AudioService.init(
      builder: () => PodStreamAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.podstream.channel.audio',
        androidNotificationChannelName: 'Lecture de Podcast',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
    print(
        'AA_DEBUG_INIT_UI: globalAudioHandler est désormais initialisé dans le main principal !');
    debugPrint('--- AudioService OK ---');
  } catch (e) {
    debugPrint('Erreur critique AudioService: $e');
  }

  try {
    debugPrint('--- Initialisation Firebase... ---');
    await Firebase.initializeApp();

    await FirebaseAppCheck.instance.activate(
      providerAndroid: const AndroidDebugProvider(),
      providerApple: const AppleDebugProvider(),
    );

    debugPrint('--- Firebase OK ---');
  } catch (e) {
    debugPrint('Erreur initialisation Firebase: $e');
  }

  debugPrint('--- Lancement de l\'application ---');
  runApp(const PodStreamApp());
}

class PodStreamApp extends StatelessWidget {
  const PodStreamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PodStream',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _buildAuthResolver(),
    );
  }

  Widget _buildAuthResolver() {
    debugPrint("--- BUILD AUTH RESOLVER ---");
    if (Firebase.apps.isEmpty) {
      debugPrint("AuthResolver: Firebase.apps.isEmpty");
      return const Scaffold(
        body: Center(
          child: Text(
            'Firebase non configuré pour cette plateforme.\nVeuillez tester sur Android ou configurer le Web.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        debugPrint(
            "AuthResolver: state=${snapshot.connectionState}, hasData=${snapshot.hasData}");
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return FutureBuilder(
            future: Future.delayed(const Duration(seconds: 3)),
            builder: (context, delaySnapshot) {
              if (delaySnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Synchronisation du profil...'),
                      ],
                    ),
                  ),
                );
              }
              return const MainScreen();
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}
