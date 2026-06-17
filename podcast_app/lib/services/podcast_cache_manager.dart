import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'download_manager.dart';
import 'sqlite_podcast_repository.dart';
import 'database_repository.dart'; // Pour la compatibilité des classes CacheStats et EpisodeCacheInfo
import '../models/episode_model.dart';
import '../models/app_settings.dart';
import 'itunes_gateway.dart';

/// Gestionnaire de cache pour les fichiers audio téléchargés dans PodStream.
///
/// **Utilité** : Gère le cycle de vie intelligent du cache audio (priorisation par liste + purge FIFO).
/// **Point d'entrée** : Appelé lors de la mise à jour de la file d'écoute ou du rafraîchissement manuel.
/// **Maintenance** : Si la logique FIFO doit devenir LRU (Least Recently Used), modifier la méthode _identifyOldestEpisodes ici.
/// Si la structure des données change, cela peut impacter les ListenableBuilder associés dans l'UI (ex: SettingsScreen, MyPodcastsTab).
class PodcastCacheManager extends ChangeNotifier {
  final SqlitePodcastRepository _sqliteRepository;
  final Map<String, dynamic> _inMemoryCache = {};

  bool isProcessing = false;
  String? errorMessage;
  CacheStats? cacheStats;

  /// Initialise le gestionnaire avec un dépôt SQLite injecté.
  PodcastCacheManager({SqlitePodcastRepository? sqliteRepository})
      : _sqliteRepository = sqliteRepository ?? SqlitePodcastRepository();

  /// Vérifie si une clé existe dans le cache mémoire temporaire.
  ///
  /// **Utilité** : Évite les allers-retours vers la base de données pour les listes statiques.
  /// **Point d'entrée** : Appelé par le service de données pour vérifier la fraîcheur d'un chargement.
  /// **Maintenance** : Modifier si les clés de cache ou les politiques d'invalidation mémoire changent.
  bool hasKey(String key) {
    return _inMemoryCache.containsKey(key);
  }

  /// Lit une valeur depuis le cache mémoire.
  ///
  /// **Utilité** : Récupère les données en mémoire.
  /// **Point d'entrée** : Utilisé pour éviter des requêtes répétées.
  /// **Maintenance** : Pas de maintenance particulière nécessaire sauf si le typage des retours change.
  dynamic read(String key) {
    return _inMemoryCache[key];
  }

  /// Écrit une valeur dans le cache mémoire.
  ///
  /// **Utilité** : Enregistre des données temporaires en mémoire RAM.
  /// **Point d'entrée** : Appelé après chaque récupération réseau pour stocker le résultat en mémoire.
  /// **Maintenance** : Modifier si une expiration temporelle de la RAM est nécessaire.
  void write(String key, dynamic data) {
    _inMemoryCache[key] = data;
  }

  /// Supprime une valeur du cache mémoire.
  ///
  /// **Utilité** : Force l'invalidation d'une clé de cache RAM.
  /// **Point d'entrée** : Appelé lors d'un désabonnement ou d'une mise à jour de liste.
  /// **Maintenance** : Modifier si le nettoyage mémoire doit déclencher d'autres événements.
  void remove(String key) {
    _inMemoryCache.remove(key);
  }

  /// Notifie tous les écouteurs de changements (par exemple, pour forcer le rafraîchissement d'écrans).
  ///
  /// **Utilité** : Déclenche les builders de l'UI liés au stockage.
  /// **Point d'entrée** : Appelé après un nettoyage ou vidage de cache réussi.
  /// **Maintenance** : Aucune.
  void notify() {
    notifyListeners();
  }

  /// Interroge SQLite pour retourner les statistiques en temps réel de l'utilisation du cache.
  ///
  /// **Utilité** : Calcule le nombre d'épisodes téléchargés et l'espace occupé (octets).
  /// **Point d'entrée** : Appelé à l'affichage des réglages de stockage (`SettingsScreen`).
  /// **Maintenance** : Modifier si de nouvelles mesures de statistiques (ex: espace libre) sont requises.
  Future<CacheStats> getCachedEpisodesStats() async {
    final stats = await _sqliteRepository.getCachedEpisodesStats();
    cacheStats = stats;
    return stats;
  }

