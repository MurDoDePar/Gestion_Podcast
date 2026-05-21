import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/episode_model.dart';
import '../models/podcast_model.dart';
import 'cache_manager.dart';
import 'podcast_repository.dart';

class DatabaseRepository {
  final CacheManager _cacheManager = CacheManager();

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

  Future<List<PodcastModel>> getMySubscribedPodcasts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    const String cacheKey = 'my_subscribed_podcasts';

    // 1. Vérifier le cache en mémoire pour éviter des requêtes inutiles
    if (_cacheManager.hasKey(cacheKey)) {
      final cachedData = _cacheManager.read(cacheKey);
      if (cachedData is List<PodcastModel>) {
        return cachedData;
      }
    }

    // 2. Récupérer les abonnements via les deux sources possibles pour une compatibilité maximale
    try {
      List<PodcastModel> podcasts = [];

      // A. Tenter d'abord de récupérer depuis Firebase Data Connect (qui est la vraie DB des abonnements de l'app)
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
        print("DataConnect fetch failed, falling back to Firestore: $e");
      }

      // B. Si Data Connect est vide ou a échoué, tenter d'interroger la collection Firestore 'subscriptions' (si existante)
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

        // Trier par orderIndex ascendant
        podcastWithOrder.sort((a, b) => a.value.compareTo(b.value));
        podcasts = podcastWithOrder.map((entry) => entry.key).toList();
      } else {
        // Si récupéré de Data Connect, ordonner également selon les orderIndex stockés dans Firestore
        try {
          final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
              .collection('subscriptions')
              .where('userId', isEqualTo: user.uid)
              .get();

          final Map<String, int> orderMap = {};
          for (var doc in querySnapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final fUrl = data['feedUrl']?.toString();
            final orderVal = data['orderIndex'];
            if (fUrl != null && orderVal is int) {
              orderMap[fUrl] = orderVal;
            }
          }

          if (orderMap.isNotEmpty) {
            podcasts.sort((a, b) {
              final orderA = orderMap[a.feedUrl] ?? 9999;
              final orderB = orderMap[b.feedUrl] ?? 9999;
              return orderA.compareTo(orderB);
            });
          }
        } catch (e) {
          print(
              "Error sorting DataConnect podcasts with Firestore orderIndex: $e");
        }
      }

      // 3. Mettre à jour le cache
      if (podcasts.isNotEmpty) {
        _cacheManager.write(cacheKey, podcasts);
      }

      return podcasts;
    } catch (e) {
      print('Erreur lors de la récupération des podcasts abonnés : $e');
      return [];
    }
  }

  /// Met à jour le champ orderIndex dans Firestore pour sauvegarder l'ordre des abonnements
  Future<void> updatePodcastsOrder(List<PodcastModel> reorderedPodcasts) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final WriteBatch batch = FirebaseFirestore.instance.batch();

      for (int i = 0; i < reorderedPodcasts.length; i++) {
        final podcast = reorderedPodcasts[i];

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

      // Mettre à jour le cache local en mémoire
      _cacheManager.write('my_subscribed_podcasts', reorderedPodcasts);
    } catch (e) {
      print('Erreur lors de la mise à jour de l\'ordre des podcasts : $e');
    }
  }

  /// Récupère la liste des épisodes à écouter (file "À écouter")
  Future<List<EpisodeModel>> getEpisodesToListen() async {
    return await PodcastRepository().fetchAllRecentEpisodes();
  }
}
