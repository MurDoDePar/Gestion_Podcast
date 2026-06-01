import 'dart:convert';
import 'package:crypto/crypto.dart';

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

  String get id {
    if (feedUrl.isEmpty) return '00000000-0000-4000-8000-000000000000';
    final bytes = utf8.encode(feedUrl);
    final digest = md5.convert(bytes).toString();
    // Formatage en UUID standard
    return '${digest.substring(0, 8)}-${digest.substring(8, 12)}-${digest.substring(12, 16)}-${digest.substring(16, 20)}-${digest.substring(20)}';
  }

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
      'id': id,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'artistName': artistName,
      'artworkUrl600': artworkUrl,
      'feedUrl': feedUrl,
    };
  }
}
