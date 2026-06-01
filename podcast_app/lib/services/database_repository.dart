import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';
import '../dataconnect-generated/example.dart';
import '../core/services/service_locator.dart';
import '../core/services/auth_service.dart';
import '../core/services/podcast_sync_service.dart';
import '../models/episode_model.dart';
import '../models/podcast_model.dart';
import 'cache_manager.dart';
import 'podcast_repository.dart';
import 'database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'itunes_service.dart';
import 'audio_service.dart' as app_audio;
import 'rss_service.dart';

class UpdateRequiredException implements Exception {
  final String message;
  UpdateRequiredException(this.message);
  @override
  String toString() => message;
}

class DatabaseRepository {
  final CacheManager _cacheManager = CacheManager();
  static bool _isSyncing = false;
  static List<EpisodeModel>? _cachedEpisodesToListen;
  static bool debugSimulateSqliteFailure = false;
  static final Set<String> _attemptedRepairIds = {};
  Future<List<EpisodeModel>> getMyEpisodes() async {
    const String cacheKey = 'my_episodes';
    // 1. Vérifier le cache en mémoire pour éviter des requêtes inutiles
    if (_cacheManager.hasKey(cacheKey)) {
      final cachedData = _cacheManager.read(cacheKey);
      if (cachedData is List<EpisodeModel>) {
        return cachedData;
      }
    }
    // 2. Interroger la collection 'episodes' via syncService
    try {
      final episodes =
          await locator<PodcastSyncService>().fetchRemoteEpisodes();
      // 3. Mettre à jour le cache
      _cacheManager.write(cacheKey, episodes);
      return episodes;
    } catch (e) {
      // print('Erreur lors de la récupération des épisodes : $e');
      rethrow;
    }
  }

