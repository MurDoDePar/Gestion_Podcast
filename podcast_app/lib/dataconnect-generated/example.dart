library podcast_app;

import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

part 'insert_user.dart';

part 'upsert_user.dart';

part 'upsert_podcast.dart';

part 'upsert_episode.dart';

part 'subscribe_to_podcast.dart';

part 'update_subscription_order.dart';

part 'unsubscribe_from_podcast.dart';

part 'update_listen_history.dart';

part 'cleanup_duplicates.dart';

part 'upsert_app_cache.dart';

part 'find_user_by_google_id.dart';

part 'get_my_subscriptions.dart';

part 'get_listen_history.dart';

part 'get_recommendations.dart';

part 'get_episodes_by_podcast.dart';

part 'get_latest_subscribed_episodes.dart';

part 'get_oldest_subscribed_episodes.dart';

part 'get_app_cache.dart';

part 'get_podcast_by_feed_url.dart';

String bigIntToJson(BigInt value) {
  return value.toString();
}

BigInt bigIntFromJson(dynamic value) {
  return BigInt.parse(value);
}

class ExampleConnector {
  InsertUserVariablesBuilder insertUser({
    required String googleId,
    required String displayName,
    required Timestamp createdAt,
  }) {
    return InsertUserVariablesBuilder(
      dataConnect,
      googleId: googleId,
      displayName: displayName,
      createdAt: createdAt,
    );
  }

  UpsertUserVariablesBuilder upsertUser({
    required String id,
    required String googleId,
    required String displayName,
    required Timestamp createdAt,
  }) {
    return UpsertUserVariablesBuilder(
      dataConnect,
      id: id,
      googleId: googleId,
      displayName: displayName,
      createdAt: createdAt,
    );
  }

  UpsertPodcastVariablesBuilder upsertPodcast({
    required String title,
    required String feedUrl,
    required Timestamp createdAt,
  }) {
    return UpsertPodcastVariablesBuilder(
      dataConnect,
      title: title,
      feedUrl: feedUrl,
      createdAt: createdAt,
    );
  }

  UpsertEpisodeVariablesBuilder upsertEpisode({
    required String podcastId,
    required String title,
    required String audioUrl,
    required BigInt duration,
    required Timestamp publishedAt,
  }) {
    return UpsertEpisodeVariablesBuilder(
      dataConnect,
      podcastId: podcastId,
      title: title,
      audioUrl: audioUrl,
      duration: duration,
      publishedAt: publishedAt,
    );
  }

  SubscribeToPodcastVariablesBuilder subscribeToPodcast({
    required String userId,
    required String podcastId,
    required Timestamp subscribedAt,
  }) {
    return SubscribeToPodcastVariablesBuilder(
      dataConnect,
      userId: userId,
      podcastId: podcastId,
      subscribedAt: subscribedAt,
    );
  }

  UpdateSubscriptionOrderVariablesBuilder updateSubscriptionOrder({
    required String userId,
    required String podcastId,
    required int listOrder,
  }) {
    return UpdateSubscriptionOrderVariablesBuilder(
      dataConnect,
      userId: userId,
      podcastId: podcastId,
      listOrder: listOrder,
    );
  }

  UnsubscribeFromPodcastVariablesBuilder unsubscribeFromPodcast({
    required String userId,
    required String podcastId,
  }) {
    return UnsubscribeFromPodcastVariablesBuilder(
      dataConnect,
      userId: userId,
      podcastId: podcastId,
    );
  }

  UpdateListenHistoryVariablesBuilder updateListenHistory({
    required String userId,
    required String episodeId,
    required BigInt progressSeconds,
    required bool finishedListening,
    required Timestamp listenedAt,
  }) {
    return UpdateListenHistoryVariablesBuilder(
      dataConnect,
      userId: userId,
      episodeId: episodeId,
      progressSeconds: progressSeconds,
      finishedListening: finishedListening,
      listenedAt: listenedAt,
    );
  }

  CleanupDuplicatesVariablesBuilder cleanupDuplicates() {
    return CleanupDuplicatesVariablesBuilder(
      dataConnect,
    );
  }

  UpsertAppCacheVariablesBuilder upsertAppCache({
    required String id,
    required dynamic data,
    required Timestamp updatedAt,
  }) {
    return UpsertAppCacheVariablesBuilder(
      dataConnect,
      id: id,
      data: data,
      updatedAt: updatedAt,
    );
  }

  FindUserByGoogleIdVariablesBuilder findUserByGoogleId({
    required String googleId,
  }) {
    return FindUserByGoogleIdVariablesBuilder(
      dataConnect,
      googleId: googleId,
    );
  }

  GetMySubscriptionsVariablesBuilder getMySubscriptions({
    required String userId,
  }) {
    return GetMySubscriptionsVariablesBuilder(
      dataConnect,
      userId: userId,
    );
  }

  GetListenHistoryVariablesBuilder getListenHistory({
    required String userId,
  }) {
    return GetListenHistoryVariablesBuilder(
      dataConnect,
      userId: userId,
    );
  }

  GetRecommendationsVariablesBuilder getRecommendations({
    required String feedUrl,
  }) {
    return GetRecommendationsVariablesBuilder(
      dataConnect,
      feedUrl: feedUrl,
    );
  }

  GetEpisodesByPodcastVariablesBuilder getEpisodesByPodcast({
    required String podcastId,
  }) {
    return GetEpisodesByPodcastVariablesBuilder(
      dataConnect,
      podcastId: podcastId,
    );
  }

  GetLatestSubscribedEpisodesVariablesBuilder getLatestSubscribedEpisodes({
    required String userId,
  }) {
    return GetLatestSubscribedEpisodesVariablesBuilder(
      dataConnect,
      userId: userId,
    );
  }

  GetOldestSubscribedEpisodesVariablesBuilder getOldestSubscribedEpisodes({
    required String userId,
  }) {
    return GetOldestSubscribedEpisodesVariablesBuilder(
      dataConnect,
      userId: userId,
    );
  }

  GetAppCacheVariablesBuilder getAppCache({
    required String id,
  }) {
    return GetAppCacheVariablesBuilder(
      dataConnect,
      id: id,
    );
  }

  GetPodcastByFeedUrlVariablesBuilder getPodcastByFeedUrl({
    required String feedUrl,
  }) {
    return GetPodcastByFeedUrlVariablesBuilder(
      dataConnect,
      feedUrl: feedUrl,
    );
  }

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'europe-west9',
    'example',
    'podstream-a980a-service',
  );

  ExampleConnector({required this.dataConnect});
  static ExampleConnector get instance {
    return ExampleConnector(
        dataConnect: FirebaseDataConnect.instanceFor(
            connectorConfig: connectorConfig,
            sdkType: CallerSDKType.generated));
  }

  FirebaseDataConnect dataConnect;
}
