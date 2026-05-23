part of 'example.dart';

class GetMySubscriptionsVariablesBuilder {
  String userId;

  final FirebaseDataConnect _dataConnect;
  GetMySubscriptionsVariablesBuilder(
    this._dataConnect, {
    required this.userId,
  });
  Deserializer<GetMySubscriptionsData> dataDeserializer =
      (dynamic json) => GetMySubscriptionsData.fromJson(jsonDecode(json));
  Serializer<GetMySubscriptionsVariables> varsSerializer =
      (GetMySubscriptionsVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetMySubscriptionsData, GetMySubscriptionsVariables>>
      execute() {
    return ref().execute();
  }

  QueryRef<GetMySubscriptionsData, GetMySubscriptionsVariables> ref() {
    GetMySubscriptionsVariables vars = GetMySubscriptionsVariables(
      userId: userId,
    );
    return _dataConnect.query(
        "GetMySubscriptions", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetMySubscriptionsSubscriptionTypes {
  final int? listOrder;
  final GetMySubscriptionsSubscriptionTypesPodcast podcast;
  GetMySubscriptionsSubscriptionTypes.fromJson(dynamic json)
      : listOrder = json['listOrder'] == null
            ? null
            : nativeFromJson<int>(json['listOrder']),
        podcast = GetMySubscriptionsSubscriptionTypesPodcast.fromJson(
            json['podcast']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetMySubscriptionsSubscriptionTypes otherTyped =
        other as GetMySubscriptionsSubscriptionTypes;
    return listOrder == otherTyped.listOrder && podcast == otherTyped.podcast;
  }

  @override
  int get hashCode => Object.hashAll([listOrder.hashCode, podcast.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (listOrder != null) {
      json['listOrder'] = nativeToJson<int?>(listOrder);
    }
    json['podcast'] = podcast.toJson();
    return json;
  }

  GetMySubscriptionsSubscriptionTypes({
    this.listOrder,
    required this.podcast,
  });
}

@immutable
class GetMySubscriptionsSubscriptionTypesPodcast {
  final String id;
  final String title;
  final String feedUrl;
  final String? imageUrl;
  final String? author;
  final List<String>? categories;
  GetMySubscriptionsSubscriptionTypesPodcast.fromJson(dynamic json)
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

    final GetMySubscriptionsSubscriptionTypesPodcast otherTyped =
        other as GetMySubscriptionsSubscriptionTypesPodcast;
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

  GetMySubscriptionsSubscriptionTypesPodcast({
    required this.id,
    required this.title,
    required this.feedUrl,
    this.imageUrl,
    this.author,
    this.categories,
  });
}

@immutable
class GetMySubscriptionsData {
  final List<GetMySubscriptionsSubscriptionTypes> subscriptionTypes;
  GetMySubscriptionsData.fromJson(dynamic json)
      : subscriptionTypes = (json['subscriptionTypes'] as List<dynamic>)
            .map((e) => GetMySubscriptionsSubscriptionTypes.fromJson(e))
            .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetMySubscriptionsData otherTyped = other as GetMySubscriptionsData;
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

  GetMySubscriptionsData({
    required this.subscriptionTypes,
  });
}

@immutable
class GetMySubscriptionsVariables {
  final String userId;
  @Deprecated(
      'fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetMySubscriptionsVariables.fromJson(Map<String, dynamic> json)
      : userId = nativeFromJson<String>(json['userId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetMySubscriptionsVariables otherTyped =
        other as GetMySubscriptionsVariables;
    return userId == otherTyped.userId;
  }

  @override
  int get hashCode => userId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userId'] = nativeToJson<String>(userId);
    return json;
  }

  GetMySubscriptionsVariables({
    required this.userId,
  });
}
