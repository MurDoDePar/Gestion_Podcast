import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart' hide Timestamp;
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:crypto/crypto.dart';
import '../../core/services/podcast_sync_service.dart';
import '../../models/podcast_model.dart';
import '../../models/episode_model.dart';
import '../../dataconnect-generated/example.dart';

class FirebasePodcastSyncService implements PodcastSyncService {
  String _getPodcastUuid(int? collectionId, String feedUrl) {
    if (feedUrl.isEmpty) return '00000000-0000-4000-8000-000000000000';
    final bytes = utf8.encode(feedUrl);
    final digest = md5.convert(bytes);
    final rawId = digest.toString(); // 32 hex chars
    return '${rawId.substring(0, 8)}-${rawId.substring(8, 12)}-${rawId.substring(12, 16)}-${rawId.substring(16, 20)}-${rawId.substring(20, 32)}';
  }

  @override
  Future<List<PodcastModel>> fetchRemoteSubscriptions(String userId) async {
    List<PodcastModel> podcasts = [];
    // A. Essayer Data Connect
    try {
      final userResult = await ExampleConnector.instance
          .findUserByGoogleId(googleId: userId)
          .execute();
      final users = userResult.data.users;
      if (users.isNotEmpty) {
        final postgresUuid = users.first.id;
        final subsResult = await ExampleConnector.instance
            .getMySubscriptions(userId: postgresUuid)
            .execute();
        final subs = subsResult.data.subscriptionTypes.toList();
        subs.sort((a, b) {
          final orderA = a.listOrder ?? 9999;
          final orderB = b.listOrder ?? 9999;
          if (orderA == orderB) {
            return a.podcast.title.compareTo(b.podcast.title);
          }
          return orderA.compareTo(orderB);
        });
        podcasts = subs.map((sub) {
          return PodcastModel(
            collectionName: sub.podcast.title,
            artistName: sub.podcast.author ?? 'Auteur inconnu',
            artworkUrl: sub.podcast.imageUrl ?? '',
            feedUrl: sub.podcast.feedUrl,
            collectionId:
                int.tryParse(sub.podcast.id) ?? sub.podcast.id.hashCode,
          );
        }).toList();
      }
    } catch (e) {}
    // B. Essayer Firestore
    if (podcasts.isEmpty) {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .get();
      final List<MapEntry<PodcastModel, int>> podcastWithOrder =
          querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final podcast = PodcastModel(
          collectionName: data['collectionName']?.toString() ?? 'Sans titre',
          artistName: data['artistName']?.toString() ?? 'Artiste inconnu',
          artworkUrl: data['artworkUrl600']?.toString() ??
              data['artworkUrl100']?.toString() ??
              '',
          feedUrl: data['feedUrl']?.toString() ?? '',
          collectionId: data['collectionId'] is int?
              ? data['collectionId'] as int?
              : int.tryParse(data['collectionId']?.toString() ?? ''),
        );
        final orderVal =
            data['orderIndex'] is int ? data['orderIndex'] as int : 9999;
        return MapEntry(podcast, orderVal);
      }).toList();
      podcastWithOrder.sort((a, b) => a.value.compareTo(b.value));
      podcasts = podcastWithOrder.map((entry) => entry.key).toList();
    }
    return podcasts;
  }

  @override
  Future<List<String>> fetchEpisodeHistory(String userId) async {
    final List<String> episodeIds = [];
    try {
      final historySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('episode_history')
          .where('finishedListening', isEqualTo: true)
          .get();
      for (var doc in historySnapshot.docs) {
        try {
          final decodedBytes = base64Url.decode(base64Url.normalize(doc.id));
          final decodedId = utf8.decode(decodedBytes);
          episodeIds.add(decodedId);
        } catch (_) {
          episodeIds.add(doc.id);
        }
      }
    } catch (e) {}
    return episodeIds;
  }

  @override
  Future<void> syncSubscribe(
      String userId, PodcastModel podcast, int orderIndex) async {
    final String podcastUuid =
        _getPodcastUuid(podcast.collectionId, podcast.feedUrl);
    // 1. Ajouter dans Firestore
    final QuerySnapshot query = await FirebaseFirestore.instance
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .where('feedUrl', isEqualTo: podcast.feedUrl)
        .get();
    if (query.docs.isEmpty) {
      await FirebaseFirestore.instance.collection('subscriptions').add({
        'userId': userId,
        'collectionId': podcast.collectionId,
        'collectionName': podcast.collectionName,
        'artistName': podcast.artistName,
        'artworkUrl600': podcast.artworkUrl,
        'feedUrl': podcast.feedUrl,
        'orderIndex': orderIndex,
        'subscribedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await query.docs.first.reference.update({'orderIndex': orderIndex});
    }
    // 2. Ajouter dans Data Connect
    final userResult = await ExampleConnector.instance
        .findUserByGoogleId(googleId: userId)
        .execute();
    if (userResult.data.users.isNotEmpty) {
      final postgresUuid = userResult.data.users.first.id;
      await ExampleConnector.instance
          .upsertPodcast(
            title: podcast.collectionName,
            feedUrl: podcast.feedUrl,
            createdAt:
                Timestamp(DateTime.now().millisecondsSinceEpoch ~/ 1000, 0),
          )
          .id(podcastUuid)
          .imageUrl(podcast.artworkUrl)
          .author(podcast.artistName)
          .execute();
      await ExampleConnector.instance
          .subscribeToPodcast(
            userId: postgresUuid,
            podcastId: podcastUuid,
            subscribedAt:
                Timestamp(DateTime.now().millisecondsSinceEpoch ~/ 1000, 0),
          )
          .listOrder(orderIndex)
          .execute();
    }
  }

  @override
  Future<void> syncUnsubscribe(
      String userId, String feedUrl, String podcastId) async {
    // 1. Supprimer de Firestore
    final QuerySnapshot query = await FirebaseFirestore.instance
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .where('feedUrl', isEqualTo: feedUrl)
        .get();
    for (var doc in query.docs) {
      await doc.reference.delete();
    }
    // 2. Supprimer de Data Connect
    final userResult = await ExampleConnector.instance
        .findUserByGoogleId(googleId: userId)
        .execute();
    if (userResult.data.users.isNotEmpty) {
      final postgresUuid = userResult.data.users.first.id;
      await ExampleConnector.instance
          .unsubscribeFromPodcast(
            userId: postgresUuid,
            podcastId: podcastId,
          )
          .execute();
    }
  }

  @override
  Future<Set<String>> fetchReadEpisodeIds(String userId) async {
    final readIds = <String>{};
    try {
      final historySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('episode_history')
          .where('finishedListening', isEqualTo: true)
          .get();
      for (var doc in historySnapshot.docs) {
        try {
          final decodedBytes = base64Url.decode(base64Url.normalize(doc.id));
          final decodedId = utf8.decode(decodedBytes);
          readIds.add(decodedId);
        } catch (_) {
          readIds.add(doc.id);
        }
      }
    } catch (e) {
      // print("Erreur fetchReadEpisodeIds Firestore: $e");
    }
    return readIds;
  }

  @override
  Future<void> syncEpisodeRead(String userId, String episodeId) async {
    final String encodedId = base64UrlEncode(utf8.encode(episodeId));
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('episode_history')
        .doc(encodedId)
        .set({'finishedListening': true}, SetOptions(merge: true)).timeout(
            const Duration(seconds: 4));
  }

  @override
  Future<void> checkRemoteVersionRequirements(int currentBuild) async {
    final configDoc = await FirebaseFirestore.instance
        .collection('system')
        .doc('config')
        .get(const GetOptions(source: Source.serverAndCache))
        .timeout(const Duration(seconds: 4));
    if (!configDoc.exists) return;
    final data = configDoc.data()!;
    final minSupportedBuild = data['min_supported_build'] as int? ?? 0;
    final killSwitchActive = data['kill_switch_active'] as bool? ?? false;
    final messages = data['deprecation_messages'] as Map<String, dynamic>?;
    if (killSwitchActive || currentBuild < minSupportedBuild) {
      final errorMsg = messages?['fr'] ??
          "Une mise à jour importante est requise pour continuer à utiliser PodStream.";
      throw UpdateRequiredException(errorMsg);
    }
  }

  @override
  Future<List<EpisodeModel>> fetchRemoteEpisodes() async {
    final QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('episodes').get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return EpisodeModel.fromMap(data, documentId: doc.id);
    }).toList();
  }

  @override
  Future<List<PodcastModel>> fetchAffinityPodcasts(
      String userId, List<String> localFeedUrls) async {
    if (localFeedUrls.isEmpty) return [];
    try {
      // 1. Résoudre le googleId (String) en UUID PostgreSQL
      final userResult = await ExampleConnector.instance
          .findUserByGoogleId(googleId: userId)
          .execute();
      final users = userResult.data.users;
      if (users.isEmpty) {
//         debugPrint(
//             "⚠️ Utilisateur avec googleId/userId $userId introuvable dans la table PostgreSQL.");
        return [];
      }
      final postgresUuid = users.first.id;
//       debugPrint(
//           "✅ Utilisateur trouvé en base, UUID PostgreSQL : $postgresUuid");

      // 2. Appeler la requête Data Connect pour récupérer les affinités
      final affinityResult = await ExampleConnector.instance
          .getAffinityRecommendations(userId: postgresUuid)
          .execute();

      final mySubs = affinityResult.data.mySubscriptions;
      if (mySubs.isEmpty) {
        return [];
      }

      final Map<String, int> peerOverlapCounts = {};
      final Map<
              String,
              List<
                  GetAffinityRecommendationsMySubscriptionsPodcastSubscriptionTypesOnPodcastUserSubscriptionTypesOnUserPodcast>>
          peerSubscriptions = {};

      for (var sub in mySubs) {
        for (var peerSub in sub.podcast.subscriptionTypes_on_podcast) {
          final peer = peerSub.user;
          final peerId = peer.id;
          if (peerId == postgresUuid) continue;

          peerOverlapCounts[peerId] = (peerOverlapCounts[peerId] ?? 0) + 1;
          peerSubscriptions[peerId] =
              peer.subscriptionTypes_on_user.map((su) => su.podcast).toList();
        }
      }

      if (peerOverlapCounts.isEmpty) {
        return [];
      }

      // Trier les pairs par score d'affinité décroissant et prendre le top 10
      final sortedPeers = peerOverlapCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topPeers = sortedPeers.take(10).map((e) => e.key).toList();

      final Map<String, PodcastModel> recommendedPodcasts = {};
      final Map<String, double> recommendedScores = {};

      for (final peerId in topPeers) {
        final peerWeight = peerOverlapCounts[peerId] ?? 1;
        final podcasts = peerSubscriptions[peerId] ?? [];
        for (var podcast in podcasts) {
          final feedUrl = podcast.feedUrl;
          if (feedUrl.isEmpty) continue;
          if (localFeedUrls.contains(feedUrl)) continue;

          if (!recommendedPodcasts.containsKey(feedUrl)) {
            recommendedPodcasts[feedUrl] = PodcastModel(
              collectionName: podcast.title,
              artistName: podcast.author ?? 'Artiste inconnu',
              artworkUrl: podcast.imageUrl ?? '',
              feedUrl: feedUrl,
              collectionId: int.tryParse(podcast.id) ?? podcast.id.hashCode,
            );
          }
          recommendedScores[feedUrl] =
              (recommendedScores[feedUrl] ?? 0) + peerWeight;
        }
      }

      final sortedRecommendations = recommendedScores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return sortedRecommendations
          .map((entry) => recommendedPodcasts[entry.key]!)
          .toList();
    } catch (e) {
      // ❌ NE PLUS JAMAIS AVALER L'ERREUR DANS LE FUTUR
//       debugPrint("🚨 ERREUR CRITIQUE dans fetchAffinityPodcasts : $e");
//       debugPrint("🔍 StackTrace associée : $stackTrace");
      // Affiche aussi les données en entrée pour vérifier tes IDs
//       debugPrint("ℹ️ UserID utilisé pour la requête : $userId");
      return [];
    }
  }

  @override
  Future<Map<String, int>> fetchRemoteSubscriptionOrders(String userId) async {
    final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .get();
    final Map<String, int> firestoreMap = {};
    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final feedUrl = data['feedUrl'] as String? ?? '';
      final orderIndex = data['orderIndex'] as int? ?? -1;
      if (feedUrl.isNotEmpty) {
        firestoreMap[feedUrl] = orderIndex;
      }
    }
    return firestoreMap;
  }
}
