import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_repository.dart';
import 'database_helper.dart';
import '../models/app_settings.dart';

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
      // Exécuter l'audit anti-zombie au démarrage (v6)
      await auditStorage();
      // Exécuter la réparation des tailles de fichiers nulles (v6)
      await DatabaseRepository().repairZeroSizeEpisodes();
    } catch (e) {
//       debugPrint("DownloadManager: Erreur d'initialisation de la queue : $e");
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

//       debugPrint(
//           "DownloadManager: Début des téléchargements automatiques en Wi-Fi...");

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
//       debugPrint(
//           "DownloadManager: Erreur lors du déclenchement automatique : $e");
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
        final dbPath = row['localPath'] as String;
        try {
          // 1. Mettre à jour la base de données en premier pour conserver la cohérence de la SSOT
          await DatabaseRepository().updateEpisodeLocalPath(episodeId, null);

          // 2. Supprimer ensuite le fichier physique. Si cela échoue (ex: verrouillé),
          // le fichier devenu orphelin (zombie) sera supprimé par auditStorage() au démarrage suivant.
          final resolvedPath = await _resolveToAbsolutePath(dbPath);
          if (resolvedPath != null) {
            final file = File(resolvedPath);
            if (await file.exists()) {
              await file.delete();
            }
          }
//           debugPrint(
//               "DownloadManager: Suppression de l'ancien téléchargement de l'épisode $episodeId");
        } catch (e) {
//           debugPrint(
//               "DownloadManager: Erreur lors du nettoyage de l'épisode $episodeId: $e");
        }
      }
    } catch (e) {
//       debugPrint("DownloadManager: Erreur lors de cleanupOldDownloads : $e");
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

  /// Résout un chemin stocké en base (qu'il soit absolu ou relatif) en chemin absolu valide
  Future<String?> _resolveToAbsolutePath(String? dbPath) async {
    if (dbPath == null || dbPath.isEmpty) return null;
    final directory = await getApplicationDocumentsDirectory();
    if (p.isAbsolute(dbPath)) {
      // Si c'est un chemin absolu (ex: de la v5), on vérifie s'il existe directement
      final file = File(dbPath);
      if (await file.exists()) {
        return dbPath;
      }
      // Sinon, on extrait le nom du fichier et on tente de le résoudre dans le répertoire privé
      final fileName = p.basename(dbPath);
      final resolvedFile = File('${directory.path}/downloads/$fileName');
      if (await resolvedFile.exists()) {
        return resolvedFile.path;
      }
      return null;
    } else {
      // Si c'est un chemin relatif (ex: 'downloads/ep_xxx.mp3'), on le résout par rapport au répertoire privé
      final file = File('${directory.path}/$dbPath');
      if (await file.exists()) {
        return file.path;
      }
      return null;
    }
  }

  /// Vérifie si le fichier existe localement et retourne son chemin absolu
  Future<String?> getLocalFilePath(String episodeId) async {
    try {
      final dbPath = await DatabaseRepository().getEpisodeLocalPath(episodeId);
      final resolvedPath = await _resolveToAbsolutePath(dbPath);
      if (resolvedPath != null) {
        return resolvedPath;
      }

      // Fallback ultime : Vérifier par le nom de fichier par défaut
      final directory = await getApplicationDocumentsDirectory();
      final fileName = _getSafeFileName(episodeId);
      final file = File('${directory.path}/downloads/$fileName');
      if (await file.exists()) {
        return file.path;
      }
    } catch (e) {
//       debugPrint("DownloadManager error [getLocalFilePath] for $episodeId: $e");
    }
    return null;
  }

  /// Compare la liste des fichiers sur le disque avec SQLite et supprime les fichiers orphelins.
  /// S'exécute une seule fois au premier démarrage de la version 6.
  Future<void> auditStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasAudited = prefs.getBool('storage_audit_done_v6') ?? false;
      if (hasAudited) {
        return;
      }

//       debugPrint("DownloadManager: Démarrage de l'audit de stockage (v6)...");

      final helper = DatabaseHelper();
      final db = await helper.database;

      // 1. Récupérer tous les localPath valides dans episodes_status
      final List<Map<String, dynamic>> statusResults = await db.query(
        'episodes_status',
        columns: ['localPath'],
        where: 'localPath IS NOT NULL',
      );
      final Set<String> dbPaths = statusResults
          .map((row) => row['localPath'] as String?)
          .where((path) => path != null && path.isNotEmpty)
          .cast<String>()
          .toSet();

      // 2. Récupérer tous les tempPath de la queue de téléchargement
      final List<Map<String, dynamic>> queueResults = await db.query(
        'download_queue',
        columns: ['tempPath'],
      );
      final Set<String> queuePaths = queueResults
          .map((row) => row['tempPath'] as String?)
          .where((path) => path != null && path.isNotEmpty)
          .cast<String>()
          .toSet();

      // 3. Extraire les basenames de tous les fichiers autorisés
      final Set<String> allowedFilenames = {
        ...dbPaths.map((path) => p.basename(path)),
        ...queuePaths.map((path) => p.basename(path)),
      };

      // 4. Parcourir le dossier de téléchargement et supprimer les orphelins (zombies)
      final directory = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${directory.path}/downloads');
      if (await downloadDir.exists()) {
        // int deletedCount = 0;
        final List<FileSystemEntity> files = await downloadDir.list().toList();
        for (var file in files) {
          if (file is File) {
            final filename = p.basename(file.path);

            // Ne toucher qu'aux fichiers audio mp3 ou aux fichiers temporaires .tmp orphelins
            if (filename.endsWith('.mp3') || filename.endsWith('.tmp')) {
              if (!allowedFilenames.contains(filename)) {
                try {
                  await file.delete();
                  // deletedCount++;
//                   debugPrint(
//                       "DownloadManager: auditStorage - Fichier zombie supprimé : $filename");
                } catch (e) {
//                   debugPrint(
//                       "DownloadManager: Impossible de supprimer le fichier zombie $filename : $e");
                }
              }
            }
          }
        }
//         debugPrint(
//             "DownloadManager: auditStorage complété. Fichiers supprimés : $deletedCount");
      } else {
//         debugPrint(
//             "DownloadManager: Le dossier de téléchargements n'existe pas. Aucun audit requis.");
      }

      // 5. Enregistrer le flag de fin d'audit
      await prefs.setBool('storage_audit_done_v6', true);
    } catch (e) {
//       debugPrint("DownloadManager: Erreur lors de l'audit de stockage : $e");
    }
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
//       debugPrint(
//           "DownloadManager: Téléchargement en attente de connexion autorisée pour $episodeId");
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

