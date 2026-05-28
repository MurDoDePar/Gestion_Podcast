import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Timestamp;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../dataconnect-generated/example.dart';
import '../models/episode_model.dart';
import '../models/podcast_model.dart';
import 'cache_manager.dart';
import 'podcast_repository.dart';
import 'database_helper.dart';
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

  Future<List<EpisodeModel>> getMyEpisodes() async {
    const String cacheKey = 'my_episodes';

    // 1. Vérifier le cache en mémoire pour éviter des requêtes inutiles
    if (_cacheManager.hasKey(cacheKey)) {
      final cachedData = _cacheManager.read(cacheKey);
      if (cachedData is List<EpisodeModel>) {
        return cachedData;
      }
    }

    // 2. Interroger la collection 'episodes' dans Cloud Firestore
    try {
      final QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('episodes').get();

      final List<EpisodeModel> episodes = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return EpisodeModel.fromMap(data, documentId: doc.id);
      }).toList();

      // 3. Mettre à jour le cache
      _cacheManager.write(cacheKey, episodes);

      return episodes;
    } catch (e) {
      print(
          'Erreur lors de la récupération des épisodes depuis Firestore : $e');
      rethrow;
    }
  }

  Future<void> migrateFromPreferencesToSqlite() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Vérification double validation : Si la migration a déjà été validée et enregistrée, on ignore.
      final doneVersion = prefs.getInt('migration_done_version') ?? 0;
      if (doneVersion >= 1) {
        print(
            'AA_DEBUG: Migration des préférences déjà effectuée (version $doneVersion). Passage.');
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
              print(
                  'AA_DEBUG: Erreur lors de la migration d\'un abonnement pref : $err');
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
                print(
                    'AA_DEBUG: Validation Échouée - Flux abonnement absent de SQLite: $expectedUrl');
                break;
              }
            }

            if (allFound) {
              print(
                  'AA_DEBUG: Migration et validation des abonnements réussies (${expectedFeedUrls.length} abonnements vérifiés). Nettoyage SharedPreferences.');
              await prefs.remove('cache_my_podcasts');
            } else {
              subscriptionsMigrationOk = false;
              print(
                  'AA_DEBUG: ERREUR CRITIQUE - Échec de validation d\'intégrité des abonnements insérés.');
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
          final List<String> expectedReadEpisodes = [];
          for (var epId in readList) {
            try {
              final isRead = await helper.isEpisodeRead(epId);
              if (!isRead) {
                await helper.markEpisodeAsRead(epId);
              }
              expectedReadEpisodes.add(epId);
            } catch (err) {
              print(
                  'AA_DEBUG: Erreur lors de la migration d\'un statut de lecture pref : $err');
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
                print(
                    'AA_DEBUG: Validation Échouée - Épisode non marqué comme lu dans SQLite: $epId');
                break;
              }
            }

            if (allFound) {
              print(
                  'AA_DEBUG: Migration et validation de l\'historique réussies (${expectedReadEpisodes.length} épisodes vérifiés). Nettoyage SharedPreferences.');
              await prefs.remove('local_read_episodes');
            } else {
              readHistoryMigrationOk = false;
              print(
                  'AA_DEBUG: ERREUR CRITIQUE - Échec de validation d\'intégrité de l\'historique de lecture.');
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
        print(
            'AA_DEBUG: Migration SharedPreferences -> SQLite validée globalement et enregistrée.');
      } else {
        print(
            'AA_DEBUG: ATTENTION - Une ou plusieurs étapes de migration ont échoué la validation. La migration globale sera retentée au prochain lancement.');
      }
    } catch (e) {
      print(
          'AA_DEBUG: Erreur globale lors de la migration SharedPreferences -> SQLite : $e');
    }
  }

  Future<void> ensureInitialized() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final isEmpty = await DatabaseHelper().isTableEmpty('my_podcasts');
      if (isEmpty) {
        print(
            'AA_DEBUG: SQLite vide, lancement de la migration silencieuse...');
        await initializeFromFirebase();
      }
    } catch (e) {
      print('AA_DEBUG: Erreur dans ensureInitialized: $e');
    }
  }

  Future<void> checkRemoteVersionAndRequirements() async {
    try {
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

      // Récupérer le build number actuel de l'application
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      if (killSwitchActive || currentBuild < minSupportedBuild) {
        final errorMsg = messages?['fr'] ??
            "Une mise à jour importante est requise pour continuer à utiliser PodStream.";
        throw UpdateRequiredException(errorMsg);
      }
    } on UpdateRequiredException {
      rethrow;
    } catch (e) {
      // En cas de problème réseau temporaire ou d'indisponibilité de Firestore,
      // on tolère le démarrage en mode dégradé (Offline-First) plutôt que de bloquer l'utilisateur.
      print(
          "AA_DEBUG: Impossible de vérifier la version distante : $e. Mode hors-ligne actif.");
    }
  }

  Future<void> init() async {
    await checkRemoteVersionAndRequirements();
    await migrateFromPreferencesToSqlite();
    await ensureInitialized();
    await _cleanObsoletePopularCache();
    await retryUnsyncedOrders();
  }

  Future<void> _cleanObsoletePopularCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadyCleaned = prefs.getBool('popular_cache_cleaned_v2') ?? false;
      if (!alreadyCleaned) {
        final languages = ['fr', 'en', 'es', 'de', 'all'];
        for (var lang in languages) {
          final cacheKey = 'popular_$lang';
          try {
            await ExampleConnector.instance
                .upsertAppCache(
                  id: cacheKey,
                  data: AnyValue('[]'),
                  updatedAt: Timestamp(0, 0),
                )
                .execute();
            debugPrint(
                "AA_DEBUG: cleaned DataConnect cache for key: $cacheKey");
          } catch (e) {
            debugPrint("AA_DEBUG: error cleaning cache key $cacheKey: $e");
          }
        }
        await prefs.setBool('popular_cache_cleaned_v2', true);
      }
    } catch (e) {
      debugPrint("Erreur cleanObsoletePopularCache: $e");
    }
  }

  Future<List<PodcastModel>> getMySubscribedPodcasts(
      {bool forceRefresh = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    if (forceRefresh) {
      // Force reload from Firebase to sync SQLite
      await _forceSyncFromFirebase();
    }

    // Lire depuis SQLite
    try {
      final podcasts = await DatabaseHelper().getSubscribedPodcasts();
      return podcasts;
    } catch (e) {
      print('AA_DEBUG: Erreur lors de la récupération des podcasts locaux: $e');
      return [];
    }
  }

  Future<List<PodcastModel>> getAffinityPodcasts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    const String cacheKey = 'affinity_podcasts_cache';
    final prefs = await SharedPreferences.getInstance();

    try {
      // 1. Récupérer les abonnements locaux (SQLite)
      final localSubs = await DatabaseHelper().getSubscribedPodcasts();
      final localFeedUrls = localSubs
          .map((p) => p.feedUrl)
          .where((url) => url.isNotEmpty)
          .toSet();

      if (localFeedUrls.isEmpty) {
        return [];
      }

      // 2. Trouver les utilisateurs ayant au moins un podcast en commun
      // Firestore 'whereIn' est limité à 30 éléments max. On découpe notre liste.
      final List<String> localFeedUrlsList = localFeedUrls.toList();
      final List<List<String>> chunks = [];
      for (var i = 0; i < localFeedUrlsList.length; i += 30) {
        chunks.add(localFeedUrlsList.sublist(
          i,
          i + 30 > localFeedUrlsList.length ? localFeedUrlsList.length : i + 30,
        ));
      }

      final Map<String, int> peerOverlapCounts =
          {}; // peerUserId -> overlap count

      // Effectuer les requêtes de recherche de pairs en parallèle
      final List<Future<QuerySnapshot>> peerQueries = chunks.map((chunk) {
        return FirebaseFirestore.instance
            .collection('subscriptions')
            .where('feedUrl', whereIn: chunk)
            .get();
      }).toList();

      final List<QuerySnapshot> peerSnapshots = await Future.wait(peerQueries);

      for (var snapshot in peerSnapshots) {
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final peerId = data['userId'] as String?;
          if (peerId != null && peerId != user.uid) {
            peerOverlapCounts[peerId] = (peerOverlapCounts[peerId] ?? 0) + 1;
          }
        }
      }

      if (peerOverlapCounts.isEmpty) {
        return [];
      }

      // Trier les pairs par score d'affinité décroissant et garder le top 10 pour limiter les lectures
      final sortedPeers = peerOverlapCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topPeers = sortedPeers.take(10).map((e) => e.key).toList();

      // 3. Récupérer tous les abonnements de ces pairs en parallèle
      final List<Future<QuerySnapshot>> peerSubsQueries =
          topPeers.map((peerId) {
        return FirebaseFirestore.instance
            .collection('subscriptions')
            .where('userId', isEqualTo: peerId)
            .get();
      }).toList();

      final List<QuerySnapshot> peerSubsSnapshots =
          await Future.wait(peerSubsQueries);

      final Map<String, PodcastModel> recommendedPodcasts = {};
      final Map<String, double> recommendedScores =
          {}; // feedUrl -> score cumulé

      for (int i = 0; i < topPeers.length; i++) {
        final peerId = topPeers[i];
        final peerAffinityWeight = peerOverlapCounts[peerId] ?? 1;
        final snapshot = peerSubsSnapshots[i];

        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final feedUrl = data['feedUrl'] as String?;
          if (feedUrl == null || feedUrl.isEmpty) continue;

          // Exclure les podcasts déjà possédés par l'utilisateur connecté
          if (localFeedUrls.contains(feedUrl)) continue;

          // Si pas encore recommandé, extraire les métadonnées
          if (!recommendedPodcasts.containsKey(feedUrl)) {
            recommendedPodcasts[feedUrl] = PodcastModel(
              collectionName:
                  data['collectionName']?.toString() ?? 'Sans titre',
              artistName: data['artistName']?.toString() ?? 'Artiste inconnu',
              artworkUrl: data['artworkUrl600']?.toString() ??
                  data['artworkUrl100']?.toString() ??
                  '',
              feedUrl: feedUrl,
              collectionId: data['collectionId'] is int?
                  ? data['collectionId'] as int?
                  : int.tryParse(data['collectionId']?.toString() ?? ''),
            );
          }

          // Accumuler le score : plus le pair a d'affinité, plus son avis pèse
          recommendedScores[feedUrl] =
              (recommendedScores[feedUrl] ?? 0) + peerAffinityWeight;
        }
      }

      // 4. Classer les recommandations par score d'affinité décroissant
      final sortedRecommendations = recommendedScores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final List<PodcastModel> result = sortedRecommendations
          .map((entry) => recommendedPodcasts[entry.key]!)
          .toList();

      // Sauvegarder dans le cache local (SharedPreferences) pour le support Offline-First
      final jsonList = result.map((p) => p.toMap()).toList();
      await prefs.setString(cacheKey, jsonEncode(jsonList));

      return result;
    } catch (e) {
      print(
          "AA_DEBUG: Erreur dans getAffinityPodcasts, chargement du cache : $e");

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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final localSubs = await DatabaseHelper().getSubscribedPodcasts();
      if (localSubs.isNotEmpty) {
        // SQLite is not empty, migration already done or subscription exists
        return;
      }

      print('AA_DEBUG: Initialisation de SQLite à partir de Firebase...');
      List<PodcastModel> podcasts = [];

      // A. Essayer Data Connect
      try {
        final userResult = await ExampleConnector.instance
            .findUserByGoogleId(googleId: user.uid)
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
      } catch (e) {
        print(
            "AA_DEBUG: Migration DataConnect failed, falling back to Firestore: $e");
      }

      // B. Essayer Firestore
      if (podcasts.isEmpty) {
        final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('subscriptions')
            .where('userId', isEqualTo: user.uid)
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

      // Save to SQLite
      for (int i = 0; i < podcasts.length; i++) {
        await DatabaseHelper().insertPodcast(podcasts[i], i, isSynced: 1);
      }
      print(
          'AA_DEBUG: Migration depuis Firebase complétée. ${podcasts.length} podcasts insérés dans SQLite.');
    } catch (e) {
      print('AA_DEBUG: Erreur lors de initializeFromFirebase: $e');
    }
  }

  Future<void> _forceSyncFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      print("AA_DEBUG: Force sync from Firebase...");
      List<PodcastModel> podcasts = [];
      // Fetch from Data Connect
      try {
        final userResult = await ExampleConnector.instance
            .findUserByGoogleId(googleId: user.uid)
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
      } catch (e) {
        print("AA_DEBUG: _forceSyncFromFirebase DataConnect failed: $e");
      }

      // Fetch from Firestore fallback
      if (podcasts.isEmpty) {
        final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('subscriptions')
            .where('userId', isEqualTo: user.uid)
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

      if (podcasts.isNotEmpty) {
        // Enregistrer localement dans SQLite en conservant l'ordre
        for (int i = 0; i < podcasts.length; i++) {
          await DatabaseHelper().insertPodcast(podcasts[i], i, isSynced: 1);
        }
      }
    } catch (e) {
      print("AA_DEBUG: Force sync failed: $e");
    }
  }

  Future<void> updatePodcastsOrder(List<PodcastModel> updatedList) async {
    try {
      print(
          "AA_DEBUG: updatePodcastsOrder appelé pour réordonner ${updatedList.length} podcasts.");

      // 1. Mettre à jour l'ordre dans SQLite
      final List<Map<String, dynamic>> orderUpdates = [];
      for (int i = 0; i < updatedList.length; i++) {
        orderUpdates.add({
          'feedUrl': updatedList[i].feedUrl,
          'sortOrder': i,
          'isSynced': 0, // Non synchronisé
        });
      }
      await DatabaseHelper().updatePodcastsSortOrder(orderUpdates);
      print("AA_DEBUG: Ordre mis à jour en local dans SQLite.");

      // Mettre à jour le cache local en mémoire
      _cacheManager.write('my_subscribed_podcasts', updatedList);

      // 2. Vider le cache mémoire et persistant et rafraîchir la file
      _refreshEpisodesToListen().then((_) {
        // 5. Assurer que l'UI est notifiée du changement via AudioService().listRefreshNotifier
        try {
          app_audio.AudioService().listRefreshNotifier.value++;
          print(
              "AA_DEBUG: UI notifiée de la reconstruction de la file d'attente.");
        } catch (e) {
          print(
              "AA_DEBUG: Impossible de notifier listRefreshNotifier dans updatePodcastsOrder: $e");
        }
      });

      // 4. Déclencher la synchronisation vers Firebase en tâche de fond
      retryUnsyncedOrders();
    } catch (e) {
      print('Erreur lors de la mise à jour de l\'ordre des podcasts : $e');
    }
  }

  Future<void> subscribeToPodcast(PodcastModel podcast) async {
    try {
      final currentSubs = await DatabaseHelper().getSubscribedPodcasts();
      final sortOrder = currentSubs.length;
      await DatabaseHelper().insertPodcast(podcast, sortOrder, isSynced: 0);

      // Mettre à jour le cache local en mémoire
      final cached = _cacheManager.read('my_subscribed_podcasts');
      if (cached is List<PodcastModel>) {
        cached.add(podcast);
        _cacheManager.write('my_subscribed_podcasts', cached);
      }

      _syncSubscribeToFirebase(podcast, sortOrder).then((_) {
        print(
            "AA_DEBUG: Inscription Firebase réussie pour ${podcast.collectionName}");
      }).catchError((err) {
        print(
            "AA_DEBUG: Échec inscription Firebase pour ${podcast.collectionName}: $err. En attente.");
      });
    } catch (e) {
      print("AA_DEBUG: Erreur dans subscribeToPodcast: $e");
    }
  }

  Future<void> unsubscribeFromPodcast(String feedUrl, String podcastId) async {
    try {
      await DatabaseHelper().deletePodcast(feedUrl);

      // Mettre à jour le cache local en mémoire
      final cached = _cacheManager.read('my_subscribed_podcasts');
      if (cached is List<PodcastModel>) {
        cached.removeWhere((p) => p.feedUrl == feedUrl);
        _cacheManager.write('my_subscribed_podcasts', cached);
      }

      await _addPendingDeletion(feedUrl, podcastId);

      _syncUnsubscribeFromFirebase(feedUrl, podcastId).then((_) {
        print("AA_DEBUG: Désinscription Firebase réussie pour $feedUrl");
      }).catchError((err) {
        print(
            "AA_DEBUG: Échec désinscription Firebase pour $feedUrl: $err. Placé dans la file.");
      });
    } catch (e) {
      print("AA_DEBUG: Erreur dans unsubscribeFromPodcast: $e");
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
    } catch (e) {
      print('AA_DEBUG: Erreur ajout pending deletion: $e');
    }
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
    } catch (e) {
      print('AA_DEBUG: Erreur retrait pending deletion: $e');
    }
  }

  Future<void> _syncSubscribeToFirebase(
      PodcastModel model, int orderIndex) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String podcastUuid =
        _getPodcastUuid(model.collectionId, model.feedUrl);

    // 1. Ajouter dans Firestore
    final QuerySnapshot query = await FirebaseFirestore.instance
        .collection('subscriptions')
        .where('userId', isEqualTo: user.uid)
        .where('feedUrl', isEqualTo: model.feedUrl)
        .get();

    if (query.docs.isEmpty) {
      await FirebaseFirestore.instance.collection('subscriptions').add({
        'userId': user.uid,
        'collectionId': model.collectionId,
        'collectionName': model.collectionName,
        'artistName': model.artistName,
        'artworkUrl600': model.artworkUrl,
        'feedUrl': model.feedUrl,
        'orderIndex': orderIndex,
        'subscribedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await query.docs.first.reference.update({'orderIndex': orderIndex});
    }

    // 2. Ajouter dans Data Connect
    final userResult = await ExampleConnector.instance
        .findUserByGoogleId(googleId: user.uid)
        .execute();
    if (userResult.data.users.isNotEmpty) {
      final postgresUuid = userResult.data.users.first.id;

      await ExampleConnector.instance
          .upsertPodcast(
            title: model.collectionName,
            feedUrl: model.feedUrl,
            createdAt:
                Timestamp(DateTime.now().millisecondsSinceEpoch ~/ 1000, 0),
          )
          .id(podcastUuid)
          .imageUrl(model.artworkUrl)
          .author(model.artistName)
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

    // Marquer comme synchronisé dans SQLite
    await DatabaseHelper().setPodcastSyncStatus(model.feedUrl, 1);
  }

  Future<void> _syncUnsubscribeFromFirebase(
      String feedUrl, String podcastId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Supprimer de Firestore
    final QuerySnapshot query = await FirebaseFirestore.instance
        .collection('subscriptions')
        .where('userId', isEqualTo: user.uid)
        .where('feedUrl', isEqualTo: feedUrl)
        .get();

    for (var doc in query.docs) {
      await doc.reference.delete();
    }

    // 2. Supprimer de Data Connect
    final userResult = await ExampleConnector.instance
        .findUserByGoogleId(googleId: user.uid)
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

    // Retirer de la file d'attente locale
    await _removePendingDeletion(feedUrl, podcastId);
  }

  String _getPodcastUuid(int? collectionId, String feedUrl) {
    final rawId = collectionId?.toString() ?? feedUrl.hashCode.abs().toString();
    if (rawId.contains('-')) return rawId;
    if (rawId.length == 32) {
      return '${rawId.substring(0, 8)}-${rawId.substring(8, 12)}-${rawId.substring(12, 16)}-${rawId.substring(16, 20)}-${rawId.substring(20, 32)}';
    }
    final paddedId = rawId.padLeft(12, '0');
    return '00000000-0000-4000-8000-$paddedId';
  }

  Future<void> retryUnsyncedOrders() async {
    if (_isSyncing) {
      print("AA_DEBUG: retryUnsyncedOrders déjà en cours, tentative ignorée.");
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _isSyncing = true;
    print("AA_DEBUG: Début de retryUnsyncedOrders (verrou activé)...");

    try {
      // A. Traiter les désabonnements en attente
      final prefs = await SharedPreferences.getInstance();
      final pendingDeletions = prefs.getStringList('pending_deletions') ?? [];
      if (pendingDeletions.isNotEmpty) {
        print(
            "AA_DEBUG: ${pendingDeletions.length} suppressions en attente trouvées.");
        final List<String> currentPendingList = List.from(pendingDeletions);
        for (var item in currentPendingList) {
          try {
            final decoded = jsonDecode(item);
            final feedUrl = decoded['feedUrl'] as String;
            final podcastId = decoded['podcastId'] as String;
            await _syncUnsubscribeFromFirebase(feedUrl, podcastId);
          } catch (e) {
            print(
                "AA_DEBUG: Échec traitement suppression en attente pour $item : $e");
          }
        }
      }

      // B. Traiter les abonnements non synchronisés (isSynced = 0)
      final unsynced = await DatabaseHelper().getUnsyncedPodcasts();
      if (unsynced.isNotEmpty) {
        print(
            "AA_DEBUG: ${unsynced.length} abonnements locaux non synchronisés trouvés.");
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
          } catch (e) {
            print(
                "AA_DEBUG: Échec traitement abonnement non synchronisé pour ${map['feedUrl']} : $e");
          }
        }
      }

      // C. Synchroniser l'ordre de tri de tous les abonnements actuels pour correspondre parfaitement
      final localSubs = await DatabaseHelper().getSubscribedPodcasts();
      if (localSubs.isNotEmpty) {
        await _syncSortOrdersOnly(localSubs);
      }

      print("AA_DEBUG: Fin de retryUnsyncedOrders avec succès.");
    } catch (e) {
      print("AA_DEBUG: Erreur lors de la synchronisation : $e");
    } finally {
      _isSyncing = false;
      print("AA_DEBUG: Verrou désactivé pour retryUnsyncedOrders.");
    }
  }

  Future<void> _syncSortOrdersOnly(List<PodcastModel> localSubs) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Firestore
      final WriteBatch batch = FirebaseFirestore.instance.batch();
      for (int i = 0; i < localSubs.length; i++) {
        final podcast = localSubs[i];
        final QuerySnapshot query = await FirebaseFirestore.instance
            .collection('subscriptions')
            .where('userId', isEqualTo: user.uid)
            .where('feedUrl', isEqualTo: podcast.feedUrl)
            .get();

        for (var doc in query.docs) {
          batch.update(doc.reference, {'orderIndex': i});
        }
      }
      await batch.commit();

      // 2. Data Connect
      final userResult = await ExampleConnector.instance
          .findUserByGoogleId(googleId: user.uid)
          .execute();
      if (userResult.data.users.isNotEmpty) {
        final postgresUuid = userResult.data.users.first.id;
        for (int i = 0; i < localSubs.length; i++) {
          final podcast = localSubs[i];
          final podcastUuid =
              _getPodcastUuid(podcast.collectionId, podcast.feedUrl);
          await ExampleConnector.instance
              .updateSubscriptionOrder(
                userId: postgresUuid,
                podcastId: podcastUuid,
                listOrder: i,
              )
              .execute();
        }
      }
    } catch (e) {
      print(
          "AA_DEBUG: Échec de la mise à jour de l'ordre de tri sur Firebase: $e");
      rethrow;
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
      print('Erreur lors de la récupération des IDs des podcasts abonnés : $e');
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
            if (cacheAgeMs > 24 * 60 * 60 * 1000) {
              print("AA_DEBUG: Le cache des épisodes à écouter a plus de 24h.");
            }
          } catch (e) {
            print(
                "AA_DEBUG: Erreur lors de la lecture du cache episodes_to_listen: $e");
          }
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
        print(
            "AA_DEBUG: Erreur récupération en ligne des épisodes (offline/timeout), fallback sur le cache: $e");

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
        print(
            "AA_DEBUG: Erreur lors du filtrage SQLite des épisodes à écouter: $e");
        return list;
      }
    }

    return [];
  }

  Future<void> _refreshEpisodesToListen() async {
    print("AA_DEBUG: _refreshEpisodesToListen lancé en arrière-plan...");
    _cachedEpisodesToListen = null;
    _cacheManager.remove('cache_episodes_to_listen');

    // Recharger immédiatement en tâche de fond pour reconstruire le cache
    // Cette opération asynchrone gère elle-même son exception/réseau sans bloquer l'UI
    try {
      await getEpisodesToListen(forceRefresh: true);
      print(
          "AA_DEBUG: Cache des épisodes reconstruit avec succès en arrière-plan.");
    } catch (e) {
      print(
          "AA_DEBUG: Échec de la reconstruction immédiate du cache (offline ou erreur) : $e");
    }
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
    print(
        'AA_DEBUG: markEpisodeAsRead appelé dans DatabaseRepository pour l\'épisode: $episodeId');

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
      print(
          'AA_DEBUG: Écriture SQLite réussie dans DatabaseRepository pour $episodeId');

      // Double validation immédiate dans SQLite : on vérifie que l'épisode a bien été marqué comme lu
      final verifyWrite = await DatabaseHelper().isEpisodeRead(episodeId);
      if (!verifyWrite) {
        throw Exception(
            "Validation post-écriture SQLite échouée : l'épisode n'a pas été marqué comme lu.");
      }
    } catch (e) {
      print(
          'AA_DEBUG: Erreur critique d\'écriture SQLite dans DatabaseRepository: $e. Toutes les synchronisations et mises à jour de cache sont annulées.');
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
          print(
              'AA_DEBUG: Cache SharedPreferences mis à jour de manière atomique après lecture.');
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
    } catch (e) {
      print('AA_DEBUG: Erreur lors de la mise à jour atomique du cache : $e');
    }

    // 3. Synchronisation distante asynchrone (Firestore & Data Connect) en arrière-plan
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !episodeId.startsWith('mock_')) {
      _syncEpisodeReadToFirebase(user.uid, episodeId).catchError((e) {
        print(
            'AA_DEBUG: Échec de la synchronisation en arrière-plan pour $episodeId : $e');
      });
    }

    // 4. Notifier l'UI via le listRefreshNotifier centralisé
    try {
      app_audio.AudioService().listRefreshNotifier.value++;
      print(
          'AA_DEBUG: listRefreshNotifier notifié avec succès depuis DatabaseRepository');
    } catch (e) {
      print(
          'AA_DEBUG: Erreur lors de la notification de listRefreshNotifier: $e');
    }
  }

  Future<void> _syncEpisodeReadToFirebase(String uid, String episodeId) async {
    final String encodedId = base64UrlEncode(utf8.encode(episodeId));

    // A. Sync to Firestore
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('episode_history')
          .doc(encodedId)
          .set({'finishedListening': true}, SetOptions(merge: true)).timeout(
              const Duration(seconds: 4));
      print('AA_DEBUG: Synchro Firestore réussie pour l\'épisode: $episodeId');
    } catch (e) {
      print('AA_DEBUG: Échec synchro Firestore (timeout/hors-ligne) : $e');
    }

    // B. Sync to Data Connect (ExampleConnector)
    try {
      final userResult = await ExampleConnector.instance
          .findUserByGoogleId(googleId: uid)
          .execute();
      if (userResult.data.users.isNotEmpty) {
        final postgresUuid = userResult.data.users.first.id;
        final String formattedEpisodeId = _formatUuidForSync(episodeId);

        int durationSeconds = 600;
        await ExampleConnector.instance
            .updateListenHistory(
              userId: postgresUuid,
              episodeId: formattedEpisodeId,
              progressSeconds: BigInt.from(durationSeconds),
              finishedListening: true,
              listenedAt:
                  Timestamp(DateTime.now().millisecondsSinceEpoch ~/ 1000, 0),
            )
            .execute();
        print(
            'AA_DEBUG: Synchro Data Connect réussie pour l\'épisode: $episodeId');
      }
    } catch (e) {
      print('AA_DEBUG: Échec synchro Data Connect: $e');
    }
  }

  String _formatUuidForSync(String rawId) {
    if (rawId.contains('-')) return rawId;
    if (rawId.length == 32) {
      return '${rawId.substring(0, 8)}-${rawId.substring(8, 12)}-${rawId.substring(12, 16)}-${rawId.substring(16, 20)}-${rawId.substring(20, 32)}';
    }
    return rawId;
  }

  Future<List<PodcastModel>> getPodcastsByThemeWithCache(String theme) async {
    try {
      final cacheTime = await DatabaseHelper().getThemeCacheTime(theme);
      final now = DateTime.now().millisecondsSinceEpoch;

      // 7 jours en millisecondes = 7 * 24 * 60 * 60 * 1000 = 604 800 000
      const int sevenDaysMs = 7 * 24 * 60 * 60 * 1000;

      if (cacheTime != null && (now - cacheTime) < sevenDaysMs) {
        print(
            "AA_DEBUG: Cache hit pour le thème '$theme'. Lecture depuis SQLite.");
        final cachedPodcasts = await DatabaseHelper().getThemeCache(theme);
        if (cachedPodcasts.isNotEmpty) {
          return cachedPodcasts;
        }
      }

      print(
          "AA_DEBUG: Cache miss ou expiré (7 jours dépassés) pour le thème '$theme'. Récupération via iTunes API...");
      final freshPodcasts = await ItunesService().getPodcastsByTheme(theme);

      if (freshPodcasts.isNotEmpty) {
        // Enregistrer dans SQLite de manière transactionnelle
        await DatabaseHelper().saveThemeCache(theme, freshPodcasts);
      }

      return freshPodcasts;
    } catch (e) {
      print("AA_DEBUG: Erreur dans getPodcastsByThemeWithCache: $e");
      // Fallback sur le cache si l'appel API échoue
      try {
        final cached = await DatabaseHelper().getThemeCache(theme);
        if (cached.isNotEmpty) {
          print(
              "AA_DEBUG: Fallback sur le cache SQLite réussi suite à une erreur API.");
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
      final List<Map<String, dynamic>> maps = await db.query(
        'episodes_status',
        where: 'isRead = ?',
        whereArgs: [1],
        orderBy: 'readAt DESC',
        limit: limit,
        offset: offset,
      );

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

      // Vérification et auto-réparation des entrées sans titre ou vignette
      bool needsRepair = history.any((ep) =>
          ep.title == 'Sans titre' ||
          ep.title == 'Épisode sans titre' ||
          ep.imageUrl.isEmpty ||
          ep.podcastName.isEmpty);

      if (needsRepair) {
        print("AA_DEBUG: Besoin de réparer des épisodes dans l'historique...");
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

        bool allRepaired = true;
        for (int i = 0; i < history.length; i++) {
          final ep = history[i];
          if (ep.title == 'Sans titre' ||
              ep.title == 'Épisode sans titre' ||
              ep.imageUrl.isEmpty ||
              ep.podcastName.isEmpty) {
            final match = cacheMap[ep.id] ?? cacheMap[ep.audioUrl];
            if (match != null) {
              history[i] = EpisodeModel(
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
              // Sauvegarde locale SQLite
              await DatabaseHelper().markEpisodeAsRead(
                ep.id,
                title: history[i].title,
                audioUrl: history[i].audioUrl,
                imageUrl: history[i].imageUrl,
                podcastName: history[i].podcastName,
                pubDate: history[i].pubDate?.toIso8601String(),
                description: history[i].description,
              );
            } else {
              allRepaired = false;
            }
          }
        }

        // Si certains ne sont toujours pas réparés, lancer la tâche en arrière-plan
        if (!allRepaired) {
          _repairHistoryFromFeedsInBackground(history);
        }
      }

      return history;
    } catch (e) {
      print("AA_DEBUG: Erreur getReadEpisodesHistory: $e");
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
        print(
            "AA_DEBUG: Des épisodes de l'historique ont été réparés depuis les flux RSS.");
        // Déclencher le rafraîchissement des listes
        app_audio.AudioService().listRefreshNotifier.value++;
      }
    } catch (e) {
      print(
          "AA_DEBUG: Erreur lors de la réparation de l'historique en arrière-plan: $e");
    }
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

      print(
          "AA_DEBUG: Données de test SharedPreferences simulées avec succès !");
    } catch (e) {
      print("AA_DEBUG: Erreur lors de la simulation SharedPreferences : $e");
    }
  }
}
