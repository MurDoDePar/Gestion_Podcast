part of 'example.dart';

class GetOldestSubscribedEpisodesVariablesBuilder {
  String userId;

  final FirebaseDataConnect _dataConnect;
  GetOldestSubscribedEpisodesVariablesBuilder(
    this._dataConnect, {
    required this.userId,
  });
  Deserializer<GetOldestSubscribedEpisodesData> dataDeserializer =
      (dynamic json) =>
          GetOldestSubscribedEpisodesData.fromJson(jsonDecode(json));
  Serializer<GetOldestSubscribedEpisodesVariables> varsSerializer =
      (GetOldestSubscribedEpisodesVariables vars) => jsonEncode(vars.toJson());
  Future<
      QueryResult<GetOldestSubscribedEpisodesData,
          GetOldestSubscribedEpisodesVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetOldestSubscribedEpisodesData,
      GetOldestSubscribedEpisodesVariables> ref() {
    GetOldestSubscribedEpisodesVariables vars =
        GetOldestSubscribedEpisodesVariables(
      userId: userId,
    );
    return _dataConnect.query(
        "GetOldestSubscribedEpisodes", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetOldestSubscribedEpisodesSubscriptionTypes {
  final int? listOrder;
  final GetOldestSubscribedEpisodesSubscriptionTypesPodcast podcast;
  GetOldestSubscribedEpisodesSubscriptionTypes.fromJson(dynamic json)
      : listOrder = json['listOrder'] == null
            ? null
            : nativeFromJson<int>(json['listOrder']),
        podcast = GetOldestSubscribedEpisodesSubscriptionTypesPodcast.fromJson(
            json['podcast']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetOldestSubscribedEpisodesSubscriptionTypes otherTyped =
        other as GetOldestSubscribedEpisodesSubscriptionTypes;
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

  GetOldestSubscribedEpisodesSubscriptionTypes({
    this.listOrder,
    required this.podcast,
  });
}

@immutable
class GetOldestSubscribedEpisodesSubscriptionTypesPodcast {
  final String id;
  final String title;
  final String? imageUrl;
  final List<GetOldestSubscribedEpisodesSubscriptionTypesPodcastOldestEpisodes>
      oldest_episodes;
  GetOldestSubscribedEpisodesSubscriptionTypesPodcast.fromJson(dynamic json)
      : id = nativeFromJson<String>(json['id']),
        title = nativeFromJson<String>(json['title']),
        imageUrl = json['imageUrl'] == null
            ? null
            : nativeFromJson<String>(json['imageUrl']),
        oldest_episodes = (json['oldest_episodes'] as List<dynamic>)
            .map((e) =>
                GetOldestSubscribedEpisodesSubscriptionTypesPodcastOldestEpisodes
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

    final GetOldestSubscribedEpisodesSubscriptionTypesPodcast otherTyped =
        other as GetOldestSubscribedEpisodesSubscriptionTypesPodcast;
    return id == otherTyped.id &&
        title == otherTyped.title &&
        imageUrl == otherTyped.imageUrl &&
        oldest_episodes == otherTyped.oldest_episodes;
  }

  @override
  int get hashCode => Object.hashAll([
        id.hashCode,
        title.hashCode,
        imageUrl.hashCode,
        oldest_episodes.hashCode
      ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['title'] = nativeToJson<String>(title);
    if (imageUrl != null) {
      json['imageUrl'] = nativeToJson<String?>(imageUrl);
    }
    json['oldest_episodes'] = oldest_episodes.map((e) => e.toJson()).toList();
    return json;
  }

  GetOldestSubscribedEpisodesSubscriptionTypesPodcast({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.oldest_episodes,
  });
}

@immutable
class GetOldestSubscribedEpisodesSubscriptionTypesPodcastOldestEpisodes {
  final String id;
  final String title;
  final String audioUrl;
  final Timestamp publishedAt;
  final String? imageUrl;
  final String? description;
  GetOldestSubscribedEpisodesSubscriptionTypesPodcastOldestEpisodes.fromJson(
      dynamic json)
      : id = nativeFromJson<String>(json['id']),
        title = nativeFromJson<String>(json['title']),
        audioUrl = nativeFromJson<String>(json['audioUrl']),
        publishedAt = Timestamp.fromJson(json['publishedAt']),
        imageUrl = json['imageUrl'] == null
            ? null
            : nativeFromJson<String>(json['imageUrl']),
        description = json['description'] == null
            ? null
            : nativeFromJson<String>(json['description']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetOldestSubscribedEpisodesSubscriptionTypesPodcastOldestEpisodes
        otherTyped = other
            as GetOldestSubscribedEpisodesSubscriptionTypesPodcastOldestEpisodes;
    return id == otherTyped.id &&
        title == otherTyped.title &&
        audioUrl == otherTyped.audioUrl &&
        publishedAt == otherTyped.publishedAt &&
        imageUrl == otherTyped.imageUrl &&
        description == otherTyped.description;
  }

  @override
  int get hashCode => Object.hashAll([
        id.hashCode,
        title.hashCode,
        audioUrl.hashCode,
        publishedAt.hashCode,
        imageUrl.hashCode,
        description.hashCode
      ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['title'] = nativeToJson<String>(title);
    json['audioUrl'] = nativeToJson<String>(audioUrl);
    json['publishedAt'] = publishedAt.toJson();
    if (imageUrl != null) {
      json['imageUrl'] = nativeToJson<String?>(imageUrl);
    }
    if (description != null) {
      json['description'] = nativeToJson<String?>(description);
    }
    return json;
  }

  GetOldestSubscribedEpisodesSubscriptionTypesPodcastOldestEpisodes({
    required this.id,
    required this.title,
    required this.audioUrl,
    required this.publishedAt,
    this.imageUrl,
    this.description,
  });
}

@immutable
class GetOldestSubscribedEpisodesData {
  final List<GetOldestSubscribedEpisodesSubscriptionTypes> subscriptionTypes;
  GetOldestSubscribedEpisodesData.fromJson(dynamic json)
      : subscriptionTypes = (json['subscriptionTypes'] as List<dynamic>)
            .map(
                (e) => GetOldestSubscribedEpisodesSubscriptionTypes.fromJson(e))
            .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetOldestSubscribedEpisodesData otherTyped =
        other as GetOldestSubscribedEpisodesData;
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

  GetOldestSubscribedEpisodesData({
    required this.subscriptionTypes,
  });
}

@immutable
class GetOldestSubscribedEpisodesVariables {
  final String userId;
  @Deprecated(
      'fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetOldestSubscribedEpisodesVariables.fromJson(Map<String, dynamic> json)
      : userId = nativeFromJson<String>(json['userId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetOldestSubscribedEpisodesVariables otherTyped =
        other as GetOldestSubscribedEpisodesVariables;
    return userId == otherTyped.userId;
  }

  @override
  int get hashCode => userId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userId'] = nativeToJson<String>(userId);
    return json;
  }

  GetOldestSubscribedEpisodesVariables({
    required this.userId,
  });
}
