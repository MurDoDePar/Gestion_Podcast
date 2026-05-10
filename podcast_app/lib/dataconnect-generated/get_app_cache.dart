part of 'example.dart';

class GetAppCacheVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  GetAppCacheVariablesBuilder(
    this._dataConnect, {
    required this.id,
  });
  Deserializer<GetAppCacheData> dataDeserializer =
      (dynamic json) => GetAppCacheData.fromJson(jsonDecode(json));
  Serializer<GetAppCacheVariables> varsSerializer =
      (GetAppCacheVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetAppCacheData, GetAppCacheVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetAppCacheData, GetAppCacheVariables> ref() {
    GetAppCacheVariables vars = GetAppCacheVariables(
      id: id,
    );
    return _dataConnect.query(
        "GetAppCache", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetAppCacheAppCache {
  final String id;
  final AnyValue data;
  final Timestamp updatedAt;
  GetAppCacheAppCache.fromJson(dynamic json)
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

    final GetAppCacheAppCache otherTyped = other as GetAppCacheAppCache;
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

  GetAppCacheAppCache({
    required this.id,
    required this.data,
    required this.updatedAt,
  });
}

@immutable
class GetAppCacheData {
  final GetAppCacheAppCache? appCache;
  GetAppCacheData.fromJson(dynamic json)
      : appCache = json['appCache'] == null
            ? null
            : GetAppCacheAppCache.fromJson(json['appCache']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetAppCacheData otherTyped = other as GetAppCacheData;
    return appCache == otherTyped.appCache;
  }

  @override
  int get hashCode => appCache.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (appCache != null) {
      json['appCache'] = appCache!.toJson();
    }
    return json;
  }

  GetAppCacheData({
    this.appCache,
  });
}

@immutable
class GetAppCacheVariables {
  final String id;
  @Deprecated(
      'fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetAppCacheVariables.fromJson(Map<String, dynamic> json)
      : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetAppCacheVariables otherTyped = other as GetAppCacheVariables;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetAppCacheVariables({
    required this.id,
  });
}
