import 'dart:async';
import 'audio_handler_locator.dart';
import '../services/audio_service.dart' as app_audio;
import 'database_repository.dart';

class MarkAsReadService {
  /// Executes the three‑step "mark as read" workflow.
  Future<void> markAsRead(String episodeId) async {
    print(
        'DEBUG MarkAsReadService: markAsRead appelé pour l\'épisode: $episodeId');

    // Déléguer les écritures locales et distantes au DatabaseRepository
    await DatabaseRepository().markEpisodeAsRead(episodeId);

    // Actions de finalisation (arrêt du lecteur et rafraîchissement UI)
    try {
      if (globalAudioHandler != null) {
        print('DEBUG AUDIO: Arrêt forcé du lecteur audio.');
        await globalAudioHandler!.stop();
      }
    } catch (e) {
      print(
          'DEBUG MarkAsReadService: Erreur lors de l\'arrêt du lecteur audio : $e');
    }

    print('DEBUG UI: Déclenchement du rafraîchissement UI....');
    app_audio.AudioService().listRefreshNotifier.value++;
  }

  static final _refreshController = StreamController<void>.broadcast();
  static Stream<void> get onRefresh => _refreshController.stream;
}
