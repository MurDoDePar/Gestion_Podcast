# Basic Usage

```dart
ExampleConnector.instance.FindUserByGoogleId(findUserByGoogleIdVariables).execute();
ExampleConnector.instance.GetMySubscriptions(getMySubscriptionsVariables).execute();
ExampleConnector.instance.GetListenHistory(getListenHistoryVariables).execute();
ExampleConnector.instance.GetRecommendations(getRecommendationsVariables).execute();
ExampleConnector.instance.GetEpisodesByPodcast(getEpisodesByPodcastVariables).execute();
ExampleConnector.instance.GetLatestSubscribedEpisodes(getLatestSubscribedEpisodesVariables).execute();
ExampleConnector.instance.GetAppCache(getAppCacheVariables).execute();
ExampleConnector.instance.InsertUser(insertUserVariables).execute();
ExampleConnector.instance.UpsertUser(upsertUserVariables).execute();
ExampleConnector.instance.UpsertPodcast(upsertPodcastVariables).execute();

```

## Optional Fields

Some operations may have optional fields. In these cases, the Flutter SDK exposes a builder method, and will have to be set separately.

Optional fields can be discovered based on classes that have `Optional` object types.

This is an example of a mutation with an optional field:

```dart
await ExampleConnector.instance.SubscribeToPodcast({ ... })
.listOrder(...)
.execute();
```

Note: the above example is a mutation, but the same logic applies to query operations as well. Additionally, `createMovie` is an example, and may not be available to the user.

