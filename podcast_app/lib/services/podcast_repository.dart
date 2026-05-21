import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/episode_model.dart';
import '../dataconnect-generated/example.dart';

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

    // 3. Source Local (SharedPreferences)
    try {
      final prefs = await SharedPreferences.getInstance();
      final localReadList = prefs.getStringList('local_read_episodes') ?? [];
      readIds.addAll(localReadList);
    } catch (e) {
      print("Erreur _getReadEpisodeIds SharedPreferences: $e");
    }

    return readIds;
  }

  static Future<List<GetMySubscriptionsSubscriptionTypes>> fetchPodcasts(
      String googleId) async {
    try {
      final userResult = await ExampleConnector.instance
          .findUserByGoogleId(googleId: googleId)
          .execute();
      final users = userResult.data.users;
      if (users.isEmpty) return [];
      final postgresUuid = users.first.id;
      final subsResult = await ExampleConnector.instance
          .getMySubscriptions(userId: postgresUuid)
          .execute();
      final subs = subsResult.data.subscriptionTypes.toList();
      subs.sort((a, b) {
        final orderA = a.listOrder ?? 9999;
        final orderB = b.listOrder ?? 9999;
        if (orderA == orderB) return a.podcast.title.compareTo(b.podcast.title);
        return orderA.compareTo(orderB);
      });

      final prefs = await SharedPreferences.getInstance();
      final jsonList = subs
          .map((sub) => {
                'listOrder': sub.listOrder,
                'podcast': {
                  'id': sub.podcast.id,
                  'title': sub.podcast.title,
                  'author': sub.podcast.author,
                  'imageUrl': sub.podcast.imageUrl,
                  'feedUrl': sub.podcast.feedUrl,
                }
              })
          .toList();
      prefs.setString('cache_my_podcasts', jsonEncode(jsonList));

      return subs;
    } catch (e) {
      print("Erreur PodcastRepository.fetchPodcasts: $e");
      try {
        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getString('cache_my_podcasts');
        if (cached != null) {
          final List<dynamic> decoded = jsonDecode(cached);
          if (decoded.isNotEmpty) {
            return decoded
                .map((e) => GetMySubscriptionsSubscriptionTypes.fromJson(e))
                .toList();
          }
        }
      } catch (err) {
        print("Erreur décodage cache my podcasts: $err");
      }

      // HARDCODED FALLBACK MOCK
      final mockSubs = [
        {
          'listOrder': 0,
          'podcast': {
            'id': 'mock_podcast_1',
            'title': 'Mock Podcast 1 (Test)',
            'author': 'Test Author',
            'imageUrl':
                'https://upload.wikimedia.org/wikipedia/commons/4/47/PNG_transparency_demonstration_1.png',
            'feedUrl': 'https://test.com/feed.xml',
          }
        }
      ];
      return mockSubs
          .map((e) => GetMySubscriptionsSubscriptionTypes.fromJson(e))
          .toList();
    }
  }

  static Future<List<Map<String, dynamic>>> fetchEpisodesToListen(
      String googleId) async {
    try {
      final userResult = await ExampleConnector.instance
          .findUserByGoogleId(googleId: googleId)
          .execute();
      if (userResult.data.users.isEmpty) return [];
      final postgresUuid = userResult.data.users.first.id;

      final readEpisodeIds =
          await PodcastRepository()._getReadEpisodeIds(postgresUuid);

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

      List<Map<String, dynamic>> finalEpisodes = [];

      // Find the first podcast that has unread episodes
      for (var sub in subs) {
        final podcastName = sub.podcast.title;
        final podcastImageUrl = sub.podcast.imageUrl;
        final listOrder = sub.listOrder ?? 9999;

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

        // Filter unread episodes
        for (var ep in epsList) {
          final encodedId = base64UrlEncode(utf8.encode(ep.id));
          if (!readEpisodeIds.contains(ep.id) &&
              !readEpisodeIds.contains(encodedId)) {
            finalEpisodes.add({
              'id': ep.id,
              'title': ep.title,
              'audioUrl': ep.audioUrl,
              'imageUrl': ep.imageUrl ?? podcastImageUrl,
              'podcastName': podcastName,
              'publishedAt': ep.publishedAt.toDateTime(),
              'listOrder': listOrder,
              'description': ep.description,
            });
          }
        }

        // If we found unread episodes for this podcast, we return them!
        // The condition requires us to return exactly the episodes of the *first* podcast that has unread episodes.
        if (finalEpisodes.isNotEmpty) {
          prefs.setString(
              'cache_episodes_to_listen',
              jsonEncode(finalEpisodes
                  .map((e) => {
                        ...e,
                        'publishedAt': e['publishedAt'].toIso8601String(),
                      })
                  .toList()));
          return finalEpisodes;
        }
      }

      return [];
    } catch (e) {
      print("Erreur PodcastRepository.fetchEpisodesToListen: $e");
      try {
        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getString('cache_episodes_to_listen');
        if (cached != null) {
          final List<dynamic> decoded = jsonDecode(cached);
          if (decoded.isNotEmpty) {
            return decoded
                .map((e) => {
                      ...e,
                      'publishedAt': DateTime.parse(e['publishedAt']),
                    })
                .toList()
                .cast<Map<String, dynamic>>();
          }
        }
      } catch (err) {
        print("Erreur décodage cache episodes to listen: $err");
      }

      // HARDCODED FALLBACK MOCK
      final mockEps = [
        {
          'id': 'mock_ep_1',
          'title': 'Mock Episode 1 (Test)',
          'audioUrl':
              'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
          'imageUrl':
              'https://upload.wikimedia.org/wikipedia/commons/4/47/PNG_transparency_demonstration_1.png',
          'podcastName': 'Mock Podcast 1 (Test)',
          'publishedAt': DateTime.now(),
          'listOrder': 0,
          'description':
              'Ceci est un épisode de test hardcodé car le quota Firebase est épuisé et le cache est vide.',
        }
      ];
      try {
        final prefs = await SharedPreferences.getInstance();
        final localReadList = prefs.getStringList('local_read_episodes') ?? [];
        return mockEps
            .where((ep) => !localReadList.contains(ep['id']))
            .toList();
      } catch (_) {
        return mockEps;
      }
    }
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
      return [];
    }
  }
}
