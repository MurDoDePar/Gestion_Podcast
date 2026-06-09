part of 'example.dart';

class GetAffinityRecommendationsVariablesBuilder {
  String userId;

  final FirebaseDataConnect _dataConnect;
  GetAffinityRecommendationsVariablesBuilder(
    this._dataConnect, {
    required this.userId,
  });
  Deserializer<GetAffinityRecommendationsData> dataDeserializer =
      (dynamic json) =>
          GetAffinityRecommendationsData.fromJson(jsonDecode(json));
  Serializer<GetAffinityRecommendationsVariables> varsSerializer =
      (GetAffinityRecommendationsVariables vars) => jsonEncode(vars.toJson());
  Future<
      QueryResult<GetAffinityRecommendationsData,
          GetAffinityRecommendationsVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetAffinityRecommendationsData, GetAffinityRecommendationsVariables>
      ref() {
    GetAffinityRecommendationsVariables vars =
        GetAffinityRecommendationsVariables(
      userId: userId,
    );
    return _dataConnect.query(
        "GetAffinityRecommendations", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetAffinityRecommendationsMySubscriptions {
  final GetAffinityRecommendationsMySubscriptionsPodcast podcast;
  GetAffinityRecommendationsMySubscriptions.fromJson(dynamic json)
      : podcast = GetAffinityRecommendationsMySubscriptionsPodcast.fromJson(
            json['podcast']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetAffinityRecommendationsMySubscriptions otherTyped =
        other as GetAffinityRecommendationsMySubscriptions;
    return podcast == otherTyped.podcast;
  }

  @override
  int get hashCode => podcast.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['podcast'] = podcast.toJson();
    return json;
  }

  GetAffinityRecommendationsMySubscriptions({
    required this.podcast,
  });
}

@immutable
class GetAffinityRecommendationsMySubscriptionsPodcast {
  final String id;
  final String feedUrl;
  final String title;
  final List<
          GetAffinityRecommendationsMySubscriptionsPodcastSubscriptionTypesOnPodcast>
      subscriptionTypes_on_podcast;
  GetAffinityRecommendationsMySubscriptionsPodcast.fromJson(dynamic json)
      : id = nativeFromJson<String>(json['id']),
        feedUrl = nativeFromJson<String>(json['feedUrl']),
        title = nativeFromJson<String>(json['title']),
        subscriptionTypes_on_podcast = (json['subscriptionTypes_on_podcast']
                as List<dynamic>)
            .map((e) =>
                GetAffinityRecommendationsMySubscriptionsPodcastSubscriptionTypesOnPodcast
                    .fromJson(e))
            .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetAffinityRecommendationsMySubscriptionsPodcast otherTyped =
        other as GetAffinityRecommendationsMySubscriptionsPodcast;
    return id == otherTyped.id &&
        feedUrl == otherTyped.feedUrl &&
        title == otherTyped.title &&
        subscriptionTypes_on_podcast == otherTyped.subscriptionTypes_on_podcast;
  }

  @override
  int get hashCode => Object.hashAll([
        id.hashCode,
        feedUrl.hashCode,
        title.hashCode,
        subscriptionTypes_on_podcast.hashCode
      ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['feedUrl'] = nativeToJson<String>(feedUrl);
    json['title'] = nativeToJson<String>(title);
    json['subscriptionTypes_on_podcast'] =
        subscriptionTypes_on_podcast.map((e) => e.toJson()).toList();
    return json;
  }

  GetAffinityRecommendationsMySubscriptionsPodcast({
    required this.id,
    required this.feedUrl,
    required this.title,
    required this.subscriptionTypes_on_podcast,
  });
}

@immutable
class GetAffinityRecommendationsMySubscriptionsPodcastSubscriptionTypesOnPodcast {
  final GetAffinityRecommendationsMySubscriptionsPodcastSubscriptionTypesOnPodcastUser
      user;
  GetAffinityRecommendationsMySubscriptionsPodcastSubscriptionTypesOnPodcast.fromJson(
      dynamic json)
      : user =
            GetAffinityRecommendationsMySubscriptionsPodcastSubscriptionTypesOnPodcastUser
                .fromJson(json['user']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetAffinityRecommendationsMySubscriptionsPodcastSubscriptionTypesOnPodcast
        otherTyped = other
            as GetAffinityRecommendationsMySubscriptionsPodcastSubscriptionTypesOnPodcast;
    return user == otherTyped.user;
  }

  @override
  int get hashCode => user.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['user'] = user.toJson();
    return json;
  }

  GetAffinityRecommendationsMySubscriptionsPodcastSubscriptionTypesOnPodcast({
    required this.user,
  });
}

@immutable
class GetAffinityRecommendationsMySubscriptionsPodcastSubscriptionTypesOnPodcastUser {
  final String id;
  final String displayName;
  final List<
          GetAffinityRecommendationsMySubscriptionsPodcastSubscriptionTypesOnPodcastUserSubscriptionTypesOnUser>
      subscriptionTypes_on_user;
  GetAffinityRecommendationsMySubscriptionsPodcastSubscriptionTypesOnPodcastUser.fromJson(
      dynamic json)
      : id = nativeFromJson<String>(json['id']),
        displayName = nativeFromJson<String>(json['displayName']),
        subscriptionTypes_on_user = (json['subscriptionTypes_on_user']
                as List<dynamic>)
            .map((e) =>
                GetAffinityRecommendationsMySubscriptionsPodcastSubscriptionTypesOnPodcastUserSubscriptionTypesOnUser
                    .fromJson(e))
            .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetAffinityRecommendationsMySubscriptionsPodcastSubscriptionTypesOnPodcastUser
        otherTyped = other
            as GetAffinityRecommendationsMySubscriptionsPodcastSubscriptionTypesOnPodcastUser;
    return id == otherTyped.id &&
        displayName == otherTyped.displayName &&
        subscriptionTypes_on_user == otherTyped.subscriptionTypes_on_user;
  }

