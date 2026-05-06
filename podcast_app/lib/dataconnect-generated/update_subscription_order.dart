part of 'example.dart';

class UpdateSubscriptionOrderVariablesBuilder {
  String userId;
  String podcastId;
  int listOrder;

  final FirebaseDataConnect _dataConnect;
  UpdateSubscriptionOrderVariablesBuilder(
    this._dataConnect, {
    required this.userId,
    required this.podcastId,
    required this.listOrder,
  });
  Deserializer<UpdateSubscriptionOrderData> dataDeserializer =
      (dynamic json) => UpdateSubscriptionOrderData.fromJson(jsonDecode(json));
  Serializer<UpdateSubscriptionOrderVariables> varsSerializer =
      (UpdateSubscriptionOrderVariables vars) => jsonEncode(vars.toJson());
  Future<
      OperationResult<UpdateSubscriptionOrderData,
          UpdateSubscriptionOrderVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateSubscriptionOrderData, UpdateSubscriptionOrderVariables>
      ref() {
    UpdateSubscriptionOrderVariables vars = UpdateSubscriptionOrderVariables(
      userId: userId,
      podcastId: podcastId,
      listOrder: listOrder,
    );
    return _dataConnect.mutation(
        "UpdateSubscriptionOrder", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateSubscriptionOrderSubscriptionTypeUpdate {
  final String userId;
  final String podcastId;
  UpdateSubscriptionOrderSubscriptionTypeUpdate.fromJson(dynamic json)
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

    final UpdateSubscriptionOrderSubscriptionTypeUpdate otherTyped =
        other as UpdateSubscriptionOrderSubscriptionTypeUpdate;
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

  UpdateSubscriptionOrderSubscriptionTypeUpdate({
    required this.userId,
    required this.podcastId,
  });
}

@immutable
class UpdateSubscriptionOrderData {
  final UpdateSubscriptionOrderSubscriptionTypeUpdate? subscriptionType_update;
  UpdateSubscriptionOrderData.fromJson(dynamic json)
      : subscriptionType_update = json['subscriptionType_update'] == null
            ? null
            : UpdateSubscriptionOrderSubscriptionTypeUpdate.fromJson(
                json['subscriptionType_update']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateSubscriptionOrderData otherTyped =
        other as UpdateSubscriptionOrderData;
    return subscriptionType_update == otherTyped.subscriptionType_update;
  }

  @override
  int get hashCode => subscriptionType_update.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (subscriptionType_update != null) {
      json['subscriptionType_update'] = subscriptionType_update!.toJson();
    }
    return json;
  }

  UpdateSubscriptionOrderData({
    this.subscriptionType_update,
  });
}

@immutable
class UpdateSubscriptionOrderVariables {
  final String userId;
  final String podcastId;
  final int listOrder;
  @Deprecated(
      'fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateSubscriptionOrderVariables.fromJson(Map<String, dynamic> json)
      : userId = nativeFromJson<String>(json['userId']),
        podcastId = nativeFromJson<String>(json['podcastId']),
        listOrder = nativeFromJson<int>(json['listOrder']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateSubscriptionOrderVariables otherTyped =
        other as UpdateSubscriptionOrderVariables;
    return userId == otherTyped.userId &&
        podcastId == otherTyped.podcastId &&
        listOrder == otherTyped.listOrder;
  }

  @override
  int get hashCode =>
      Object.hashAll([userId.hashCode, podcastId.hashCode, listOrder.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userId'] = nativeToJson<String>(userId);
    json['podcastId'] = nativeToJson<String>(podcastId);
    json['listOrder'] = nativeToJson<int>(listOrder);
    return json;
  }

  UpdateSubscriptionOrderVariables({
    required this.userId,
    required this.podcastId,
    required this.listOrder,
  });
}
