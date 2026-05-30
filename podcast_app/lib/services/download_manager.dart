import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'database_repository.dart';
import 'database_helper.dart';

enum DownloadStatus {
  idle,
  downloading,
  downloaded,
  failed,
}

class DownloadManager {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal() {
    // Initialiser la file de téléchargement persistante au démarrage de l'app
    _initQueue();
    // Écouter les changements de connexion réseau pour relancer les téléchargements en attente si nécessaire
    Connectivity().onConnectivityChanged.listen((results) {
      _onConnectivityChanged(results);
    });
  }

  final Dio _dio = Dio();
  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, ValueNotifier<double>> _progressNotifiers = {};
  final Map<String, ValueNotifier<DownloadStatus>> _statusNotifiers = {};

  /// Charge et relance la queue persistante SQLite au démarrage
  Future<void> _initQueue() async {
    try {
      final tasks = await DatabaseRepository().getDownloadQueueTasks();
      for (var task in tasks) {
        final episodeId = task['episodeId'] as String;
        final audioUrl = task['audioUrl'] as String;
        // Relancer le téléchargement de manière asynchrone
        downloadEpisode(episodeId, audioUrl);
      }
      // Effectuer aussi un nettoyage des vieux épisodes téléchargés (> 7 jours et lus)
      await cleanupOldDownloads();
    } catch (e) {
      debugPrint("DownloadManager: Erreur d'initialisation de la queue : $e");
    }
  }

  /// Appelé lors d'un changement de statut de connexion pour relancer la file d'attente
  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    if (results.contains(ConnectivityResult.none)) return;

    // Si on retrouve de la connexion, on ré-évalue les téléchargements manqués
    final tasks = await DatabaseRepository().getDownloadQueueTasks();
    if (tasks.isNotEmpty) {
      final policy = await DatabaseRepository().getDownloadNetworkPolicy();
      final allowed = await isDownloadAllowed(policy);
      if (allowed) {
        for (var task in tasks) {
          final episodeId = task['episodeId'] as String;
          final audioUrl = task['audioUrl'] as String;
          if (getStatusNotifier(episodeId).value !=
              DownloadStatus.downloading) {
            downloadEpisode(episodeId, audioUrl);
          }
        }
      }
    }

