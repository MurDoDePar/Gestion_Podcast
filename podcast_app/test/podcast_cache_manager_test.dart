import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:podcast_app/services/database_helper.dart';
import 'package:podcast_app/services/sqlite_podcast_repository.dart';
import 'package:podcast_app/services/podcast_cache_manager.dart';
import 'package:podcast_app/services/download_manager.dart';
import 'package:podcast_app/services/itunes_gateway.dart';
import 'package:podcast_app/models/episode_model.dart';
import 'package:podcast_app/models/app_settings.dart';
import 'package:podcast_app/core/services/service_locator.dart';

class FakeDownloadManager extends DownloadManager {
  final Map<String, ValueNotifier<double>> _progressNotifiers = {};
  final Map<String, ValueNotifier<DownloadStatus>> _statusNotifiers = {};
  final List<String> downloadedEpisodes = [];

  FakeDownloadManager() : super.forTesting();

  @override
  ValueNotifier<double> getProgressNotifier(String episodeId) {
    return _progressNotifiers.putIfAbsent(
        episodeId, () => ValueNotifier<double>(0.0));
  }

  @override
  ValueNotifier<DownloadStatus> getStatusNotifier(String episodeId) {
    return _statusNotifiers.putIfAbsent(
        episodeId, () => ValueNotifier<DownloadStatus>(DownloadStatus.idle));
  }

  @override
  Future<void> downloadEpisode(String episodeId, String url) async {
    downloadedEpisodes.add(episodeId);
    getStatusNotifier(episodeId).value = DownloadStatus.downloaded;
    getProgressNotifier(episodeId).value = 1.0;
  }
}

class FakeITunesGateway extends ITunesGateway {
  final Map<String, int> urlSizes = {};

  FakeITunesGateway() : super.forTesting();

