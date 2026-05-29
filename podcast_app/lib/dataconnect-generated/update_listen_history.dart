part of 'example.dart';

class UpdateListenHistoryVariablesBuilder {
  String userId;
  String episodeId;
  BigInt progressSeconds;
  bool finishedListening;
  Timestamp listenedAt;

  final FirebaseDataConnect _dataConnect;
  UpdateListenHistoryVariablesBuilder(
    this._dataConnect, {
    required this.userId,
    required this.episodeId,
    required this.progressSeconds,
    required this.finishedListening,
    required this.listenedAt,
  });
  Deserializer<UpdateListenHistoryData> dataDeserializer =
      (dynamic json) => UpdateListenHistoryData.fromJson(jsonDecode(json));
  Serializer<UpdateListenHistoryVariables> varsSerializer =
      (UpdateListenHistoryVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateListenHistoryData, UpdateListenHistoryVariables>>
      execute() {
    return ref().execute();
  }

  MutationRef<UpdateListenHistoryData, UpdateListenHistoryVariables> ref() {
    UpdateListenHistoryVariables vars = UpdateListenHistoryVariables(
      userId: userId,
      episodeId: episodeId,
      progressSeconds: progressSeconds,
      finishedListening: finishedListening,
      listenedAt: listenedAt,
    );
    return _dataConnect.mutation(
        "UpdateListenHistory", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateListenHistoryListenHistoryUpsert {
  final String userId;
  final String episodeId;
  UpdateListenHistoryListenHistoryUpsert.fromJson(dynamic json)
      : userId = nativeFromJson<String>(json['userId']),
        episodeId = nativeFromJson<String>(json['episodeId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateListenHistoryListenHistoryUpsert otherTyped =
        other as UpdateListenHistoryListenHistoryUpsert;
    return userId == otherTyped.userId && episodeId == otherTyped.episodeId;
  }

  @override
  int get hashCode => Object.hashAll([userId.hashCode, episodeId.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userId'] = nativeToJson<String>(userId);
    json['episodeId'] = nativeToJson<String>(episodeId);
    return json;
  }

  UpdateListenHistoryListenHistoryUpsert({
    required this.userId,
    required this.episodeId,
  });
}

@immutable
class UpdateListenHistoryData {
  final UpdateListenHistoryListenHistoryUpsert listenHistory_upsert;
  UpdateListenHistoryData.fromJson(dynamic json)
      : listenHistory_upsert = UpdateListenHistoryListenHistoryUpsert.fromJson(
            json['listenHistory_upsert']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateListenHistoryData otherTyped = other as UpdateListenHistoryData;
    return listenHistory_upsert == otherTyped.listenHistory_upsert;
  }

  @override
  int get hashCode => listenHistory_upsert.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['listenHistory_upsert'] = listenHistory_upsert.toJson();
    return json;
  }

  UpdateListenHistoryData({
    required this.listenHistory_upsert,
  });
}

@immutable
class UpdateListenHistoryVariables {
  final String userId;
  final String episodeId;
  final BigInt progressSeconds;
  final bool finishedListening;
  final Timestamp listenedAt;
  @Deprecated(
      'fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateListenHistoryVariables.fromJson(Map<String, dynamic> json)
      : userId = nativeFromJson<String>(json['userId']),
        episodeId = nativeFromJson<String>(json['episodeId']),
        progressSeconds = bigIntFromJson(json['progressSeconds']),
        finishedListening = nativeFromJson<bool>(json['finishedListening']),
        listenedAt = Timestamp.fromJson(json['listenedAt']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateListenHistoryVariables otherTyped =
        other as UpdateListenHistoryVariables;
    return userId == otherTyped.userId &&
        episodeId == otherTyped.episodeId &&
        progressSeconds == otherTyped.progressSeconds &&
        finishedListening == otherTyped.finishedListening &&
        listenedAt == otherTyped.listenedAt;
  }

  @override
  int get hashCode => Object.hashAll([
        userId.hashCode,
        episodeId.hashCode,
        progressSeconds.hashCode,
        finishedListening.hashCode,
        listenedAt.hashCode
      ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userId'] = nativeToJson<String>(userId);
    json['episodeId'] = nativeToJson<String>(episodeId);
    json['progressSeconds'] = bigIntToJson(progressSeconds);
    json['finishedListening'] = nativeToJson<bool>(finishedListening);
    json['listenedAt'] = listenedAt.toJson();
    return json;
  }

  UpdateListenHistoryVariables({
    required this.userId,
    required this.episodeId,
    required this.progressSeconds,
    required this.finishedListening,
    required this.listenedAt,
  });
}