  Future<void> migrateFromPreferencesToSqlite() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Vérification double validation : Si la migration a déjà été validée et enregistrée, on ignore.
      final doneVersion = prefs.getInt('migration_done_version') ?? 0;
      if (doneVersion >= 1) {
        return;
      }
      final helper = DatabaseHelper();
      bool subscriptionsMigrationOk = true;
      bool readHistoryMigrationOk = true;
      // 1. Migration des abonnements (cache_my_podcasts)
      if (prefs.containsKey('cache_my_podcasts')) {
        final cachedStr = prefs.getString('cache_my_podcasts');
        if (cachedStr != null && cachedStr.isNotEmpty) {
          final List<dynamic> decoded = jsonDecode(cachedStr);
          final List<String> expectedFeedUrls = [];
          for (var item in decoded) {
            try {
              final podcastData = item['podcast'] as Map<String, dynamic>?;
              if (podcastData != null) {
                final feedUrl = podcastData['feedUrl']?.toString() ?? '';
                if (feedUrl.isNotEmpty) {
                  final podcast = PodcastModel(
                    collectionId:
                        int.tryParse(podcastData['id']?.toString() ?? ''),
                    collectionName:
                        podcastData['title']?.toString() ?? 'Sans titre',
                    artistName: podcastData['author']?.toString() ?? 'Inconnu',
                    artworkUrl: podcastData['imageUrl']?.toString() ?? '',
                    feedUrl: feedUrl,
                  );
                  final sortOrder = item['listOrder'] as int? ?? 0;
                  await helper.insertPodcast(podcast, sortOrder, isSynced: 1);
                  expectedFeedUrls.add(feedUrl);
                }
              }
            } catch (err) {
              subscriptionsMigrationOk = false;
            }
          }
          // Validation stricte post-migration pour les abonnements
          if (subscriptionsMigrationOk && expectedFeedUrls.isNotEmpty) {
            final sqliteSubs = await helper.getSubscribedPodcasts();
            final sqliteFeedUrls = sqliteSubs.map((p) => p.feedUrl).toSet();
            bool allFound = true;
            for (var expectedUrl in expectedFeedUrls) {
              if (!sqliteFeedUrls.contains(expectedUrl)) {
                allFound = false;
                break;
              }
            }
            if (allFound) {
              await prefs.remove('cache_my_podcasts');
            } else {
              subscriptionsMigrationOk = false;
            }
          } else if (expectedFeedUrls.isEmpty) {
            // Aucun abonnement à migrer, c'est OK
            await prefs.remove('cache_my_podcasts');
          }
        } else {
          await prefs.remove('cache_my_podcasts');
        }
      }
      // 2. Migration de l'historique de lecture (local_read_episodes)
      if (prefs.containsKey('local_read_episodes')) {
        final readList = prefs.getStringList('local_read_episodes');
        if (readList != null && readList.isNotEmpty) {
          // Charger le cache des épisodes pour tenter d'associer des métadonnées lors de la migration
          Map<String, EpisodeModel> cacheMap = {};
          if (prefs.containsKey('cache_episodes_to_listen')) {
            try {
              final cachedStr = prefs.getString('cache_episodes_to_listen');
              if (cachedStr != null && cachedStr.isNotEmpty) {
                final List<dynamic> decoded = jsonDecode(cachedStr);
                for (var item in decoded) {
                  final ep = EpisodeModel.fromMap(item as Map<String, dynamic>);
                  if (ep.id.isNotEmpty) cacheMap[ep.id] = ep;
                  if (ep.audioUrl.isNotEmpty) cacheMap[ep.audioUrl] = ep;
                }
              }
            } catch (_) {}
          }
          final List<String> expectedReadEpisodes = [];
          for (var epId in readList) {
            try {
              final isRead = await helper.isEpisodeRead(epId);
              if (!isRead) {
                final match = cacheMap[epId];
                await helper.markEpisodeAsRead(
                  epId,
                  title: match?.title,
                  audioUrl: match?.audioUrl,
                  imageUrl: match?.imageUrl,
                  podcastName: match?.podcastName,
                  pubDate: match?.pubDate?.toIso8601String(),
                  description: match?.description,
                );
              }
              expectedReadEpisodes.add(epId);
            } catch (err) {
              readHistoryMigrationOk = false;
            }
          }
          // Validation stricte post-migration pour l'historique de lecture
          if (readHistoryMigrationOk && expectedReadEpisodes.isNotEmpty) {
            bool allFound = true;
            for (var epId in expectedReadEpisodes) {
              final verifiedRead = await helper.isEpisodeRead(epId);
              if (!verifiedRead) {
                allFound = false;
                break;
              }
            }
            if (allFound) {
              await prefs.remove('local_read_episodes');
            } else {
              readHistoryMigrationOk = false;
            }
          } else if (expectedReadEpisodes.isEmpty) {
            await prefs.remove('local_read_episodes');
          }
        } else {
          await prefs.remove('local_read_episodes');
        }
      }
      // Si l'une des migrations a rencontré un problème d'intégrité, on ne marque pas comme totalement terminé pour permettre un retry.
      if (subscriptionsMigrationOk && readHistoryMigrationOk) {
        await prefs.setInt('migration_done_version', 1);
      } else {}
    } catch (e) {}
  }

  Future<void> _ensureUserExistsInPostgres(String googleId) async {
    try {
      final userResult = await ExampleConnector.instance
          .findUserByGoogleId(googleId: googleId)
          .execute();
      if (userResult.data.users.isEmpty) {
        final profile = locator<AuthService>().currentUserProfile;
        final displayName = profile?.displayName ?? 'Utilisateur';
        final email = profile?.email;
        final photoUrl = profile?.photoUrl;

        await ExampleConnector.instance
            .insertUser(
              googleId: googleId,
              displayName: displayName,
              createdAt:
                  Timestamp(DateTime.now().millisecondsSinceEpoch ~/ 1000, 0),
            )
            .email(email)
            .photoUrl(photoUrl)
            .execute();
      }
    } catch (e) {
      // Échec silencieux de la vérification de l'utilisateur
    }
  }

  Future<void> ensureInitialized() async {
    final userId = locator<AuthService>().currentUserId;
    if (userId == null) return;
    try {
      // S'assurer d'abord que l'utilisateur est inscrit dans Data Connect
      await _ensureUserExistsInPostgres(userId);

      final isEmpty = await DatabaseHelper().isTableEmpty('my_podcasts');
      if (isEmpty) {
        await initializeFromFirebase();
      }
    } catch (e) {
      // Échec silencieux de l'initialisation
    }
  }

  Future<void> checkRemoteVersionAndRequirements() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;
      await locator<PodcastSyncService>()
          .checkRemoteVersionRequirements(currentBuild);
    } on UpdateRequiredException {
      rethrow;
    }
  }

  Future<void> init() async {
    await checkRemoteVersionAndRequirements();
    await migrateFromPreferencesToSqlite();
    await ensureInitialized();
    await retryUnsyncedOrders();
  }

  Future<List<PodcastModel>> getMySubscribedPodcasts(
      {bool forceRefresh = false}) async {
    final userId = locator<AuthService>().currentUserId;
    if (userId == null) return [];
    if (forceRefresh) {
      // Force reload from Firebase to sync SQLite
      await _forceSyncFromFirebase();
    }
    // Lire depuis SQLite
    try {
      final podcasts = await DatabaseHelper().getSubscribedPodcasts();
      return podcasts;
    } catch (e) {
      return [];
    }
  }

  Future<List<PodcastModel>> getAffinityPodcasts() async {
    final userId = locator<AuthService>().currentUserId;
    if (userId == null) return [];
    const String cacheKey = 'affinity_podcasts_cache';
    final prefs = await SharedPreferences.getInstance();
    try {
      // 1. Récupérer les abonnements locaux (SQLite)
      final localSubs = await DatabaseHelper().getSubscribedPodcasts();
      final localFeedUrls = localSubs
          .map((p) => p.feedUrl)
          .where((url) => url.isNotEmpty)
          .toList();
      if (localFeedUrls.isEmpty) {
        return [];
      }
      final result = await locator<PodcastSyncService>()
          .fetchAffinityPodcasts(userId, localFeedUrls);
      // Sauvegarder dans le cache local (SharedPreferences) pour le support Offline-First
      final jsonList = result.map((p) => p.toMap()).toList();
      await prefs.setString(cacheKey, jsonEncode(jsonList));
      return result;
    } catch (e) {
      // Fallback hors-ligne : lire le dernier calcul depuis le cache local
      final cachedJson = prefs.getString(cacheKey);
      if (cachedJson != null) {
        try {
          final List<dynamic> decoded = jsonDecode(cachedJson);
          return decoded
              .map(
                  (item) => PodcastModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } catch (_) {}
      }
      return [];
    }
  }

  Future<void> initializeFromFirebase() async {
    final userId = locator<AuthService>().currentUserId;
    if (userId == null) return;
    try {
      final localSubs = await DatabaseHelper().getSubscribedPodcasts();
      if (localSubs.isNotEmpty) {
        // SQLite is not empty, migration already done or subscription exists
        return;
      }
      final syncService = locator<PodcastSyncService>();
      final List<PodcastModel> podcasts =
          await syncService.fetchRemoteSubscriptions(userId);
      // Save to SQLite
      for (int i = 0; i < podcasts.length; i++) {
        await DatabaseHelper().insertPodcast(podcasts[i], i, isSynced: 1);
      }
      // C. Synchroniser l'historique de lecture (episode_history) depuis Firestore vers SQLite
      try {
        final episodeIds = await syncService.fetchEpisodeHistory(userId);
        if (episodeIds.isNotEmpty) {
          final db = await DatabaseHelper().database;
          final now = DateTime.now().millisecondsSinceEpoch;
          await db.transaction((txn) async {
            for (var episodeId in episodeIds) {
              // Enregistrer dans la base SQLite locale sous la transaction txn
              await txn.insert(
                'episodes_status',
                {
                  'episodeId': episodeId,
                  'isRead': 1,
                  'readAt': now,
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          });
        } else {}
      } catch (e) {
        // Échec de la synchronisation de l'historique
      }
    } catch (e) {
      // Échec de l'initialisation depuis Firebase
    }
  }

  Future<void> _forceSyncFromFirebase() async {
    final userId = locator<AuthService>().currentUserId;
    if (userId == null) return;
    try {
      final syncService = locator<PodcastSyncService>();
      final List<PodcastModel> podcasts =
          await syncService.fetchRemoteSubscriptions(userId);
      if (podcasts.isNotEmpty) {
        // Enregistrer localement dans SQLite en conservant l'ordre
        for (int i = 0; i < podcasts.length; i++) {
          await DatabaseHelper().insertPodcast(podcasts[i], i, isSynced: 1);
        }
      }
    } catch (e) {}
  }

  Future<void> updatePodcastsOrder(List<PodcastModel> updatedList) async {
    final helper = DatabaseHelper();
    final db = await helper.database;
    // 1. Transaction SQLite locale pure
    try {
      await db.transaction((txn) async {
        for (int i = 0; i < updatedList.length; i++) {
          final podcast = updatedList[i];
          await txn.update(
            'my_podcasts',
            {'sortOrder': i},
            where: 'feedUrl = ?',
            whereArgs: [podcast.feedUrl],
          );
        }
      });
    } catch (e) {
      rethrow;
    }
    // 2. Mettre à jour le cache local en mémoire
    _cacheManager.write('my_subscribed_podcasts', updatedList);
    _refreshEpisodesToListen(); // Rafraîchir les épisodes à écouter
    // 3. Notifier immédiatement l'interface utilisateur
    try {
      app_audio.AudioService().listRefreshNotifier.value++;
    } catch (_) {}
  }

  Future<void> subscribeToPodcast(PodcastModel podcast) async {
    try {
      final helper = DatabaseHelper();
      final db = await helper.database;
      int sortOrder = 0;
      // 1. Transaction SQLite locale
      await db.transaction((txn) async {
        final List<Map<String, dynamic>> maps = await txn.query(
          'my_podcasts',
          columns: ['COUNT(*) as cnt'],
        );
        final count = maps.isNotEmpty ? maps.first['cnt'] as int : 0;
        sortOrder = count;
        await txn.insert(
          'my_podcasts',
          {
            'id': podcast.id,
            'feedUrl': podcast.feedUrl,
            'collectionId': podcast.collectionId,
            'collectionName': podcast.collectionName,
            'artistName': podcast.artistName,
            'artworkUrl': podcast.artworkUrl,
            'sortOrder': sortOrder,
            'isSynced': 0, // 0 = En attente de synchro
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });

      // 2. Mettre à jour le cache local en mémoire
      final cached = _cacheManager.read('my_subscribed_podcasts');
      if (cached is List<PodcastModel>) {
        cached.removeWhere((p) => p.feedUrl == podcast.feedUrl);
        cached.add(podcast);
        _cacheManager.write('my_subscribed_podcasts', cached);
      }

      // 3. Lancer la synchro asynchrone ("Fire and forget") vers Firebase/Data Connect
      _syncSubscribeToFirebase(podcast, sortOrder)
          .then((_) {})
          .catchError((err) {});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unsubscribeFromPodcast(String feedUrl) async {
    try {
      final helper = DatabaseHelper();
      final db = await helper.database;
      // 1. Transaction SQLite locale
      await db.transaction((txn) async {
        await txn.delete(
          'my_podcasts',
          where: 'feedUrl = ?',
          whereArgs: [feedUrl],
        );
      });

      // 2. Mettre à jour le cache local en mémoire
      final cached = _cacheManager.read('my_subscribed_podcasts');
      if (cached is List<PodcastModel>) {
        cached.removeWhere((p) => p.feedUrl == feedUrl);
        _cacheManager.write('my_subscribed_podcasts', cached);
      }
      // Déterminer l'ID distant de manière déterministe par rapport au feedUrl (aligné sur _getPodcastUuid)
      final bytes = utf8.encode(feedUrl);
      final digest = md5.convert(bytes);
      final rawId = digest.toString(); // 32 hex chars
      final String podcastId =
          '${rawId.substring(0, 8)}-${rawId.substring(8, 12)}-${rawId.substring(12, 16)}-${rawId.substring(16, 20)}-${rawId.substring(20, 32)}';
      await _addPendingDeletion(feedUrl, podcastId);

      // 3. Lancer la synchro asynchrone ("Fire and forget") vers Firebase/Data Connect
      _syncUnsubscribeFromFirebase(feedUrl, podcastId)
          .then((_) {})
          .catchError((err) {});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _addPendingDeletion(String feedUrl, String podcastId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentList = prefs.getStringList('pending_deletions') ?? [];
      final newItem = jsonEncode({'feedUrl': feedUrl, 'podcastId': podcastId});
      if (!currentList.contains(newItem)) {
        currentList.add(newItem);
        await prefs.setStringList('pending_deletions', currentList);
      }
    } catch (e) {}
  }

  Future<void> _removePendingDeletion(String feedUrl, String podcastId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentList = prefs.getStringList('pending_deletions') ?? [];
      currentList.removeWhere((item) {
        try {
          final decoded = jsonDecode(item);
          return decoded['feedUrl'] == feedUrl;
        } catch (_) {
          return false;
        }
      });
      await prefs.setStringList('pending_deletions', currentList);
    } catch (e) {}
  }

  Future<void> _syncSubscribeToFirebase(
      PodcastModel model, int orderIndex) async {
    final userId = locator<AuthService>().currentUserId;
    if (userId == null) return;
    await locator<PodcastSyncService>()
        .syncSubscribe(userId, model, orderIndex);
    // Marquer comme synchronisé dans SQLite
    await DatabaseHelper().setPodcastSyncStatus(model.feedUrl, 1);
  }

  Future<void> _syncUnsubscribeFromFirebase(
      String feedUrl, String podcastId) async {
    final userId = locator<AuthService>().currentUserId;
    if (userId == null) return;
    await locator<PodcastSyncService>()
        .syncUnsubscribe(userId, feedUrl, podcastId);
    // Retirer de la file d'attente locale
    await _removePendingDeletion(feedUrl, podcastId);
  }

  Future<void> retryUnsyncedOrders() async {
    if (_isSyncing) {
      return;
    }
    final userId = locator<AuthService>().currentUserId;
    if (userId == null) return;
    _isSyncing = true;
    try {
      // A. Traiter les désabonnements en attente
      final prefs = await SharedPreferences.getInstance();
      final pendingDeletions = prefs.getStringList('pending_deletions') ?? [];
      if (pendingDeletions.isNotEmpty) {
        final List<String> currentPendingList = List.from(pendingDeletions);
        for (var item in currentPendingList) {
          try {
            final decoded = jsonDecode(item);
            final feedUrl = decoded['feedUrl'] as String;
            final podcastId = decoded['podcastId'] as String;
            await _syncUnsubscribeFromFirebase(feedUrl, podcastId);
          } catch (e) {}
        }
      }
      // B. Traiter les abonnements non synchronisés (isSynced = 0)
      final unsynced = await DatabaseHelper().getUnsyncedPodcasts();
      if (unsynced.isNotEmpty) {
        for (var map in unsynced) {
          try {
            final podcast = PodcastModel(
              collectionId: map['collectionId'] as int?,
              collectionName: map['collectionName'] as String,
              artistName: map['artistName'] as String,
              artworkUrl: map['artworkUrl'] as String,
              feedUrl: map['feedUrl'] as String,
            );
            final sortOrder = map['sortOrder'] as int;
            await _syncSubscribeToFirebase(podcast, sortOrder);
          } catch (e) {}
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<Set<String>> getSubscribedPodcastIds(
      {bool forceRefresh = false}) async {
    try {
      final List<PodcastModel> subscribed =
          await getMySubscribedPodcasts(forceRefresh: forceRefresh);
      return subscribed
          .map((p) => p.feedUrl)
          .where((url) => url.isNotEmpty)
          .toSet();
    } catch (e) {
      // print('Erreur lors de la récupération des IDs des podcasts abonnés : $e');
      return <String>{};
    }
  }

  Future<List<EpisodeModel>> getEpisodesToListen(
      {bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    const String cacheKey = 'cache_episodes_to_listen';
    const String timeKey = 'cache_episodes_to_listen_time';
    List<EpisodeModel>? list;
    // Si on ne force pas le rafraîchissement, tenter de lire le cache
    if (!forceRefresh) {
      if (_cachedEpisodesToListen != null) {
        list = _cachedEpisodesToListen!;
      } else {
        final cachedJson = prefs.getString(cacheKey);
        if (cachedJson != null) {
          try {
            final List<dynamic> decoded = jsonDecode(cachedJson);
            list = decoded
                .map((item) =>
                    EpisodeModel.fromMap(item as Map<String, dynamic>))
                .toList();
            _cachedEpisodesToListen = list;
            // Vérification de la fraîcheur du cache
            final lastCachedTime = prefs.getInt(timeKey) ?? 0;
            final now = DateTime.now().millisecondsSinceEpoch;
            final cacheAgeMs = now - lastCachedTime;
            // Si le cache a plus de 24 heures (86400000 ms), on avertit
            if (cacheAgeMs > 24 * 60 * 60 * 1000) {}
          } catch (e) {}
        }
      }
    }
    if (list == null) {
      // Sinon, on effectue un rafraîchissement depuis le réseau
      try {
        final List<EpisodeModel> episodes =
            await PodcastRepository().fetchAllRecentEpisodes();
        // Enregistrer dans SharedPreferences
        final jsonList = episodes.map((e) => e.toMap()).toList();
        await prefs.setString(cacheKey, jsonEncode(jsonList));
        await prefs.setInt(timeKey, DateTime.now().millisecondsSinceEpoch);
        _cachedEpisodesToListen = episodes;
        list = episodes;
      } catch (e) {
        // Si la récupération en ligne échoue, fallback silencieux sur le cache local
        final cachedJson = prefs.getString(cacheKey);
        if (cachedJson != null) {
          try {
            final List<dynamic> decoded = jsonDecode(cachedJson);
            list = decoded
                .map((item) =>
                    EpisodeModel.fromMap(item as Map<String, dynamic>))
                .toList();
            _cachedEpisodesToListen = list;
          } catch (_) {}
        }
      }
    }
    // Filtrage dynamique strict avec SQLite local (isRead = 0)
    if (list != null) {
      try {
        final readIds = await DatabaseHelper().getReadEpisodeIds();
        final readIdsSet = readIds.toSet();
        final filtered = list.where((ep) {
          return !readIdsSet.contains(ep.id) &&
              !readIdsSet.contains(ep.audioUrl);
        }).toList();
        return filtered;
      } catch (e) {
        return list;
      }
    }
    return [];
  }

  Future<void> _refreshEpisodesToListen() async {
    _cachedEpisodesToListen = null;
    _cacheManager.remove('cache_episodes_to_listen');
    // Recharger immédiatement en tâche de fond pour reconstruire le cache
    // Cette opération asynchrone gère elle-même son exception/réseau sans bloquer l'UI
    try {
      await getEpisodesToListen(forceRefresh: true);
    } catch (e) {}
  }

  Future<void> markEpisodeAsRead(
    String episodeId, {
    String? title,
    String? audioUrl,
    String? imageUrl,
    String? podcastName,
    String? pubDate,
    String? description,
  }) async {
    // Essayer de retrouver l'épisode dans la mémoire cache pour extraire les métadonnées
    EpisodeModel? matchedEpisode;
    try {
      if (_cachedEpisodesToListen != null) {
        matchedEpisode = _cachedEpisodesToListen!.firstWhere(
          (e) => e.id == episodeId || e.audioUrl == episodeId,
        );
      }
    } catch (_) {}
    if (matchedEpisode == null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedJson = prefs.getString('cache_episodes_to_listen');
        if (cachedJson != null) {
          final List<dynamic> decoded = jsonDecode(cachedJson);
          final matchedMap = decoded.firstWhere(
            (item) {
              final id = item['id']?.toString() ?? '';
              final audioUrl = item['audioUrl']?.toString() ?? '';
              return id == episodeId || audioUrl == episodeId;
            },
            orElse: () => null,
          );
          if (matchedMap != null) {
            matchedEpisode =
                EpisodeModel.fromMap(matchedMap as Map<String, dynamic>);
          }
        }
      } catch (_) {}
    }
    final finalTitle = title ?? matchedEpisode?.title;
    final finalAudioUrl = audioUrl ?? matchedEpisode?.audioUrl;
    final finalImageUrl = imageUrl ?? matchedEpisode?.imageUrl;
    final finalPodcastName = podcastName ?? matchedEpisode?.podcastName;
    final finalPubDate = pubDate ?? matchedEpisode?.pubDate?.toIso8601String();
    final finalDescription = description ?? matchedEpisode?.description;
    // 1. Écriture locale immédiate et OBLIGATOIRE dans SQLite (table episodes_status)
    // C'est notre Source Unique de Vérité (SSOT) locale.
    // L'exécution locale est prioritaire et bloquante : si elle échoue, aucune autre action n'est entreprise.
    try {
      if (debugSimulateSqliteFailure) {
        throw Exception(
            "AA_DEBUG_TEST: Simulation d'une exception SQLite (erreur de table bloquée).");
      }
      await DatabaseHelper().markEpisodeAsRead(
        episodeId,
        title: finalTitle,
        audioUrl: finalAudioUrl,
        imageUrl: finalImageUrl,
        podcastName: finalPodcastName,
        pubDate: finalPubDate,
        description: finalDescription,
      );
      // Double validation immédiate dans SQLite : on vérifie que l'épisode a bien été marqué comme lu
      final verifyWrite = await DatabaseHelper().isEpisodeRead(episodeId);
      if (!verifyWrite) {
        throw Exception(
            "Validation post-écriture SQLite échouée : l'épisode n'a pas été marqué comme lu.");
      }
    } catch (e) {
      rethrow; // Arrête immédiatement l'exécution
    }
    // 2. Mettre à jour le cache local d'épisodes de manière atomique (opération extrêmement légère)
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('cache_episodes_to_listen');
      if (cachedJson != null) {
        final List<dynamic> decoded = jsonDecode(cachedJson);
        final initialLength = decoded.length;
        decoded.removeWhere((item) {
          final id = item['id']?.toString() ?? '';
          final audioUrl = item['audioUrl']?.toString() ?? '';
          return id == episodeId || audioUrl == episodeId;
        });
        if (decoded.length < initialLength) {
          await prefs.setString(
              'cache_episodes_to_listen', jsonEncode(decoded));
        }
      }
      // Mettre à jour le cache en mémoire aussi s'il existe
      if (_cacheManager.hasKey('cache_episodes_to_listen')) {
        final cachedData = _cacheManager.read('cache_episodes_to_listen');
        if (cachedData is List<EpisodeModel>) {
          cachedData
              .removeWhere((e) => e.id == episodeId || e.audioUrl == episodeId);
          _cacheManager.write('cache_episodes_to_listen', cachedData);
        }
      }
    } catch (e) {}
    // 3. Synchronisation distante asynchrone (Firestore & Data Connect) en arrière-plan
    final userId = locator<AuthService>().currentUserId;
    if (userId != null && !episodeId.startsWith('mock_')) {
      _syncEpisodeReadToFirebase(userId, episodeId).catchError((e) {});
    }
    // 4. Notifier l'UI via le listRefreshNotifier centralisé
    try {
      app_audio.AudioService().listRefreshNotifier.value++;
    } catch (e) {}
  }

  Future<void> _syncEpisodeReadToFirebase(String uid, String episodeId) async {
    try {
      await locator<PodcastSyncService>().syncEpisodeRead(uid, episodeId);
    } catch (e) {}
  }

  Future<List<PodcastModel>> getPodcastsByThemeWithCache(String theme) async {
    try {
      final cacheTime = await DatabaseHelper().getThemeCacheTime(theme);
      final now = DateTime.now().millisecondsSinceEpoch;
      // 7 jours en millisecondes = 7 * 24 * 60 * 60 * 1000 = 604 800 000
      const int sevenDaysMs = 7 * 24 * 60 * 60 * 1000;
      if (cacheTime != null && (now - cacheTime) < sevenDaysMs) {
        final cachedPodcasts = await DatabaseHelper().getThemeCache(theme);
        if (cachedPodcasts.isNotEmpty) {
          return cachedPodcasts;
        }
      }
      final freshPodcasts = await ItunesService().getPodcastsByTheme(theme);
      if (freshPodcasts.isNotEmpty) {
        // Enregistrer dans SQLite de manière transactionnelle
        await DatabaseHelper().saveThemeCache(theme, freshPodcasts);
      }
      return freshPodcasts;
    } catch (e) {
      // Fallback sur le cache si l'appel API échoue
      try {
        final cached = await DatabaseHelper().getThemeCache(theme);
        if (cached.isNotEmpty) {
          return cached;
        }
      } catch (_) {}
      return [];
    }
  }

  Future<List<EpisodeModel>> getReadEpisodesHistory(
      {int limit = 20, int offset = 0}) async {
    try {
      final db = await DatabaseHelper().database;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT 
          s.episodeId, 
          s.isRead, 
          s.readAt, 
          s.localPath,
          s.status,
          m.title, 
          m.audioUrl, 
          m.imageUrl, 
          m.podcastName, 
          m.pubDate, 
          m.description
        FROM episodes_status s
        LEFT JOIN episodes_metadata m ON s.episodeId = m.episodeId
        WHERE s.isRead = 1
        ORDER BY s.readAt DESC
        LIMIT ? OFFSET ?
      ''', [limit, offset]);
      final List<EpisodeModel> history = maps.map((map) {
        return EpisodeModel(
          id: map['episodeId'] as String,
          title: map['title'] as String? ?? 'Sans titre',
          audioUrl: map['audioUrl'] as String? ?? '',
          imageUrl: map['imageUrl'] as String? ?? '',
          podcastName: map['podcastName'] as String? ?? '',
          pubDate: map['pubDate'] != null
              ? DateTime.tryParse(map['pubDate'] as String) ?? DateTime.now()
              : DateTime.now(),
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
              !_attemptedRepairIds.contains(ep.id))
          .toList();
      if (brokenEpisodes.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final cachedJson = prefs.getString('cache_episodes_to_listen');
        Map<String, EpisodeModel> cacheMap = {};
        if (cachedJson != null) {
          try {
            final List<dynamic> decoded = jsonDecode(cachedJson);
            for (var item in decoded) {
              final ep = EpisodeModel.fromMap(item as Map<String, dynamic>);
              if (ep.id.isNotEmpty) cacheMap[ep.id] = ep;
              if (ep.audioUrl.isNotEmpty) cacheMap[ep.audioUrl] = ep;
            }
          } catch (_) {}
        }
        bool updatedAny = false;
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
                podcastName: ep.podcastName.isNotEmpty
                    ? ep.podcastName
                    : match.podcastName,
                pubDate: ep.pubDate,
                description: ep.description.isNotEmpty
                    ? ep.description
                    : match.description,
              );
            }
            // Sauvegarde locale SQLite
            await DatabaseHelper().markEpisodeAsRead(
              ep.id,
              title: match.title,
              audioUrl: ep.audioUrl.isNotEmpty ? ep.audioUrl : match.audioUrl,
              imageUrl: ep.imageUrl.isNotEmpty ? ep.imageUrl : match.imageUrl,
              podcastName: ep.podcastName.isNotEmpty
                  ? ep.podcastName
                  : match.podcastName,
              pubDate: ep.pubDate?.toIso8601String(),
              description: ep.description.isNotEmpty
                  ? ep.description
                  : match.description,
            );
            updatedAny = true;
            _attemptedRepairIds.add(ep.id);
          } else {
            remainingBroken.add(ep);
          }
        }
        if (updatedAny) {
          // Déclencher le rafraîchissement des listes
          app_audio.AudioService().listRefreshNotifier.value++;
        }
        // Si certains ne sont toujours pas réparés par le cache, lancer la tâche RSS en arrière-plan
        if (remainingBroken.isNotEmpty) {
          for (var ep in remainingBroken) {
            _attemptedRepairIds.add(ep.id);
          }
          _repairHistoryFromFeedsInBackground(remainingBroken);
        }
      }
      return history;
    } catch (e) {
      return [];
    }
  }

  void _repairHistoryFromFeedsInBackground(
      List<EpisodeModel> brokenHistory) async {
    try {
      final subscribed = await DatabaseHelper().getSubscribedPodcasts();
      if (subscribed.isEmpty) return;
      Map<String, EpisodeModel> feedEpisodes = {};
      final rssService = RssService();
      // Récupérer les épisodes des flux en parallèle sous timeout de 15 secondes
      final fetchFutures = subscribed.map((podcast) async {
        try {
          final eps = await rssService.getEpisodesFromFeed(podcast.feedUrl);
          for (var ep in eps) {
            if (ep.id.isNotEmpty) feedEpisodes[ep.id] = ep;
            if (ep.audioUrl.isNotEmpty) feedEpisodes[ep.audioUrl] = ep;
          }
        } catch (_) {}
      }).toList();
      await Future.wait(fetchFutures).timeout(const Duration(seconds: 15));
      bool updatedAny = false;
      for (var ep in brokenHistory) {
        if (ep.title == 'Sans titre' ||
            ep.title == 'Épisode sans titre' ||
            ep.imageUrl.isEmpty ||
            ep.podcastName.isEmpty) {
          final match = feedEpisodes[ep.id] ?? feedEpisodes[ep.audioUrl];
          if (match != null) {
            final finalTitle =
                (ep.title == 'Sans titre' || ep.title == 'Épisode sans titre')
                    ? match.title
                    : ep.title;
            final finalImageUrl =
                ep.imageUrl.isEmpty ? match.imageUrl : ep.imageUrl;
            final finalPodcastName =
                ep.podcastName.isEmpty ? match.podcastName : ep.podcastName;
            final finalDescription =
                ep.description.isEmpty ? match.description : ep.description;
            final finalAudioUrl =
                ep.audioUrl.isEmpty ? match.audioUrl : ep.audioUrl;
            await DatabaseHelper().markEpisodeAsRead(
              ep.id,
              title: finalTitle,
              audioUrl: finalAudioUrl,
              imageUrl: finalImageUrl,
              podcastName: finalPodcastName,
              pubDate: ep.pubDate?.toIso8601String(),
              description: finalDescription,
            );
            updatedAny = true;
          }
        }
      }
      if (updatedAny) {
        // Déclencher le rafraîchissement des listes
        app_audio.AudioService().listRefreshNotifier.value++;
      }
    } catch (e) {}
  }

  /// Méthode d'aide pour simuler les anciennes SharedPreferences (Tests Manuels Phase 1)
  Future<void> debugSeedSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Réinitialiser la clé de double validation pour permettre le test
      await prefs.remove('migration_done_version');
      // 1. Simuler un abonnement dans SharedPreferences (cache_my_podcasts)
      final mockSub = [
        {
          "listOrder": 0,
          "podcast": {
            "id": "mock_podcast_id_123",
            "title": "Mon Podcast de Test SharedPreferences",
            "author": "Développeur PodStream",
            "imageUrl":
                "https://images.unsplash.com/photo-1590602847861-f357a9332bbc",
            "feedUrl": "https://example.com/mock_podcast_feed.xml"
          }
        }
      ];
      await prefs.setString('cache_my_podcasts', jsonEncode(mockSub));
      // 2. Simuler l'historique de lecture (local_read_episodes)
      final mockHistory = ["mock_episode_id_aaa", "mock_episode_id_bbb"];
      await prefs.setStringList('local_read_episodes', mockHistory);
    } catch (e) {}
  }

  /// Compare le contenu de my_podcasts locale avec la collection subscriptions de Firebase
  Future<void> runSubscriptionsAudit() async {
    final userId = locator<AuthService>().currentUserId;
    if (userId == null) {
      // print("❌ Audit Impossible : Aucun utilisateur connecté.");
      return;
    }
    // print("--- 🩺 DÉBUT DE L'AUDIT DE COHÉRENCE DES ABONNEMENTS ---");
    // 1. Récupérer l'état SQLite
    final localList = await DatabaseHelper().getSubscribedPodcastsRaw();
    final Map<String, int> localMap = {
      for (var row in localList)
        row['feedUrl'] as String: row['sortOrder'] as int
    };
    // 2. Récupérer l'état Firestore via syncService
    final firestoreMap = await locator<PodcastSyncService>()
        .fetchRemoteSubscriptionOrders(userId);
    // 3. Analyse des écarts
    final localUrls = localMap.keys.toSet();
    final firestoreUrls = firestoreMap.keys.toSet();
    final missingLocally = firestoreUrls.difference(localUrls);
    final missingInFirestore = localUrls.difference(firestoreUrls);
    // print(
    // "📊 Statistiques : Local = ${localUrls.length} | Distant (Firestore) = ${firestoreUrls.length}");
    if (missingLocally.isNotEmpty) {
      // print("⚠️ Manquant localement (présent dans Firestore) :");
      // for (var url in missingLocally) {
      //   // print("   - $url");
      // }
    }
    if (missingInFirestore.isNotEmpty) {
      // print("⚠️ Manquant sur Firestore (présent en local) :");
      // for (var url in missingInFirestore) {
      //   // print(
      //   // "   - $url (isSynced = ${localList.firstWhere((r) => r['feedUrl'] == url)['isSynced']})");
      // }
    }
    // 4. Vérification du tri
    int orderMismatches = 0;
    for (var url in localUrls.intersection(firestoreUrls)) {
      if (localMap[url] != firestoreMap[url]) {
        // print(
        // "🔄 Désalignement du tri pour $url : Local = ${localMap[url]} | Firestore = ${firestoreMap[url]}");
        orderMismatches++;
      }
    }
    if (missingLocally.isEmpty &&
        missingInFirestore.isEmpty &&
        orderMismatches == 0) {
      // print("✅ Succès : SQLite et Firestore sont parfaitement synchronisés.");
    } else {
      // print("❌ Audit terminé : Des incohérences ont été détectées.");
    }
    // print("--- FIN DE L'AUDIT ---");
  }

  // --- SETTINGS OPERATIONS ---
  /// Récupère la politique réseau de téléchargement depuis SQLite
  Future<String> getDownloadNetworkPolicy() async {
    try {
      final helper = DatabaseHelper();
      final db = await helper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: ['download_network_policy'],
      );
      if (maps.isEmpty) return 'always';
      return maps.first['value'] as String? ?? 'always';
    } catch (e) {
      return 'always';
    }
  }

  /// Sauvegarde la politique réseau de téléchargement dans SQLite
  Future<void> setDownloadNetworkPolicy(String policy) async {
    try {
      final helper = DatabaseHelper();
      final db = await helper.database;
      await db.insert(
        'settings',
        {
          'key': 'download_network_policy',
          'value': policy,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {}
  }

  // --- LOCAL PATH operations & DOWNLOAD STATUS ---
  /// Met à jour le localPath et le statut d'un épisode dans SQLite
  Future<void> updateEpisodeLocalPath(
      String episodeId, String? localPath) async {
    try {
      final helper = DatabaseHelper();
      final db = await helper.database;
      final int status = localPath != null ? 1 : 0;

      // Convertir en chemin relatif au dossier de documents privé de l'app si possible
      String? relativePath;
      if (localPath != null) {
        final directory = await getApplicationDocumentsDirectory();
        final docDirPrefix = directory.path;
        if (localPath.startsWith(docDirPrefix)) {
          relativePath = localPath.substring(docDirPrefix.length);
          if (relativePath.startsWith('/') || relativePath.startsWith('\\')) {
            relativePath = relativePath.substring(1);
          }
        } else {
          relativePath = localPath;
        }
      }

      // On met à jour s'il existe déjà dans episodes_status
      final List<Map<String, dynamic>> existing = await db.query(
        'episodes_status',
        where: 'episodeId = ?',
        whereArgs: [episodeId],
      );
      if (existing.isNotEmpty) {
        await db.update(
          'episodes_status',
          {
            'localPath': relativePath,
            'status': status,
          },
          where: 'episodeId = ?',
          whereArgs: [episodeId],
        );
      } else {
        // Sinon on crée une entrée par défaut (non lu)
        await db.insert(
          'episodes_status',
          {
            'episodeId': episodeId,
            'localPath': relativePath,
            'isRead': 0,
            'readAt': null,
            'status': status,
          },
        );
      }
    } catch (e) {}
  }

  /// Met à jour uniquement le statut de téléchargement d'un épisode
  Future<void> updateEpisodeDownloadStatus(String episodeId, int status) async {
    try {
      final helper = DatabaseHelper();
      final db = await helper.database;
      final List<Map<String, dynamic>> existing = await db.query(
        'episodes_status',
        where: 'episodeId = ?',
        whereArgs: [episodeId],
      );
      if (existing.isNotEmpty) {
        await db.update(
          'episodes_status',
          {'status': status},
          where: 'episodeId = ?',
          whereArgs: [episodeId],
        );
      } else {
        await db.insert(
          'episodes_status',
          {
            'episodeId': episodeId,
            'isRead': 0,
            'readAt': null,
            'localPath': null,
            'status': status,
          },
        );
      }
    } catch (e) {}
  }

  /// Récupère le localPath d'un épisode depuis SQLite
  Future<String?> getEpisodeLocalPath(String episodeId) async {
    try {
      final helper = DatabaseHelper();
      final db = await helper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'episodes_status',
        columns: ['localPath'],
        where: 'episodeId = ?',
        whereArgs: [episodeId],
      );
      if (maps.isEmpty) return null;
      return maps.first['localPath'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Récupère le statut de téléchargement d'un épisode depuis SQLite
  Future<int> getEpisodeDownloadStatus(String episodeId) async {
    try {
      final helper = DatabaseHelper();
      final db = await helper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'episodes_status',
        columns: ['status'],
        where: 'episodeId = ?',
        whereArgs: [episodeId],
      );
      if (maps.isEmpty) return 0;
      return maps.first['status'] as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // --- DOWNLOAD QUEUE OPERATIONS ---
  /// Enregistre une tâche dans la file d'attente de téléchargement persistante
  Future<void> enqueueDownloadTask(
      String episodeId, String audioUrl, String tempPath) async {
    try {
      final helper = DatabaseHelper();
      final db = await helper.database;
      await db.insert(
        'download_queue',
        {
          'episodeId': episodeId,
          'audioUrl': audioUrl,
          'tempPath': tempPath,
          'status': 'queued',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {}
  }

  /// Supprime une tâche de la file d'attente de téléchargement persistante
  Future<void> dequeueDownloadTask(String episodeId) async {
    try {
      final helper = DatabaseHelper();
      final db = await helper.database;
      await db.delete(
        'download_queue',
        where: 'episodeId = ?',
        whereArgs: [episodeId],
      );
    } catch (e) {}
  }

  /// Récupère la liste des tâches de téléchargement persistantes
  Future<List<Map<String, dynamic>>> getDownloadQueueTasks() async {
    try {
      final helper = DatabaseHelper();
      final db = await helper.database;
      return await db.query('download_queue');
    } catch (e) {
      return [];
    }
  }
}
