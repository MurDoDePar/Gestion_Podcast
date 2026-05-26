import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

enum DownloadStatus {
  idle,
  downloading,
  downloaded,
  failed,
}

class DownloadService {
  // Pattern Singleton pour garantir une unique instance dans toute l'application
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final Dio _dio = Dio();

  // Registry des tokens d'annulation pour les téléchargements actifs
  final Map<String, CancelToken> _cancelTokens = {};

  // Registries de notificateurs réactifs pour l'UI et les écouteurs de statut
  final Map<String, ValueNotifier<double>> _progressNotifiers = {};
  final Map<String, ValueNotifier<DownloadStatus>> _statusNotifiers = {};

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
    // Évite les caractères non autorisés par les différents OS
    final sanitized = episodeId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    // Limite la taille pour ne pas dépasser les contraintes du système de fichiers
    final shortName = sanitized.length > 100
        ? sanitized.substring(sanitized.length - 100)
        : sanitized;
    final hashSuffix = episodeId.hashCode.toRadixString(16);
    return 'ep_${hashSuffix}_$shortName.mp3';
  }

  /// Vérifie si le fichier existe localement et retourne son chemin absolu
  /// Si le fichier n'existe pas, retourne null
  Future<String?> getLocalFilePath(String episodeId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = _getSafeFileName(episodeId);
      final file = File('${directory.path}/downloads/$fileName');
      if (await file.exists()) {
        return file.path;
      }
    } catch (e) {
      debugPrint("DownloadService error [getLocalFilePath] for $episodeId: $e");
    }
    return null;
  }

  /// Télécharge un épisode de manière asynchrone
  Future<void> downloadEpisode(String episodeId, String url) async {
    final statusNotifier = getStatusNotifier(episodeId);
    final progressNotifier = getProgressNotifier(episodeId);

    // 1. Éviter les accès concurrents ou les téléchargements redondants
    if (statusNotifier.value == DownloadStatus.downloading) {
      debugPrint(
          "DownloadService: Téléchargement déjà en cours pour l'épisode $episodeId");
      return;
    }
    if (statusNotifier.value == DownloadStatus.downloaded) {
      final existingPath = await getLocalFilePath(episodeId);
      if (existingPath != null) {
        debugPrint(
            "DownloadService: Épisode $episodeId déjà téléchargé localement.");
        return;
      }
    }

    // Création d'un token d'annulation pour cette opération
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

      // Utilisation d'un fichier temporaire .tmp pour éviter de valider des téléchargements corrompus / partiels
      final tempPath = '$savePath.tmp';

      debugPrint(
          "DownloadService: Début du téléchargement de $url vers $tempPath");
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

      // Renommer le fichier temporaire en fichier final
      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        await tempFile.rename(savePath);
      }

      debugPrint(
          "DownloadService: Téléchargement complété avec succès pour $episodeId. Enregistré sous $savePath");
      statusNotifier.value = DownloadStatus.downloaded;
      progressNotifier.value = 1.0;
    } catch (e) {
      if (CancelToken.isCancel(e as DioException)) {
        debugPrint(
            "DownloadService: Téléchargement annulé par l'utilisateur pour l'épisode $episodeId");
        statusNotifier.value = DownloadStatus.idle;
      } else {
        debugPrint(
            "DownloadService: Erreur de téléchargement pour $episodeId: $e");
        statusNotifier.value = DownloadStatus.failed;
      }

      // Nettoyer les fichiers résiduels en cas d'erreur
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
  }

  /// Supprime le fichier d'épisode téléchargé (Invalidation du cache)
  Future<void> deleteDownloadedEpisode(String episodeId) async {
    try {
      final path = await getLocalFilePath(episodeId);
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
          debugPrint(
              "DownloadService: Fichier supprimé pour l'épisode $episodeId");
        }
      }
    } catch (e) {
      debugPrint(
          "DownloadService: Erreur lors de la suppression de l'épisode $episodeId: $e");
    } finally {
      // Réinitialiser les notificateurs de l'UI
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
          "DownloadService: Impossible de nettoyer le fichier temporaire: $e");
    }
  }

  /// Supprime tous les fichiers cache (mp3 et tmp) sauf celui de l'épisode spécifié.
  /// Attend que les fichiers soient supprimés avant de renvoyer la main pour éviter la concurrence.
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
            // On ne supprime que les .mp3 et .tmp obsolètes
            if ((filename.endsWith('.mp3') || filename.endsWith('.tmp')) &&
                filename != safeName &&
                filename != safeTempName) {
              try {
                await file.delete();
                debugPrint(
                    "DownloadService [clearCacheExcept]: Supprimé le fichier cache obsolète $filename");
              } catch (e) {
                debugPrint("DownloadService error deleting file $filename: $e");
              }
            }
          }
        }
      }

      // Notification de l'UI pour tous les autres épisodes supprimés
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
      debugPrint("DownloadService error [clearCacheExcept]: $e");
    }
  }

  /// Alias asynchrone pour télécharger un épisode
  Future<void> download(String episodeId, String url) async {
    await downloadEpisode(episodeId, url);
  }
}
