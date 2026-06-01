import 'dart:async';
import 'audio_handler_locator.dart';
import 'database_repository.dart';
import '../models/episode_model.dart';

class MarkAsReadService {
  /// Executes the three‑step "mark as read" workflow.
  Future<void> markAsRead(String episodeId, {EpisodeModel? episode}) async {
    // print(
    // 'DEBUG MarkAsReadService: markAsRead appelé pour l\'épisode: $episodeId');

    // Déléguer les écritures locales et distantes au DatabaseRepository
    await DatabaseRepository().markEpisodeAsRead(
      episodeId,
      title: episode?.title,
      audioUrl: episode?.audioUrl,
      imageUrl: episode?.imageUrl,
      podcastName: episode?.podcastName,
      pubDate: episode?.pubDate?.toIso8601String(),
      description: episode?.description,
    );

    // Actions de finalisation (arrêt du lecteur)
    try {
      if (globalAudioHandler != null) {
        // print('DEBUG AUDIO: Arrêt forcé du lecteur audio.');
        await globalAudioHandler!.stop();
      }
    } catch (e) {
      // print(
      // 'DEBUG MarkAsReadService: Erreur lors de l\'arrêt du lecteur audio : $e');
    }
  }

  static final _refreshController = StreamController<void>.broadcast();
  static Stream<void> get onRefresh => _refreshController.stream;
}
