import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:podcast_app/services/database_helper.dart';

void main() {
  // Configurer l'environnement de test FFI pour SQLite
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('SQLite Database Migration Tests (v1 -> v8)', () {
    late String dbPath;
    late String pathString;

    setUp(() async {
      dbPath = await getDatabasesPath();
      pathString = join(dbPath, 'podstream.db');

      // S'assurer que la base de données de test repart de zéro
      final file = File(pathString);
      if (await file.exists()) {
        await file.delete();
      }
    });

    tearDown(() async {
      // Nettoyer la connexion DatabaseHelper et supprimer le fichier physique
      await DatabaseHelper().closeDatabase();
      final file = File(pathString);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    });

    test(
        'Migration v1 à v8 préserve les abonnements, l\'historique et reconstruit les index',
        () async {
      // 1. Simuler l'état v1 initial
      final dbV1 = await openDatabase(
        pathString,
        version: 1,
        onCreate: (db, version) async {
          // Table my_podcasts en v1 (la clé primaire est feedUrl)
          await db.execute('''
            CREATE TABLE my_podcasts (
              feedUrl TEXT PRIMARY KEY,
              collectionId INTEGER,
              collectionName TEXT,
              artistName TEXT,
              artworkUrl TEXT,
              sortOrder INTEGER,
              isSynced INTEGER DEFAULT 1
            )
          ''');

          // Table episodes_status en v1 (version ultra-allégée historique)
          await db.execute('''
            CREATE TABLE episodes_status (
              episodeId TEXT PRIMARY KEY,
              isRead INTEGER DEFAULT 0
            )
          ''');
        },
      );

      // Insérer des données factices dans la v1
      const testFeedUrl = 'https://example.com/podcast.xml';
      await dbV1.insert('my_podcasts', {
        'feedUrl': testFeedUrl,
        'collectionId': 12345,
        'collectionName': 'Podcast Test de Migration',
        'artistName': 'Artiste Test',
        'artworkUrl': 'https://example.com/artwork.jpg',
        'sortOrder': 4,
        'isSynced': 1,
      });

      const testEpisodeId = 'episode_123';
      await dbV1.insert('episodes_status', {
        'episodeId': testEpisodeId,
        'isRead': 1,
      });

      // Fermer proprement la base v1
      await dbV1.close();

      // 2. Ouvrir en v2 pour simuler l'écriture de métadonnées dans episodes_status (comme le faisait la v2)
      final dbV2 = await openDatabase(
        pathString,
        version: 2,
        onUpgrade: (db, oldV, newV) async {
          if (oldV < 2) {
            await db.execute(
                'ALTER TABLE episodes_status ADD COLUMN readAt INTEGER');
            await db
                .execute('ALTER TABLE episodes_status ADD COLUMN title TEXT');
            await db.execute(
                'ALTER TABLE episodes_status ADD COLUMN audioUrl TEXT');
            await db.execute(
                'ALTER TABLE episodes_status ADD COLUMN imageUrl TEXT');
            await db.execute(
                'ALTER TABLE episodes_status ADD COLUMN podcastName TEXT');
            await db
                .execute('ALTER TABLE episodes_status ADD COLUMN pubDate TEXT');
            await db.execute(
                'ALTER TABLE episodes_status ADD COLUMN description TEXT');
            await db.execute(
                'CREATE INDEX idx_episodes_status_readAt ON episodes_status(readAt)');
          }
        },
      );

      // Mettre à jour l'épisode avec des métadonnées v2
      await dbV2.update(
        'episodes_status',
        {
          'readAt': 1600000000000,
          'title': 'Mon Super Épisode',
          'audioUrl': 'https://example.com/audio.mp3',
          'imageUrl': 'https://example.com/episode.jpg',
          'podcastName': 'Podcast Test de Migration',
          'pubDate': '2026-06-11T12:00:00Z',
          'description': 'Description de l\'épisode de test',
        },
        where: 'episodeId = ?',
        whereArgs: [testEpisodeId],
      );

      // Fermer proprement la base v2
      await dbV2.close();

      // 3. Déclencher la migration vers v8 en ouvrant la base via DatabaseHelper
      final helper = DatabaseHelper();
      final migratedDb = await helper.database;

      // 4. Vérifications d'intégrité et de préservation des données

      // A. Table my_podcasts (Doit avoir 1 ligne, avec genres='' et UUID calculé)
      final podcasts = await migratedDb.query('my_podcasts');
      expect(podcasts.length, 1,
          reason: 'Le podcast abonné a été perdu pendant la migration');

      final pod = podcasts.first;
      expect(pod['feedUrl'], testFeedUrl);
      expect(pod['collectionName'], 'Podcast Test de Migration');

      // UUID MD5 déterministe généré en v4
      final bytes = utf8.encode(testFeedUrl);
      final expectedUuid = md5.convert(bytes).toString();
      final formattedUuid =
          '${expectedUuid.substring(0, 8)}-${expectedUuid.substring(8, 12)}-${expectedUuid.substring(12, 16)}-${expectedUuid.substring(16, 20)}-${expectedUuid.substring(20)}';
      expect(pod['id'], formattedUuid,
          reason: 'L\'UUID déterministe MD5 n\'a pas été généré correctement');
      expect(pod['genres'], '',
          reason: 'La colonne genres n\'a pas été créée ou initialisée à vide');

      // B. Table episodes_status & episodes_metadata (Doivent avoir 1 ligne avec les bonnes relations)
      final statusRows = await migratedDb.query('episodes_status');
      expect(statusRows.length, 1,
          reason:
              'Le statut de lecture de l\'épisode a été perdu pendant la migration');

      final status = statusRows.first;
      expect(status['episodeId'], testEpisodeId);
      expect(status['isRead'], 1);
      expect(status['readAt'], 1600000000000);
      expect(status['localPath'],
          isNull); // localPath ajouté en v3, non défini ici
      expect(status['status'], 0); // status ajouté en v6
      expect(status['fileSize'], 0); // fileSize ajouté en v7

      final metaRows = await migratedDb.query('episodes_metadata');
      expect(metaRows.length, 1,
          reason:
              'Les métadonnées de l\'épisode n\'ont pas été migrées vers episodes_metadata');

      final meta = metaRows.first;
      expect(meta['episodeId'], testEpisodeId);
      expect(meta['title'], 'Mon Super Épisode');
      expect(meta['audioUrl'], 'https://example.com/audio.mp3');
      expect(meta['imageUrl'], 'https://example.com/episode.jpg');
      expect(meta['podcastName'], 'Podcast Test de Migration');
      expect(meta['pubDate'], '2026-06-11T12:00:00Z');
      expect(meta['description'], 'Description de l\'épisode de test');

      // C. Vérification de la création des nouvelles tables de support
      final settingsCountResult = await migratedDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='settings'");
      expect(settingsCountResult.isNotEmpty, isTrue,
          reason: 'La table settings n\'a pas été créée');

      final downloadQueueCountResult = await migratedDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='download_queue'");
      expect(downloadQueueCountResult.isNotEmpty, isTrue,
          reason: 'La table download_queue n\'a pas été créée');

      final recsCountResult = await migratedDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='recommended_podcasts'");
      expect(recsCountResult.isNotEmpty, isTrue,
          reason: 'La table recommended_podcasts n\'a pas été créée');

      // D. Vérification de l'existence des index dans sqlite_master
      final indexCheck = await migratedDb.rawQuery(
          "SELECT name, tbl_name FROM sqlite_master WHERE type='index'");
      final indexNames =
          indexCheck.map((row) => row['name'] as String).toList();
      final indexTables =
          indexCheck.map((row) => row['tbl_name'] as String).toList();

      // Vérifier idx_podcasts_sortOrder sur my_podcasts
      final podcastsSortOrderIndexIdx =
          indexNames.indexOf('idx_podcasts_sortOrder');
      expect(podcastsSortOrderIndexIdx != -1, isTrue,
          reason: 'L\'index idx_podcasts_sortOrder a été perdu');
      expect(indexTables[podcastsSortOrderIndexIdx], 'my_podcasts');

      // Vérifier idx_episodes_status_readAt sur episodes_status
      final episodesReadAtIndexIdx =
          indexNames.indexOf('idx_episodes_status_readAt');
      expect(episodesReadAtIndexIdx != -1, isTrue,
          reason: 'L\'index idx_episodes_status_readAt a été perdu');
      expect(indexTables[episodesReadAtIndexIdx], 'episodes_status');

      // Vérifier idx_episodes_metadata_episodeId sur episodes_metadata
      final episodesMetaIndexIdx =
          indexNames.indexOf('idx_episodes_metadata_episodeId');
      expect(episodesMetaIndexIdx != -1, isTrue,
          reason: 'L\'index idx_episodes_metadata_episodeId n\'existe pas');
      expect(indexTables[episodesMetaIndexIdx], 'episodes_metadata');
    });
  });
}
