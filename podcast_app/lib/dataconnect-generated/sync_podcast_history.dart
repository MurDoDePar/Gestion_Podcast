part of 'example.dart';

class SyncPodcastHistoryVariablesBuilder {
  String userId;
  AnyValue history;

  final FirebaseDataConnect _dataConnect;
  SyncPodcastHistoryVariablesBuilder(this._dataConnect, {required  this.userId,required  this.history,});
  Deserializer<SyncPodcastHistoryData> dataDeserializer = (dynamic json)  => SyncPodcastHistoryData.fromJson(jsonDecode(json));
  Serializer<SyncPodcastHistoryVariables> varsSerializer = (SyncPodcastHistoryVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<SyncPodcastHistoryData, SyncPodcastHistoryVariables>> execute() {
    return ref().execute();
  }

  MutationRef<SyncPodcastHistoryData, SyncPodcastHistoryVariables> ref() {
    SyncPodcastHistoryVariables vars= SyncPodcastHistoryVariables(userId: userId,history: history,);
    return _dataConnect.mutation("SyncPodcastHistory", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class SyncPodcastHistoryData {
  final int? sync;
  SyncPodcastHistoryData.fromJson(dynamic json):
  
  sync = json['sync'] == null ? null : nativeFromJson<int>(json['sync']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final SyncPodcastHistoryData otherTyped = other as SyncPodcastHistoryData;
    return sync == otherTyped.sync;
    
  }
  @override
  int get hashCode => sync.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (sync != null) {
      json['sync'] = nativeToJson<int?>(sync);
    }
    return json;
  }

  SyncPodcastHistoryData({
    this.sync,
  });
}

@immutable
class SyncPodcastHistoryVariables {
  final String userId;
  final AnyValue history;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  SyncPodcastHistoryVariables.fromJson(Map<String, dynamic> json):
  
  userId = nativeFromJson<String>(json['userId']),
  history = AnyValue.fromJson(json['history']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final SyncPodcastHistoryVariables otherTyped = other as SyncPodcastHistoryVariables;
    return userId == otherTyped.userId && 
    history == otherTyped.history;
    
  }
  @override
  int get hashCode => Object.hashAll([userId.hashCode, history.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userId'] = nativeToJson<String>(userId);
    json['history'] = history.toJson();
    return json;
  }

  SyncPodcastHistoryVariables({
    required this.userId,
    required this.history,
  });
}

