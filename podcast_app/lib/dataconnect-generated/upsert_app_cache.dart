part of 'example.dart';

class UpsertAppCacheVariablesBuilder {
  String id;
  AnyValue data;
  Timestamp updatedAt;

  final FirebaseDataConnect _dataConnect;
  UpsertAppCacheVariablesBuilder(
    this._dataConnect, {
    required this.id,
    required this.data,
    required this.updatedAt,
  });
  Deserializer<UpsertAppCacheData> dataDeserializer =
      (dynamic json) => UpsertAppCacheData.fromJson(jsonDecode(json));
  Serializer<UpsertAppCacheVariables> varsSerializer =
      (UpsertAppCacheVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpsertAppCacheData, UpsertAppCacheVariables>>
      execute() {
    return ref().execute();
  }

  MutationRef<UpsertAppCacheData, UpsertAppCacheVariables> ref() {
    UpsertAppCacheVariables vars = UpsertAppCacheVariables(
      id: id,
      data: data,
      updatedAt: updatedAt,
    );
    return _dataConnect.mutation(
        "UpsertAppCache", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpsertAppCacheAppCacheUpsert {
  final String id;
  UpsertAppCacheAppCacheUpsert.fromJson(dynamic json)
      : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertAppCacheAppCacheUpsert otherTyped =
        other as UpsertAppCacheAppCacheUpsert;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpsertAppCacheAppCacheUpsert({
    required this.id,
  });
}

@immutable
class UpsertAppCacheData {
  final UpsertAppCacheAppCacheUpsert appCache_upsert;
  UpsertAppCacheData.fromJson(dynamic json)
      : appCache_upsert =
            UpsertAppCacheAppCacheUpsert.fromJson(json['appCache_upsert']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertAppCacheData otherTyped = other as UpsertAppCacheData;
    return appCache_upsert == otherTyped.appCache_upsert;
  }

  @override
  int get hashCode => appCache_upsert.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['appCache_upsert'] = appCache_upsert.toJson();
    return json;
  }

  UpsertAppCacheData({
    required this.appCache_upsert,
  });
}

@immutable
class UpsertAppCacheVariables {
  final String id;
  final AnyValue data;
  final Timestamp updatedAt;
  @Deprecated(
      'fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpsertAppCacheVariables.fromJson(Map<String, dynamic> json)
      : id = nativeFromJson<String>(json['id']),
        data = AnyValue.fromJson(json['data']),
        updatedAt = Timestamp.fromJson(json['updatedAt']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertAppCacheVariables otherTyped = other as UpsertAppCacheVariables;
    return id == otherTyped.id &&
        data == otherTyped.data &&
        updatedAt == otherTyped.updatedAt;
  }

  @override
  int get hashCode =>
      Object.hashAll([id.hashCode, data.hashCode, updatedAt.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['data'] = data.toJson();
    json['updatedAt'] = updatedAt.toJson();
    return json;
  }

  UpsertAppCacheVariables({
    required this.id,
    required this.data,
    required this.updatedAt,
  });
}
