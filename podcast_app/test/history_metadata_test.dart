import 'package:flutter_test/flutter_test.dart';
import 'package:podcast_app/models/episode_model.dart';

// Représentation logique de DatabaseHelper.markEpisodeAsRead
void simulateMarkEpisodeAsRead(
  Map<String, Map<String, dynamic>> mockDb,
  String episodeId, {
  String? title,
  String? audioUrl,
  String? imageUrl,
  String? podcastName,
}) {
  final now = DateTime.now().millisecondsSinceEpoch;

  if (mockDb.containsKey(episodeId)) {
    final existing = mockDb[episodeId]!;
    final finalTitle = (title != null && title.isNotEmpty)
        ? title
        : existing['title'] as String?;
    final finalAudioUrl = (audioUrl != null && audioUrl.isNotEmpty)
        ? audioUrl
        : existing['audioUrl'] as String?;
    final finalImageUrl = (imageUrl != null && imageUrl.isNotEmpty)
        ? imageUrl
        : existing['imageUrl'] as String?;
    final finalPodcastName = (podcastName != null && podcastName.isNotEmpty)
        ? podcastName
        : existing['podcastName'] as String?;
    final finalLocalPath = existing['localPath'] as String?;

    mockDb[episodeId] = {
      'episodeId': episodeId,
      'isRead': 1,
      'readAt': now,
      'title': finalTitle,
      'audioUrl': finalAudioUrl,
      'imageUrl': finalImageUrl,
      'podcastName': finalPodcastName,
      'localPath': finalLocalPath,
    };
  } else {
    mockDb[episodeId] = {
      'episodeId': episodeId,
      'isRead': 1,
      'readAt': now,
      'title': title,
      'audioUrl': audioUrl,
      'imageUrl': imageUrl,
      'podcastName': podcastName,
      'localPath': null,
    };
  }
}

