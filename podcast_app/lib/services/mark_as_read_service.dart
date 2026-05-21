import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'audio_handler_locator.dart';
// provides globalAudioHandler
import '../services/audio_service.dart' as app_audio;

class MarkAsReadService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Executes the three‑step "mark as read" workflow.
  Future<void> markAsRead(String episodeId) async {
    print(
        'DEBUG MarkAsReadService: markAsRead appelé pour l\'épisode: $episodeId');

    try {
      // 1. Écriture dans Firestore (utilisation de base64UrlEncode pour éviter le crash avec les slashes //)
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        final String encodedId = base64UrlEncode(utf8.encode(episodeId));
        print(
            'DEBUG MarkAsReadService: Écriture Firestore pour l\'épisode: $episodeId (encodedId: $encodedId)');
        await _db
            .collection('users')
            .doc(uid)
            .collection('episode_history')
            .doc(encodedId)
            .set({'finishedListening': true}, SetOptions(merge: true)).timeout(
                const Duration(seconds: 5));
      }

      // 2. Écriture locale dans les SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final List<String> readList =
          prefs.getStringList('local_read_episodes') ?? [];
      if (!readList.contains(episodeId)) {
        readList.add(episodeId);
        await prefs.setStringList('local_read_episodes', readList);
        print(
            'DEBUG MarkAsReadService: Écriture SharedPreferences réussie pour l\'épisode: $episodeId');
      }
    } catch (e) {
      print('DEBUG ERREUR FIREBASE (ou Timeout): $e');
    } finally {
      // Force stop the audio playback before refreshing UI
      if (globalAudioHandler != null) {
        print('DEBUG AUDIO: Arrêt forcé du lecteur audio.');
        await globalAudioHandler!.stop();
      }

      // Force le rafraîchissement UI
      print('DEBUG UI: Déclenchement du rafraîchissement UI....');
      app_audio.AudioService().listRefreshNotifier.value++;
    }
  }

  static final _refreshController = StreamController<void>.broadcast();
  static Stream<void> get onRefresh => _refreshController.stream;
}
