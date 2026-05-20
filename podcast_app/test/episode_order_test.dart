import 'package:flutter_test/flutter_test.dart';

// --- Fonction mockée reproduisant la logique de PodcastRepository ---
List<Map<String, dynamic>> mockFetchEpisodesToListen({
  required String orderSetting,
  required List<Map<String, dynamic>> mockSubscriptions,
  required Map<String, List<Map<String, dynamic>>> mockEpisodesByPodcastId,
  required Set<String> readEpisodeIds,
}) {
  // Sort podcasts according to listOrder
  mockSubscriptions.sort((a, b) {
    final orderA = a['listOrder'] ?? 9999;
    final orderB = b['listOrder'] ?? 9999;
    if (orderA == orderB) return a['title'].compareTo(b['title']);
    return orderA.compareTo(orderB);
  });

  List<Map<String, dynamic>> finalEpisodes = [];

  for (var sub in mockSubscriptions) {
    final podcastId = sub['id'];

    // Obtenir les épisodes pour ce podcast
    var epsList = List<Map<String, dynamic>>.from(
        mockEpisodesByPodcastId[podcastId] ?? []);

    // Trier les épisodes
    epsList.sort((a, b) {
      int cmp = 0;
      final matchA = RegExp(r'#(\d+)').firstMatch(a['title']);
      final matchB = RegExp(r'#(\d+)').firstMatch(b['title']);

      if (matchA != null && matchB != null) {
        final numA = int.parse(matchA.group(1)!);
        final numB = int.parse(matchB.group(1)!);
        cmp = numA.compareTo(numB);
      } else {
        cmp = (a['publishedAt'] as DateTime)
            .compareTo(b['publishedAt'] as DateTime);
        if (cmp == 0) cmp = a['title'].compareTo(b['title']);
      }

      if (orderSetting == 'asc') {
        return cmp; // oldest first
      } else {
        return -cmp; // newest first
      }
    });

    // Filtrer les épisodes non lus
    for (var ep in epsList) {
      if (!readEpisodeIds.contains(ep['id'])) {
        finalEpisodes.add(ep);
      }
    }

    // Fallback: si on a trouvé des non-lus, on s'arrête là et on retourne le flux
    if (finalEpisodes.isNotEmpty) {
      return finalEpisodes;
    }
  }

  return [];
}

void main() {
  group('Tests Avancés: Ordre et File d\'attente des Podcasts', () {
    test('1. Test de tri inverse (asc vs desc)', () {
      final episodes = [
        {
          'id': 'ep1',
          'title': 'Episode #2',
          'publishedAt': DateTime(2023, 1, 2)
        },
        {
          'id': 'ep2',
          'title': 'Episode #1',
          'publishedAt': DateTime(2023, 1, 1)
        },
        {
          'id': 'ep3',
          'title': 'Episode #3',
          'publishedAt': DateTime(2023, 1, 3)
        },
      ];

      final subs = [
        {'id': 'pod1', 'title': 'Pod1', 'listOrder': 1}
      ];
      final episodesMap = {'pod1': episodes};

      // Cas 1: 'asc' (Plus ancien en premier)
      final ascResult = mockFetchEpisodesToListen(
        orderSetting: 'asc',
        mockSubscriptions: subs,
        mockEpisodesByPodcastId: episodesMap,
        readEpisodeIds: {},
      );
      expect(ascResult.length, 3);
      expect(ascResult[0]['title'], 'Episode #1'); // Le plus vieux
      expect(ascResult[2]['title'], 'Episode #3'); // Le plus récent

      // Cas 2: 'desc' (Plus récent en premier)
      final descResult = mockFetchEpisodesToListen(
        orderSetting: 'desc',
        mockSubscriptions: subs,
        mockEpisodesByPodcastId: episodesMap,
        readEpisodeIds: {},
      );
      expect(descResult.length, 3);
      expect(descResult[0]['title'], 'Episode #3'); // Le plus récent
      expect(descResult[2]['title'], 'Episode #1'); // Le plus vieux
    });

    test('2. Test du Fallback séquentiel (À écouter passe au suivant)', () {
      final subs = [
        {'id': 'pod1', 'title': 'Pod1', 'listOrder': 1},
        {'id': 'pod2', 'title': 'Pod2', 'listOrder': 2},
      ];

      final episodesMap = {
        'pod1': [
          {
            'id': 'pod1_ep1',
            'title': 'P1 Ep1',
            'publishedAt': DateTime(2023, 1, 1)
          },
          {
            'id': 'pod1_ep2',
            'title': 'P1 Ep2',
            'publishedAt': DateTime(2023, 1, 2)
          },
        ],
        'pod2': [
          {
            'id': 'pod2_ep1',
            'title': 'P2 Ep1',
            'publishedAt': DateTime(2023, 1, 3)
          },
          {
            'id': 'pod2_ep2',
            'title': 'P2 Ep2',
            'publishedAt': DateTime(2023, 1, 4)
          },
        ]
      };

      // Simuler que TOUS les épisodes du podcast 1 sont lus
      final readEpisodes = {'pod1_ep1', 'pod1_ep2'};

      final result = mockFetchEpisodesToListen(
        orderSetting: 'asc',
        mockSubscriptions: subs,
        mockEpisodesByPodcastId: episodesMap,
        readEpisodeIds: readEpisodes,
      );

      // L'algorithme doit sauter pod1 (tout est lu) et retourner les épisodes de pod2 triés du plus ancien au plus récent
      expect(result.length, 2);
      expect(result[0]['title'], 'P2 Ep1');
      expect(result[1]['title'], 'P2 Ep2');
    });

    test('3. Test de réactivité (Mise à jour du Statut Lu)', () {
      final subs = [
        {'id': 'pod1', 'title': 'Pod1', 'listOrder': 1}
      ];
      final episodesMap = {
        'pod1': [
          {
            'id': 'ep1',
            'title': 'Episode #1',
            'publishedAt': DateTime(2023, 1, 1)
          },
          {
            'id': 'ep2',
            'title': 'Episode #2',
            'publishedAt': DateTime(2023, 1, 2)
          },
          {
            'id': 'ep3',
            'title': 'Episode #3',
            'publishedAt': DateTime(2023, 1, 3)
          },
        ]
      };

      // Au début, rien n'est lu
      Set<String> readEpisodes = {};

      var resultList = mockFetchEpisodesToListen(
        orderSetting: 'asc',
        mockSubscriptions: subs,
        mockEpisodesByPodcastId: episodesMap,
        readEpisodeIds: readEpisodes,
      );

      expect(resultList[0]['title'], 'Episode #1'); // En tête de liste

      // Simuler la lecture complète de l'épisode en tête de liste
      readEpisodes.add('ep1');

      // Nouveau fetch (qui correspond à un listRefreshNotifier ou démarrage)
      var updatedList = mockFetchEpisodesToListen(
        orderSetting: 'asc',
        mockSubscriptions: subs,
        mockEpisodesByPodcastId: episodesMap,
        readEpisodeIds: readEpisodes,
      );

      // L'épisode 1 doit disparaître, l'épisode 2 prend immédiatement la tête
      expect(updatedList.length, 2);
      expect(updatedList[0]['title'], 'Episode #2');
      expect(updatedList[1]['title'], 'Episode #3');
    });
  });
}