// Représentation logique de DatabaseRepository.getReadEpisodesHistory
Future<List<EpisodeModel>> simulateGetReadEpisodesHistory({
  required Map<String, Map<String, dynamic>> mockDb,
  required List<EpisodeModel> cacheList,
  required Set<String> attemptedRepairIds,
  required Future<void> Function(List<EpisodeModel>) mockBackgroundRepair,
}) async {
  // Simuler la requête SELECT
  final List<Map<String, dynamic>> maps =
      mockDb.values.where((row) => row['isRead'] == 1).toList();

  final List<EpisodeModel> history = maps.map((map) {
    return EpisodeModel(
      id: map['episodeId'] as String,
      title: map['title'] as String? ?? 'Sans titre',
      audioUrl: map['audioUrl'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      podcastName: map['podcastName'] as String? ?? '',
      description: map['description'] as String? ?? '',
    );
  }).toList();

  // Trouver les épisodes cassés que nous n'avons pas encore tenté de réparer dans cette session
  final brokenEpisodes = history
      .where((ep) =>
          (ep.title == 'Sans titre' ||
              ep.title == 'Épisode sans titre' ||
              ep.imageUrl.isEmpty ||
              ep.podcastName.isEmpty) &&
          !attemptedRepairIds.contains(ep.id))
      .toList();

  if (brokenEpisodes.isNotEmpty) {
    // A. Tenter d'abord la réparation via le cache
    final Map<String, EpisodeModel> cacheMap = {};
    for (var ep in cacheList) {
      if (ep.id.isNotEmpty) cacheMap[ep.id] = ep;
      if (ep.audioUrl.isNotEmpty) cacheMap[ep.audioUrl] = ep;
    }

    final List<EpisodeModel> remainingBroken = [];

    for (var ep in brokenEpisodes) {
      final match = cacheMap[ep.id] ?? cacheMap[ep.audioUrl];
      if (match != null) {
        final idx = history.indexWhere((element) => element.id == ep.id);
        if (idx != -1) {
          history[idx] = EpisodeModel(
            id: ep.id,
            title: match.title,
            audioUrl: ep.audioUrl.isNotEmpty ? ep.audioUrl : match.audioUrl,
            imageUrl: ep.imageUrl.isNotEmpty ? ep.imageUrl : match.imageUrl,
            podcastName:
                ep.podcastName.isNotEmpty ? ep.podcastName : match.podcastName,
            description:
                ep.description.isNotEmpty ? ep.description : match.description,
          );
        }
        // Sauvegarde locale SQLite simulée
        simulateMarkEpisodeAsRead(
          mockDb,
          ep.id,
          title: match.title,
          audioUrl: ep.audioUrl.isNotEmpty ? ep.audioUrl : match.audioUrl,
          imageUrl: ep.imageUrl.isNotEmpty ? ep.imageUrl : match.imageUrl,
          podcastName:
              ep.podcastName.isNotEmpty ? ep.podcastName : match.podcastName,
        );
        attemptedRepairIds.add(ep.id);
      } else {
        remainingBroken.add(ep);
      }
    }

    // B. Si certains ne sont toujours pas réparés par le cache, lancer la tâche en arrière-plan
    if (remainingBroken.isNotEmpty) {
      for (var ep in remainingBroken) {
        attemptedRepairIds.add(ep.id);
      }
      await mockBackgroundRepair(remainingBroken);
    }
  }

  return history;
}

void main() {
  group('History Metadata Resolution & Repair Tests', () {
    test('1. markEpisodeAsRead fusionne et préserve les métadonnées existantes',
        () {
      final Map<String, Map<String, dynamic>> mockDb = {};

      // Étape A : Insérer un épisode avec métadonnées complètes et localPath
      mockDb['ep1'] = {
        'episodeId': 'ep1',
        'isRead': 1,
        'readAt': 12345,
        'title': 'Titre Initial',
        'audioUrl': 'https://example.com/audio.mp3',
        'imageUrl': 'https://example.com/image.jpg',
        'podcastName': 'Mon Podcast',
        'localPath': '/path/to/file.mp3',
      };

      // Étape B : Appeler markEpisodeAsRead avec uniquement l'id (comme lors d'une synchro simple)
      simulateMarkEpisodeAsRead(mockDb, 'ep1');

      // Vérifier que le titre, l'image et le localPath existants ont bien été conservés
      expect(mockDb['ep1']!['title'], 'Titre Initial');
      expect(mockDb['ep1']!['imageUrl'], 'https://example.com/image.jpg');
      expect(mockDb['ep1']!['localPath'], '/path/to/file.mp3');
    });

    test(
        '2. getReadEpisodesHistory répare les épisodes sans titre via le cache',
        () async {
      final Map<String, Map<String, dynamic>> mockDb = {};
      final Set<String> attemptedRepairIds = {};

      // Épisode cassé sans titre/image en base
      mockDb['ep1'] = {
        'episodeId': 'ep1',
        'isRead': 1,
        'readAt': 12345,
        'title': 'Sans titre',
        'audioUrl': '',
        'imageUrl': '',
        'podcastName': '',
        'localPath': null,
      };

      // Épisode correct correspondant dans le cache
      final cacheList = [
        EpisodeModel(
          id: 'ep1',
          audioUrl: 'https://example.com/audio.mp3',
          title: 'Titre Réparé',
          podcastName: 'Podcast Réparé',
          imageUrl: 'https://example.com/image.jpg',
          description: 'Description de test',
        )
      ];

      bool backgroundRepairCalled = false;

      final history = await simulateGetReadEpisodesHistory(
        mockDb: mockDb,
        cacheList: cacheList,
        attemptedRepairIds: attemptedRepairIds,
        mockBackgroundRepair: (broken) async {
          backgroundRepairCalled = true;
        },
      );

      // Le titre doit être réparé
      expect(history.first.title, 'Titre Réparé');
      expect(history.first.podcastName, 'Podcast Réparé');
      expect(history.first.imageUrl, 'https://example.com/image.jpg');

      // La base de données locale simulée doit être mise à jour
      expect(mockDb['ep1']!['title'], 'Titre Réparé');

      // Le background repair (flux RSS) ne doit pas être appelé car résolu par le cache
      expect(backgroundRepairCalled, isFalse);

      // L'id doit être marqué comme tenté pour ne pas relancer
      expect(attemptedRepairIds.contains('ep1'), isTrue);
    });

    test(
        '3. getReadEpisodesHistory évite les boucles infinies de réparation via attemptedRepairIds',
        () async {
      final Map<String, Map<String, dynamic>> mockDb = {};
      final Set<String> attemptedRepairIds = {};

      // Épisode cassé sans titre, non présent dans le cache
      mockDb['ep1'] = {
        'episodeId': 'ep1',
        'isRead': 1,
        'readAt': 12345,
        'title': 'Sans titre',
        'audioUrl': '',
        'imageUrl': '',
        'podcastName': '',
        'localPath': null,
      };

      int backgroundRepairCallCount = 0;

      // Premier appel : lance la réparation en arrière-plan
      await simulateGetReadEpisodesHistory(
        mockDb: mockDb,
        cacheList: [],
        attemptedRepairIds: attemptedRepairIds,
        mockBackgroundRepair: (broken) async {
          backgroundRepairCallCount++;
        },
      );

      expect(backgroundRepairCallCount, 1);
      expect(attemptedRepairIds.contains('ep1'), isTrue);

      // Deuxième appel : comme l'id 'ep1' est dans attemptedRepairIds, la réparation ne doit plus être lancée
      await simulateGetReadEpisodesHistory(
        mockDb: mockDb,
        cacheList: [],
        attemptedRepairIds: attemptedRepairIds,
        mockBackgroundRepair: (broken) async {
          backgroundRepairCallCount++;
        },
      );

      expect(backgroundRepairCallCount, 1); // Le compteur doit rester à 1
    });
  });
}
