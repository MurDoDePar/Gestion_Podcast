library podcast_app;

import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

part 'find_user_by_google_id.dart';

part 'get_my_subscriptions.dart';

part 'get_recommendations.dart';

part 'get_podcast_by_feed_url.dart';

part 'get_affinity_recommendations.dart';

part 'get_podcast_history_delta.dart';

part 'insert_user.dart';

part 'upsert_user.dart';

part 'upsert_podcast.dart';

part 'subscribe_to_podcast.dart';

part 'update_subscription_order.dart';

part 'unsubscribe_from_podcast.dart';

part 'cleanup_duplicates.dart';

part 'sync_podcast_history.dart';

class ExampleConnector {
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

  GetRecommendationsVariablesBuilder getRecommendations({
    required String feedUrl,
  }) {
    return GetRecommendationsVariablesBuilder(
      dataConnect,
      feedUrl: feedUrl,
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

  GetAffinityRecommendationsVariablesBuilder getAffinityRecommendations({
    required String userId,
  }) {
    return GetAffinityRecommendationsVariablesBuilder(
      dataConnect,
      userId: userId,
    );
  }

  GetPodcastHistoryDeltaVariablesBuilder getPodcastHistoryDelta({
    required String userId,
    required Timestamp since,
  }) {
    return GetPodcastHistoryDeltaVariablesBuilder(
      dataConnect,
      userId: userId,
      since: since,
    );
  }

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

  CleanupDuplicatesVariablesBuilder cleanupDuplicates() {
    return CleanupDuplicatesVariablesBuilder(
      dataConnect,
    );
  }

  SyncPodcastHistoryVariablesBuilder syncPodcastHistory({
    required String userId,
    required dynamic history,
  }) {
    return SyncPodcastHistoryVariablesBuilder(
      dataConnect,
      userId: userId,
      history: history,
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
