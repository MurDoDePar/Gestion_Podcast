part of 'example.dart';

class UnsubscribeFromPodcastVariablesBuilder {
  String userId;
  String podcastId;

  final FirebaseDataConnect _dataConnect;
  UnsubscribeFromPodcastVariablesBuilder(this._dataConnect, {required  this.userId,required  this.podcastId,});
  Deserializer<UnsubscribeFromPodcastData> dataDeserializer = (dynamic json)  => UnsubscribeFromPodcastData.fromJson(jsonDecode(json));
  Serializer<UnsubscribeFromPodcastVariables> varsSerializer = (UnsubscribeFromPodcastVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UnsubscribeFromPodcastData, UnsubscribeFromPodcastVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UnsubscribeFromPodcastData, UnsubscribeFromPodcastVariables> ref() {
    UnsubscribeFromPodcastVariables vars= UnsubscribeFromPodcastVariables(userId: userId,podcastId: podcastId,);
    return _dataConnect.mutation("UnsubscribeFromPodcast", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UnsubscribeFromPodcastSubscriptionTypeDelete {
  final String userId;
  final String podcastId;
  UnsubscribeFromPodcastSubscriptionTypeDelete.fromJson(dynamic json):
  
  userId = nativeFromJson<String>(json['userId']),
  podcastId = nativeFromJson<String>(json['podcastId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UnsubscribeFromPodcastSubscriptionTypeDelete otherTyped = other as UnsubscribeFromPodcastSubscriptionTypeDelete;
    return userId == otherTyped.userId && 
    podcastId == otherTyped.podcastId;
    
  }
  @override
  int get hashCode => Object.hashAll([userId.hashCode, podcastId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userId'] = nativeToJson<String>(userId);
    json['podcastId'] = nativeToJson<String>(podcastId);
    return json;
  }

  UnsubscribeFromPodcastSubscriptionTypeDelete({
    required this.userId,
    required this.podcastId,
  });
}

@immutable
class UnsubscribeFromPodcastData {
  final UnsubscribeFromPodcastSubscriptionTypeDelete? subscriptionType_delete;
  UnsubscribeFromPodcastData.fromJson(dynamic json):
  
  subscriptionType_delete = json['subscriptionType_delete'] == null ? null : UnsubscribeFromPodcastSubscriptionTypeDelete.fromJson(json['subscriptionType_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UnsubscribeFromPodcastData otherTyped = other as UnsubscribeFromPodcastData;
    return subscriptionType_delete == otherTyped.subscriptionType_delete;
    
  }
  @override
  int get hashCode => subscriptionType_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (subscriptionType_delete != null) {
      json['subscriptionType_delete'] = subscriptionType_delete!.toJson();
    }
    return json;
  }

  UnsubscribeFromPodcastData({
    this.subscriptionType_delete,
  });
}

@immutable
class UnsubscribeFromPodcastVariables {
  final String userId;
  final String podcastId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UnsubscribeFromPodcastVariables.fromJson(Map<String, dynamic> json):
  
  userId = nativeFromJson<String>(json['userId']),
  podcastId = nativeFromJson<String>(json['podcastId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UnsubscribeFromPodcastVariables otherTyped = other as UnsubscribeFromPodcastVariables;
    return userId == otherTyped.userId && 
    podcastId == otherTyped.podcastId;
    
  }
  @override
  int get hashCode => Object.hashAll([userId.hashCode, podcastId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userId'] = nativeToJson<String>(userId);
    json['podcastId'] = nativeToJson<String>(podcastId);
    return json;
  }

  UnsubscribeFromPodcastVariables({
    required this.userId,
    required this.podcastId,
  });
}

