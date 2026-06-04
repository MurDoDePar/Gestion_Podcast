part of 'example.dart';

class CleanupDuplicatesVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  CleanupDuplicatesVariablesBuilder(this._dataConnect, );
  Deserializer<CleanupDuplicatesData> dataDeserializer = (dynamic json)  => CleanupDuplicatesData.fromJson(jsonDecode(json));
  
  Future<OperationResult<CleanupDuplicatesData, void>> execute() {
    return ref().execute();
  }

  MutationRef<CleanupDuplicatesData, void> ref() {
    
    return _dataConnect.mutation("CleanupDuplicates", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class CleanupDuplicatesData {
  final int? cleanPodcasts;
  final int? cleanUsers;
  CleanupDuplicatesData.fromJson(dynamic json):
  
  cleanPodcasts = json['cleanPodcasts'] == null ? null : nativeFromJson<int>(json['cleanPodcasts']),
  cleanUsers = json['cleanUsers'] == null ? null : nativeFromJson<int>(json['cleanUsers']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CleanupDuplicatesData otherTyped = other as CleanupDuplicatesData;
    return cleanPodcasts == otherTyped.cleanPodcasts && 
    cleanUsers == otherTyped.cleanUsers;
    
  }
  @override
  int get hashCode => Object.hashAll([cleanPodcasts.hashCode, cleanUsers.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (cleanPodcasts != null) {
      json['cleanPodcasts'] = nativeToJson<int?>(cleanPodcasts);
    }
    if (cleanUsers != null) {
      json['cleanUsers'] = nativeToJson<int?>(cleanUsers);
    }
    return json;
  }

  CleanupDuplicatesData({
    this.cleanPodcasts,
    this.cleanUsers,
  });
}

