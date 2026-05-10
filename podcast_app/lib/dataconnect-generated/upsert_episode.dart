part of 'example.dart';

class UpsertEpisodeVariablesBuilder {
  Optional<String> _id = Optional.optional(nativeFromJson, nativeToJson);
  String podcastId;
  String title;
  String audioUrl;
  BigInt duration;
  Optional<String> _description =
      Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _imageUrl = Optional.optional(nativeFromJson, nativeToJson);
  Timestamp publishedAt;

  final FirebaseDataConnect _dataConnect;
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

  UpsertEpisodeVariablesBuilder(
    this._dataConnect, {
    required this.podcastId,
    required this.title,
    required this.audioUrl,
    required this.duration,
    required this.publishedAt,
  });
  Deserializer<UpsertEpisodeData> dataDeserializer =
      (dynamic json) => UpsertEpisodeData.fromJson(jsonDecode(json));
  Serializer<UpsertEpisodeVariables> varsSerializer =
      (UpsertEpisodeVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpsertEpisodeData, UpsertEpisodeVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpsertEpisodeData, UpsertEpisodeVariables> ref() {
    UpsertEpisodeVariables vars = UpsertEpisodeVariables(
      id: _id,
      podcastId: podcastId,
      title: title,
      audioUrl: audioUrl,
      duration: duration,
      description: _description,
      imageUrl: _imageUrl,
      publishedAt: publishedAt,
    );
    return _dataConnect.mutation(
        "UpsertEpisode", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpsertEpisodeEpisodeUpsert {
  final String id;
  UpsertEpisodeEpisodeUpsert.fromJson(dynamic json)
      : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertEpisodeEpisodeUpsert otherTyped =
        other as UpsertEpisodeEpisodeUpsert;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpsertEpisodeEpisodeUpsert({
    required this.id,
  });
}

@immutable
class UpsertEpisodeData {
  final UpsertEpisodeEpisodeUpsert episode_upsert;
  UpsertEpisodeData.fromJson(dynamic json)
      : episode_upsert =
            UpsertEpisodeEpisodeUpsert.fromJson(json['episode_upsert']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertEpisodeData otherTyped = other as UpsertEpisodeData;
    return episode_upsert == otherTyped.episode_upsert;
  }

  @override
  int get hashCode => episode_upsert.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['episode_upsert'] = episode_upsert.toJson();
    return json;
  }

  UpsertEpisodeData({
    required this.episode_upsert,
  });
}

@immutable
class UpsertEpisodeVariables {
  late final Optional<String> id;
  final String podcastId;
  final String title;
  final String audioUrl;
  final BigInt duration;
  late final Optional<String> description;
  late final Optional<String> imageUrl;
  final Timestamp publishedAt;
  @Deprecated(
      'fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpsertEpisodeVariables.fromJson(Map<String, dynamic> json)
      : podcastId = nativeFromJson<String>(json['podcastId']),
        title = nativeFromJson<String>(json['title']),
        audioUrl = nativeFromJson<String>(json['audioUrl']),
        duration = bigIntFromJson(json['duration']),
        publishedAt = Timestamp.fromJson(json['publishedAt']) {
    id = Optional.optional(nativeFromJson, nativeToJson);
    id.value = json['id'] == null ? null : nativeFromJson<String>(json['id']);

    description = Optional.optional(nativeFromJson, nativeToJson);
    description.value = json['description'] == null
        ? null
        : nativeFromJson<String>(json['description']);

    imageUrl = Optional.optional(nativeFromJson, nativeToJson);
    imageUrl.value = json['imageUrl'] == null
        ? null
        : nativeFromJson<String>(json['imageUrl']);
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertEpisodeVariables otherTyped = other as UpsertEpisodeVariables;
    return id == otherTyped.id &&
        podcastId == otherTyped.podcastId &&
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
        podcastId.hashCode,
        title.hashCode,
        audioUrl.hashCode,
        duration.hashCode,
        description.hashCode,
        imageUrl.hashCode,
        publishedAt.hashCode
      ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (id.state == OptionalState.set) {
      json['id'] = id.toJson();
    }
    json['podcastId'] = nativeToJson<String>(podcastId);
    json['title'] = nativeToJson<String>(title);
    json['audioUrl'] = nativeToJson<String>(audioUrl);
    json['duration'] = bigIntToJson(duration);
    if (description.state == OptionalState.set) {
      json['description'] = description.toJson();
    }
    if (imageUrl.state == OptionalState.set) {
      json['imageUrl'] = imageUrl.toJson();
    }
    json['publishedAt'] = publishedAt.toJson();
    return json;
  }

  UpsertEpisodeVariables({
    required this.id,
    required this.podcastId,
    required this.title,
    required this.audioUrl,
    required this.duration,
    required this.description,
    required this.imageUrl,
    required this.publishedAt,
  });
}