  @override
  int get hashCode => Object.hashAll(
      [id.hashCode, displayName.hashCode, subscriptionTypes_on_user.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['displayName'] = nativeToJson<String>(displayName);
    json['subscriptionTypes_on_user'] =
        subscriptionTypes_on_user.map((e) => e.toJson()).toList();
    return json;
  }

  GetAffinityRecommendationsMySubscriptionsPodcastSubscriptionTypesOnPodcastUser({
    required this.id,
    required this.displayName,
    required this.subscriptionTypes_on_user,
  });
}

@immutable
class GetAffinityRecommendationsMySubscriptionsPodcastSubscriptionTypesOnPodcastUserSubscriptionTypesOnUser {
  final GetAffinityRecommendationsMySubscriptionsPodcastSubscriptionTypesOnPodcastUserSubscriptionTypesOnUserPodcast
      podcast;
  GetAffinityRecommendationsMySubscriptionsPodcastSubscriptionTypesOnPodcastUserSubscriptionTypesOnUser.fromJson(
      dynamic json)
      : podcast =
            GetAffinityRecommendationsMySubscriptionsPodcastSubscriptionTypesOnPodcastUserSubscriptionTypesOnUserPodcast
                .fromJson(json['podcast']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetAffinityRecommendationsMySubscriptionsPodcastSubscriptionTypesOnPodcastUserSubscriptionTypesOnUser
        otherTyped = other
            as GetAffinityRecommendationsMySubscriptionsPodcastSubscriptionTypesOnPodcastUserSubscriptionTypesOnUser;
    return podcast == otherTyped.podcast;
  }

  @override
  int get hashCode => podcast.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['podcast'] = podcast.toJson();
    return json;
  }

  GetAffinityRecommendationsMySubscriptionsPodcastSubscriptionTypesOnPodcastUserSubscriptionTypesOnUser({
    required this.podcast,
  });
}

