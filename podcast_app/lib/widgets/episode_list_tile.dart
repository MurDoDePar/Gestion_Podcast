import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../models/episode_model.dart';
import '../theme/app_theme.dart';
import '../services/audio_handler_locator.dart';
import '../services/mark_as_read_service.dart';

class EpisodeListTile extends StatelessWidget {
  final EpisodeModel episode;

  const EpisodeListTile({super.key, required this.episode});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(8),
          image: episode.imageUrl.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(episode.imageUrl),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: episode.imageUrl.isEmpty
            ? const Icon(Icons.play_circle_fill, color: AppTheme.primaryColor)
            : null,
      ),
      title: Text(episode.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(episode.podcastName,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppTheme.surfaceColor,
              title: Text(
                episode.title,
                style: const TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Text(
                    episode.description,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await MarkAsReadService().markAsRead(episode.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Épisode marqué comme lu'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Marquer comme lu',
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Fermer',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      onTap: () async {
        print('AA_DEBUG_UI: Clic détecté sur l\'épisode ${episode.title}');
        if (globalAudioHandler == null) {
          print('AA_DEBUG_ERROR: globalAudioHandler is null!');
          return;
        }
        await globalAudioHandler!.playMediaItem(
          MediaItem(
            id: episode.audioUrl,
            title: episode.title,
            artist: episode.podcastName,
            artUri: episode.imageUrl.isNotEmpty
                ? Uri.parse(episode.imageUrl)
                : null,
            extras: {'episodeId': episode.id},
          ),
        );
      },
    );
  }
}
