part of 'example.dart';

class GetLatestSubscribedEpisodesVariablesBuilder {
  String userId;

  final FirebaseDataConnect _dataConnect;
  GetLatestSubscribedEpisodesVariablesBuilder(
    this._dataConnect, {
    required this.userId,
  });
  Deserializer<GetLatestSubscribedEpisodesData> dataDeserializer =
      (dynamic json) =>
          GetLatestSubscribedEpisodesData.fromJson(jsonDecode(json));
  Serializer<GetLatestSubscribedEpisodesVariables> varsSerializer =
      (GetLatestSubscribedEpisodesVariables vars) => jsonEncode(vars.toJson());
  Future<
      QueryResult<GetLatestSubscribedEpisodesData,
          GetLatestSubscribedEpisodesVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetLatestSubscribedEpisodesData,
      GetLatestSubscribedEpisodesVariables> ref() {
    GetLatestSubscribedEpisodesVariables vars =
        GetLatestSubscribedEpisodesVariables(
      userId: userId,
    );
    return _dataConnect.query(
        "GetLatestSubscribedEpisodes", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetLatestSubscribedEpisodesSubscriptionTypes {
  final int? listOrder;
  final GetLatestSubscribedEpisodesSubscriptionTypesPodcast podcast;
  GetLatestSubscribedEpisodesSubscriptionTypes.fromJson(dynamic json)
      : listOrder = json['listOrder'] == null
            ? null
            : nativeFromJson<int>(json['listOrder']),
        podcast = GetLatestSubscribedEpisodesSubscriptionTypesPodcast.fromJson(
            json['podcast']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetLatestSubscribedEpisodesSubscriptionTypes otherTyped =
        other as GetLatestSubscribedEpisodesSubscriptionTypes;
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

  GetLatestSubscribedEpisodesSubscriptionTypes({
    this.listOrder,
    required this.podcast,
  });
}

@immutable
class GetLatestSubscribedEpisodesSubscriptionTypesPodcast {
  final String id;
  final String title;
  final String? imageUrl;
  final List<
          GetLatestSubscribedEpisodesSubscriptionTypesPodcastEpisodesOnPodcast>
      episodes_on_podcast;
  GetLatestSubscribedEpisodesSubscriptionTypesPodcast.fromJson(dynamic json)
      : id = nativeFromJson<String>(json['id']),
        title = nativeFromJson<String>(json['title']),
        imageUrl = json['imageUrl'] == null
            ? null
            : nativeFromJson<String>(json['imageUrl']),
        episodes_on_podcast = (json['episodes_on_podcast'] as List<dynamic>)
            .map((e) =>
                GetLatestSubscribedEpisodesSubscriptionTypesPodcastEpisodesOnPodcast
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

    final GetLatestSubscribedEpisodesSubscriptionTypesPodcast otherTyped =
        other as GetLatestSubscribedEpisodesSubscriptionTypesPodcast;
    return id == otherTyped.id &&
        title == otherTyped.title &&
        imageUrl == otherTyped.imageUrl &&
        episodes_on_podcast == otherTyped.episodes_on_podcast;
  }

  @override
  int get hashCode => Object.hashAll([
        id.hashCode,
        title.hashCode,
        imageUrl.hashCode,
        episodes_on_podcast.hashCode
      ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['title'] = nativeToJson<String>(title);
    if (imageUrl != null) {
      json['imageUrl'] = nativeToJson<String?>(imageUrl);
    }
    json['episodes_on_podcast'] =
        episodes_on_podcast.map((e) => e.toJson()).toList();
    return json;
  }

  GetLatestSubscribedEpisodesSubscriptionTypesPodcast({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.episodes_on_podcast,
  });
}

@immutable
class GetLatestSubscribedEpisodesSubscriptionTypesPodcastEpisodesOnPodcast {
  final String id;
  final String title;
  final String audioUrl;
  final Timestamp publishedAt;
  final String? imageUrl;
  GetLatestSubscribedEpisodesSubscriptionTypesPodcastEpisodesOnPodcast.fromJson(
      dynamic json)
      : id = nativeFromJson<String>(json['id']),
        title = nativeFromJson<String>(json['title']),
        audioUrl = nativeFromJson<String>(json['audioUrl']),
        publishedAt = Timestamp.fromJson(json['publishedAt']),
        imageUrl = json['imageUrl'] == null
            ? null
            : nativeFromJson<String>(json['imageUrl']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetLatestSubscribedEpisodesSubscriptionTypesPodcastEpisodesOnPodcast
        otherTyped = other
            as GetLatestSubscribedEpisodesSubscriptionTypesPodcastEpisodesOnPodcast;
    return id == otherTyped.id &&
        title == otherTyped.title &&
        audioUrl == otherTyped.audioUrl &&
        publishedAt == otherTyped.publishedAt &&
        imageUrl == otherTyped.imageUrl;
  }

  @override
  int get hashCode => Object.hashAll([
        id.hashCode,
        title.hashCode,
        audioUrl.hashCode,
        publishedAt.hashCode,
        imageUrl.hashCode
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
    return json;
  }

  GetLatestSubscribedEpisodesSubscriptionTypesPodcastEpisodesOnPodcast({
    required this.id,
    required this.title,
    required this.audioUrl,
    required this.publishedAt,
    this.imageUrl,
  });
}

@immutable
class GetLatestSubscribedEpisodesData {
  final List<GetLatestSubscribedEpisodesSubscriptionTypes> subscriptionTypes;
  GetLatestSubscribedEpisodesData.fromJson(dynamic json)
      : subscriptionTypes = (json['subscriptionTypes'] as List<dynamic>)
            .map(
                (e) => GetLatestSubscribedEpisodesSubscriptionTypes.fromJson(e))
            .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetLatestSubscribedEpisodesData otherTyped =
        other as GetLatestSubscribedEpisodesData;
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

  GetLatestSubscribedEpisodesData({
    required this.subscriptionTypes,
  });
}

@immutable
class GetLatestSubscribedEpisodesVariables {
  final String userId;
  @Deprecated(
      'fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetLatestSubscribedEpisodesVariables.fromJson(Map<String, dynamic> json)
      : userId = nativeFromJson<String>(json['userId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetLatestSubscribedEpisodesVariables otherTyped =
        other as GetLatestSubscribedEpisodesVariables;
    return userId == otherTyped.userId;
  }

  @override
  int get hashCode => userId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userId'] = nativeToJson<String>(userId);
    return json;
  }

  GetLatestSubscribedEpisodesVariables({
    required this.userId,
  });
}
