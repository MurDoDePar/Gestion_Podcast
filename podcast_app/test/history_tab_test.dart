import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:podcast_app/screens/tabs/history_tab.dart';
import 'package:podcast_app/services/database_repository.dart';
import 'package:podcast_app/models/episode_model.dart';

// Un mock simple de DatabaseRepository pour éviter de charger SQLite et Firestore réels
class MockDatabaseRepository extends DatabaseRepository {
  final List<EpisodeModel> mockEpisodes;

  MockDatabaseRepository({this.mockEpisodes = const []});

  @override
  Future<List<EpisodeModel>> getReadEpisodesHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    // Renvoie la tranche d'épisodes simulés correspondant à la pagination
    if (offset >= mockEpisodes.length) return [];
    final end = (offset + limit) > mockEpisodes.length
        ? mockEpisodes.length
        : (offset + limit);
    return mockEpisodes.sublist(offset, end);
  }
}

void main() {
  group('HistoryTab Widget Tests', () {
    testWidgets(
        'Affiche "Aucun épisode lu pour le moment" si l\'historique est vide',
        (WidgetTester tester) async {
      // 1. Initialiser le mock repository avec une liste vide
      final mockRepo = MockDatabaseRepository(mockEpisodes: []);

      // 2. Dessiner le widget
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HistoryTab(repository: mockRepo),
        ),
      ));

      // 3. Attendre que l'initState et le chargement asynchrone se terminent
      await tester.pumpAndSettle();

      // 4. Vérifier la présence du message informatif et de l'icône de rechange
      expect(find.text('Aucun épisode lu pour le moment'), findsOneWidget);
      expect(
        find.text(
            'Les podcasts que vous écoutez apparaîtront ici dans l\'historique.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets(
        'Affiche la liste des épisodes lus si l\'historique contient des données',
        (WidgetTester tester) async {
      // 1. Initialiser des données d'épisode simulées (imageUrl vide pour éviter NetworkImage dans les tests)
      final mockEpisodes = [
        EpisodeModel(
          id: '1',
          audioUrl: 'https://example.com/audio1.mp3',
          title: 'Episode Test 1',
          podcastName: 'Podcast Francophone',
          imageUrl: '',
          description: 'Description de l\'épisode 1',
          pubDate: DateTime(2026, 5, 27),
        ),
        EpisodeModel(
          id: '2',
          audioUrl: 'https://example.com/audio2.mp3',
          title: 'Episode Test 2',
          podcastName: 'Podcast Technologique',
          imageUrl: '',
          description: 'Description de l\'épisode 2',
          pubDate: DateTime(2026, 5, 26),
        ),
      ];

      final mockRepo = MockDatabaseRepository(mockEpisodes: mockEpisodes);

      // 2. Dessiner le widget
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HistoryTab(repository: mockRepo),
        ),
      ));

      // 3. Attendre le chargement asynchrone des données
      await tester.pumpAndSettle();

      // 4. Vérifier que la liste d'épisodes s'affiche correctement
      expect(find.text('Episode Test 1'), findsOneWidget);
      expect(find.text('Podcast Francophone'), findsOneWidget);
      expect(find.text('Episode Test 2'), findsOneWidget);
      expect(find.text('Podcast Technologique'), findsOneWidget);

      // 5. Vérifier que le message de secours "Aucun épisode" n'est pas présent
      expect(find.text('Aucun épisode lu pour le moment'), findsNothing);
    });
  });
}
