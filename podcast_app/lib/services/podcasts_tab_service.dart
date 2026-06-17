import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/podcast_model.dart';
import '../models/episode_model.dart';
import 'sqlite_podcast_repository.dart';
import 'sql_connect_repository.dart';
import 'podcast_cache_manager.dart';
import 'rss_service.dart';
import 'download_manager.dart';
import 'audio_service.dart' as app_audio;
import 'database_repository.dart'; // Pour la compatibilité des exceptions / types si nécessaire
import '../core/services/auth_service.dart';
import '../core/services/service_locator.dart';

/// Service métier principal de l'onglet "Mes podcasts" (`MyPodcastsTab`).
///
/// Ce service regroupe toutes les opérations métier liées à la gestion de la bibliothèque de podcasts
/// de l'utilisateur : abonnements, désabonnements, réorganisation de l'ordre d'affichage,
/// et agrégation ordonnée des flux d'épisodes (Offline-First).
class PodcastsTabService extends ChangeNotifier {
  final SqlitePodcastRepository _sqliteRepository;
  final SqlConnectRepository _sqlConnectRepository;
  final PodcastCacheManager _cacheManager;
  final RssService _rssService;
  final AuthService _authService;

  List<PodcastModel> subscribedPodcasts = [];
  List<EpisodeModel> episodesToListen = [];
  bool isLoading = false;
  String? errorMessage;

  /// Initialise le service d'abonnements avec ses dépendances injectées.
  PodcastsTabService({
    SqlitePodcastRepository? sqliteRepository,
    SqlConnectRepository? sqlConnectRepository,
    PodcastCacheManager? cacheManager,
    RssService? rssService,
    AuthService? authService,
  })  : _sqliteRepository = sqliteRepository ?? SqlitePodcastRepository(),
        _sqlConnectRepository = sqlConnectRepository ?? SqlConnectRepository(),
        _cacheManager = cacheManager ?? PodcastCacheManager(),
        _rssService = rssService ?? RssService(),
        _authService = authService ?? locator<AuthService>();

  /// Récupère la liste des podcasts abonnés de l'utilisateur.
  ///
  /// **Utilité** : Fournit la liste ordonnée des abonnements depuis la base locale SQLite.
  /// **Point d'entrée** : Appelé lors du chargement de l'onglet bibliothèque.
  /// **Maintenance** : Modifier en cas de changement de logique d'accès local (ex: ajout de filtres).
  Future<List<PodcastModel>> getMySubscribedPodcasts() async {
    return await _sqliteRepository.getSubscribedPodcasts();
  }

  /// Récupère la liste des épisodes à écouter en déléguant au dépôt de données.
  ///
  /// **Utilité** : Tente de charger le cache d'épisodes existant ou de rafraîchir à partir du réseau si forceRefresh est vrai.
  /// **Point d'entrée** : Appelé par `MyPodcastsTab` lors du tirage vers le bas (pull-to-refresh).
  /// **Maintenance** : Modifier si les règles de rafraîchissement forcé ou de gestion du cache réseau changent.
  Future<List<EpisodeModel>> getEpisodesToListen(
      {bool forceRefresh = false}) async {
    return await DatabaseRepository()
        .getEpisodesToListen(forceRefresh: forceRefresh);
  }

  /// **Utilité** : Enchaînement dynamique respectant l'ordre de tri utilisateur.
  ///
  /// **Point d'entrée** : Trigger sur événement onCompletion du lecteur audio ou prefetch.
  ///
  /// **Maintenance** : Si la logique de tri ou de filtrage de la liste 'À écouter' change, modifier PodcastsTabService.getNextEpisode.
  /// Si la structure de EpisodeModel ou le mode de tri change, l'impact potentiel sur les ListenableBuilder associés est minime car cette méthode n'est qu'un sélecteur de transition.
  Future<EpisodeModel?> getNextEpisode(String currentEpisodeId) async {
    try {
      final List<EpisodeModel> currentList = await getEpisodesToListen();
      final int currentIndex = currentList.indexWhere(
        (e) => e.id == currentEpisodeId || e.audioUrl == currentEpisodeId,
      );

      if (currentIndex != -1 && currentIndex < currentList.length - 1) {
        return currentList[currentIndex + 1];
      } else if (currentIndex == -1 && currentList.isNotEmpty) {
        return currentList.first;
      }
    } catch (_) {
      // Échec silencieux
    }
    return null;
  }

