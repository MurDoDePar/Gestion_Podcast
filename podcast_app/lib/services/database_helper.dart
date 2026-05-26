import 'dart:async';
import 'package:flutter/foundation.dart';
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
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. my_podcasts Table: stores user subscriptions locally with order and sync flag
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

    // 2. episodes_status Table: stores read/unread status of episodes and metadata
    await db.execute('''
      CREATE TABLE episodes_status (
        episodeId TEXT PRIMARY KEY,
        isRead INTEGER DEFAULT 0,
        readAt INTEGER,
        title TEXT,
        audioUrl TEXT,
        imageUrl TEXT,
        podcastName TEXT,
        pubDate TEXT,
        description TEXT
      )
    ''');

    // Create index on episodes_status.readAt for fast history ordering
    await db.execute(
        'CREATE INDEX idx_episodes_status_readAt ON episodes_status(readAt)');

    // 3. themes_cache Table: caches weekly podcast results for themes
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
      } catch (e) {
        debugPrint(
            "AA_DEBUG: Erreur lors de la mise à jour des colonnes de episodes_status : $e");
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
    await db.insert(
      'episodes_status',
      {
        'episodeId': episodeId,
        'isRead': 1,
        'readAt': now,
        'title': title,
        'audioUrl': audioUrl,
        'imageUrl': imageUrl,
        'podcastName': podcastName,
        'pubDate': pubDate,
        'description': description,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
    debugPrint(
        "AA_DEBUG: themes_cache saved successfully for theme '$theme' with ${podcasts.length} items.");
  }
}
