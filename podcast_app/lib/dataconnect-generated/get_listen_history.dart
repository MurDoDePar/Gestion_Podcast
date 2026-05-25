part of 'example.dart';

class GetListenHistoryVariablesBuilder {
  String userId;

  final FirebaseDataConnect _dataConnect;
  GetListenHistoryVariablesBuilder(
    this._dataConnect, {
    required this.userId,
  });
  Deserializer<GetListenHistoryData> dataDeserializer =
      (dynamic json) => GetListenHistoryData.fromJson(jsonDecode(json));
  Serializer<GetListenHistoryVariables> varsSerializer =
      (GetListenHistoryVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetListenHistoryData, GetListenHistoryVariables>>
      execute() {
    return ref().execute();
  }

  QueryRef<GetListenHistoryData, GetListenHistoryVariables> ref() {
    GetListenHistoryVariables vars = GetListenHistoryVariables(
      userId: userId,
    );
    return _dataConnect.query(
        "GetListenHistory", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetListenHistoryListenHistories {
  final GetListenHistoryListenHistoriesEpisode episode;
  final BigInt progressSeconds;
  final bool? finishedListening;
  GetListenHistoryListenHistories.fromJson(dynamic json)
      : episode =
            GetListenHistoryListenHistoriesEpisode.fromJson(json['episode']),
        progressSeconds = bigIntFromJson(json['progressSeconds']),
        finishedListening = json['finishedListening'] == null
            ? null
            : nativeFromJson<bool>(json['finishedListening']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetListenHistoryListenHistories otherTyped =
        other as GetListenHistoryListenHistories;
    return episode == otherTyped.episode &&
        progressSeconds == otherTyped.progressSeconds &&
        finishedListening == otherTyped.finishedListening;
  }

  @override
  int get hashCode => Object.hashAll(
      [episode.hashCode, progressSeconds.hashCode, finishedListening.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['episode'] = episode.toJson();
    json['progressSeconds'] = bigIntToJson(progressSeconds);
    if (finishedListening != null) {
      json['finishedListening'] = nativeToJson<bool?>(finishedListening);
    }
    return json;
  }

  GetListenHistoryListenHistories({
    required this.episode,
    required this.progressSeconds,
    this.finishedListening,
  });
}

@immutable
class GetListenHistoryListenHistoriesEpisode {
  final String id;
  final String audioUrl;
  GetListenHistoryListenHistoriesEpisode.fromJson(dynamic json)
      : id = nativeFromJson<String>(json['id']),
        audioUrl = nativeFromJson<String>(json['audioUrl']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetListenHistoryListenHistoriesEpisode otherTyped =
        other as GetListenHistoryListenHistoriesEpisode;
    return id == otherTyped.id && audioUrl == otherTyped.audioUrl;
  }

  @override
  int get hashCode => Object.hashAll([id.hashCode, audioUrl.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['audioUrl'] = nativeToJson<String>(audioUrl);
    return json;
  }

  GetListenHistoryListenHistoriesEpisode({
    required this.id,
    required this.audioUrl,
  });
}

@immutable
class GetListenHistoryData {
  final List<GetListenHistoryListenHistories> listenHistories;
  GetListenHistoryData.fromJson(dynamic json)
      : listenHistories = (json['listenHistories'] as List<dynamic>)
            .map((e) => GetListenHistoryListenHistories.fromJson(e))
            .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetListenHistoryData otherTyped = other as GetListenHistoryData;
    return listenHistories == otherTyped.listenHistories;
  }

  @override
  int get hashCode => listenHistories.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['listenHistories'] = listenHistories.map((e) => e.toJson()).toList();
    return json;
  }

  GetListenHistoryData({
    required this.listenHistories,
  });
}

@immutable
class GetListenHistoryVariables {
  final String userId;
  @Deprecated(
      'fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetListenHistoryVariables.fromJson(Map<String, dynamic> json)
      : userId = nativeFromJson<String>(json['userId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetListenHistoryVariables otherTyped =
        other as GetListenHistoryVariables;
    return userId == otherTyped.userId;
  }

  @override
  int get hashCode => userId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userId'] = nativeToJson<String>(userId);
    return json;
  }

  GetListenHistoryVariables({
    required this.userId,
  });
}
