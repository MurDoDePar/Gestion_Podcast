import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/app_settings.dart';
import 'sqlite_podcast_repository.dart';
import 'podcast_cache_manager.dart';
import 'download_manager.dart';
import 'database_repository.dart'; // Pour la compatibilité de CacheStats
import 'audio_service.dart' as app_audio;

/// Service métier de l'écran des Réglages/Paramètres (`SettingsScreen`).
///
/// Ce service fournit les méthodes métier pour charger, enregistrer les préférences utilisateur,
/// récupérer l'état physique du cache disque local et déclencher les purges.
class SettingsPageService extends ChangeNotifier {
  final SqlitePodcastRepository _sqliteRepository;
  final PodcastCacheManager _cacheManager;

  String language = 'fr';
  String order = 'asc';
  String downloadPolicy = 'always';
  bool isLoading = false;
  String appVersion = '';
  CacheStats cacheStats = CacheStats(totalBytes: 0, count: 0);
  int maxLimit = 0;
  List<Map<String, dynamic>> storageBreakdown = [];
  bool isCacheStatsLoading = false;

  /// Initialise le service de paramètres avec ses dépendances injectées.
  SettingsPageService({
    SqlitePodcastRepository? sqliteRepository,
    PodcastCacheManager? cacheManager,
  })  : _sqliteRepository = sqliteRepository ?? SqlitePodcastRepository(),
        _cacheManager = cacheManager ?? PodcastCacheManager();

  /// Récupère la politique réseau active pour les téléchargements de fichiers MP3.
  ///
  /// **Utilité** : Lit la valeur de politique réseau (Wi-Fi uniquement ou Mobile autorisés) stockée localement.
  /// **Point d'entrée** : Appelé à l'initialisation de l'écran des paramètres.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si la valeur par défaut change.
  Future<String> getDownloadNetworkPolicy() async {
    return await _sqliteRepository.getDownloadNetworkPolicy();
  }

  /// Sauvegarde la politique réseau pour les téléchargements.
  ///
  /// **Utilité** : Enregistre le réglage utilisateur dans la table settings.
  /// **Point d'entrée** : Appelé lorsque l'utilisateur modifie la valeur d'autorisation dans les réglages.
  /// **Maintenance** : Modifier si les valeurs d'énumération réseau permises changent.
  Future<void> setDownloadNetworkPolicy(String policy) async {
    await _sqliteRepository.setDownloadNetworkPolicy(policy);
  }

  /// Récupère l'espace de stockage consommé par le cache d'épisodes téléchargés.
  ///
  /// **Utilité** : Calcule le nombre de fichiers MP3 et leur taille cumulée sur le disque.
  /// **Point d'entrée** : Appelé pour alimenter la barre d'occupation du cache dans l'UI.
  /// **Maintenance** : Modifier si de nouvelles mesures de stockage (ex: espace restant sur l'appareil) sont requises.
  Future<CacheStats> getCachedEpisodesStats() async {
    return await _cacheManager.getCachedEpisodesStats();
  }

  /// Récupère le détail de la consommation de cache par podcast.
  ///
  /// **Utilité** : Calcule l'espace disque occupé pour chaque podcast abonné.
  /// **Point d'entrée** : Appelé pour afficher la liste de répartition par podcast dans les paramètres.
  /// **Maintenance** : Modifier si la requête SQL sous-jacente doit exclure certains types de podcasts.
  Future<List<Map<String, dynamic>>> getStorageBreakdownPerPodcast() async {
    return await _sqliteRepository.getStorageBreakdownPerPodcast();
  }

  /// Vide l'intégralité du cache (fichiers MP3 et listes d'affinités).
  ///
  /// **Utilité** : Supprime physiquement tous les fichiers MP3 de l'appareil, réinitialise les états en BDD, et efface le cache de la liste d'affinités.
  /// **Point d'entrée** : Appelé lors du clic sur le bouton "Vide le cache" dans les paramètres.
  /// **Maintenance** : Modifier si les dossiers ou types de fichiers à supprimer lors de la purge s'élargissent (ex: fichiers de log).
  Future<void> clearAllCache() async {
    isLoading = true;
    notifyListeners();

    try {
      // 1. Purger le cache des fichiers MP3 téléchargés
      await DownloadManager().clearAllCache();

      // 2. Purger les clés SharedPreferences pour l'affinité
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('affinity_podcasts_cache');

      // 3. Notifier l'UI via le listRefreshNotifier centralisé
      app_audio.AudioService().listRefreshNotifier.value++;

      // 4. Invalider les stats locales
      DatabaseRepository.invalidateCacheStats();
      _cacheManager.notify();

      // 5. Recalculer les stats locales
      await refresh();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Recharge toutes les préférences utilisateur et les statistiques de stockage.
  ///
  /// **Utilité** : Charge l'ensemble des réglages locaux (langue, tri, politique, version de l'app, stats et répartition du cache) et notifie les écouteurs.
  /// **Point d'entrée** : Appelé lors du premier chargement ou de la mise à jour des statistiques de stockage.
  /// **Maintenance** : Si de nouvelles préférences ou statistiques sont ajoutées, les charger ici.
  Future<void> refresh() async {
    isCacheStatsLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      language = prefs.getString('podstream_lang') ?? 'fr';
      order = prefs.getString('podstream_order') ?? 'asc';
      downloadPolicy = await getDownloadNetworkPolicy();

      try {
        final packageInfo = await PackageInfo.fromPlatform();
        appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      } catch (_) {
        appVersion = '3.4.2 (342)';
      }

      cacheStats = await getCachedEpisodesStats();
      maxLimit = await AppSettings.getMaxCacheSize();
      storageBreakdown = await getStorageBreakdownPerPodcast();
    } catch (_) {
      // Ignorer
    } finally {
      isCacheStatsLoading = false;
      notifyListeners();
    }
  }

  /// Enregistre une préférence utilisateur.
  ///
  /// **Utilité** : Enregistre localement la langue ou le tri préféré, met à jour l'état et notifie.
  /// **Point d'entrée** : Changement d'option de langue ou de tri dans l'UI.
  /// **Maintenance** : Si d'autres SharedPreferences doivent être synchronisées, modifier ici.
  Future<void> saveSettings(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    if (key == 'podstream_lang') language = value;
    if (key == 'podstream_order') order = value;
    notifyListeners();
  }

  /// Enregistre la politique de téléchargement.
  ///
  /// **Utilité** : Met à jour la politique réseau locale, met à jour l'état et notifie.
  /// **Point d'entrée** : Modification de la politique de téléchargement dans l'UI.
  /// **Maintenance** : Aucune.
  Future<void> saveDownloadPolicy(String value) async {
    await setDownloadNetworkPolicy(value);
    downloadPolicy = value;
    notifyListeners();
  }
}
