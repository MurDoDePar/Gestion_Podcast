part of 'example.dart';

class GetRecommendationsVariablesBuilder {
  String feedUrl;

  final FirebaseDataConnect _dataConnect;
  GetRecommendationsVariablesBuilder(
    this._dataConnect, {
    required this.feedUrl,
  });
  Deserializer<GetRecommendationsData> dataDeserializer =
      (dynamic json) => GetRecommendationsData.fromJson(jsonDecode(json));
  Serializer<GetRecommendationsVariables> varsSerializer =
      (GetRecommendationsVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetRecommendationsData, GetRecommendationsVariables>>
      execute() {
    return ref().execute();
  }

  QueryRef<GetRecommendationsData, GetRecommendationsVariables> ref() {
    GetRecommendationsVariables vars = GetRecommendationsVariables(
      feedUrl: feedUrl,
    );
    return _dataConnect.query(
        "GetRecommendations", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetRecommendationsSubscriptionTypes {
  final GetRecommendationsSubscriptionTypesUser user;
  GetRecommendationsSubscriptionTypes.fromJson(dynamic json)
      : user = GetRecommendationsSubscriptionTypesUser.fromJson(json['user']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetRecommendationsSubscriptionTypes otherTyped =
        other as GetRecommendationsSubscriptionTypes;
    return user == otherTyped.user;
  }

  @override
  int get hashCode => user.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['user'] = user.toJson();
    return json;
  }

  GetRecommendationsSubscriptionTypes({
    required this.user,
  });
}

@immutable
class GetRecommendationsSubscriptionTypesUser {
  final List<GetRecommendationsSubscriptionTypesUserSubscriptionTypesOnUser>
      subscriptionTypes_on_user;
  GetRecommendationsSubscriptionTypesUser.fromJson(dynamic json)
      : subscriptionTypes_on_user = (json['subscriptionTypes_on_user']
                as List<dynamic>)
            .map((e) =>
                GetRecommendationsSubscriptionTypesUserSubscriptionTypesOnUser
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

    final GetRecommendationsSubscriptionTypesUser otherTyped =
        other as GetRecommendationsSubscriptionTypesUser;
    return subscriptionTypes_on_user == otherTyped.subscriptionTypes_on_user;
  }

  @override
  int get hashCode => subscriptionTypes_on_user.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['subscriptionTypes_on_user'] =
        subscriptionTypes_on_user.map((e) => e.toJson()).toList();
    return json;
  }

  GetRecommendationsSubscriptionTypesUser({
    required this.subscriptionTypes_on_user,
  });
}

@immutable
class GetRecommendationsSubscriptionTypesUserSubscriptionTypesOnUser {
  final GetRecommendationsSubscriptionTypesUserSubscriptionTypesOnUserPodcast
      podcast;
  GetRecommendationsSubscriptionTypesUserSubscriptionTypesOnUser.fromJson(
      dynamic json)
      : podcast =
            GetRecommendationsSubscriptionTypesUserSubscriptionTypesOnUserPodcast
                .fromJson(json['podcast']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetRecommendationsSubscriptionTypesUserSubscriptionTypesOnUser
        otherTyped =
        other as GetRecommendationsSubscriptionTypesUserSubscriptionTypesOnUser;
    return podcast == otherTyped.podcast;
  }

  @override
  int get hashCode => podcast.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['podcast'] = podcast.toJson();
    return json;
  }

  GetRecommendationsSubscriptionTypesUserSubscriptionTypesOnUser({
    required this.podcast,
  });
}

@immutable
class GetRecommendationsSubscriptionTypesUserSubscriptionTypesOnUserPodcast {
  final String id;
  final String title;
  final String? imageUrl;
  final String feedUrl;
  final String? author;
  final List<String>? categories;
  GetRecommendationsSubscriptionTypesUserSubscriptionTypesOnUserPodcast.fromJson(
      dynamic json)
      : id = nativeFromJson<String>(json['id']),
        title = nativeFromJson<String>(json['title']),
        imageUrl = json['imageUrl'] == null
            ? null
            : nativeFromJson<String>(json['imageUrl']),
        feedUrl = nativeFromJson<String>(json['feedUrl']),
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

    final GetRecommendationsSubscriptionTypesUserSubscriptionTypesOnUserPodcast
        otherTyped = other
            as GetRecommendationsSubscriptionTypesUserSubscriptionTypesOnUserPodcast;
    return id == otherTyped.id &&
        title == otherTyped.title &&
        imageUrl == otherTyped.imageUrl &&
        feedUrl == otherTyped.feedUrl &&
        author == otherTyped.author &&
        categories == otherTyped.categories;
  }

  @override
  int get hashCode => Object.hashAll([
        id.hashCode,
        title.hashCode,
        imageUrl.hashCode,
        feedUrl.hashCode,
        author.hashCode,
        categories.hashCode
      ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['title'] = nativeToJson<String>(title);
    if (imageUrl != null) {
      json['imageUrl'] = nativeToJson<String?>(imageUrl);
    }
    json['feedUrl'] = nativeToJson<String>(feedUrl);
    if (author != null) {
      json['author'] = nativeToJson<String?>(author);
    }
    if (categories != null) {
      json['categories'] =
          categories?.map((e) => nativeToJson<String>(e)).toList();
    }
    return json;
  }

  GetRecommendationsSubscriptionTypesUserSubscriptionTypesOnUserPodcast({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.feedUrl,
    this.author,
    this.categories,
  });
}

@immutable
class GetRecommendationsData {
  final List<GetRecommendationsSubscriptionTypes> subscriptionTypes;
  GetRecommendationsData.fromJson(dynamic json)
      : subscriptionTypes = (json['subscriptionTypes'] as List<dynamic>)
            .map((e) => GetRecommendationsSubscriptionTypes.fromJson(e))
            .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetRecommendationsData otherTyped = other as GetRecommendationsData;
    return subscriptionTypes == otherTyped.subscriptionTypes;
  }

  @override
  int get hashCode => subscriptionTypes.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['subscriptionTypes'] =
        subscriptionTypes.map((e) => e.toJson()).toList();
    return json;
  }

  GetRecommendationsData({
    required this.subscriptionTypes,
  });
}

@immutable
class GetRecommendationsVariables {
  final String feedUrl;
  @Deprecated(
      'fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetRecommendationsVariables.fromJson(Map<String, dynamic> json)
      : feedUrl = nativeFromJson<String>(json['feedUrl']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetRecommendationsVariables otherTyped =
        other as GetRecommendationsVariables;
    return feedUrl == otherTyped.feedUrl;
  }

  @override
  int get hashCode => feedUrl.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['feedUrl'] = nativeToJson<String>(feedUrl);
    return json;
  }

  GetRecommendationsVariables({
    required this.feedUrl,
  });
}
