import 'package:flutter/material.dart';
import '../services/download_service.dart';

class DownloadWidget extends StatelessWidget {
  final String episodeId;
  final String audioUrl;
  final double size;

  const DownloadWidget({
    super.key,
    required this.episodeId,
    required this.audioUrl,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final downloadService = DownloadService();
    final statusNotifier = downloadService.getStatusNotifier(episodeId);
    final progressNotifier = downloadService.getProgressNotifier(episodeId);

    return ValueListenableBuilder<DownloadStatus>(
      valueListenable: statusNotifier,
      builder: (context, status, child) {
        switch (status) {
          case DownloadStatus.downloading:
            return ValueListenableBuilder<double>(
              valueListenable: progressNotifier,
              builder: (context, progress, child) {
                return Tooltip(
                  message:
                      "Téléchargement en cours (${(progress * 100).toInt()}%). Appuyez pour annuler.",
                  child: InkWell(
                    onTap: () => downloadService.cancelDownload(episodeId),
                    borderRadius: BorderRadius.circular(size),
                    child: SizedBox(
                      width: size + 12,
                      height: size + 12,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Icon(
                            Icons.close,
                            size: size * 0.6,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );

          case DownloadStatus.downloaded:
            return Tooltip(
              message:
                  "Disponible hors-ligne. Appuyez pour supprimer du cache.",
              child: IconButton(
                iconSize: size,
                icon: Icon(
                  Icons.offline_pin,
                  color: Colors.green.shade400,
                ),
                onPressed: () =>
                    _showDeleteConfirmation(context, downloadService),
              ),
            );

          case DownloadStatus.failed:
            return Tooltip(
              message: "Le téléchargement a échoué. Appuyez pour réessayer.",
              child: IconButton(
                iconSize: size,
                icon: Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                onPressed: () =>
                    downloadService.downloadEpisode(episodeId, audioUrl),
              ),
            );

          case DownloadStatus.idle:
            return Tooltip(
              message: "Télécharger pour écoute hors-ligne",
              child: IconButton(
                iconSize: size,
                icon: const Icon(Icons.download_for_offline_outlined),
                onPressed: () =>
                    downloadService.downloadEpisode(episodeId, audioUrl),
              ),
            );
        }
      },
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, DownloadService downloadService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Supprimer l'épisode ?"),
          content: const Text(
            "Ce fichier audio sera effacé de votre stockage local. Vous pourrez toujours le lire en streaming si vous disposez d'une connexion internet.",
          ),
          actions: [
            TextButton(
              child: const Text("Annuler"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text("Supprimer"),
              onPressed: () {
                downloadService.deleteDownloadedEpisode(episodeId);
                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Épisode supprimé du stockage local."),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