  /// Résout un chemin de base de données en chemin absolu valide sur l'appareil.
  ///
  /// **Utilité** : Gère les chemins absolus et relatifs en localisant le fichier MP3 physique dans le répertoire documents.
  /// **Point d'entrée** : Appelé lors du nettoyage physique ou de la suppression d'épisodes sur disque.
  /// **Maintenance** : Modifier si l'arborescence des dossiers système évolue ou si le dossier `downloads` est déplacé.
  Future<String?> _resolveToAbsolutePath(String? dbPath) async {
    if (dbPath == null || dbPath.isEmpty) return null;
    final directory = await getApplicationDocumentsDirectory();
    if (p.isAbsolute(dbPath)) {
      final file = File(dbPath);
      if (await file.exists()) {
        return dbPath;
      }
      final fileName = p.basename(dbPath);
      final resolvedFile = File('${directory.path}/downloads/$fileName');
      if (await resolvedFile.exists()) {
        return resolvedFile.path;
      }
      return null;
    } else {
      final file = File('${directory.path}/$dbPath');
      if (await file.exists()) {
        return file.path;
      }
      return null;
    }
  }

  /// Identifie les épisodes les plus anciens dans le cache physique.
  ///
  /// **Utilité** : Identifie les épisodes à purger en priorité.
  /// **Point d'entrée** : Appelé par la méthode `_enforceCacheLimitInternal`.
  /// **Maintenance** : Si la logique FIFO doit devenir LRU (Least Recently Used), modifier la méthode _identifyOldestEpisodes ici.
  Future<List<EpisodeCacheInfo>> _identifyOldestEpisodes() async {
    return await _sqliteRepository.getCacheCandidates();
  }