  /// Recharge les abonnements locaux et agrège la liste des épisodes à écouter.
  ///
  /// **Utilité** : Met à jour la liste des podcasts abonnés et agrège les derniers épisodes associés.
  /// **Point d'entrée** : Appelé lors du chargement de l'onglet bibliothèque ou lors d'un pull-to-refresh.
  /// **Maintenance** : Modifier en cas de changement dans le flux de chargement des abonnements ou d'épisodes.
  Future<void> refresh({bool forceRefresh = false}) async {
    if (isLoading) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      subscribedPodcasts = await _sqliteRepository.getSubscribedPodcasts();
      if (forceRefresh) {
        // Optionnellement rafraîchir en ligne via la BDD globale
        await DatabaseRepository().getEpisodesToListen(forceRefresh: true);
      }
      episodesToListen = await fetchAndAggregateEpisodes(subscribedPodcasts);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Met à jour l'ordre d'affichage des abonnements localement puis lance la synchro en arrière-plan.
  ///
  /// **Utilité** : Enregistre le nouvel ordre dans SQLite locale de manière transactionnelle (Atomicité), invalide les caches d'épisodes et lance le téléchargement automatique des épisodes prioritaires.
  /// **Point d'entrée** : Appelé lors du drag-and-drop de réorganisation de tuile de podcast.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si la politique d'auto-téléchargement après tri change.
  Future<void> updatePodcastsOrder(List<PodcastModel> updatedList) async {
    final List<Map<String, dynamic>> orderUpdates = [];
    for (int i = 0; i < updatedList.length; i++) {
      orderUpdates.add({
        'feedUrl': updatedList[i].feedUrl,
        'sortOrder': i,
        'isSynced': 0, // En attente de synchro
      });
    }

    // Mise à jour de la BDD locale (Transaction SQLite)
    await _sqliteRepository.updatePodcastsSortOrder(orderUpdates);

    // Invalidation de cache RAM
    _cacheManager.write('my_subscribed_podcasts', updatedList);

    // Recalcul instantané local de la liste "À écouter"
    await recalculateEpisodesToListenInstantly();

    // Déclenchement de l'auto-téléchargement
    DownloadManager().triggerAutoDownloads();

    // Lancer la synchro asynchrone des ordres vers PostgreSQL
    _syncOrdersToFirebase(updatedList).catchError((_) {});

    // Mettre à jour l'état et notifier les écouteurs
    subscribedPodcasts = List.from(updatedList);
    notifyListeners();
  }

  /// S'abonne à un podcast localement puis lance la synchronisation distante.
  ///
  /// **Utilité** : Insère le podcast dans SQLite local, met à jour les caches mémoire et lance la tâche asynchrone vers Firestore / Data Connect.
  /// **Point d'entrée** : Clic sur le bouton s'abonner depuis l'écran de détails.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier si les métadonnées par défaut d'un abonnement changent.
  Future<void> subscribeToPodcast(PodcastModel podcast) async {
    final list = await _sqliteRepository.getSubscribedPodcasts();
    final sortOrder = list.length;

    // Écriture locale SQLite
    await _sqliteRepository.insertPodcast(podcast, sortOrder, isSynced: 0);

    // Mise à jour RAM cache
    final cached = _cacheManager.read('my_subscribed_podcasts');
    if (cached is List<PodcastModel>) {
      cached.removeWhere((p) => p.feedUrl == podcast.feedUrl);
      cached.add(podcast);
      _cacheManager.write('my_subscribed_podcasts', cached);
    }

    // Lancer la synchro asynchrone distante
    _syncSubscribeToFirebase(podcast, sortOrder).catchError((_) {});

    // Rafraîchir localement
    await refresh();
  }

  /// Se désabonne d'un podcast localement et synchronise l'information.
  ///
  /// **Utilité** : Supprime le podcast de SQLite locale, gère les clés de suppression en attente (offline) et délègue la suppression Firebase.
  /// **Point d'entrée** : Clic sur le bouton de désabonnement depuis l'écran de détails.
  /// **Maintenance** : Modifier si les clés de désabonnement ou d'annulation de cache associées doivent être purgées simultanément.
  Future<void> unsubscribeFromPodcast(String feedUrl) async {
    // Écriture locale SQLite
    await _sqliteRepository.deletePodcast(feedUrl);

    // Invalidation de cache RAM
    final cached = _cacheManager.read('my_subscribed_podcasts');
    if (cached is List<PodcastModel>) {
      cached.removeWhere((p) => p.feedUrl == feedUrl);
      _cacheManager.write('my_subscribed_podcasts', cached);
    }

    // Déterminer l'ID distant pour suppression
    final bytes = utf8.encode(feedUrl);
    final digest = md5.convert(bytes);
    final rawId = digest.toString();
    final String podcastId =
        '${rawId.substring(0, 8)}-${rawId.substring(8, 12)}-${rawId.substring(12, 16)}-${rawId.substring(16, 20)}-${rawId.substring(20, 32)}';

    await _addPendingDeletion(feedUrl, podcastId);

    // Lancement synchro asynchrone distante
    _syncUnsubscribeFromFirebase(feedUrl, podcastId).catchError((_) {});

    // Rafraîchir localement
    await refresh();
  }

  /// Récupère, filtre et trie de façon Offline-First la liste agrégée des épisodes de tous les abonnements.
  ///
  /// **Utilité** : Charge en parallèle les flux RSS/Caches de tous les abonnements, applique les filtres des épisodes lus locaux et ordonne par date de publication (selon réglage utilisateur asc/desc).
  /// **Point d'entrée** : Appelé lors du rendu de la section "À écouter" de `MyPodcastsTab`.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si un nouveau filtre d'exclusion d'épisodes (ex: épisodes partiellement écoutés) est ajouté.
  Future<List<EpisodeModel>> fetchAndAggregateEpisodes(
      List<PodcastModel> subscribedPodcasts) async {
    if (subscribedPodcasts.isEmpty) return [];

    // 1. Charger tous les flux RSS en parallèle pour optimiser le réseau
    final List<Future<List<EpisodeModel>?>> futures = subscribedPodcasts
        .map((podcast) => _rssService.getEpisodesFromFeed(podcast.feedUrl))
        .toList();

    final List<List<EpisodeModel>?> results = await Future.wait(futures);

    // 2. Récupérer l'historique et préférences locales
    final prefs = await SharedPreferences.getInstance();
    final String order = prefs.getString('podstream_order') ?? 'asc';

    final sqliteReadList = await _sqliteRepository.getReadEpisodeIds();
    final Set<String> localReadSet = sqliteReadList.toSet();

    final List<EpisodeModel> orderedEpisodes = [];

    // 3. Traiter les épisodes dans l'ordre exact des abonnements
    for (int i = 0; i < subscribedPodcasts.length; i++) {
      final podcast = subscribedPodcasts[i];
      var podcastEpisodes = results[i];

      if (podcastEpisodes == null) {
        // Fallback Cache 304
        podcastEpisodes = await _rssService.getCachedEpisodes(podcast.feedUrl);
      } else {
        if (podcastEpisodes.isNotEmpty) {
          await _sqliteRepository.insertEpisodesMetadata(podcastEpisodes);
        }
      }

      final List<EpisodeModel> unreadEpisodes = [];
      for (var episode in podcastEpisodes) {
        if (!localReadSet.contains(episode.id)) {
          unreadEpisodes.add(
            EpisodeModel(
              id: episode.id,
              audioUrl: episode.audioUrl,
              title: episode.title,
              podcastName: episode.podcastName.isNotEmpty
                  ? episode.podcastName
                  : podcast.collectionName,
              imageUrl: podcast.artworkUrl,
              description: episode.description,
              pubDate: episode.pubDate,
            ),
          );
        }
      }

      // Tri des épisodes du podcast selon préférence utilisateur
      unreadEpisodes.sort((a, b) {
        if (a.pubDate == null && b.pubDate == null) return 0;
        if (a.pubDate == null) return 1;
        if (b.pubDate == null) return -1;
        final cmp = a.pubDate!.compareTo(b.pubDate!);
        return order == 'asc' ? cmp : -cmp;
      });

      orderedEpisodes.addAll(unreadEpisodes);
    }

    return orderedEpisodes;
  }

  /// Recalcule de manière purement locale (sans requêtes réseau) la liste "À écouter".
  ///
  /// **Utilité** : Reconstitue rapidement la liste en cache des épisodes à écouter à partir des caches RSS locaux de SQLite.
  /// **Point d'entrée** : Appelé après réorganisation d'ordre de tri pour mettre à jour instantanément l'UI.
  /// **Maintenance** : Modifier si les règles de tri ou d'exclusion d'épisodes en local sont modifiées.
  Future<void> recalculateEpisodesToListenInstantly() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const String cacheKey = 'cache_episodes_to_listen';

      final localSubs = await _sqliteRepository.getSubscribedPodcasts();
      final readIds = await _sqliteRepository.getReadEpisodeIds();
      final readIdsSet = readIds.toSet();

      List<EpisodeModel> instantList = [];
      final order = prefs.getString('podstream_order') ?? 'asc';

      for (var podcast in localSubs) {
        final cachedEpisodes =
            await _rssService.getCachedEpisodes(podcast.feedUrl);

        cachedEpisodes.sort((a, b) {
          int cmp = 0;
          final matchA = RegExp(r'#(\d+)').firstMatch(a.title);
          final matchB = RegExp(r'#(\d+)').firstMatch(b.title);

          if (matchA != null && matchB != null) {
            final numA = int.parse(matchA.group(1)!);
            final numB = int.parse(matchB.group(1)!);
            cmp = numA.compareTo(numB);
          } else {
            final dateA = a.pubDate ?? DateTime.now();
            final dateB = b.pubDate ?? DateTime.now();
            cmp = dateA.compareTo(dateB);
            if (cmp == 0) cmp = a.title.compareTo(b.title);
          }

          return order == 'asc' ? cmp : -cmp;
        });

        for (var ep in cachedEpisodes) {
          if (!readIdsSet.contains(ep.id) &&
              !readIdsSet.contains(ep.audioUrl)) {
            instantList.add(EpisodeModel(
              id: ep.id,
              title: ep.title,
              audioUrl: ep.audioUrl,
              imageUrl:
                  ep.imageUrl.isNotEmpty ? ep.imageUrl : podcast.artworkUrl,
              podcastName: podcast.collectionName,
              pubDate: ep.pubDate,
              description: ep.description,
            ));
          }
        }
      }

      await prefs.setString(
          cacheKey, jsonEncode(instantList.map((e) => e.toMap()).toList()));
      await prefs.setInt('cache_episodes_to_listen_time',
          DateTime.now().millisecondsSinceEpoch);

      subscribedPodcasts = localSubs;
      episodesToListen = instantList;
      notifyListeners();

      // Rafraîchir l'UI via le signal notifier
      app_audio.AudioService().listRefreshNotifier.value++;
    } catch (_) {}
  }

  // --- MÉTHODES PRIVÉES DE SYNCHRONISATION DISTANTE ---

  Future<void> _syncSubscribeToFirebase(
      PodcastModel model, int orderIndex) async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    final String podcastUuid =
        _getPodcastUuid(model.collectionId, model.feedUrl);
    // Synchro PostgreSQL via SQLConnect
    await _sqlConnectRepository.upsertPodcast(
      id: podcastUuid,
      title: model.collectionName,
      feedUrl: model.feedUrl,
      imageUrl: model.artworkUrl,
      author: model.artistName,
      categories: model.genres,
    );
    await _sqlConnectRepository.subscribeToPodcast(
      userId:
          userId, // Id utilisateur résolu en UUID dans le repository/sync ou passé directement
      podcastId: podcastUuid,
      listOrder: orderIndex,
    );

    // Marquer localement comme synchronisé
    await _sqliteRepository.setPodcastSyncStatus(model.feedUrl, 1);
  }

  Future<void> _syncUnsubscribeFromFirebase(
      String feedUrl, String podcastId) async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    // Résoudre l'UUID distant de l'utilisateur
    final userResult = await _sqlConnectRepository.findUserByGoogleId(userId);
    if (userResult.data.users.isNotEmpty) {
      final postgresUuid = userResult.data.users.first.id;
      await _sqlConnectRepository.unsubscribeFromPodcast(
        userId: postgresUuid,
        podcastId: podcastId,
      );
    }
    await _removePendingDeletion(feedUrl, podcastId);
  }

  Future<void> _syncOrdersToFirebase(List<PodcastModel> updatedList) async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    final userResult = await _sqlConnectRepository.findUserByGoogleId(userId);
    if (userResult.data.users.isNotEmpty) {
      final postgresUuid = userResult.data.users.first.id;
      for (int i = 0; i < updatedList.length; i++) {
        final podcast = updatedList[i];
        final podcastUuid =
            _getPodcastUuid(podcast.collectionId, podcast.feedUrl);
        await _sqlConnectRepository.subscribeToPodcast(
          userId: postgresUuid,
          podcastId: podcastUuid,
          listOrder: i,
        );
        await _sqliteRepository.setPodcastSyncStatus(podcast.feedUrl, 1);
      }
    }
  }

  String _getPodcastUuid(int? collectionId, String feedUrl) {
    if (feedUrl.isEmpty) return '00000000-0000-4000-8000-000000000000';
    final bytes = utf8.encode(feedUrl);
    final digest = md5.convert(bytes);
    final rawId = digest.toString();
    return '${rawId.substring(0, 8)}-${rawId.substring(8, 12)}-${rawId.substring(12, 16)}-${rawId.substring(16, 20)}-${rawId.substring(20, 32)}';
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
    } catch (_) {}
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
    } catch (_) {}
  }
}
