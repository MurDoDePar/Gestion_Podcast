part of 'example.dart';

class SubscribeToPodcastVariablesBuilder {
  String userId;
  String podcastId;
  Timestamp subscribedAt;
  Optional<int> _listOrder = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;
  SubscribeToPodcastVariablesBuilder listOrder(int? t) {
    _listOrder.value = t;
    return this;
  }

  SubscribeToPodcastVariablesBuilder(
    this._dataConnect, {
    required this.userId,
    required this.podcastId,
    required this.subscribedAt,
  });
  Deserializer<SubscribeToPodcastData> dataDeserializer =
      (dynamic json) => SubscribeToPodcastData.fromJson(jsonDecode(json));
  Serializer<SubscribeToPodcastVariables> varsSerializer =
      (SubscribeToPodcastVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<SubscribeToPodcastData, SubscribeToPodcastVariables>>
      execute() {
    return ref().execute();
  }

  MutationRef<SubscribeToPodcastData, SubscribeToPodcastVariables> ref() {
    SubscribeToPodcastVariables vars = SubscribeToPodcastVariables(
      userId: userId,
      podcastId: podcastId,
      subscribedAt: subscribedAt,
      listOrder: _listOrder,
    );
    return _dataConnect.mutation(
        "SubscribeToPodcast", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class SubscribeToPodcastSubscriptionTypeUpsert {
  final String userId;
  final String podcastId;
  SubscribeToPodcastSubscriptionTypeUpsert.fromJson(dynamic json)
      : userId = nativeFromJson<String>(json['userId']),
        podcastId = nativeFromJson<String>(json['podcastId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final SubscribeToPodcastSubscriptionTypeUpsert otherTyped =
        other as SubscribeToPodcastSubscriptionTypeUpsert;
    return userId == otherTyped.userId && podcastId == otherTyped.podcastId;
  }

  @override
  int get hashCode => Object.hashAll([userId.hashCode, podcastId.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userId'] = nativeToJson<String>(userId);
    json['podcastId'] = nativeToJson<String>(podcastId);
    return json;
  }

  SubscribeToPodcastSubscriptionTypeUpsert({
    required this.userId,
    required this.podcastId,
  });
}

@immutable
class SubscribeToPodcastData {
  final SubscribeToPodcastSubscriptionTypeUpsert subscriptionType_upsert;
  SubscribeToPodcastData.fromJson(dynamic json)
      : subscriptionType_upsert =
            SubscribeToPodcastSubscriptionTypeUpsert.fromJson(
                json['subscriptionType_upsert']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final SubscribeToPodcastData otherTyped = other as SubscribeToPodcastData;
    return subscriptionType_upsert == otherTyped.subscriptionType_upsert;
  }

  @override
  int get hashCode => subscriptionType_upsert.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['subscriptionType_upsert'] = subscriptionType_upsert.toJson();
    return json;
  }

  SubscribeToPodcastData({
    required this.subscriptionType_upsert,
  });
}

@immutable
class SubscribeToPodcastVariables {
  final String userId;
  final String podcastId;
  final Timestamp subscribedAt;
  late final Optional<int> listOrder;
  @Deprecated(
      'fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  SubscribeToPodcastVariables.fromJson(Map<String, dynamic> json)
      : userId = nativeFromJson<String>(json['userId']),
        podcastId = nativeFromJson<String>(json['podcastId']),
        subscribedAt = Timestamp.fromJson(json['subscribedAt']) {
    listOrder = Optional.optional(nativeFromJson, nativeToJson);
    listOrder.value = json['listOrder'] == null
        ? null
        : nativeFromJson<int>(json['listOrder']);
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final SubscribeToPodcastVariables otherTyped =
        other as SubscribeToPodcastVariables;
    return userId == otherTyped.userId &&
        podcastId == otherTyped.podcastId &&
        subscribedAt == otherTyped.subscribedAt &&
        listOrder == otherTyped.listOrder;
  }

  @override
  int get hashCode => Object.hashAll([
        userId.hashCode,
        podcastId.hashCode,
        subscribedAt.hashCode,
        listOrder.hashCode
      ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userId'] = nativeToJson<String>(userId);
    json['podcastId'] = nativeToJson<String>(podcastId);
    json['subscribedAt'] = subscribedAt.toJson();
    if (listOrder.state == OptionalState.set) {
      json['listOrder'] = listOrder.toJson();
    }
    return json;
  }

  SubscribeToPodcastVariables({
    required this.userId,
    required this.podcastId,
    required this.subscribedAt,
    required this.listOrder,
  });
}