  /// Implémentation interne de la purge sous contrainte d'espace sans verrouillage isProcessing pour éviter les deadlocks.
  Future<void> _enforceCacheLimitInternal(int maxStorageMB,
      [int requiredSpaceBytes = 0, List<String>? protectedEpisodeIds]) async {
    final int hardLimit = maxStorageMB * 1024 * 1024;
    final int targetLimit = requiredSpaceBytes > 0
        ? hardLimit - requiredSpaceBytes
        : (hardLimit * 0.9).toInt();

    int currentBytes = await _sqliteRepository.getTotalCacheSize();

    final int limitToCheck = requiredSpaceBytes > 0 ? targetLimit : hardLimit;
    if (currentBytes <= limitToCheck) {
      return; // Le cache respecte déjà la limite
    }

    final List<EpisodeCacheInfo> candidates = await _identifyOldestEpisodes();
    final List<String> removedEpisodeIds = [];

    for (var row in candidates) {
      if (currentBytes <= targetLimit) break;

      final episodeId = row.episodeId;
      final fileSize = row.fileSize;
      final dbPath = row.localPath;

      if (protectedEpisodeIds != null &&
          protectedEpisodeIds.contains(episodeId)) {
        continue; // Ignorer la purge des épisodes prioritaires
      }

      if (dbPath != null) {
        final resolvedPath = await _resolveToAbsolutePath(dbPath);
        if (resolvedPath != null) {
          final file = File(resolvedPath);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }

      removedEpisodeIds.add(episodeId);

      // Mise à jour de l'UI en mémoire pour les indicateurs de téléchargement
      DownloadManager().getStatusNotifier(episodeId).value =
          DownloadStatus.idle;
      DownloadManager().getProgressNotifier(episodeId).value = 0.0;

      currentBytes -= fileSize;
    }

    if (removedEpisodeIds.isNotEmpty) {
      await _sqliteRepository.removeEpisodesFromCache(removedEpisodeIds);
    }

    DatabaseRepository.invalidateCacheStats();
    await getCachedEpisodesStats();
  }

  /// Purge le cache selon la taille maximale spécifiée (en Mo) en appliquant le principe FIFO (les plus anciens d'abord).
  ///
  /// **Utilité** : Limite l'espace disque consommé par l'application sous le seuil maximal.
  /// **Point d'entrée** : Appelé de manière asynchrone après chaque fin de téléchargement d'épisode.
  /// **Maintenance** : Si le calcul de la limite ou de l'espace requis change, adapter ici.
  Future<void> enforceCacheLimit(int maxStorageMB,
      [int requiredSpaceBytes = 0, List<String>? protectedEpisodeIds]) async {
    if (isProcessing) return;
    isProcessing = true;
    errorMessage = null;
    try {
      await _enforceCacheLimitInternal(
          maxStorageMB, requiredSpaceBytes, protectedEpisodeIds);
      notifyListeners();
    } catch (e) {
      errorMessage = "Échec de la purge du cache audio : ${e.toString()}";
      notifyListeners();
      rethrow;
    } finally {
      isProcessing = false;
    }
  }

  /// **Utilité** : Gère le téléchargement intelligent sous contrainte d'espace.
  ///
  /// **Point d'entrée** : Appelé lors de la préparation de la playlist ou de l'actualisation du flux.
  ///
  /// **Maintenance** : Si la règle de calcul de poids (taille octet) change, modifier la méthode `_calculateTotalSize` ici.
  Future<void> loadEpisodes(List<EpisodeModel> episodes) async {
    if (isProcessing) return;
    isProcessing = true;
    errorMessage = null;
    try {
      final int maxCacheSize = await AppSettings.getMaxCacheSize();
      final int maxStorageMB = maxCacheSize ~/ (1024 * 1024);

      final List<String> protectedEpisodeIds =
          episodes.map((e) => e.id).toList();

      // Calcul de poids total
      final int totalWeight = await _calculateTotalSize(episodes);

      if (totalWeight <= maxCacheSize) {
        // Charger tous les épisodes
        await _enforceCacheLimitInternal(
            maxStorageMB, totalWeight, protectedEpisodeIds);

        for (var ep in episodes) {
          await DownloadManager().downloadEpisode(ep.id, ep.audioUrl);
        }
      } else {
        // Charger uniquement les épisodes jusqu'à ce que la limite soit atteinte
        int runningSum = 0;
        for (var ep in episodes) {
          int size = await _sqliteRepository.getEpisodeFileSize(ep.id);
          if (size == 0) {
            try {
              size = await ITunesGateway().getUrlFileSize(ep.audioUrl);
            } catch (_) {}
          }
          if (size == 0) {
            size = 30 * 1024 * 1024;
          }

          if (size > maxCacheSize) {
            continue; // Cet épisode dépasse à lui seul la limite maxCacheSize, on le saute
          }

          if (runningSum + size <= maxCacheSize) {
            runningSum += size;

            // Purger pour faire de la place pour cet épisode particulier
            await _enforceCacheLimitInternal(
                maxStorageMB, size, protectedEpisodeIds);

            await DownloadManager().downloadEpisode(ep.id, ep.audioUrl);
          } else {
            break; // Respect strict de l'ordre, on s'arrête
          }
        }
      }

      await getCachedEpisodesStats();
      notifyListeners();
    } catch (e) {
      errorMessage =
          "Erreur lors du téléchargement des épisodes : ${e.toString()}";
      notifyListeners();
    } finally {
      isProcessing = false;
    }
  }

  /// **Maintenance** : Si la règle de calcul de poids (taille octet) change, modifier la méthode `_calculateTotalSize` ici.
  Future<int> _calculateTotalSize(List<EpisodeModel> episodes) async {
    int total = 0;
    for (var ep in episodes) {
      int size = await _sqliteRepository.getEpisodeFileSize(ep.id);
      if (size == 0) {
        try {
          size = await ITunesGateway().getUrlFileSize(ep.audioUrl);
        } catch (_) {}
      }
      if (size == 0) {
        size = 30 * 1024 * 1024; // 30 MB par défaut
      }
      total += size;
    }
    return total;
  }
}
