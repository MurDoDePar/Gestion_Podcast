import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/podcast_model.dart';

class DatabaseHelper {
  // Singleton pattern
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final pathString = join(dbPath, 'podstream.db');
    return await openDatabase(
      pathString,
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // GUARD : Empêche toute réinitialisation si l'une de nos tables principales existe déjà
    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('my_podcasts', 'episodes_status')");
    if (tables.isNotEmpty) {
      return;
    }
    // 1. my_podcasts Table: stores user subscriptions locally with order and sync flag
    await db.execute('''
      CREATE TABLE my_podcasts (
        id TEXT PRIMARY KEY,
        feedUrl TEXT UNIQUE,
        collectionId INTEGER,
        collectionName TEXT,
        artistName TEXT,
        artworkUrl TEXT,
        sortOrder INTEGER,
        isSynced INTEGER DEFAULT 1
      )
    ''');
    // Create index on my_podcasts.sortOrder for fast sorting
    await db.execute(
        'CREATE INDEX idx_podcasts_sortOrder ON my_podcasts(sortOrder)');
    // 2. episodes_metadata Table: stores immutable details of episodes
    await db.execute('''
      CREATE TABLE episodes_metadata (
        episodeId TEXT PRIMARY KEY,
        title TEXT,
        audioUrl TEXT,
        imageUrl TEXT,
        podcastName TEXT,
        pubDate TEXT,
        description TEXT
      )
    ''');
    // Create index on episodes_metadata.episodeId for fast joining
    await db.execute(
        'CREATE INDEX idx_episodes_metadata_episodeId ON episodes_metadata(episodeId)');

    // 3. episodes_status Table: stores read/unread status of episodes and local path
    await db.execute('''
      CREATE TABLE episodes_status (
        episodeId TEXT PRIMARY KEY,
        isRead INTEGER DEFAULT 0,
        readAt INTEGER,
        localPath TEXT,
        status INTEGER DEFAULT 0
      )
    ''');
    // Create index on episodes_status.readAt for fast history ordering
    await db.execute(
        'CREATE INDEX idx_episodes_status_readAt ON episodes_status(readAt)');
    // 4. themes_cache Table: caches weekly podcast results for themes
    await db.execute('''
      CREATE TABLE themes_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        theme TEXT,
        collectionId INTEGER,
        collectionName TEXT,
        artistName TEXT,
        artworkUrl TEXT,
        feedUrl TEXT,
        cachedAt INTEGER
      )
    ''');
    // Create index on themes_cache.theme for fast queries
    await db
        .execute('CREATE INDEX idx_themes_cache_theme ON themes_cache(theme)');
    // 5. settings Table: stores local app settings
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
    // 6. download_queue Table: stores active/pending downloads for crash resumption
    await db.execute('''
      CREATE TABLE download_queue (
        episodeId TEXT PRIMARY KEY,
        audioUrl TEXT,
        tempPath TEXT,
        status TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db
            .execute('ALTER TABLE episodes_status ADD COLUMN readAt INTEGER');
        await db.execute('ALTER TABLE episodes_status ADD COLUMN title TEXT');
        await db
            .execute('ALTER TABLE episodes_status ADD COLUMN audioUrl TEXT');
        await db
            .execute('ALTER TABLE episodes_status ADD COLUMN imageUrl TEXT');
        await db
            .execute('ALTER TABLE episodes_status ADD COLUMN podcastName TEXT');
        await db.execute('ALTER TABLE episodes_status ADD COLUMN pubDate TEXT');
        await db
            .execute('ALTER TABLE episodes_status ADD COLUMN description TEXT');
        await db.execute(
            'CREATE INDEX idx_episodes_status_readAt ON episodes_status(readAt)');
      } catch (e) {}
    }
    if (oldVersion < 3) {
      try {
        await db
            .execute('ALTER TABLE episodes_status ADD COLUMN localPath TEXT');
      } catch (e) {}
      try {
        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
      } catch (e) {}
      try {
        await db.execute('''
          CREATE TABLE download_queue (
            episodeId TEXT PRIMARY KEY,
            audioUrl TEXT,
            tempPath TEXT,
            status TEXT
          )
        ''');
      } catch (e) {}
    }
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE my_podcasts RENAME TO my_podcasts_old');
        await db.execute('''
          CREATE TABLE my_podcasts (
            id TEXT PRIMARY KEY,
            feedUrl TEXT UNIQUE,
            collectionId INTEGER,
            collectionName TEXT,
            artistName TEXT,
            artworkUrl TEXT,
            sortOrder INTEGER,
            isSynced INTEGER DEFAULT 1
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_podcasts_sortOrder ON my_podcasts(sortOrder)');

        final List<Map<String, dynamic>> oldRows =
            await db.query('my_podcasts_old');
        for (var row in oldRows) {
          final feedUrl = row['feedUrl'] as String? ?? '';
          if (feedUrl.isNotEmpty) {
            final bytes = utf8.encode(feedUrl);
            final digest = md5.convert(bytes).toString();
            final uuid =
                '${digest.substring(0, 8)}-${digest.substring(8, 12)}-${digest.substring(12, 16)}-${digest.substring(16, 20)}-${digest.substring(20)}';

            await db.insert('my_podcasts', {
              'id': uuid,
              'feedUrl': feedUrl,
              'collectionId': row['collectionId'],
              'collectionName': row['collectionName'],
              'artistName': row['artistName'],
              'artworkUrl': row['artworkUrl'],
              'sortOrder': row['sortOrder'],
              'isSynced': row['isSynced'] ?? 1,
            });
          }
        }
        await db.execute('DROP TABLE my_podcasts_old');
      } catch (e) {
        // print("Erreur de migration SQLite v4 : $e");
        rethrow;
      }
    }
    if (oldVersion < 5) {
      try {
        // 1. Créer la table episodes_metadata
        await db.execute('''
          CREATE TABLE episodes_metadata (
            episodeId TEXT PRIMARY KEY,
            title TEXT,
            audioUrl TEXT,
            imageUrl TEXT,
            podcastName TEXT,
            pubDate TEXT,
            description TEXT
          )
        ''');
        // Créer l'index sur episodes_metadata.episodeId
        await db.execute(
            'CREATE INDEX idx_episodes_metadata_episodeId ON episodes_metadata(episodeId)');

        // 2. Extraire et copier les métadonnées existantes de episodes_status vers episodes_metadata
        final List<Map<String, dynamic>> oldRows = await db.query(
          'episodes_status',
          columns: [
            'episodeId',
            'title',
            'audioUrl',
            'imageUrl',
            'podcastName',
            'pubDate',
            'description'
          ],
        );
        final Set<String> insertedIds = {};
        for (var row in oldRows) {
          final episodeId = row['episodeId'] as String? ?? '';
          if (episodeId.isNotEmpty && !insertedIds.contains(episodeId)) {
            await db.insert(
                'episodes_metadata',
                {
                  'episodeId': episodeId,
                  'title': row['title'],
                  'audioUrl': row['audioUrl'],
                  'imageUrl': row['imageUrl'],
                  'podcastName': row['podcastName'],
                  'pubDate': row['pubDate'],
                  'description': row['description'],
                },
                conflictAlgorithm: ConflictAlgorithm.ignore);
            insertedIds.add(episodeId);
          }
        }

        // 3. Renommer episodes_status en episodes_status_old
        await db.execute(
            'ALTER TABLE episodes_status RENAME TO episodes_status_old');

        // 4. Créer la nouvelle table episodes_status allégée
        await db.execute('''
          CREATE TABLE episodes_status (
            episodeId TEXT PRIMARY KEY,
            isRead INTEGER DEFAULT 0,
            readAt INTEGER,
            localPath TEXT
          )
        ''');
        // Recréer l'index sur readAt
        await db.execute(
            'CREATE INDEX idx_episodes_status_readAt ON episodes_status(readAt)');

        // 5. Copier les données de comportement depuis la table temporaire
        final List<Map<String, dynamic>> oldStatusRows =
            await db.query('episodes_status_old');
        for (var row in oldStatusRows) {
          final episodeId = row['episodeId'] as String? ?? '';
          if (episodeId.isNotEmpty) {
            await db.insert(
                'episodes_status',
                {
                  'episodeId': episodeId,
                  'isRead': row['isRead'] ?? 0,
                  'readAt': row['readAt'],
                  'localPath': row['localPath'],
                },
                conflictAlgorithm: ConflictAlgorithm.ignore);
          }
        }

        // 6. Supprimer la table temporaire
        await db.execute('DROP TABLE episodes_status_old');
      } catch (e) {
        // print("Erreur de migration SQLite v5 : $e");
        rethrow;
      }
    }
    if (oldVersion < 6) {
      try {
        await db.execute(
            'ALTER TABLE episodes_status ADD COLUMN status INTEGER DEFAULT 0');
      } catch (e) {
        // print("Erreur de migration SQLite v6 : $e");
        rethrow;
      }
    }
  }

