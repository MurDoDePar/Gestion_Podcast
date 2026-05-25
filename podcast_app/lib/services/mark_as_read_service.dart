import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'audio_handler_locator.dart';
import 'database_helper.dart';
// provides globalAudioHandler
import '../services/audio_service.dart' as app_audio;

class MarkAsReadService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Executes the three‑step "mark as read" workflow.
  Future<void> markAsRead(String episodeId) async {
    print(
        'DEBUG MarkAsReadService: markAsRead appelé pour l\'épisode: $episodeId');

    // 1. Écriture locale immédiate et garantie (SQLite & SharedPreferences)
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> readList =
          prefs.getStringList('local_read_episodes') ?? [];
      if (!readList.contains(episodeId)) {
        readList.add(episodeId);
        await prefs.setStringList('local_read_episodes', readList);
        print(
            'DEBUG MarkAsReadService: Écriture SharedPreferences réussie pour l\'épisode: $episodeId');
      }

      await DatabaseHelper().markEpisodeAsRead(episodeId);
      print(
          'DEBUG MarkAsReadService: Écriture SQLite réussie pour l\'épisode: $episodeId');
    } catch (e) {
      print('DEBUG MarkAsReadService: Erreur écriture locale : $e');
    }

    // 2. Écriture distante Firestore asynchrone (attrapée séparément)
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      final String encodedId = base64UrlEncode(utf8.encode(episodeId));
      print(
          'DEBUG MarkAsReadService: Tentative écriture Firestore pour l\'épisode: $episodeId (encodedId: $encodedId)');
      try {
        await _db
            .collection('users')
            .doc(uid)
            .collection('episode_history')
            .doc(encodedId)
            .set({'finishedListening': true}, SetOptions(merge: true)).timeout(
                const Duration(seconds: 4));
        print(
            'DEBUG MarkAsReadService: Écriture Firestore réussie pour l\'épisode: $episodeId');
      } catch (e) {
        print(
            'DEBUG MarkAsReadService: Échec de l\'écriture Firestore (mode hors-ligne ou timeout) : $e');
      }
    }

    // 3. Actions de finalisation (arrêt du lecteur et rafraîchissement UI)
    try {
      if (globalAudioHandler != null) {
        print('DEBUG AUDIO: Arrêt forcé du lecteur audio.');
        await globalAudioHandler!.stop();
      }
    } catch (e) {
      print(
          'DEBUG MarkAsReadService: Erreur lors de l\'arrêt du lecteur audio : $e');
    }

    print('DEBUG UI: Déclenchement du rafraîchissement UI....');
    app_audio.AudioService().listRefreshNotifier.value++;
  }

  static final _refreshController = StreamController<void>.broadcast();
  static Stream<void> get onRefresh => _refreshController.stream;
}
