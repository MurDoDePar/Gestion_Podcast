import '../../models/podcast_model.dart';
import '../../models/episode_model.dart';

class UpdateRequiredException implements Exception {
  final String message;
  UpdateRequiredException(this.message);
  @override
  String toString() => message;
}

abstract class PodcastSyncService {
  Future<List<PodcastModel>> fetchRemoteSubscriptions(String userId);
  Future<List<String>> fetchEpisodeHistory(String userId);
  Future<void> syncSubscribe(
      String userId, PodcastModel podcast, int orderIndex);
  Future<void> syncUnsubscribe(String userId, String feedUrl, String podcastId);
  Future<Set<String>> fetchReadEpisodeIds(String userId);
  Future<void> syncEpisodeRead(String userId, String episodeId);
  Future<void> checkRemoteVersionRequirements(int currentBuild);
  Future<List<EpisodeModel>> fetchRemoteEpisodes();
  Future<List<PodcastModel>> fetchAffinityPodcasts(
      String userId, List<String> localFeedUrls);
  Future<Map<String, int>> fetchRemoteSubscriptionOrders(String userId);
}
