import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/episode_model.dart';
import '../dataconnect-generated/example.dart';
import 'database_helper.dart';

class PodcastRepository {
  /// Récupère les IDs des épisodes déjà lus (Source Firestore + Data Connect + Local)
  Future<Set<String>> _getReadEpisodeIds(String postgresUuid) async {
    final readIds = <String>{};

    // 1. Source Data Connect (ExampleConnector)
    try {
      final historyResult = await ExampleConnector.instance
          .getListenHistory(userId: postgresUuid)
          .execute();

      final dcIds = historyResult.data.listenHistories
          .where((h) => h.finishedListening == true)
          .map((h) => h.episode.id)
          .toSet();
      readIds.addAll(dcIds);
    } catch (e) {
      print("Erreur _getReadEpisodeIds Data Connect: $e");
    }

    // 2. Source Firestore
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final historySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('episode_history')
            .where('finishedListening', isEqualTo: true)
            .get();

        for (var doc in historySnapshot.docs) {
          try {
            // Décodage base64 pour retrouver l'ID original (e.g. audioUrl ou stable UUID)
            final decodedBytes = base64Url.decode(base64Url.normalize(doc.id));
            final decodedId = utf8.decode(decodedBytes);
            readIds.add(decodedId);
          } catch (_) {
            // Fallback si ce n'est pas du base64 valide
            readIds.add(doc.id);
          }
        }
      }
    } catch (e) {
      print("Erreur _getReadEpisodeIds Firestore: $e");
    }

    // 3. Source Local (SQLite uniquement)
    try {
      final sqliteReadList = await DatabaseHelper().getReadEpisodeIds();
      readIds.addAll(sqliteReadList);
    } catch (e) {
      print("Erreur _getReadEpisodeIds SQLite: $e");
    }

    return readIds;
  }

  Future<List<EpisodeModel>> fetchAllRecentEpisodes() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];
      final googleId = user.uid;

      final userResult = await ExampleConnector.instance
          .findUserByGoogleId(googleId: googleId)
          .execute();
      if (userResult.data.users.isEmpty) return [];
      final postgresUuid = userResult.data.users.first.id;

      final readIds = await _getReadEpisodeIds(postgresUuid);

      final prefs = await SharedPreferences.getInstance();
      final order = prefs.getString('podstream_order') ?? 'asc';

      final subsResult = await ExampleConnector.instance
          .getMySubscriptions(userId: postgresUuid)
          .execute();
      final subs = subsResult.data.subscriptionTypes.toList();

      // Sort podcasts according to listOrder
      subs.sort((a, b) {
        final orderA = a.listOrder ?? 9999;
        final orderB = b.listOrder ?? 9999;
        if (orderA == orderB) return a.podcast.title.compareTo(b.podcast.title);
        return orderA.compareTo(orderB);
      });

      List<EpisodeModel> allEpisodes = [];

      for (var sub in subs) {
        final podcastName = sub.podcast.title;
        final podcastImageUrl = sub.podcast.imageUrl;

        final episodesResult = await ExampleConnector.instance
            .getEpisodesByPodcast(podcastId: sub.podcast.id)
            .execute();

        var epsList = episodesResult.data.episodes.toList();

        // Sort episodes of the current podcast
        epsList.sort((a, b) {
          int cmp = 0;
          final matchA = RegExp(r'#(\d+)').firstMatch(a.title);
          final matchB = RegExp(r'#(\d+)').firstMatch(b.title);

          if (matchA != null && matchB != null) {
            final numA = int.parse(matchA.group(1)!);
            final numB = int.parse(matchB.group(1)!);
            cmp = numA.compareTo(numB);
          } else {
            cmp = a.publishedAt
                .toDateTime()
                .compareTo(b.publishedAt.toDateTime());
            if (cmp == 0) cmp = a.title.compareTo(b.title);
          }

          if (order == 'asc') {
            return cmp; // oldest first
          } else {
            return -cmp; // newest first
          }
        });

        for (var ep in epsList) {
          final encodedId = base64UrlEncode(utf8.encode(ep.id));
          if (!readIds.contains(ep.id) && !readIds.contains(encodedId)) {
            allEpisodes.add(EpisodeModel(
              id: ep.id,
              title: ep.title,
              audioUrl: ep.audioUrl,
              imageUrl: ep.imageUrl ?? podcastImageUrl ?? '',
              podcastName: podcastName,
              pubDate: ep.publishedAt.toDateTime(),
              description: ep.description ?? '',
            ));
          }
        }
      }

      return allEpisodes;
    } catch (e) {
      print("Erreur PodcastRepository.fetchAllRecentEpisodes: $e");
      rethrow;
    }
  }
}
