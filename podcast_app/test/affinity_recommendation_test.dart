import 'package:flutter_test/flutter_test.dart';

// Représentation simplifiée des types et de la logique de recommandation
class MockUser {
  final String id;
  final List<MockPodcast> subscriptions;

  MockUser({required this.id, required this.subscriptions});
}

class MockPodcast {
  final String id;
  final String title;
  final String feedUrl;
  final String? author;
  final String? imageUrl;

  MockPodcast({
    required this.id,
    required this.title,
    required this.feedUrl,
    this.author,
    this.imageUrl,
  });
}

// Fonction pure reproduisant l'algorithme d'affinité de FirebasePodcastSyncService
List<MockPodcast> calculateAffinityRecommendations({
  required String currentUserId,
  required List<MockPodcast> currentUserSubs,
  required List<MockUser> allUsers,
  required List<String> localFeedUrls,
}) {
  if (currentUserSubs.isEmpty) return [];

  final Map<String, int> peerOverlapCounts = {};
  final Map<String, List<MockPodcast>> peerSubscriptions = {};

  for (var mySub in currentUserSubs) {
    // Trouver les autres utilisateurs abonnés à ce podcast
    for (var user in allUsers) {
      if (user.id == currentUserId) continue;

      final hasPodcast = user.subscriptions.any((p) => p.id == mySub.id);
      if (hasPodcast) {
        peerOverlapCounts[user.id] = (peerOverlapCounts[user.id] ?? 0) + 1;
        peerSubscriptions[user.id] = user.subscriptions;
      }
    }
  }

  if (peerOverlapCounts.isEmpty) {
    return [];
  }

  // Trier les pairs par score décroissant et prendre le top 10
  final sortedPeers = peerOverlapCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final topPeers = sortedPeers.take(10).map((e) => e.key).toList();

  final Map<String, MockPodcast> recommendedPodcasts = {};
  final Map<String, double> recommendedScores = {};

  for (final peerId in topPeers) {
    final peerWeight = peerOverlapCounts[peerId] ?? 1;
    final podcasts = peerSubscriptions[peerId] ?? [];
    for (var podcast in podcasts) {
      final feedUrl = podcast.feedUrl;
      if (feedUrl.isEmpty) continue;
      if (localFeedUrls.contains(feedUrl)) continue; // Exclusion

      if (!recommendedPodcasts.containsKey(feedUrl)) {
        recommendedPodcasts[feedUrl] = podcast;
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
}

void main() {
  group('Tests de l\'algorithme de score d\'affinité', () {
    const myUserId = 'user_me_uuid';

    test('1. Cas nominal : un podcast en commun', () {
      final pCommon = MockPodcast(
          id: 'pod_common',
          title: 'Shared Podcast',
          feedUrl: 'https://shared.com');
      final pRec = MockPodcast(
          id: 'pod_rec',
          title: 'Recommended Podcast',
          feedUrl: 'https://rec.com');

      final currentUserSubs = [pCommon];
      final peer = MockUser(id: 'peer_1', subscriptions: [pCommon, pRec]);

      final results = calculateAffinityRecommendations(
        currentUserId: myUserId,
        currentUserSubs: currentUserSubs,
        allUsers: [peer],
        localFeedUrls: ['https://shared.com'],
      );

      // Devrait recommander pRec car peer_1 le possède et partage pCommon avec nous
      expect(results.length, 1);
      expect(results.first.id, 'pod_rec');
      expect(results.first.title, 'Recommended Podcast');
    });

    test('2. Cas d\'exclusion : podcast recommandé auquel on est déjà abonné',
        () {
      final pCommon = MockPodcast(
          id: 'pod_common',
          title: 'Shared Podcast',
          feedUrl: 'https://shared.com');
      final pAlreadySubscribed = MockPodcast(
          id: 'pod_already',
          title: 'Already Subscribed',
          feedUrl: 'https://already.com');

      final currentUserSubs = [pCommon, pAlreadySubscribed];
      final peer =
          MockUser(id: 'peer_1', subscriptions: [pCommon, pAlreadySubscribed]);

      final results = calculateAffinityRecommendations(
        currentUserId: myUserId,
        currentUserSubs: currentUserSubs,
        allUsers: [peer],
        localFeedUrls: ['https://shared.com', 'https://already.com'],
      );

      // Devrait être vide car pAlreadySubscribed est dans localFeedUrls (exclus)
      expect(results, isEmpty);
    });

    test('3. Cas de liste vide', () {
      final results = calculateAffinityRecommendations(
        currentUserId: myUserId,
        currentUserSubs: [],
        allUsers: [],
        localFeedUrls: [],
      );

      expect(results, isEmpty);
    });

    test('4. Tri des recommandations selon le poids d\'affinité', () {
      final pCommon1 = MockPodcast(
          id: 'pod_c1', title: 'Common 1', feedUrl: 'https://c1.com');
      final pCommon2 = MockPodcast(
          id: 'pod_c2', title: 'Common 2', feedUrl: 'https://c2.com');

      final pRecHigh = MockPodcast(
          id: 'pod_high', title: 'High Score Rec', feedUrl: 'https://high.com');
      final pRecLow = MockPodcast(
          id: 'pod_low', title: 'Low Score Rec', feedUrl: 'https://low.com');

      final currentUserSubs = [pCommon1, pCommon2];

      // peer_1 partage 2 podcasts (Common 1 & 2) avec nous -> poids 2
      final peer1 =
          MockUser(id: 'peer_1', subscriptions: [pCommon1, pCommon2, pRecHigh]);
      // peer_2 partage seulement 1 podcast (Common 1) avec nous -> poids 1
      final peer2 = MockUser(id: 'peer_2', subscriptions: [pCommon1, pRecLow]);

      final results = calculateAffinityRecommendations(
        currentUserId: myUserId,
        currentUserSubs: currentUserSubs,
        allUsers: [peer1, peer2],
        localFeedUrls: ['https://c1.com', 'https://c2.com'],
      );

      expect(results.length, 2);
      expect(results[0].id,
          'pod_high'); // Score 2 (car partagé par peer_1 qui a un poids de 2)
      expect(results[1].id,
          'pod_low'); // Score 1 (car partagé par peer_2 qui a un poids de 1)
    });
  });
}
