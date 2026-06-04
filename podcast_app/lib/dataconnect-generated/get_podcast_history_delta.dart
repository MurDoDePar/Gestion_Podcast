part of 'example.dart';

class GetPodcastHistoryDeltaVariablesBuilder {
  String userId;
  Timestamp since;

  final FirebaseDataConnect _dataConnect;
  GetPodcastHistoryDeltaVariablesBuilder(this._dataConnect, {required  this.userId,required  this.since,});
  Deserializer<GetPodcastHistoryDeltaData> dataDeserializer = (dynamic json)  => GetPodcastHistoryDeltaData.fromJson(jsonDecode(json));
  Serializer<GetPodcastHistoryDeltaVariables> varsSerializer = (GetPodcastHistoryDeltaVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetPodcastHistoryDeltaData, GetPodcastHistoryDeltaVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetPodcastHistoryDeltaData, GetPodcastHistoryDeltaVariables> ref() {
    GetPodcastHistoryDeltaVariables vars= GetPodcastHistoryDeltaVariables(userId: userId,since: since,);
    return _dataConnect.query("GetPodcastHistoryDelta", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetPodcastHistoryDeltaUser {
  final String googleId;
  GetPodcastHistoryDeltaUser.fromJson(dynamic json):
  
  googleId = nativeFromJson<String>(json['googleId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetPodcastHistoryDeltaUser otherTyped = other as GetPodcastHistoryDeltaUser;
    return googleId == otherTyped.googleId;
    
  }
  @override
  int get hashCode => googleId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['googleId'] = nativeToJson<String>(googleId);
    return json;
  }

  GetPodcastHistoryDeltaUser({
    required this.googleId,
  });
}

@immutable
class GetPodcastHistoryDeltaData {
  final GetPodcastHistoryDeltaUser? user;
  final List<AnyValue>? delta;
  final AnyValue? serverTime;
  GetPodcastHistoryDeltaData.fromJson(dynamic json):
  
  user = json['user'] == null ? null : GetPodcastHistoryDeltaUser.fromJson(json['user']),
  delta = json['delta'] == null ? null : (json['delta'] as List<dynamic>)
        .map((e) => AnyValue.fromJson(e))
        .toList(),
  serverTime = json['serverTime'] == null ? null : AnyValue.fromJson(json['serverTime']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetPodcastHistoryDeltaData otherTyped = other as GetPodcastHistoryDeltaData;
    return user == otherTyped.user && 
    delta == otherTyped.delta && 
    serverTime == otherTyped.serverTime;
    
  }
  @override
  int get hashCode => Object.hashAll([user.hashCode, delta.hashCode, serverTime.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (user != null) {
      json['user'] = user!.toJson();
    }
    if (delta != null) {
      json['delta'] = delta?.map((e) => e!.toJson()).toList();
    }
    if (serverTime != null) {
      json['serverTime'] = serverTime!.toJson();
    }
    return json;
  }

  GetPodcastHistoryDeltaData({
    this.user,
    this.delta,
    this.serverTime,
  });
}

@immutable
class GetPodcastHistoryDeltaVariables {
  final String userId;
  final Timestamp since;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetPodcastHistoryDeltaVariables.fromJson(Map<String, dynamic> json):
  
  userId = nativeFromJson<String>(json['userId']),
  since = Timestamp.fromJson(json['since']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetPodcastHistoryDeltaVariables otherTyped = other as GetPodcastHistoryDeltaVariables;
    return userId == otherTyped.userId && 
    since == otherTyped.since;
    
  }
  @override
  int get hashCode => Object.hashAll([userId.hashCode, since.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userId'] = nativeToJson<String>(userId);
    json['since'] = since.toJson();
    return json;
  }

  GetPodcastHistoryDeltaVariables({
    required this.userId,
    required this.since,
  });
}

