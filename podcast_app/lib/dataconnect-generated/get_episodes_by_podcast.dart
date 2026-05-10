part of 'example.dart';

class GetEpisodesByPodcastVariablesBuilder {
  String podcastId;

  final FirebaseDataConnect _dataConnect;
  GetEpisodesByPodcastVariablesBuilder(
    this._dataConnect, {
    required this.podcastId,
  });
  Deserializer<GetEpisodesByPodcastData> dataDeserializer =
      (dynamic json) => GetEpisodesByPodcastData.fromJson(jsonDecode(json));
  Serializer<GetEpisodesByPodcastVariables> varsSerializer =
      (GetEpisodesByPodcastVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetEpisodesByPodcastData, GetEpisodesByPodcastVariables>>
      execute() {
    return ref().execute();
  }

  QueryRef<GetEpisodesByPodcastData, GetEpisodesByPodcastVariables> ref() {
    GetEpisodesByPodcastVariables vars = GetEpisodesByPodcastVariables(
      podcastId: podcastId,
    );
    return _dataConnect.query(
        "GetEpisodesByPodcast", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetEpisodesByPodcastEpisodes {
  final String id;
  final String title;
  final String audioUrl;
  final BigInt duration;
  final String? description;
  final String? imageUrl;
  final Timestamp publishedAt;
  GetEpisodesByPodcastEpisodes.fromJson(dynamic json)
      : id = nativeFromJson<String>(json['id']),
        title = nativeFromJson<String>(json['title']),
        audioUrl = nativeFromJson<String>(json['audioUrl']),
        duration = bigIntFromJson(json['duration']),
        description = json['description'] == null
            ? null
            : nativeFromJson<String>(json['description']),
        imageUrl = json['imageUrl'] == null
            ? null
            : nativeFromJson<String>(json['imageUrl']),
        publishedAt = Timestamp.fromJson(json['publishedAt']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetEpisodesByPodcastEpisodes otherTyped =
        other as GetEpisodesByPodcastEpisodes;
    return id == otherTyped.id &&
        title == otherTyped.title &&
        audioUrl == otherTyped.audioUrl &&
        duration == otherTyped.duration &&
        description == otherTyped.description &&
        imageUrl == otherTyped.imageUrl &&
        publishedAt == otherTyped.publishedAt;
  }

  @override
  int get hashCode => Object.hashAll([
        id.hashCode,
        title.hashCode,
        audioUrl.hashCode,
        duration.hashCode,
        description.hashCode,
        imageUrl.hashCode,
        publishedAt.hashCode
      ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['title'] = nativeToJson<String>(title);
    json['audioUrl'] = nativeToJson<String>(audioUrl);
    json['duration'] = bigIntToJson(duration);
    if (description != null) {
      json['description'] = nativeToJson<String?>(description);
    }
    if (imageUrl != null) {
      json['imageUrl'] = nativeToJson<String?>(imageUrl);
    }
    json['publishedAt'] = publishedAt.toJson();
    return json;
  }

  GetEpisodesByPodcastEpisodes({
    required this.id,
    required this.title,
    required this.audioUrl,
    required this.duration,
    this.description,
    this.imageUrl,
    required this.publishedAt,
  });
}

@immutable
class GetEpisodesByPodcastData {
  final List<GetEpisodesByPodcastEpisodes> episodes;
  GetEpisodesByPodcastData.fromJson(dynamic json)
      : episodes = (json['episodes'] as List<dynamic>)
            .map((e) => GetEpisodesByPodcastEpisodes.fromJson(e))
            .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetEpisodesByPodcastData otherTyped =
        other as GetEpisodesByPodcastData;
    return episodes == otherTyped.episodes;
  }

  @override
  int get hashCode => episodes.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['episodes'] = episodes.map((e) => e.toJson()).toList();
    return json;
  }

  GetEpisodesByPodcastData({
    required this.episodes,
  });
}

@immutable
class GetEpisodesByPodcastVariables {
  final String podcastId;
  @Deprecated(
      'fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetEpisodesByPodcastVariables.fromJson(Map<String, dynamic> json)
      : podcastId = nativeFromJson<String>(json['podcastId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetEpisodesByPodcastVariables otherTyped =
        other as GetEpisodesByPodcastVariables;
    return podcastId == otherTyped.podcastId;
  }

  @override
  int get hashCode => podcastId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['podcastId'] = nativeToJson<String>(podcastId);
    return json;
  }

  GetEpisodesByPodcastVariables({
    required this.podcastId,
  });
}
