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


### GetPodcastByFeedUrl
#### Required Arguments
```dart
String feedUrl = ...;
ExampleConnector.instance.getPodcastByFeedUrl(
  feedUrl: feedUrl,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetPodcastByFeedUrlData, GetPodcastByFeedUrlVariables>`
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

final result = await ExampleConnector.instance.getPodcastByFeedUrl(
  feedUrl: feedUrl,
);
GetPodcastByFeedUrlData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String feedUrl = ...;

final ref = ExampleConnector.instance.getPodcastByFeedUrl(
  feedUrl: feedUrl,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetAffinityRecommendations
#### Required Arguments
```dart
String userId = ...;
ExampleConnector.instance.getAffinityRecommendations(
  userId: userId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetAffinityRecommendationsData, GetAffinityRecommendationsVariables>`
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

final result = await ExampleConnector.instance.getAffinityRecommendations(
  userId: userId,
);
GetAffinityRecommendationsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String userId = ...;

final ref = ExampleConnector.instance.getAffinityRecommendations(
  userId: userId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetPodcastHistoryDelta
#### Required Arguments
```dart
String userId = ...;
Timestamp since = ...;
ExampleConnector.instance.getPodcastHistoryDelta(
  userId: userId,
  since: since,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetPodcastHistoryDeltaData, GetPodcastHistoryDeltaVariables>`
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

final result = await ExampleConnector.instance.getPodcastHistoryDelta(
  userId: userId,
  since: since,
);
GetPodcastHistoryDeltaData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String userId = ...;
Timestamp since = ...;

final ref = ExampleConnector.instance.getPodcastHistoryDelta(
  userId: userId,
  since: since,
).ref();
ref.execute();

ref.subscribe(...);
```

## Mutations

### InsertUser
#### Required Arguments
```dart
String googleId = ...;
String displayName = ...;
Timestamp createdAt = ...;
ExampleConnector.instance.insertUser(
  googleId: googleId,
  displayName: displayName,
  createdAt: createdAt,
).execute();
```

#### Optional Arguments
We return a builder for each query. For InsertUser, we created `InsertUserBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class InsertUserVariablesBuilder {
  ...
   InsertUserVariablesBuilder email(String? t) {
   _email.value = t;
   return this;
  }
  InsertUserVariablesBuilder photoUrl(String? t) {
   _photoUrl.value = t;
   return this;
  }

  ...
}
ExampleConnector.instance.insertUser(
  googleId: googleId,
  displayName: displayName,
  createdAt: createdAt,
)
.email(email)
.photoUrl(photoUrl)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<InsertUserData, InsertUserVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.insertUser(
  googleId: googleId,
  displayName: displayName,
  createdAt: createdAt,
);
InsertUserData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String googleId = ...;
String displayName = ...;
Timestamp createdAt = ...;

final ref = ExampleConnector.instance.insertUser(
  googleId: googleId,
  displayName: displayName,
  createdAt: createdAt,
).ref();
ref.execute();
```


### UpsertUser
#### Required Arguments
```dart
String id = ...;
String googleId = ...;
String displayName = ...;
Timestamp createdAt = ...;
ExampleConnector.instance.upsertUser(
  id: id,
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
  id: id,
  googleId: googleId,
  displayName: displayName,
  createdAt: createdAt,
)
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
  id: id,
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
String id = ...;
String googleId = ...;
String displayName = ...;
Timestamp createdAt = ...;

final ref = ExampleConnector.instance.upsertUser(
  id: id,
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


### CleanupDuplicates
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.cleanupDuplicates().execute();
```



#### Return Type
`execute()` returns a `OperationResult<CleanupDuplicatesData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.cleanupDuplicates();
CleanupDuplicatesData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.cleanupDuplicates().ref();
ref.execute();
```


### SyncPodcastHistory
#### Required Arguments
```dart
String userId = ...;
AnyValue history = ...;
ExampleConnector.instance.syncPodcastHistory(
  userId: userId,
  history: history,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<SyncPodcastHistoryData, SyncPodcastHistoryVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.syncPodcastHistory(
  userId: userId,
  history: history,
);
SyncPodcastHistoryData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String userId = ...;
AnyValue history = ...;

final ref = ExampleConnector.instance.syncPodcastHistory(
  userId: userId,
  history: history,
).ref();
ref.execute();
```