  Future<bool> isTableEmpty(String tableName) async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableName'),
    );
    return count == 0;
  }

  // --- MY PODCASTS OPERATIONS ---
  Future<List<PodcastModel>> getSubscribedPodcasts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'my_podcasts',
      orderBy: 'sortOrder ASC',
    );
    return List.generate(maps.length, (i) {
      return PodcastModel(
        collectionId: maps[i]['collectionId'] as int?,
        collectionName: maps[i]['collectionName'] as String,
        artistName: maps[i]['artistName'] as String,
        artworkUrl: maps[i]['artworkUrl'] as String,
        feedUrl: maps[i]['feedUrl'] as String,
      );
    });
  }

  Future<List<Map<String, dynamic>>> getSubscribedPodcastsRaw() async {
    final db = await database;
    return await db.query('my_podcasts', orderBy: 'sortOrder ASC');
  }

  Future<int> insertPodcast(PodcastModel podcast, int sortOrder,
      {int isSynced = 1}) async {
    final db = await database;
    return await db.insert(
      'my_podcasts',
      {
        'id': podcast.id,
        'feedUrl': podcast.feedUrl,
        'collectionId': podcast.collectionId,
        'collectionName': podcast.collectionName,
        'artistName': podcast.artistName,
        'artworkUrl': podcast.artworkUrl,
        'sortOrder': sortOrder,
        'isSynced': isSynced,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deletePodcast(String feedUrl) async {
    final db = await database;
    return await db.delete(
      'my_podcasts',
      where: 'feedUrl = ?',
      whereArgs: [feedUrl],
    );
  }

  Future<void> updatePodcastsSortOrder(
      List<Map<String, dynamic>> orderUpdates) async {
    final db = await database;
    await db.transaction((txn) async {
      for (var update in orderUpdates) {
        final feedUrl = update['feedUrl'] as String;
        final sortOrder = update['sortOrder'] as int;
        final isSynced = update['isSynced'] as int? ?? 0;
        await txn.update(
          'my_podcasts',
          {'sortOrder': sortOrder, 'isSynced': isSynced},
          where: 'feedUrl = ?',
          whereArgs: [feedUrl],
        );
      }
    });
  }

  Future<void> setPodcastSyncStatus(String feedUrl, int isSynced) async {
    final db = await database;
    await db.update(
      'my_podcasts',
      {'isSynced': isSynced},
      where: 'feedUrl = ?',
      whereArgs: [feedUrl],
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedPodcasts() async {
    final db = await database;
    return await db.query(
      'my_podcasts',
      where: 'isSynced = ?',
      whereArgs: [0],
    );
  }

  // --- EPISODES STATUS OPERATIONS ---
  Future<void> markEpisodeAsRead(
    String episodeId, {
    String? title,
    String? audioUrl,
    String? imageUrl,
    String? podcastName,
    String? pubDate,
    String? description,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      // 1. Gérer les métadonnées dans la table episodes_metadata
      final List<Map<String, dynamic>> existingMeta = await txn.query(
        'episodes_metadata',
        where: 'episodeId = ?',
        whereArgs: [episodeId],
      );

      String? finalTitle = title;
      String? finalAudioUrl = audioUrl;
      String? finalImageUrl = imageUrl;
      String? finalPodcastName = podcastName;
      String? finalPubDate = pubDate;
      String? finalDescription = description;

      if (existingMeta.isNotEmpty) {
        final row = existingMeta.first;
        if (finalTitle == null || finalTitle.isEmpty) {
          finalTitle = row['title'] as String?;
        }
        if (finalAudioUrl == null || finalAudioUrl.isEmpty) {
          finalAudioUrl = row['audioUrl'] as String?;
        }
        if (finalImageUrl == null || finalImageUrl.isEmpty) {
          finalImageUrl = row['imageUrl'] as String?;
        }
        if (finalPodcastName == null || finalPodcastName.isEmpty) {
          finalPodcastName = row['podcastName'] as String?;
        }
        if (finalPubDate == null || finalPubDate.isEmpty) {
          finalPubDate = row['pubDate'] as String?;
        }
        if (finalDescription == null || finalDescription.isEmpty) {
          finalDescription = row['description'] as String?;
        }
      }

      await txn.insert(
        'episodes_metadata',
        {
          'episodeId': episodeId,
          'title': finalTitle,
          'audioUrl': finalAudioUrl,
          'imageUrl': finalImageUrl,
          'podcastName': finalPodcastName,
          'pubDate': finalPubDate,
          'description': finalDescription,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Gérer le statut dans la table episodes_status
      final List<Map<String, dynamic>> existingStatus = await txn.query(
        'episodes_status',
        where: 'episodeId = ?',
        whereArgs: [episodeId],
      );

      if (existingStatus.isNotEmpty) {
        await txn.update(
          'episodes_status',
          {
            'isRead': 1,
            'readAt': now,
          },
          where: 'episodeId = ?',
          whereArgs: [episodeId],
        );
      } else {
        await txn.insert(
          'episodes_status',
          {
            'episodeId': episodeId,
            'isRead': 1,
            'readAt': now,
            'localPath': null,
            'status': 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<bool> isEpisodeRead(String episodeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'episodes_status',
      columns: ['isRead'],
      where: 'episodeId = ?',
      whereArgs: [episodeId],
    );
    if (maps.isEmpty) return false;
    return maps.first['isRead'] == 1;
  }

  Future<List<String>> getReadEpisodeIds() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'episodes_status',
      columns: ['episodeId'],
      where: 'isRead = ?',
      whereArgs: [1],
    );
    return maps.map((m) => m['episodeId'] as String).toList();
  }

  // --- THEMES CACHE OPERATIONS ---
  Future<List<PodcastModel>> getThemeCache(String theme) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'themes_cache',
      where: 'theme = ?',
      whereArgs: [theme],
    );
    return List.generate(maps.length, (i) {
      return PodcastModel(
        collectionId: maps[i]['collectionId'] as int?,
        collectionName: maps[i]['collectionName'] as String,
        artistName: maps[i]['artistName'] as String,
        artworkUrl: maps[i]['artworkUrl'] as String,
        feedUrl: maps[i]['feedUrl'] as String,
      );
    });
  }

  Future<int?> getThemeCacheTime(String theme) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'themes_cache',
      columns: ['cachedAt'],
      where: 'theme = ?',
      whereArgs: [theme],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first['cachedAt'] as int?;
  }

  Future<void> saveThemeCache(String theme, List<PodcastModel> podcasts) async {
    final db = await database;
    final cachedAt = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      // Clear old entries
      await txn.delete(
        'themes_cache',
        where: 'theme = ?',
        whereArgs: [theme],
      );
      // Insert new entries atomically
      for (var p in podcasts) {
        await txn.insert(
          'themes_cache',
          {
            'theme': theme,
            'collectionId': p.collectionId,
            'collectionName': p.collectionName,
            'artistName': p.artistName,
            'artworkUrl': p.artworkUrl,
            'feedUrl': p.feedUrl,
            'cachedAt': cachedAt,
          },
        );
      }
    });
  }
}
