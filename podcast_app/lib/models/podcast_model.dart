class PodcastModel {
  final String collectionName;
  final String artistName;
  final String artworkUrl;
  final String feedUrl;
  final int? collectionId;

  PodcastModel({
    required this.collectionName,
    required this.artistName,
    required this.artworkUrl,
    required this.feedUrl,
    this.collectionId,
  });

  factory PodcastModel.fromJson(Map<String, dynamic> json) {
    return PodcastModel(
      collectionName: json['collectionName']?.toString() ?? 'Sans titre',
      artistName: json['artistName']?.toString() ?? 'Artiste inconnu',
      artworkUrl: json['artworkUrl600']?.toString() ??
          json['artworkUrl100']?.toString() ??
          '',
      feedUrl: json['feedUrl']?.toString() ?? '',
      collectionId: json['collectionId'] is int?
          ? json['collectionId'] as int?
          : int.tryParse(json['collectionId']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'collectionId': collectionId,
      'collectionName': collectionName,
      'artistName': artistName,
      'artworkUrl600': artworkUrl,
      'feedUrl': feedUrl,
    };
  }
}