  @override
  Future<int> getUrlFileSize(String url) async {
    return urlSizes[url] ?? 0;
  }
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('PodcastCacheManager - Logique de Cache Intelligent', () {
    late String dbPath;
    late String pathString;
    late SqlitePodcastRepository sqliteRepository;
    late PodcastCacheManager cacheManager;
    late FakeDownloadManager fakeDownloadManager;
    late FakeITunesGateway fakeITunesGateway;

    setUpAll(() {
      // Setup minimal service locator dependencies if needed
      if (!locator.isRegistered<PodcastCacheManager>()) {
        locator.registerLazySingleton<PodcastCacheManager>(
            () => PodcastCacheManager());
      }
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      dbPath = await getDatabasesPath();
      pathString = p.join(dbPath, 'podstream_test.db');

      final file = File(pathString);
      if (await file.exists()) {
        await file.delete();
      }

      // Hack the database path in helper
      DatabaseHelper.mockInstance = DatabaseHelper();

      fakeDownloadManager = FakeDownloadManager();
      DownloadManager.mockInstance = fakeDownloadManager;

      fakeITunesGateway = FakeITunesGateway();
      ITunesGateway.mockInstance = fakeITunesGateway;

      // Open and initialize in-memory database or test db
      final db = await DatabaseHelper().database;
      // Empty tables
      await db.delete('episodes_status');
      await db.delete('episodes_metadata');
      await db.delete('settings');

      sqliteRepository = SqlitePodcastRepository();
      cacheManager = PodcastCacheManager(sqliteRepository: sqliteRepository);
    });

    tearDown(() async {
      DownloadManager.mockInstance = null;
      ITunesGateway.mockInstance = null;

      await DatabaseHelper().closeDatabase();
      final file = File(pathString);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    });

    test('1. Calcule la taille totale basée sur la base de données', () async {
      final db = await DatabaseHelper().database;
      // Insérer les tailles en BDD
      await db.insert('episodes_status', {
        'episodeId': 'ep1',
        'isRead': 0,
        'localPath': 'downloads/ep1.mp3',
        'status': 1,
        'fileSize': 15 * 1024 * 1024 // 15 Mo
      });
      await db.insert('episodes_status', {
        'episodeId': 'ep2',
        'isRead': 0,
        'localPath': 'downloads/ep2.mp3',
        'status': 1,
        'fileSize': 25 * 1024 * 1024 // 25 Mo
      });

      final episodes = [
        EpisodeModel(
          id: 'ep1',
          audioUrl: 'https://example.com/ep1.mp3',
          title: 'Ep 1',
          podcastName: 'Podcast',
          imageUrl: '',
          description: '',
        ),
        EpisodeModel(
          id: 'ep2',
          audioUrl: 'https://example.com/ep2.mp3',
          title: 'Ep 2',
          podcastName: 'Podcast',
          imageUrl: '',
          description: '',
        )
      ];

      // loadEpisodes va d'abord appeler _calculateTotalSize
      // Configurer la limite de cache à 50 Mo
      await AppSettings.setMaxCacheSize(50 * 1024 * 1024);

      // On appelle loadEpisodes. Comme total (40 Mo) <= maxCacheSize (50 Mo),
      // il devrait tenter de télécharger les deux épisodes
      await cacheManager.loadEpisodes(episodes);

      // On vérifie le statut des épisodes en BDD
      final size1 = await sqliteRepository.getEpisodeFileSize('ep1');
      final size2 = await sqliteRepository.getEpisodeFileSize('ep2');
      expect(size1, equals(15 * 1024 * 1024));
      expect(size2, equals(25 * 1024 * 1024));

      // On vérifie que les deux épisodes ont bien été envoyés au DownloadManager
      expect(fakeDownloadManager.downloadedEpisodes, contains('ep1'));
      expect(fakeDownloadManager.downloadedEpisodes, contains('ep2'));
    });

    test(
        '2. Ne charge pas au-delà de maxCacheSize si totalWeight > maxCacheSize',
        () async {
      final db = await DatabaseHelper().database;
      // Configurer la limite à 30 Mo
      await AppSettings.setMaxCacheSize(30 * 1024 * 1024);

      // Insérer des tailles d'épisodes en BDD
      await db.insert('episodes_status', {
        'episodeId': 'ep1',
        'isRead': 0,
        'fileSize': 20 * 1024 * 1024 // 20 Mo
      });
      await db.insert('episodes_status', {
        'episodeId': 'ep2',
        'isRead': 0,
        'fileSize': 20 * 1024 * 1024 // 20 Mo
      });

      final episodes = [
        EpisodeModel(
          id: 'ep1',
          audioUrl: 'https://example.com/ep1.mp3',
          title: 'Ep 1',
          podcastName: 'Podcast',
          imageUrl: '',
          description: '',
        ),
        EpisodeModel(
          id: 'ep2',
          audioUrl: 'https://example.com/ep2.mp3',
          title: 'Ep 2',
          podcastName: 'Podcast',
          imageUrl: '',
          description: '',
        )
      ];

      // Appeler loadEpisodes. Comme le premier fait 20 Mo (<= 30 Mo), il est chargé.
      // Le deuxième ferait monter le total à 40 Mo (> 30 Mo), donc il est sauté.
      await cacheManager.loadEpisodes(episodes);

      // Vérifier que le premier est resté à 20 Mo
      final size1 = await sqliteRepository.getEpisodeFileSize('ep1');
      expect(size1, equals(20 * 1024 * 1024));

      // ep1 a été téléchargé, ep2 a été ignoré
      expect(fakeDownloadManager.downloadedEpisodes, contains('ep1'));
      expect(fakeDownloadManager.downloadedEpisodes, isNot(contains('ep2')));
    });

    test(
        '3. Utilise la requête de passerelle si la taille n\'est pas en base de données',
        () async {
      // Configurer la limite de cache à 50 Mo
      await AppSettings.setMaxCacheSize(50 * 1024 * 1024);

      // On simule une taille de 10 Mo retournée par la passerelle pour ep1
      fakeITunesGateway.urlSizes['https://example.com/ep1.mp3'] =
          10 * 1024 * 1024;
      // ep2 n\'a pas de taille en BDD ni sur la passerelle -> fallback 30 Mo
      // Total estimé : 10 + 30 = 40 Mo <= 50 Mo -> Chargement de tous

      final episodes = [
        EpisodeModel(
          id: 'ep1',
          audioUrl: 'https://example.com/ep1.mp3',
          title: 'Ep 1',
          podcastName: 'Podcast',
          imageUrl: '',
          description: '',
        ),
        EpisodeModel(
          id: 'ep2',
          audioUrl: 'https://example.com/ep2.mp3',
          title: 'Ep 2',
          podcastName: 'Podcast',
          imageUrl: '',
          description: '',
        )
      ];

      await cacheManager.loadEpisodes(episodes);

      expect(fakeDownloadManager.downloadedEpisodes, contains('ep1'));
      expect(fakeDownloadManager.downloadedEpisodes, contains('ep2'));
    });

    test(
        '4. Utilise le fallback par défaut de 30 Mo si la passerelle échoue ou retourne 0',
        () async {
      // Limite de cache à 25 Mo
      await AppSettings.setMaxCacheSize(25 * 1024 * 1024);

      // ep1 n\'a pas de taille en BDD et la passerelle retourne 0 (ou échoue)
      // Donc fallback à 30 Mo.
      // Total (30 Mo) > maxCacheSize (25 Mo) -> ep1 ne doit pas être chargé car il dépasse à lui seul la limite

      final episodes = [
        EpisodeModel(
          id: 'ep1',
          audioUrl: 'https://example.com/ep1.mp3',
          title: 'Ep 1',
          podcastName: 'Podcast',
          imageUrl: '',
          description: '',
        )
      ];

      await cacheManager.loadEpisodes(episodes);

      expect(fakeDownloadManager.downloadedEpisodes, isEmpty);
    });

    test(
        '5. Appelle enforceCacheLimit dynamique et nettoie le cache en base de données',
        () async {
      final db = await DatabaseHelper().database;

      // Configurer la limite de cache à 20 Mo
      await AppSettings.setMaxCacheSize(20 * 1024 * 1024);

      // On insère des épisodes déjà téléchargés (localPath non null) pour simuler un cache existant
      // Total existant en cache : 25 Mo (qui dépasse la limite de 20 Mo)
      await db.insert('episodes_status', {
        'episodeId': 'old1',
        'isRead': 0,
        'localPath': 'downloads/old1.mp3',
        'fileSize': 15 * 1024 * 1024 // 15 Mo
      });
      await db.insert('episodes_status', {
        'episodeId': 'old2',
        'isRead': 0,
        'localPath': 'downloads/old2.mp3',
        'fileSize': 10 * 1024 * 1024 // 10 Mo
      });

      // On insère aussi les métadonnées pour le tri FIFO de getCacheCandidates()
      await db.insert('episodes_metadata', {
        'episodeId': 'old1',
        'title': 'Old 1',
        'pubDate': 1000 // Publié en premier
      });
      await db.insert('episodes_metadata', {
        'episodeId': 'old2',
        'title': 'Old 2',
        'pubDate': 2000 // Publié en deuxième
      });

      // On mock le path_provider pour éviter les MissingPluginException
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall methodCall) async {
          return '.';
        },
      );

      // On lance enforceCacheLimit(20) Mo
      await cacheManager.enforceCacheLimit(20);

      // Limite = 20 Mo. Safety limit = 18 Mo.
      // Espace total = 25 Mo.
      // Doit supprimer le plus ancien (\'old1\') en premier.
      // Après suppression de \'old1\', taille restante = 10 Mo.
      // 10 Mo <= 18 Mo (safety limit), donc \'old2\' est conservé.

      final pathOld1 = await sqliteRepository.getEpisodeLocalPath('old1');
      final pathOld2 = await sqliteRepository.getEpisodeLocalPath('old2');

      expect(pathOld1, isNull);
      expect(pathOld2, isNotNull);
    });
  });
}
