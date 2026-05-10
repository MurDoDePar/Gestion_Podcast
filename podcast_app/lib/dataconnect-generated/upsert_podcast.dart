part of 'example.dart';

class UpsertPodcastVariablesBuilder {
  Optional<String> _id = Optional.optional(nativeFromJson, nativeToJson);
  String title;
  String feedUrl;
  Optional<String> _description =
      Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _imageUrl = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _author = Optional.optional(nativeFromJson, nativeToJson);
  Optional<List<String>> _categories = Optional.optional(
      listDeserializer(nativeFromJson), listSerializer(nativeToJson));
  Timestamp createdAt;

  final FirebaseDataConnect _dataConnect;
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

  UpsertPodcastVariablesBuilder(
    this._dataConnect, {
    required this.title,
    required this.feedUrl,
    required this.createdAt,
  });
  Deserializer<UpsertPodcastData> dataDeserializer =
      (dynamic json) => UpsertPodcastData.fromJson(jsonDecode(json));
  Serializer<UpsertPodcastVariables> varsSerializer =
      (UpsertPodcastVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpsertPodcastData, UpsertPodcastVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpsertPodcastData, UpsertPodcastVariables> ref() {
    UpsertPodcastVariables vars = UpsertPodcastVariables(
      id: _id,
      title: title,
      feedUrl: feedUrl,
      description: _description,
      imageUrl: _imageUrl,
      author: _author,
      categories: _categories,
      createdAt: createdAt,
    );
    return _dataConnect.mutation(
        "UpsertPodcast", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpsertPodcastPodcastUpsert {
  final String id;
  UpsertPodcastPodcastUpsert.fromJson(dynamic json)
      : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertPodcastPodcastUpsert otherTyped =
        other as UpsertPodcastPodcastUpsert;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpsertPodcastPodcastUpsert({
    required this.id,
  });
}

@immutable
class UpsertPodcastData {
  final UpsertPodcastPodcastUpsert podcast_upsert;
  UpsertPodcastData.fromJson(dynamic json)
      : podcast_upsert =
            UpsertPodcastPodcastUpsert.fromJson(json['podcast_upsert']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertPodcastData otherTyped = other as UpsertPodcastData;
    return podcast_upsert == otherTyped.podcast_upsert;
  }

  @override
  int get hashCode => podcast_upsert.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['podcast_upsert'] = podcast_upsert.toJson();
    return json;
  }

  UpsertPodcastData({
    required this.podcast_upsert,
  });
}

@immutable
class UpsertPodcastVariables {
  late final Optional<String> id;
  final String title;
  final String feedUrl;
  late final Optional<String> description;
  late final Optional<String> imageUrl;
  late final Optional<String> author;
  late final Optional<List<String>> categories;
  final Timestamp createdAt;
  @Deprecated(
      'fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpsertPodcastVariables.fromJson(Map<String, dynamic> json)
      : title = nativeFromJson<String>(json['title']),
        feedUrl = nativeFromJson<String>(json['feedUrl']),
        createdAt = Timestamp.fromJson(json['createdAt']) {
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

    author = Optional.optional(nativeFromJson, nativeToJson);
    author.value =
        json['author'] == null ? null : nativeFromJson<String>(json['author']);

    categories = Optional.optional(
        listDeserializer(nativeFromJson), listSerializer(nativeToJson));
    categories.value = json['categories'] == null
        ? null
        : (json['categories'] as List<dynamic>)
            .map((e) => nativeFromJson<String>(e))
            .toList();
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertPodcastVariables otherTyped = other as UpsertPodcastVariables;
    return id == otherTyped.id &&
        title == otherTyped.title &&
        feedUrl == otherTyped.feedUrl &&
        description == otherTyped.description &&
        imageUrl == otherTyped.imageUrl &&
        author == otherTyped.author &&
        categories == otherTyped.categories &&
        createdAt == otherTyped.createdAt;
  }

  @override
  int get hashCode => Object.hashAll([
        id.hashCode,
        title.hashCode,
        feedUrl.hashCode,
        description.hashCode,
        imageUrl.hashCode,
        author.hashCode,
        categories.hashCode,
        createdAt.hashCode
      ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (id.state == OptionalState.set) {
      json['id'] = id.toJson();
    }
    json['title'] = nativeToJson<String>(title);
    json['feedUrl'] = nativeToJson<String>(feedUrl);
    if (description.state == OptionalState.set) {
      json['description'] = description.toJson();
    }
    if (imageUrl.state == OptionalState.set) {
      json['imageUrl'] = imageUrl.toJson();
    }
    if (author.state == OptionalState.set) {
      json['author'] = author.toJson();
    }
    if (categories.state == OptionalState.set) {
      json['categories'] = categories.toJson();
    }
    json['createdAt'] = createdAt.toJson();
    return json;
  }

  UpsertPodcastVariables({
    required this.id,
    required this.title,
    required this.feedUrl,
    required this.description,
    required this.imageUrl,
    required this.author,
    required this.categories,
    required this.createdAt,
  });
}