//       debugPrint(
//           "DownloadManager: Début du téléchargement de $url vers $tempPath");
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

      // Mesurer la taille du fichier téléchargé sur le fichier temporaire avant son renommage
      int fileSize = 0;
      try {
        final tempFile = File(tempPath);
        if (await tempFile.exists()) {
          fileSize = await tempFile.length();
          await tempFile.rename(savePath);
        }
      } catch (e) {
        // Échec silencieux pour le renommage, on tente de forcer le renommage quand même
        try {
          final tempFile = File(tempPath);
          if (await tempFile.exists()) {
            await tempFile.rename(savePath);
          }
        } catch (_) {}
      }

      statusNotifier.value = DownloadStatus.downloaded;
      progressNotifier.value = 1.0;

      // Mettre à jour localPath et fileSize en SQLite
      await DatabaseRepository()
          .updateEpisodeLocalPath(episodeId, savePath, fileSize: fileSize);

      // Retirer de la queue SQLite
      await DatabaseRepository().dequeueDownloadTask(episodeId);

      // Appliquer la limite de stockage LRU de manière active et asynchrone
      await enforceCacheLimit();
    } catch (e) {
      if (CancelToken.isCancel(e as DioException)) {
//         debugPrint(
//             "DownloadManager: Téléchargement annulé par l'utilisateur pour $episodeId");
        statusNotifier.value = DownloadStatus.idle;
        await DatabaseRepository().updateEpisodeDownloadStatus(episodeId, 0);
      } else {
//         debugPrint(
//             "DownloadManager: Erreur de téléchargement pour $episodeId: $e");
        statusNotifier.value = DownloadStatus.failed;
        await DatabaseRepository().updateEpisodeDownloadStatus(episodeId, 2);
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
    DatabaseRepository().updateEpisodeDownloadStatus(episodeId, 0);
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
//           debugPrint(
//               "DownloadManager: Fichier supprimé pour l'épisode $episodeId");
        }
      }
      await DatabaseRepository().updateEpisodeLocalPath(episodeId, null);
      await DatabaseRepository().dequeueDownloadTask(episodeId);
    } catch (e) {
//       debugPrint(
//           "DownloadManager: Erreur lors de la suppression de l'épisode $episodeId: $e");
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
//       debugPrint(
//           "DownloadManager: Impossible de nettoyer le fichier temporaire: $e");
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
//       debugPrint("DownloadManager error [clearCacheExcept]: $e");
    }
  }

  /// Limite activement la taille du stockage des épisodes téléchargés (LRU)
  Future<void> enforceCacheLimit() async {
    try {
      final maxSizeBytes = await AppSettings.getMaxCacheSize();
      final helper = DatabaseHelper();
      final db = await helper.database;

      // 1. Calculer la taille totale actuelle via SQL
      final List<Map<String, dynamic>> sizeResult = await db.rawQuery('''
        SELECT SUM(fileSize) as totalSize 
        FROM episodes_status 
        WHERE localPath IS NOT NULL
      ''');

      int currentBytes = 0;
      if (sizeResult.isNotEmpty && sizeResult.first['totalSize'] != null) {
        currentBytes = sizeResult.first['totalSize'] as int;
      }

      if (currentBytes <= maxSizeBytes) {
        return; // Le cache respecte déjà la limite
      }

      // 2. Récupérer les candidats à la suppression (triés par isRead DESC (lus d'abord) et pubDate ASC (anciens d'abord))
      final List<Map<String, dynamic>> candidates = await db.rawQuery('''
        SELECT s.episodeId, s.fileSize
        FROM episodes_status s
        LEFT JOIN episodes_metadata m ON s.episodeId = m.episodeId
        WHERE s.localPath IS NOT NULL
        ORDER BY s.isRead DESC, m.pubDate ASC
      ''');

      for (var row in candidates) {
        if (currentBytes <= maxSizeBytes) break;

        final episodeId = row['episodeId'] as String;
        final fileSize = row['fileSize'] as int? ?? 0;

        // Supprimer physiquement et mettre à jour la base de données + UI notifiers
        await deleteDownloadedEpisode(episodeId);

        currentBytes -= fileSize;
      }
    } catch (e) {
      // Échec silencieux
    }
  }

  /// Supprime absolument tous les fichiers téléchargés (cache complet) de manière robuste.
  Future<void> clearAllCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${directory.path}/downloads');
      if (await downloadDir.exists()) {
        final List<FileSystemEntity> files = await downloadDir.list().toList();
        for (var file in files) {
          if (file is File) {
            final filename = p.basename(file.path);
            if (filename.endsWith('.mp3') || filename.endsWith('.tmp')) {
              try {
                await file.delete();
              } catch (_) {
                // Capturer l'échec de suppression de chaque fichier individuel (ex: s'il est verrouillé)
              }
            }
          }
        }
      }

      // Mettre à jour SQLite de manière cohérente pour les fichiers réellement supprimés
      final helper = DatabaseHelper();
      final db = await helper.database;

      // Récupérer tous les épisodes avec un localPath
      final List<Map<String, dynamic>> results = await db.query(
        'episodes_status',
        columns: ['episodeId', 'localPath'],
        where: 'localPath IS NOT NULL',
      );

      await db.transaction((txn) async {
        for (var row in results) {
          final episodeId = row['episodeId'] as String;
          final dbPath = row['localPath'] as String;
          final resolvedPath = await _resolveToAbsolutePath(dbPath);

          bool stillExists = false;
          if (resolvedPath != null) {
            stillExists = await File(resolvedPath).exists();
          }

          if (!stillExists) {
            // Le fichier a bien été supprimé
            await txn.update(
              'episodes_status',
              {
                'localPath': null,
                'status': 0,
                'fileSize': 0,
              },
              where: 'episodeId = ?',
              whereArgs: [episodeId],
            );

            // Réinitialiser les notificateurs en mémoire correspondants
            _statusNotifiers[episodeId]?.value = DownloadStatus.idle;
            _progressNotifiers[episodeId]?.value = 0.0;
          }
        }
      });

      // Invalider le cache des statistiques
      DatabaseRepository.invalidateCacheStats();
    } catch (e) {
      // Échec silencieux global
    }
  }

  /// Alias asynchrone pour télécharger un épisode
  Future<void> download(String episodeId, String url) async {
    await downloadEpisode(episodeId, url);
  }
}