@immutable
class GetAffinityRecommendationsMySubscriptionsPodcastSubscriptionTypesOnPodcastUserSubscriptionTypesOnUserPodcast {
  final String id;
  final String title;
  final String feedUrl;
  final String? imageUrl;
  final String? author;
  final List<String>? categories;
  GetAffinityRecommendationsMySubscriptionsPodcastSubscriptionTypesOnPodcastUserSubscriptionTypesOnUserPodcast.fromJson(
      dynamic json)
      : id = nativeFromJson<String>(json['id']),
        title = nativeFromJson<String>(json['title']),
        feedUrl = nativeFromJson<String>(json['feedUrl']),
        imageUrl = json['imageUrl'] == null
            ? null
            : nativeFromJson<String>(json['imageUrl']),
        author = json['author'] == null
            ? null
            : nativeFromJson<String>(json['author']),
        categories = json['categories'] == null
            ? null
            : (json['categories'] as List<dynamic>)
                .map((e) => nativeFromJson<String>(e))
                .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetAffinityRecommendationsMySubscriptionsPodcastSubscriptionTypesOnPodcastUserSubscriptionTypesOnUserPodcast
        otherTyped = other
            as GetAffinityRecommendationsMySubscriptionsPodcastSubscriptionTypesOnPodcastUserSubscriptionTypesOnUserPodcast;
    return id == otherTyped.id &&
        title == otherTyped.title &&
        feedUrl == otherTyped.feedUrl &&
        imageUrl == otherTyped.imageUrl &&
        author == otherTyped.author &&
        categories == otherTyped.categories;
  }

  @override
  int get hashCode => Object.hashAll([
        id.hashCode,
        title.hashCode,
        feedUrl.hashCode,
        imageUrl.hashCode,
        author.hashCode,
        categories.hashCode
      ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['title'] = nativeToJson<String>(title);
    json['feedUrl'] = nativeToJson<String>(feedUrl);
    if (imageUrl != null) {
      json['imageUrl'] = nativeToJson<String?>(imageUrl);
    }
    if (author != null) {
      json['author'] = nativeToJson<String?>(author);
    }
    if (categories != null) {
      json['categories'] =
          categories?.map((e) => nativeToJson<String>(e)).toList();
    }
    return json;
  }

  GetAffinityRecommendationsMySubscriptionsPodcastSubscriptionTypesOnPodcastUserSubscriptionTypesOnUserPodcast({
    required this.id,
    required this.title,
    required this.feedUrl,
    this.imageUrl,
    this.author,
    this.categories,
  });
}

@immutable
class GetAffinityRecommendationsData {
  final List<GetAffinityRecommendationsMySubscriptions> mySubscriptions;
  GetAffinityRecommendationsData.fromJson(dynamic json)
      : mySubscriptions = (json['mySubscriptions'] as List<dynamic>)
            .map((e) => GetAffinityRecommendationsMySubscriptions.fromJson(e))
            .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetAffinityRecommendationsData otherTyped =
        other as GetAffinityRecommendationsData;
    return mySubscriptions == otherTyped.mySubscriptions;
  }

  @override
  int get hashCode => mySubscriptions.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['mySubscriptions'] = mySubscriptions.map((e) => e.toJson()).toList();
    return json;
  }

  GetAffinityRecommendationsData({
    required this.mySubscriptions,
  });
}

@immutable
class GetAffinityRecommendationsVariables {
  final String userId;
  @Deprecated(
      'fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetAffinityRecommendationsVariables.fromJson(Map<String, dynamic> json)
      : userId = nativeFromJson<String>(json['userId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetAffinityRecommendationsVariables otherTyped =
        other as GetAffinityRecommendationsVariables;
    return userId == otherTyped.userId;
  }

  @override
  int get hashCode => userId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userId'] = nativeToJson<String>(userId);
    return json;
  }

  GetAffinityRecommendationsVariables({
    required this.userId,
  });
}
