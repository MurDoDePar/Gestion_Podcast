# podcast_app SDK

## Installation
```sh
flutter pub get firebase_data_connect
flutterfire configure
```
For more information, see [Flutter for Firebase installation documentation](https://firebase.google.com/docs/data-connect/flutter-sdk#use-core).

## Data Connect instance
Each connector creates a static class, with an instance of the `DataConnect` class that can be used to connect to your Data Connect backend and call operations.

### Connecting to the emulator

```dart
String host = 'localhost'; // or your host name
int port = 9399; // or your port number
ExampleConnector.instance.dataConnect.useDataConnectEmulator(host, port);
```

You can also call queries and mutations by using the connector class.
## Queries

### FindUserByGoogleId
#### Required Arguments
```dart
String googleId = ...;
ExampleConnector.instance.findUserByGoogleId(
  googleId: googleId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<FindUserByGoogleIdData, FindUserByGoogleIdVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.findUserByGoogleId(
  googleId: googleId,
);
FindUserByGoogleIdData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String googleId = ...;

final ref = ExampleConnector.instance.findUserByGoogleId(
  googleId: googleId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetMySubscriptions
#### Required Arguments
```dart
String userId = ...;
ExampleConnector.instance.getMySubscriptions(
  userId: userId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetMySubscriptionsData, GetMySubscriptionsVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.getMySubscriptions(
  userId: userId,
);
GetMySubscriptionsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String userId = ...;

final ref = ExampleConnector.instance.getMySubscriptions(
  userId: userId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetListenHistory
#### Required Arguments
```dart
String userId = ...;
ExampleConnector.instance.getListenHistory(
  userId: userId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetListenHistoryData, GetListenHistoryVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.getListenHistory(
  userId: userId,
);
GetListenHistoryData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String userId = ...;

final ref = ExampleConnector.instance.getListenHistory(
  userId: userId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetRecommendations
#### Required Arguments
```dart
String feedUrl = ...;
ExampleConnector.instance.getRecommendations(
  feedUrl: feedUrl,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetRecommendationsData, GetRecommendationsVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.getRecommendations(
  feedUrl: feedUrl,
);
GetRecommendationsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String feedUrl = ...;

final ref = ExampleConnector.instance.getRecommendations(
  feedUrl: feedUrl,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetEpisodesByPodcast
#### Required Arguments
```dart
String podcastId = ...;
ExampleConnector.instance.getEpisodesByPodcast(
  podcastId: podcastId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetEpisodesByPodcastData, GetEpisodesByPodcastVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.getEpisodesByPodcast(
  podcastId: podcastId,
);
GetEpisodesByPodcastData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String podcastId = ...;

final ref = ExampleConnector.instance.getEpisodesByPodcast(
  podcastId: podcastId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetLatestSubscribedEpisodes
#### Required Arguments
```dart
String userId = ...;
ExampleConnector.instance.getLatestSubscribedEpisodes(
  userId: userId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetLatestSubscribedEpisodesData, GetLatestSubscribedEpisodesVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.getLatestSubscribedEpisodes(
  userId: userId,
);
GetLatestSubscribedEpisodesData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String userId = ...;

final ref = ExampleConnector.instance.getLatestSubscribedEpisodes(
  userId: userId,
).ref();
ref.execute();

ref.subscribe(...);
```

## Mutations

### UpsertUser
#### Required Arguments
```dart
String googleId = ...;
String displayName = ...;
Timestamp createdAt = ...;
ExampleConnector.instance.upsertUser(
  googleId: googleId,
  displayName: displayName,
  createdAt: createdAt,
).execute();
```

#### Optional Arguments
We return a builder for each query. For UpsertUser, we created `UpsertUserBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpsertUserVariablesBuilder {
  ...
 
  UpsertUserVariablesBuilder id(String? t) {
   _id.value = t;
   return this;
  }
  UpsertUserVariablesBuilder email(String? t) {
   _email.value = t;
   return this;
  }
  UpsertUserVariablesBuilder photoUrl(String? t) {
   _photoUrl.value = t;
   return this;
  }

  ...
}
ExampleConnector.instance.upsertUser(
  googleId: googleId,
  displayName: displayName,
  createdAt: createdAt,
)
.id(id)
.email(email)
.photoUrl(photoUrl)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<UpsertUserData, UpsertUserVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.upsertUser(
  googleId: googleId,
  displayName: displayName,
  createdAt: createdAt,
);
UpsertUserData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String googleId = ...;
String displayName = ...;
Timestamp createdAt = ...;

final ref = ExampleConnector.instance.upsertUser(
  googleId: googleId,
  displayName: displayName,
  createdAt: createdAt,
).ref();
ref.execute();
```


### UpsertPodcast
#### Required Arguments
```dart
String title = ...;
String feedUrl = ...;
Timestamp createdAt = ...;
ExampleConnector.instance.upsertPodcast(
  title: title,
  feedUrl: feedUrl,
  createdAt: createdAt,
).execute();
```

#### Optional Arguments
We return a builder for each query. For UpsertPodcast, we created `UpsertPodcastBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpsertPodcastVariablesBuilder {
  ...
 
  UpsertPodcastVariablesBuilder id(String? t) {
   _id.value = t;
   return this;
  }
  UpsertPodcastVariablesBuilder description(String? t) {
   _description.value = t;
   return this;
  }
  UpsertPodcastVariablesBuilder imageUrl(String? t) {
   _imageUrl.value = t;
   return this;
  }
  UpsertPodcastVariablesBuilder author(String? t) {
   _author.value = t;
   return this;
  }
  UpsertPodcastVariablesBuilder categories(List<String>? t) {
   _categories.value = t;
   return this;
  }

  ...
}
ExampleConnector.instance.upsertPodcast(
  title: title,
  feedUrl: feedUrl,
  createdAt: createdAt,
)
.id(id)
.description(description)
.imageUrl(imageUrl)
.author(author)
.categories(categories)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<UpsertPodcastData, UpsertPodcastVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.upsertPodcast(
  title: title,
  feedUrl: feedUrl,
  createdAt: createdAt,
);
UpsertPodcastData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String title = ...;
String feedUrl = ...;
Timestamp createdAt = ...;

final ref = ExampleConnector.instance.upsertPodcast(
  title: title,
  feedUrl: feedUrl,
  createdAt: createdAt,
).ref();
ref.execute();
```


### UpsertEpisode
#### Required Arguments
```dart
String podcastId = ...;
String title = ...;
String audioUrl = ...;
BigInt duration = ...;
Timestamp publishedAt = ...;
ExampleConnector.instance.upsertEpisode(
  podcastId: podcastId,
  title: title,
  audioUrl: audioUrl,
  duration: duration,
  publishedAt: publishedAt,
).execute();
```

#### Optional Arguments
We return a builder for each query. For UpsertEpisode, we created `UpsertEpisodeBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpsertEpisodeVariablesBuilder {
  ...
 
  UpsertEpisodeVariablesBuilder id(String? t) {
   _id.value = t;
   return this;
  }
  UpsertEpisodeVariablesBuilder description(String? t) {
   _description.value = t;
   return this;
  }
  UpsertEpisodeVariablesBuilder imageUrl(String? t) {
   _imageUrl.value = t;
   return this;
  }

  ...
}
ExampleConnector.instance.upsertEpisode(
  podcastId: podcastId,
  title: title,
  audioUrl: audioUrl,
  duration: duration,
  publishedAt: publishedAt,
)
.id(id)
.description(description)
.imageUrl(imageUrl)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<UpsertEpisodeData, UpsertEpisodeVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.upsertEpisode(
  podcastId: podcastId,
  title: title,
  audioUrl: audioUrl,
  duration: duration,
  publishedAt: publishedAt,
);
UpsertEpisodeData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String podcastId = ...;
String title = ...;
String audioUrl = ...;
BigInt duration = ...;
Timestamp publishedAt = ...;

final ref = ExampleConnector.instance.upsertEpisode(
  podcastId: podcastId,
  title: title,
  audioUrl: audioUrl,
  duration: duration,
  publishedAt: publishedAt,
).ref();
ref.execute();
```


### SubscribeToPodcast
#### Required Arguments
```dart
String userId = ...;
String podcastId = ...;
Timestamp subscribedAt = ...;
ExampleConnector.instance.subscribeToPodcast(
  userId: userId,
  podcastId: podcastId,
  subscribedAt: subscribedAt,
).execute();
```

#### Optional Arguments
We return a builder for each query. For SubscribeToPodcast, we created `SubscribeToPodcastBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class SubscribeToPodcastVariablesBuilder {
  ...
   SubscribeToPodcastVariablesBuilder listOrder(int? t) {
   _listOrder.value = t;
   return this;
  }

  ...
}
ExampleConnector.instance.subscribeToPodcast(
  userId: userId,
  podcastId: podcastId,
  subscribedAt: subscribedAt,
)
.listOrder(listOrder)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<SubscribeToPodcastData, SubscribeToPodcastVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.subscribeToPodcast(
  userId: userId,
  podcastId: podcastId,
  subscribedAt: subscribedAt,
);
SubscribeToPodcastData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String userId = ...;
String podcastId = ...;
Timestamp subscribedAt = ...;

final ref = ExampleConnector.instance.subscribeToPodcast(
  userId: userId,
  podcastId: podcastId,
  subscribedAt: subscribedAt,
).ref();
ref.execute();
```


### UpdateSubscriptionOrder
#### Required Arguments
```dart
String userId = ...;
String podcastId = ...;
int listOrder = ...;
ExampleConnector.instance.updateSubscriptionOrder(
  userId: userId,
  podcastId: podcastId,
  listOrder: listOrder,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateSubscriptionOrderData, UpdateSubscriptionOrderVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.updateSubscriptionOrder(
  userId: userId,
  podcastId: podcastId,
  listOrder: listOrder,
);
UpdateSubscriptionOrderData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String userId = ...;
String podcastId = ...;
int listOrder = ...;

final ref = ExampleConnector.instance.updateSubscriptionOrder(
  userId: userId,
  podcastId: podcastId,
  listOrder: listOrder,
).ref();
ref.execute();
```


### UnsubscribeFromPodcast
#### Required Arguments
```dart
String userId = ...;
String podcastId = ...;
ExampleConnector.instance.unsubscribeFromPodcast(
  userId: userId,
  podcastId: podcastId,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UnsubscribeFromPodcastData, UnsubscribeFromPodcastVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.unsubscribeFromPodcast(
  userId: userId,
  podcastId: podcastId,
);
UnsubscribeFromPodcastData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String userId = ...;
String podcastId = ...;

final ref = ExampleConnector.instance.unsubscribeFromPodcast(
  userId: userId,
  podcastId: podcastId,
).ref();
ref.execute();
```


### UpdateListenHistory
#### Required Arguments
```dart
String userId = ...;
String episodeId = ...;
BigInt progressSeconds = ...;
bool finishedListening = ...;
Timestamp listenedAt = ...;
ExampleConnector.instance.updateListenHistory(
  userId: userId,
  episodeId: episodeId,
  progressSeconds: progressSeconds,
  finishedListening: finishedListening,
  listenedAt: listenedAt,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateListenHistoryData, UpdateListenHistoryVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.updateListenHistory(
  userId: userId,
  episodeId: episodeId,
  progressSeconds: progressSeconds,
  finishedListening: finishedListening,
  listenedAt: listenedAt,
);
UpdateListenHistoryData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String userId = ...;
String episodeId = ...;
BigInt progressSeconds = ...;
bool finishedListening = ...;
Timestamp listenedAt = ...;

final ref = ExampleConnector.instance.updateListenHistory(
  userId: userId,
  episodeId: episodeId,
  progressSeconds: progressSeconds,
  finishedListening: finishedListening,
  listenedAt: listenedAt,
).ref();
ref.execute();
```

