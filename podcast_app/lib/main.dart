import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/app_theme.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Erreur initialisation Firebase: $e');
  }

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
    // Si Firebase n'a pas pu s'initialiser (ex: test sur Chrome sans firebase_options.dart)
    if (Firebase.apps.isEmpty) {
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
        // En attendant de savoir si l'utilisateur est connecté
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Si l'utilisateur est connecté
        if (snapshot.hasData) {
          // We add a tiny delay to ensure login_screen has time to display its errors
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

        // Sinon, on affiche l'écran de connexion
        return const LoginScreen();
      },
    );
  }
}
