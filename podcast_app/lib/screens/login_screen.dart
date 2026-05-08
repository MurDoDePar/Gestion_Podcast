import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';
import '../dataconnect-generated/example.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Déclenche le flux d'authentification Google
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // L'utilisateur a annulé la connexion
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Obtient les détails d'authentification de la demande
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Crée un nouvel identifiant Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Connecte l'utilisateur à Firebase
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Force le rafraîchissement du token pour s'assurer que Data Connect l'a bien reçu
        await user.getIdToken(true);

        // Vérifier si l'utilisateur existe déjà
        final userResult = await ExampleConnector.instance
            .findUserByGoogleId(googleId: user.uid)
            .execute();

        if (userResult.data.users.isEmpty) {
          // Créer l'utilisateur avec InsertUser s'il n'existe pas
          await ExampleConnector.instance
              .insertUser(
                googleId: user.uid,
                displayName: user.displayName ?? 'Utilisateur',
                createdAt:
                    Timestamp(0, DateTime.now().millisecondsSinceEpoch ~/ 1000),
              )
              .email(user.email ?? '')
              .photoUrl(user.photoURL ?? '')
              .execute();
        }
      }

      // La redirection vers l'écran principal sera gérée par le StreamBuilder dans main.dart
    } catch (e) {
      debugPrint('Erreur de connexion: $e');
      // Let's use standard Dart io
      try {
        final file = File(
            'C:\\Users\\domin\\Google Drive\\Code\\Gestion_Podcast\\error.log');
        file.writeAsStringSync('Error: $e\n', mode: FileMode.append);
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Erreur de création de profil : $e\nPrenez une capture d\'écran !',
                style: const TextStyle(fontSize: 12)),
            backgroundColor: AppTheme.dangerColor,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.podcasts,
                size: 80,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 16),
              const Text(
                'PodStream',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Connectez-vous avec Google pour sauvegarder et synchroniser vos podcasts sur le Cloud.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 48),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _signInWithGoogle,
                      icon: const Icon(Icons.login),
                      label: const Text('Continuer avec Google',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
