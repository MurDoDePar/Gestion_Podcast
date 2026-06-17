import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/podcast_model.dart';
import '../core/services/auth_service.dart';
import '../core/services/service_locator.dart';
import 'sqlite_podcast_repository.dart';
import 'sql_connect_repository.dart';

/// Service métier de l'onglet d'Affinités (`DiscoverTab`).
///
/// Ce service calcule et gère la liste de podcasts suggérés par co-abonnement (social matching),
/// en interrogeant la base relationnelle PostgreSQL distante via `SqlConnectRepository`
/// et en comparant avec les abonnements locaux de `SqlitePodcastRepository`.
class AffinityTabService extends ChangeNotifier {
  final SqlitePodcastRepository _sqliteRepository;
  final SqlConnectRepository _sqlConnectRepository;
  final AuthService _authService;

  List<PodcastModel> recommendedPodcasts = [];
  bool isLoading = false;
  String? errorMessage;

  /// Initialise le service d'affinités avec ses dépendances injectées.
  AffinityTabService({
    SqlitePodcastRepository? sqliteRepository,
    SqlConnectRepository? sqlConnectRepository,
    AuthService? authService,
  })  : _sqliteRepository = sqliteRepository ?? SqlitePodcastRepository(),
        _sqlConnectRepository = sqlConnectRepository ?? SqlConnectRepository(),
        _authService = authService ?? locator<AuthService>();

  /// Calcule et retourne la liste des podcasts recommandés par affinité avec d'autres utilisateurs.
  ///
  /// **Utilité** : Extrait les abonnements locaux, interroge PostgreSQL via SQLConnect pour trouver les utilisateurs similaires, calcule les scores d'affinité, exclut les podcasts déjà suivis, et gère un cache local (SharedPreferences) pour le support hors-ligne.
  /// **Point d'entrée** : Appelé lors du chargement ou du rafraîchissement manuel de l'onglet "Affinités" (`DiscoverTab`).
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si l'algorithme de calcul du score d'affinité (pondération des pairs ou limite du top 10 des pairs) doit être modifié.
  Future<List<PodcastModel>> getAffinityPodcasts() async {
    final userId = _authService.currentUserId;
    if (userId == null) return [];

    const String cacheKey = 'affinity_podcasts_cache';
    final prefs = await SharedPreferences.getInstance();

    try {
      // 1. Récupérer les abonnements locaux (SQLite) pour filtrage
      final localSubs = await _sqliteRepository.getSubscribedPodcasts();
      final localFeedUrls = localSubs
          .map((p) => p.feedUrl)
          .where((url) => url.isNotEmpty)
          .toList();

      if (localFeedUrls.isEmpty) {
        return [];
      }

      // 2. Résoudre le googleId (String) en UUID PostgreSQL
      final userResult = await _sqlConnectRepository.findUserByGoogleId(userId);
      final users = userResult.data.users;
      if (users.isEmpty) {
        return [];
      }
      final postgresUuid = users.first.id;

      // 3. Récupérer les recommandations d'affinité de PostgreSQL via SQLConnect
      final affinityResult =
          await _sqlConnectRepository.getAffinityRecommendations(postgresUuid);
      final mySubs = affinityResult.data.mySubscriptions;
      if (mySubs.isEmpty) {
        return [];
      }

      // 4. Algorithme d'affinité (Regroupement et comptage des co-abonnements)
      final Map<String, int> peerOverlapCounts = {};
      final Map<String, List<dynamic>> peerSubscriptions = {};

      for (var sub in mySubs) {
        for (var peerSub in sub.podcast.subscriptionTypes_on_podcast) {
          final peer = peerSub.user;
          final peerId = peer.id;
          if (peerId == postgresUuid) continue;

          peerOverlapCounts[peerId] = (peerOverlapCounts[peerId] ?? 0) + 1;
          peerSubscriptions[peerId] =
              peer.subscriptionTypes_on_user.map((su) => su.podcast).toList();
        }
      }

      if (peerOverlapCounts.isEmpty) {
        return [];
      }

      // Trier les pairs par co-abonnements décroissants (Top 10)
      final sortedPeers = peerOverlapCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topPeers = sortedPeers.take(10).map((e) => e.key).toList();

      final Map<String, PodcastModel> recommendedPodcasts = {};
      final Map<String, double> recommendedScores = {};

      for (final peerId in topPeers) {
        final peerWeight = peerOverlapCounts[peerId] ?? 1;
        final podcasts = peerSubscriptions[peerId] ?? [];
        for (var podcast in podcasts) {
          final feedUrl = podcast.feedUrl;
          if (feedUrl.isEmpty) continue;
          if (localFeedUrls.contains(feedUrl)) continue;

          if (!recommendedPodcasts.containsKey(feedUrl)) {
            recommendedPodcasts[feedUrl] = PodcastModel(
              collectionName: podcast.title,
              artistName: podcast.author ?? 'Artiste inconnu',
              artworkUrl: podcast.imageUrl ?? '',
              feedUrl: feedUrl,
              collectionId: int.tryParse(podcast.id) ?? podcast.id.hashCode,
            );
          }
          recommendedScores[feedUrl] =
              (recommendedScores[feedUrl] ?? 0) + peerWeight;
        }
      }

      final sortedRecommendations = recommendedScores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final List<PodcastModel> result = sortedRecommendations
          .map((entry) => recommendedPodcasts[entry.key]!)
          .toList();

      // Sauvegarde locale dans SharedPreferences (Offline-First)
      final jsonList = result.map((p) => p.toMap()).toList();
      await prefs.setString(cacheKey, jsonEncode(jsonList));

      return result;
    } catch (e) {
      // Fallback hors-ligne : lire la dernière liste calculée dans le cache
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

  /// Charge/Recharge la liste des podcasts recommandés par affinité.
  ///
  /// **Utilité** : Lance le calcul d'affinité, met à jour `recommendedPodcasts`, gère les erreurs, et appelle `notifyListeners()`.
  /// **Point d'entrée** : Appelé lors du premier affichage ou du pull-to-refresh de l'onglet Affinités.
  /// **Maintenance** : Si l'algorithme ou le mode de cache change, modifier ici.
  Future<void> refresh() async {
    if (isLoading) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      recommendedPodcasts = await getAffinityPodcasts();
    } catch (e) {
      errorMessage = 'Erreur lors du calcul des affinités : $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
