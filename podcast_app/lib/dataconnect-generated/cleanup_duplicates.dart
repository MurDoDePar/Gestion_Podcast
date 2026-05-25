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
  final int? cleanEpisodes;
  final int? cleanPodcasts;
  final int? cleanUsers;
  CleanupDuplicatesData.fromJson(dynamic json):
  
  cleanEpisodes = json['cleanEpisodes'] == null ? null : nativeFromJson<int>(json['cleanEpisodes']),
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
    return cleanEpisodes == otherTyped.cleanEpisodes && 
    cleanPodcasts == otherTyped.cleanPodcasts && 
    cleanUsers == otherTyped.cleanUsers;
    
  }
  @override
  int get hashCode => Object.hashAll([cleanEpisodes.hashCode, cleanPodcasts.hashCode, cleanUsers.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (cleanEpisodes != null) {
      json['cleanEpisodes'] = nativeToJson<int?>(cleanEpisodes);
    }
    if (cleanPodcasts != null) {
      json['cleanPodcasts'] = nativeToJson<int?>(cleanPodcasts);
    }
    if (cleanUsers != null) {
      json['cleanUsers'] = nativeToJson<int?>(cleanUsers);
    }
    return json;
  }

  CleanupDuplicatesData({
    this.cleanEpisodes,
    this.cleanPodcasts,
    this.cleanUsers,
  });
}

