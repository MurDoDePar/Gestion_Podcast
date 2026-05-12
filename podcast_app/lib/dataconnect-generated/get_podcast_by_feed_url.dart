part of 'example.dart';

class GetPodcastByFeedUrlVariablesBuilder {
  String feedUrl;

  final FirebaseDataConnect _dataConnect;
  GetPodcastByFeedUrlVariablesBuilder(
    this._dataConnect, {
    required this.feedUrl,
  });
  Deserializer<GetPodcastByFeedUrlData> dataDeserializer =
      (dynamic json) => GetPodcastByFeedUrlData.fromJson(jsonDecode(json));
  Serializer<GetPodcastByFeedUrlVariables> varsSerializer =
      (GetPodcastByFeedUrlVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetPodcastByFeedUrlData, GetPodcastByFeedUrlVariables>>
      execute() {
    return ref().execute();
  }

  QueryRef<GetPodcastByFeedUrlData, GetPodcastByFeedUrlVariables> ref() {
    GetPodcastByFeedUrlVariables vars = GetPodcastByFeedUrlVariables(
      feedUrl: feedUrl,
    );
    return _dataConnect.query(
        "GetPodcastByFeedUrl", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetPodcastByFeedUrlPodcasts {
  final String id;
  final String title;
  final String feedUrl;
  final String? imageUrl;
  GetPodcastByFeedUrlPodcasts.fromJson(dynamic json)
      : id = nativeFromJson<String>(json['id']),
        title = nativeFromJson<String>(json['title']),
        feedUrl = nativeFromJson<String>(json['feedUrl']),
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

    final GetPodcastByFeedUrlPodcasts otherTyped =
        other as GetPodcastByFeedUrlPodcasts;
    return id == otherTyped.id &&
        title == otherTyped.title &&
        feedUrl == otherTyped.feedUrl &&
        imageUrl == otherTyped.imageUrl;
  }

  @override
  int get hashCode => Object.hashAll(
      [id.hashCode, title.hashCode, feedUrl.hashCode, imageUrl.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['title'] = nativeToJson<String>(title);
    json['feedUrl'] = nativeToJson<String>(feedUrl);
    if (imageUrl != null) {
      json['imageUrl'] = nativeToJson<String?>(imageUrl);
    }
    return json;
  }

  GetPodcastByFeedUrlPodcasts({
    required this.id,
    required this.title,
    required this.feedUrl,
    this.imageUrl,
  });
}

@immutable
class GetPodcastByFeedUrlData {
  final List<GetPodcastByFeedUrlPodcasts> podcasts;
  GetPodcastByFeedUrlData.fromJson(dynamic json)
      : podcasts = (json['podcasts'] as List<dynamic>)
            .map((e) => GetPodcastByFeedUrlPodcasts.fromJson(e))
            .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetPodcastByFeedUrlData otherTyped = other as GetPodcastByFeedUrlData;
    return podcasts == otherTyped.podcasts;
  }

  @override
  int get hashCode => podcasts.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['podcasts'] = podcasts.map((e) => e.toJson()).toList();
    return json;
  }

  GetPodcastByFeedUrlData({
    required this.podcasts,
  });
}

@immutable
class GetPodcastByFeedUrlVariables {
  final String feedUrl;
  @Deprecated(
      'fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetPodcastByFeedUrlVariables.fromJson(Map<String, dynamic> json)
      : feedUrl = nativeFromJson<String>(json['feedUrl']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetPodcastByFeedUrlVariables otherTyped =
        other as GetPodcastByFeedUrlVariables;
    return feedUrl == otherTyped.feedUrl;
  }

  @override
  int get hashCode => feedUrl.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['feedUrl'] = nativeToJson<String>(feedUrl);
    return json;
  }

  GetPodcastByFeedUrlVariables({
    required this.feedUrl,
  });
}
