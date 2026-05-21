import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/audio_handler_locator.dart'; // provides globalAudioHandler

class MarkAsReadService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Executes the three‑step "mark as read" workflow.
  Future<void> markAsRead(String episodeId) async {
    // ---- Step 1: Seek to end ----
    try {
      final handler = globalAudioHandler;
      if (handler != null) {
        final currentMedia = handler.mediaItem.value;
        if (currentMedia?.duration != null) {
          await handler.seek(
            currentMedia!.duration! - const Duration(milliseconds: 500),
          );
        }
      }
    } catch (e) {
      print('Seek error in markAsRead: $e');
    }

    // ---- Step 2: Persist in Firestore & SharedPreferences ----
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _db
          .collection('users')
          .doc(uid)
          .collection('episode_history')
          .doc(episodeId)
          .set({'finishedListening': true}, SetOptions(merge: true));
    }
    final prefs = await SharedPreferences.getInstance();
    final List<String> readList =
        prefs.getStringList('local_read_episodes') ?? [];
    if (!readList.contains(episodeId)) {
      readList.add(episodeId);
      await prefs.setStringList('local_read_episodes', readList);
    }

    // ---- Step 3: UI refresh ----
    _refreshController.add(null);
  }

  static final _refreshController = StreamController<void>.broadcast();
  static Stream<void> get onRefresh => _refreshController.stream;
}
