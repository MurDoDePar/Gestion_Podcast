import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart' hide Timestamp;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';
import '../dataconnect-generated/example.dart';
import '../models/episode_model.dart';
import '../models/podcast_model.dart';
import 'cache_manager.dart';
import 'podcast_repository.dart';
import 'database_helper.dart';
import 'itunes_service.dart';

class DatabaseRepository {
  final CacheManager _cacheManager = CacheManager();
  static bool _isSyncing = false;

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

  Future<void> init() async {
    await ensureInitialized();
    await retryUnsyncedOrders();
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
        final subs = await PodcastRepository.fetchPodcasts(user.uid);
        if (subs.isNotEmpty) {
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
        final subs = await PodcastRepository.fetchPodcasts(user.uid);
        if (subs.isNotEmpty) {
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
      } catch (_) {}

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

  Future<void> updatePodcastsOrder(List<PodcastModel> reorderedPodcasts) async {
    try {
      // 1. Mettre à jour localement SQLite d'abord
      final List<Map<String, dynamic>> orderUpdates = [];
      for (int i = 0; i < reorderedPodcasts.length; i++) {
        orderUpdates.add({
          'feedUrl': reorderedPodcasts[i].feedUrl,
          'sortOrder': i,
          'isSynced': 0, // Unsynced
        });
      }
      await DatabaseHelper().updatePodcastsSortOrder(orderUpdates);
      print("AA_DEBUG: Ordre mis à jour en local dans SQLite.");

      // Mettre à jour le cache local en mémoire
      _cacheManager.write('my_subscribed_podcasts', reorderedPodcasts);

      // 2. Déclencher la synchronisation en tâche de fond (retryUnsyncedOrders)
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
      {bool forceRefresh = true}) async {
    if (forceRefresh) {
      _cacheManager.remove('cache_episodes_to_listen');
    }
    return await PodcastRepository().fetchAllRecentEpisodes();
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
}
