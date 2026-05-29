part of 'example.dart';

class UpsertUserVariablesBuilder {
  String id;
  String googleId;
  String displayName;
  Optional<String> _email = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _photoUrl = Optional.optional(nativeFromJson, nativeToJson);
  Timestamp createdAt;

  final FirebaseDataConnect _dataConnect;
  UpsertUserVariablesBuilder email(String? t) {
    _email.value = t;
    return this;
  }

  UpsertUserVariablesBuilder photoUrl(String? t) {
    _photoUrl.value = t;
    return this;
  }

  UpsertUserVariablesBuilder(
    this._dataConnect, {
    required this.id,
    required this.googleId,
    required this.displayName,
    required this.createdAt,
  });
  Deserializer<UpsertUserData> dataDeserializer =
      (dynamic json) => UpsertUserData.fromJson(jsonDecode(json));
  Serializer<UpsertUserVariables> varsSerializer =
      (UpsertUserVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpsertUserData, UpsertUserVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpsertUserData, UpsertUserVariables> ref() {
    UpsertUserVariables vars = UpsertUserVariables(
      id: id,
      googleId: googleId,
      displayName: displayName,
      email: _email,
      photoUrl: _photoUrl,
      createdAt: createdAt,
    );
    return _dataConnect.mutation(
        "UpsertUser", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpsertUserUserUpsert {
  final String id;
  UpsertUserUserUpsert.fromJson(dynamic json)
      : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertUserUserUpsert otherTyped = other as UpsertUserUserUpsert;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpsertUserUserUpsert({
    required this.id,
  });
}

@immutable
class UpsertUserData {
  final UpsertUserUserUpsert user_upsert;
  UpsertUserData.fromJson(dynamic json)
      : user_upsert = UpsertUserUserUpsert.fromJson(json['user_upsert']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertUserData otherTyped = other as UpsertUserData;
    return user_upsert == otherTyped.user_upsert;
  }

  @override
  int get hashCode => user_upsert.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['user_upsert'] = user_upsert.toJson();
    return json;
  }

  UpsertUserData({
    required this.user_upsert,
  });
}

@immutable
class UpsertUserVariables {
  final String id;
  final String googleId;
  final String displayName;
  late final Optional<String> email;
  late final Optional<String> photoUrl;
  final Timestamp createdAt;
  @Deprecated(
      'fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpsertUserVariables.fromJson(Map<String, dynamic> json)
      : id = nativeFromJson<String>(json['id']),
        googleId = nativeFromJson<String>(json['googleId']),
        displayName = nativeFromJson<String>(json['displayName']),
        createdAt = Timestamp.fromJson(json['createdAt']) {
    email = Optional.optional(nativeFromJson, nativeToJson);
    email.value =
        json['email'] == null ? null : nativeFromJson<String>(json['email']);

    photoUrl = Optional.optional(nativeFromJson, nativeToJson);
    photoUrl.value = json['photoUrl'] == null
        ? null
        : nativeFromJson<String>(json['photoUrl']);
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertUserVariables otherTyped = other as UpsertUserVariables;
    return id == otherTyped.id &&
        googleId == otherTyped.googleId &&
        displayName == otherTyped.displayName &&
        email == otherTyped.email &&
        photoUrl == otherTyped.photoUrl &&
        createdAt == otherTyped.createdAt;
  }

  @override
  int get hashCode => Object.hashAll([
        id.hashCode,
        googleId.hashCode,
        displayName.hashCode,
        email.hashCode,
        photoUrl.hashCode,
        createdAt.hashCode
      ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['googleId'] = nativeToJson<String>(googleId);
    json['displayName'] = nativeToJson<String>(displayName);
    if (email.state == OptionalState.set) {
      json['email'] = email.toJson();
    }
    if (photoUrl.state == OptionalState.set) {
      json['photoUrl'] = photoUrl.toJson();
    }
    json['createdAt'] = createdAt.toJson();
    return json;
  }

  UpsertUserVariables({
    required this.id,
    required this.googleId,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.createdAt,
  });
}
