part of 'example.dart';

class FindUserByGoogleIdVariablesBuilder {
  String googleId;

  final FirebaseDataConnect _dataConnect;
  FindUserByGoogleIdVariablesBuilder(
    this._dataConnect, {
    required this.googleId,
  });
  Deserializer<FindUserByGoogleIdData> dataDeserializer =
      (dynamic json) => FindUserByGoogleIdData.fromJson(jsonDecode(json));
  Serializer<FindUserByGoogleIdVariables> varsSerializer =
      (FindUserByGoogleIdVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<FindUserByGoogleIdData, FindUserByGoogleIdVariables>>
      execute() {
    return ref().execute();
  }

  QueryRef<FindUserByGoogleIdData, FindUserByGoogleIdVariables> ref() {
    FindUserByGoogleIdVariables vars = FindUserByGoogleIdVariables(
      googleId: googleId,
    );
    return _dataConnect.query(
        "FindUserByGoogleId", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class FindUserByGoogleIdUsers {
  final String id;
  final String googleId;
  final String displayName;
  final String? email;
  FindUserByGoogleIdUsers.fromJson(dynamic json)
      : id = nativeFromJson<String>(json['id']),
        googleId = nativeFromJson<String>(json['googleId']),
        displayName = nativeFromJson<String>(json['displayName']),
        email = json['email'] == null
            ? null
            : nativeFromJson<String>(json['email']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final FindUserByGoogleIdUsers otherTyped = other as FindUserByGoogleIdUsers;
    return id == otherTyped.id &&
        googleId == otherTyped.googleId &&
        displayName == otherTyped.displayName &&
        email == otherTyped.email;
  }

  @override
  int get hashCode => Object.hashAll(
      [id.hashCode, googleId.hashCode, displayName.hashCode, email.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['googleId'] = nativeToJson<String>(googleId);
    json['displayName'] = nativeToJson<String>(displayName);
    if (email != null) {
      json['email'] = nativeToJson<String?>(email);
    }
    return json;
  }

  FindUserByGoogleIdUsers({
    required this.id,
    required this.googleId,
    required this.displayName,
    this.email,
  });
}

@immutable
class FindUserByGoogleIdData {
  final List<FindUserByGoogleIdUsers> users;
  FindUserByGoogleIdData.fromJson(dynamic json)
      : users = (json['users'] as List<dynamic>)
            .map((e) => FindUserByGoogleIdUsers.fromJson(e))
            .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final FindUserByGoogleIdData otherTyped = other as FindUserByGoogleIdData;
    return users == otherTyped.users;
  }

  @override
  int get hashCode => users.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['users'] = users.map((e) => e.toJson()).toList();
    return json;
  }

  FindUserByGoogleIdData({
    required this.users,
  });
}

@immutable
class FindUserByGoogleIdVariables {
  final String googleId;
  @Deprecated(
      'fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  FindUserByGoogleIdVariables.fromJson(Map<String, dynamic> json)
      : googleId = nativeFromJson<String>(json['googleId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final FindUserByGoogleIdVariables otherTyped =
        other as FindUserByGoogleIdVariables;
    return googleId == otherTyped.googleId;
  }

  @override
  int get hashCode => googleId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['googleId'] = nativeToJson<String>(googleId);
    return json;
  }

  FindUserByGoogleIdVariables({
    required this.googleId,
  });
}
