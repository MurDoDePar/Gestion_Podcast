part of 'example.dart';

class InsertUserVariablesBuilder {
  String googleId;
  String displayName;
  Optional<String> _email = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _photoUrl = Optional.optional(nativeFromJson, nativeToJson);
  Timestamp createdAt;

  final FirebaseDataConnect _dataConnect;
  InsertUserVariablesBuilder email(String? t) {
    _email.value = t;
    return this;
  }

  InsertUserVariablesBuilder photoUrl(String? t) {
    _photoUrl.value = t;
    return this;
  }

  InsertUserVariablesBuilder(
    this._dataConnect, {
    required this.googleId,
    required this.displayName,
    required this.createdAt,
  });
  Deserializer<InsertUserData> dataDeserializer =
      (dynamic json) => InsertUserData.fromJson(jsonDecode(json));
  Serializer<InsertUserVariables> varsSerializer =
      (InsertUserVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<InsertUserData, InsertUserVariables>> execute() {
    return ref().execute();
  }

  MutationRef<InsertUserData, InsertUserVariables> ref() {
    InsertUserVariables vars = InsertUserVariables(
      googleId: googleId,
      displayName: displayName,
      email: _email,
      photoUrl: _photoUrl,
      createdAt: createdAt,
    );
    return _dataConnect.mutation(
        "InsertUser", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class InsertUserUserInsert {
  final String id;
  InsertUserUserInsert.fromJson(dynamic json)
      : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final InsertUserUserInsert otherTyped = other as InsertUserUserInsert;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  InsertUserUserInsert({
    required this.id,
  });
}

@immutable
class InsertUserData {
  final InsertUserUserInsert user_insert;
  InsertUserData.fromJson(dynamic json)
      : user_insert = InsertUserUserInsert.fromJson(json['user_insert']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final InsertUserData otherTyped = other as InsertUserData;
    return user_insert == otherTyped.user_insert;
  }

  @override
  int get hashCode => user_insert.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['user_insert'] = user_insert.toJson();
    return json;
  }

  InsertUserData({
    required this.user_insert,
  });
}

@immutable
class InsertUserVariables {
  final String googleId;
  final String displayName;
  late final Optional<String> email;
  late final Optional<String> photoUrl;
  final Timestamp createdAt;
  @Deprecated(
      'fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  InsertUserVariables.fromJson(Map<String, dynamic> json)
      : googleId = nativeFromJson<String>(json['googleId']),
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

    final InsertUserVariables otherTyped = other as InsertUserVariables;
    return googleId == otherTyped.googleId &&
        displayName == otherTyped.displayName &&
        email == otherTyped.email &&
        photoUrl == otherTyped.photoUrl &&
        createdAt == otherTyped.createdAt;
  }

  @override
  int get hashCode => Object.hashAll([
        googleId.hashCode,
        displayName.hashCode,
        email.hashCode,
        photoUrl.hashCode,
        createdAt.hashCode
      ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
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

  InsertUserVariables({
    required this.googleId,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.createdAt,
  });
}