    // Si on se connecte en Wi-Fi, on déclenche les téléchargements automatiques
    if (results.contains(ConnectivityResult.wifi)) {
      triggerAutoDownloads();
    }
  }

  /// Détermine si un téléchargement est autorisé selon la politique réseau de l'utilisateur
  Future<bool> isDownloadAllowed(String policy) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return false;
    }
    if (policy == 'wifiOnly') {
      return connectivityResult.contains(ConnectivityResult.wifi);
    }
    return true; // policy == 'always'
  }

  /// Déclenche le téléchargement automatique des épisodes en Wi-Fi
  Future<void> triggerAutoDownloads() async {
    try {
      final policy = await DatabaseRepository().getDownloadNetworkPolicy();
      final allowed = await isDownloadAllowed(policy);
      if (!allowed) return;

      debugPrint(
          "DownloadManager: Début des téléchargements automatiques en Wi-Fi...");

      // Récupérer les épisodes de la liste "À écouter"
      final episodes = await DatabaseRepository().getEpisodesToListen();

      // On télécharge au maximum les 3 premiers épisodes non téléchargés pour ne pas saturer
      int enqueuedCount = 0;
      for (var ep in episodes) {
        if (enqueuedCount >= 3) break;
        final localPath = await getLocalFilePath(ep.id);
        if (localPath == null) {
          downloadEpisode(ep.id, ep.audioUrl);
          enqueuedCount++;
        }
      }
    } catch (e) {
      debugPrint(
          "DownloadManager: Erreur lors du déclenchement automatique : $e");
    }
  }

  /// Supprime les fichiers téléchargés d'épisodes marqués comme "lus" depuis plus de 7 jours
  Future<void> cleanupOldDownloads() async {
    try {
      final helper = DatabaseHelper();
      final db = await helper.database;
      final sevenDaysAgo = DateTime.now()
          .subtract(const Duration(days: 7))
          .millisecondsSinceEpoch;

      final List<Map<String, dynamic>> toClean = await db.query(
        'episodes_status',
        columns: ['episodeId', 'localPath'],
        where: 'isRead = 1 AND readAt < ? AND localPath IS NOT NULL',
        whereArgs: [sevenDaysAgo],
      );

      if (toClean.isEmpty) return;

      for (var row in toClean) {
        final episodeId = row['episodeId'] as String;
        final localPath = row['localPath'] as String;
        try {
          final file = File(localPath);
          if (await file.exists()) {
            await file.delete();
          }
          await DatabaseRepository().updateEpisodeLocalPath(episodeId, null);
          debugPrint(
              "DownloadManager: Suppression de l'ancien téléchargement de l'épisode $episodeId");
        } catch (e) {
          debugPrint(
              "DownloadManager: Impossible de supprimer le fichier $localPath: $e");
        }
      }
    } catch (e) {
      debugPrint("DownloadManager: Erreur lors de cleanupOldDownloads : $e");
    }
  }

  /// Récupère le notificateur de progression en pourcentage (0.0 à 1.0)
  ValueNotifier<double> getProgressNotifier(String episodeId) {
    return _progressNotifiers.putIfAbsent(
        episodeId, () => ValueNotifier<double>(0.0));
  }

  /// Récupère le notificateur de statut pour un épisode donné et initialise son état
  ValueNotifier<DownloadStatus> getStatusNotifier(String episodeId) {
    return _statusNotifiers.putIfAbsent(episodeId, () {
      final notifier = ValueNotifier<DownloadStatus>(DownloadStatus.idle);
      _initializeStatus(episodeId, notifier);
      return notifier;
    });
  }

  /// Initialise de manière asynchrone le statut d'un épisode (si le fichier existe sur disque)
  Future<void> _initializeStatus(
      String episodeId, ValueNotifier<DownloadStatus> notifier) async {
    final path = await getLocalFilePath(episodeId);
    if (path != null) {
      notifier.value = DownloadStatus.downloaded;
      getProgressNotifier(episodeId).value = 1.0;
    } else {
      notifier.value = DownloadStatus.idle;
      getProgressNotifier(episodeId).value = 0.0;
    }
  }

  /// Génère un nom de fichier unique et sécurisé à partir de l'episodeId
  String _getSafeFileName(String episodeId) {
    final sanitized = episodeId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final shortName = sanitized.length > 100
        ? sanitized.substring(sanitized.length - 100)
        : sanitized;
    final hashSuffix = episodeId.hashCode.toRadixString(16);
    return 'ep_${hashSuffix}_$shortName.mp3';
  }

  /// Vérifie si le fichier existe localement et retourne son chemin absolu
  Future<String?> getLocalFilePath(String episodeId) async {
    try {
      final dbPath = await DatabaseRepository().getEpisodeLocalPath(episodeId);
      if (dbPath != null && dbPath.isNotEmpty) {
        final file = File(dbPath);
        if (await file.exists()) {
          return dbPath;
        }
      }

      // Fallback : Vérifier par le nom de fichier par défaut
      final directory = await getApplicationDocumentsDirectory();
      final fileName = _getSafeFileName(episodeId);
      final file = File('${directory.path}/downloads/$fileName');
      if (await file.exists()) {
        return file.path;
      }
    } catch (e) {
      debugPrint("DownloadManager error [getLocalFilePath] for $episodeId: $e");
    }
    return null;
  }

  /// Télécharge un épisode de manière asynchrone
  Future<void> downloadEpisode(String episodeId, String url) async {
    final statusNotifier = getStatusNotifier(episodeId);
    final progressNotifier = getProgressNotifier(episodeId);

    if (statusNotifier.value == DownloadStatus.downloading) {
      return;
    }
    if (statusNotifier.value == DownloadStatus.downloaded) {
      final existingPath = await getLocalFilePath(episodeId);
      if (existingPath != null) {
        return;
      }
    }

    // 1. Vérifier si les autorisations réseau permettent le téléchargement
    final policy = await DatabaseRepository().getDownloadNetworkPolicy();
    final allowed = await isDownloadAllowed(policy);
    if (!allowed) {
      debugPrint(
          "DownloadManager: Téléchargement en attente de connexion autorisée pour $episodeId");
      statusNotifier.value = DownloadStatus.idle;
      // Enregistrer dans la queue persistante pour reprise ultérieure
      final directory = await getApplicationDocumentsDirectory();
      final savePath =
          '${directory.path}/downloads/${_getSafeFileName(episodeId)}';
      await DatabaseRepository()
          .enqueueDownloadTask(episodeId, url, '$savePath.tmp');
      return;
    }

    final cancelToken = CancelToken();
    _cancelTokens[episodeId] = cancelToken;

    try {
      statusNotifier.value = DownloadStatus.downloading;
      progressNotifier.value = 0.0;

      final directory = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${directory.path}/downloads');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final fileName = _getSafeFileName(episodeId);
      final savePath = '${downloadDir.path}/$fileName';
      final tempPath = '$savePath.tmp';

      // Enregistrer dans la file SQLite
      await DatabaseRepository().enqueueDownloadTask(episodeId, url, tempPath);

      debugPrint(
          "DownloadManager: Début du téléchargement de $url vers $tempPath");
      await _dio.download(
        url,
        tempPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final percentage = received / total;
            progressNotifier.value = percentage;
          }
        },
      );

      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        await tempFile.rename(savePath);
      }

      debugPrint(
          "DownloadManager: Téléchargement complété pour $episodeId. Enregistré sous $savePath");
      statusNotifier.value = DownloadStatus.downloaded;
      progressNotifier.value = 1.0;

      // Mettre à jour localPath en SQLite
      await DatabaseRepository().updateEpisodeLocalPath(episodeId, savePath);

      // Retirer de la queue SQLite
      await DatabaseRepository().dequeueDownloadTask(episodeId);
    } catch (e) {
      if (CancelToken.isCancel(e as DioException)) {
        debugPrint(
            "DownloadManager: Téléchargement annulé par l'utilisateur pour $episodeId");
        statusNotifier.value = DownloadStatus.idle;
      } else {
        debugPrint(
            "DownloadManager: Erreur de téléchargement pour $episodeId: $e");
        statusNotifier.value = DownloadStatus.failed;
      }

      await _cleanupTempFile(episodeId);
    } finally {
      _cancelTokens.remove(episodeId);
    }
  }

  /// Annule le téléchargement en cours d'un épisode
  void cancelDownload(String episodeId) {
    final cancelToken = _cancelTokens[episodeId];
    if (cancelToken != null) {
      cancelToken.cancel();
      _cancelTokens.remove(episodeId);
    }
    DatabaseRepository().dequeueDownloadTask(episodeId);
  }

  /// Supprime le fichier d'épisode téléchargé
  Future<void> deleteDownloadedEpisode(String episodeId) async {
    try {
      final path = await getLocalFilePath(episodeId);
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
          debugPrint(
              "DownloadManager: Fichier supprimé pour l'épisode $episodeId");
        }
      }
      await DatabaseRepository().updateEpisodeLocalPath(episodeId, null);
      await DatabaseRepository().dequeueDownloadTask(episodeId);
    } catch (e) {
      debugPrint(
          "DownloadManager: Erreur lors de la suppression de l'épisode $episodeId: $e");
    } finally {
      _progressNotifiers[episodeId]?.value = 0.0;
      _statusNotifiers[episodeId]?.value = DownloadStatus.idle;
    }
  }

  /// Supprime un fichier temporaire .tmp s'il existe
  Future<void> _cleanupTempFile(String episodeId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = _getSafeFileName(episodeId);
      final tempFile = File('${directory.path}/downloads/$fileName.tmp');
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (e) {
      debugPrint(
          "DownloadManager: Impossible de nettoyer le fichier temporaire: $e");
    }
  }

  /// Supprime tous les fichiers cache (mp3 et tmp) sauf celui de l'épisode spécifié.
  Future<void> clearCacheExcept(String episodeId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${directory.path}/downloads');
      if (await downloadDir.exists()) {
        final safeName = _getSafeFileName(episodeId);
        final safeTempName = '$safeName.tmp';

        final List<FileSystemEntity> files = await downloadDir.list().toList();
        for (var file in files) {
          if (file is File) {
            final filename = p.basename(file.path);
            if ((filename.endsWith('.mp3') || filename.endsWith('.tmp')) &&
                filename != safeName &&
                filename != safeTempName) {
              try {
                await file.delete();
                // Chercher l'ID de l'épisode correspondant au nom de fichier pour mettre à jour SQLite si nécessaire
                // (Optionnel car clearCacheExcept est un nettoyage du cache temporaire de lecture)
              } catch (_) {}
            }
          }
        }
      }

      _statusNotifiers.forEach((key, notifier) {
        if (key != episodeId && notifier.value != DownloadStatus.idle) {
          notifier.value = DownloadStatus.idle;
        }
      });
      _progressNotifiers.forEach((key, notifier) {
        if (key != episodeId && notifier.value != 0.0) {
          notifier.value = 0.0;
        }
      });
    } catch (e) {
      debugPrint("DownloadManager error [clearCacheExcept]: $e");
    }
  }

  /// Alias asynchrone pour télécharger un épisode
  Future<void> download(String episodeId, String url) async {
    await downloadEpisode(episodeId, url);
  }
}
