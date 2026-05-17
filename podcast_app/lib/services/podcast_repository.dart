import 'package:shared_preferences/shared_preferences.dart';
import '../dataconnect-generated/example.dart';

class PodcastRepository {
  static Future<List<Map<String, dynamic>>> fetchEpisodesToListen(
      String googleId) async {
    try {
      final userResult = await ExampleConnector.instance
          .findUserByGoogleId(googleId: googleId)
          .execute();
      if (userResult.data.users.isEmpty) return [];
      final postgresUuid = userResult.data.users.first.id;

      final historyResult = await ExampleConnector.instance
          .getListenHistory(userId: postgresUuid)
          .execute();
      final readEpisodeIds = historyResult.data.listenHistories
          .where((h) => h.finishedListening == true)
          .map((h) => h.episode.id)
          .toSet();

      final prefs = await SharedPreferences.getInstance();
      final order = prefs.getString('podstream_order') ?? 'desc';

      final subsResult = await ExampleConnector.instance
          .getMySubscriptions(userId: postgresUuid)
          .execute();
      final subs = subsResult.data.subscriptionTypes.toList();

      // Sort podcasts according to listOrder
      subs.sort((a, b) {
        final orderA = a.listOrder ?? 9999;
        final orderB = b.listOrder ?? 9999;
        if (orderA == orderB) return a.podcast.title.compareTo(b.podcast.title);
        return orderA.compareTo(orderB);
      });

      List<Map<String, dynamic>> finalEpisodes = [];

      // Find the first podcast that has unread episodes
      for (var sub in subs) {
        final podcastName = sub.podcast.title;
        final podcastImageUrl = sub.podcast.imageUrl;
        final listOrder = sub.listOrder ?? 9999;

        final episodesResult = await ExampleConnector.instance
            .getEpisodesByPodcast(podcastId: sub.podcast.id)
            .execute();

        var epsList = episodesResult.data.episodes.toList();

        // Sort episodes of the current podcast
        epsList.sort((a, b) {
          int cmp = 0;
          final matchA = RegExp(r'#(\d+)').firstMatch(a.title);
          final matchB = RegExp(r'#(\d+)').firstMatch(b.title);

          if (matchA != null && matchB != null) {
            final numA = int.parse(matchA.group(1)!);
            final numB = int.parse(matchB.group(1)!);
            cmp = numA.compareTo(numB);
          } else {
            cmp = a.publishedAt
                .toDateTime()
                .compareTo(b.publishedAt.toDateTime());
            if (cmp == 0) cmp = a.title.compareTo(b.title);
          }

          if (order == 'asc') {
            return cmp; // oldest first
          } else {
            return -cmp; // newest first
          }
        });

        // Filter unread episodes
        for (var ep in epsList) {
          if (!readEpisodeIds.contains(ep.id)) {
            finalEpisodes.add({
              'id': ep.id,
              'title': ep.title,
              'audioUrl': ep.audioUrl,
              'imageUrl': ep.imageUrl ?? podcastImageUrl,
              'podcastName': podcastName,
              'publishedAt': ep.publishedAt.toDateTime(),
              'listOrder': listOrder,
              'description': ep.description,
            });
          }
        }

        // If we found unread episodes for this podcast, we return them!
        // The condition requires us to return exactly the episodes of the *first* podcast that has unread episodes.
        if (finalEpisodes.isNotEmpty) {
          return finalEpisodes;
        }
      }

      return [];
    } catch (e) {
      print("Erreur PodcastRepository.fetchEpisodesToListen: $e");
      return [];
    }
  }
}
