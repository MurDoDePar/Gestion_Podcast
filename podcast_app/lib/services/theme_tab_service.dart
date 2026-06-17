import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/podcast_model.dart';
import '../models/app_settings.dart';
import 'sqlite_podcast_repository.dart';
import 'itunes_search_gateway.dart';

/// Service métier de l'onglet de recherche par Thèmes (`ThemesTab`).
///
/// Ce service orchestre la récupération de podcasts associés à des catégories ou thématiques,
/// en gérant la mise en cache SQLite (expiration après 7 jours) et la détection de changement de langue.
class ThemeTabService extends ChangeNotifier {
  final SqlitePodcastRepository _sqliteRepository;
  final ITunesSearchGateway _itunesGateway;

  String? theme;
  List<PodcastModel> podcasts = [];
  bool isLoading = false;
  String? errorMessage;

  /// Initialise le service de thèmes avec ses dépendances de données injectées.
  ThemeTabService({
    SqlitePodcastRepository? sqliteRepository,
    ITunesSearchGateway? itunesGateway,
  })  : _sqliteRepository = sqliteRepository ?? SqlitePodcastRepository(),
        _itunesGateway = itunesGateway ?? ITunesSearchGateway();

  /// Récupère les podcasts associés à un thème, avec gestion intelligente de cache (7 jours).
  ///
  /// **Utilité** : Tente de lire le cache SQLite thématique. S'il a expiré ou si la langue a changé, interroge l'API iTunes et rafraîchit le cache local.
  /// **Point d'entrée** : Appelé lors du chargement ou du rafraîchissement d'un thème dans l'onglet "Par thème" (`ThemeResultsView`).
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si la durée de validité du cache (7 jours) ou la logique d'invalidation (langue) change.
  Future<List<PodcastModel>> getPodcastsByThemeWithCache(String theme) async {
    try {
      final currentLang = await AppSettings.getLanguage();
      final prefs = await SharedPreferences.getInstance();
      final lastThemeLang = prefs.getString('last_theme_language') ?? '';

      // Si la langue des podcasts a changé, on vide le cache thématique immédiatement
      if (lastThemeLang != currentLang) {
        await _sqliteRepository.clearThemeCache();
        await prefs.setString('last_theme_language', currentLang);
      }

      final cacheTime = await _sqliteRepository.getThemeCacheTime(theme);
      final now = DateTime.now().millisecondsSinceEpoch;
      // 7 jours en millisecondes = 7 * 24 * 60 * 60 * 1000 = 604 800 000
      const int sevenDaysMs = 7 * 24 * 60 * 60 * 1000;

      if (cacheTime != null && (now - cacheTime) < sevenDaysMs) {
        final cachedPodcasts = await _sqliteRepository.getThemeCache(theme);
        if (cachedPodcasts.isNotEmpty) {
          return cachedPodcasts;
        }
      }

      final freshPodcasts = await _itunesGateway.searchPodcasts(theme);
      if (freshPodcasts.isNotEmpty) {
        await _sqliteRepository.saveThemeCache(theme, freshPodcasts);
      }
      return freshPodcasts;
    } catch (e) {
      // Fallback sur le cache en cas d'erreur de réseau
      try {
        final cached = await _sqliteRepository.getThemeCache(theme);
        if (cached.isNotEmpty) {
          return cached;
        }
      } catch (_) {}
      return [];
    }
  }

  /// Récupère les IDs de flux RSS des podcasts abonnés pour filtrer l'affichage.
  ///
  /// **Utilité** : Fournit les URLs des abonnements locaux de l'utilisateur sous forme de Set.
  /// **Point d'entrée** : Appelé par `ThemeResultsView` pour exclure de la liste les podcasts auxquels l'utilisateur est déjà abonné.
  /// **Maintenance** : Modifier en cas d'évolution du stockage de l'ID d'abonnement.
  Future<Set<String>> getSubscribedPodcastIds() async {
    try {
      final List<PodcastModel> subscribed =
          await _sqliteRepository.getSubscribedPodcasts();
      return subscribed
          .map((p) => p.feedUrl)
          .where((url) => url.isNotEmpty)
          .toSet();
    } catch (_) {
      return <String>{};
    }
  }

  /// Charge/Recharge la liste des podcasts pour le thème actif.
  ///
  /// **Utilité** : Tente de charger le cache local ou interroge l'API iTunes pour le thème actif, puis met à jour `podcasts` et appelle `notifyListeners()`.
  /// **Point d'entrée** : Appelé lors de l'initialisation ou d'un rafraîchissement manuel d'un thème.
  /// **Maintenance** : Si les filtres ou l'invalidation changent, ajuster ici.
  Future<void> refresh() async {
    final activeTheme = theme;
    if (activeTheme == null || activeTheme.isEmpty) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final allPodcasts = await getPodcastsByThemeWithCache(activeTheme);
      final subscribedIds = await getSubscribedPodcastIds();

      // Filtrer les podcasts déjà abonnés
      podcasts =
          allPodcasts.where((p) => !subscribedIds.contains(p.feedUrl)).toList();
    } catch (e) {
      errorMessage =
          'Erreur lors du chargement des podcasts de $activeTheme : $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
