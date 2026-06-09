import 'dart:convert';
import 'package:crypto/crypto.dart';

class PodcastModel {
  final String collectionName;
  final String artistName;
  final String artworkUrl;
  final String feedUrl;
  final int? collectionId;
  final List<String> genres;
  final String?
      recommendedByGenre; // Nouveau champ pour le tag déclencheur de recommandation
  final String? country; // Code pays retourné par iTunes (ex: USA, FRA)
  final String? language; // Langue du podcast (ex: fr, en)

  PodcastModel({
    required this.collectionName,
    required this.artistName,
    required this.artworkUrl,
    required this.feedUrl,
    this.collectionId,
    this.genres = const [],
    this.recommendedByGenre,
    this.country,
    this.language,
  });

  String get id {
    if (feedUrl.isEmpty) return '00000000-0000-4000-8000-000000000000';
    final bytes = utf8.encode(feedUrl);
    final digest = md5.convert(bytes).toString();
    // Formatage en UUID standard
    return '${digest.substring(0, 8)}-${digest.substring(8, 12)}-${digest.substring(12, 16)}-${digest.substring(16, 20)}-${digest.substring(20)}';
  }

  factory PodcastModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedGenres = [];
    if (json['genres'] is List) {
      parsedGenres =
          (json['genres'] as List).map((g) => g.toString().trim()).toList();
    } else if (json['genres'] != null && json['genres'].toString().isNotEmpty) {
      parsedGenres =
          json['genres'].toString().split(',').map((g) => g.trim()).toList();
    } else if (json['primaryGenreName'] != null) {
      parsedGenres = [json['primaryGenreName'].toString().trim()];
    }

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
      genres: parsedGenres,
      recommendedByGenre: json['recommendedByGenre']?.toString(),
      country: json['country']?.toString(),
      language: json['language']?.toString(),
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
      'genres': genres.join(','),
      if (recommendedByGenre != null) 'recommendedByGenre': recommendedByGenre,
      if (country != null) 'country': country,
      if (language != null) 'language': language,
    };
  }

  PodcastModel copyWith({
    String? collectionName,
    String? artistName,
    String? artworkUrl,
    String? feedUrl,
    int? collectionId,
    List<String>? genres,
    String? recommendedByGenre,
    String? country,
    String? language,
  }) {
    return PodcastModel(
      collectionName: collectionName ?? this.collectionName,
      artistName: artistName ?? this.artistName,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      feedUrl: feedUrl ?? this.feedUrl,
      collectionId: collectionId ?? this.collectionId,
      genres: genres ?? this.genres,
      recommendedByGenre: recommendedByGenre ?? this.recommendedByGenre,
      country: country ?? this.country,
      language: language ?? this.language,
    );
  }
}
