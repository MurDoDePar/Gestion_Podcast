import 'dart:convert';

class EpisodeModel {
  final String id;
  final String audioUrl;
  final String title;
  final String podcastName;
  final String imageUrl;
  final String description;
  final DateTime? pubDate;

  EpisodeModel({
    required this.id,
    required this.audioUrl,
    required this.title,
    required this.podcastName,
    required this.imageUrl,
    required this.description,
    this.pubDate,
  });

  factory EpisodeModel.fromRawData(dynamic rawData) {
    try {
      final rawJson = jsonEncode(rawData);
      final Map<String, dynamic> item =
          jsonDecode(rawJson) as Map<String, dynamic>;

      final String parsedAudioUrl = item['audioUrl']?.toString() ?? '';

      String fallbackTitle = 'Épisode sans titre';
      if (parsedAudioUrl.isNotEmpty && parsedAudioUrl.contains('/')) {
        fallbackTitle = parsedAudioUrl.split('/').last.split('?').first;
      }

      DateTime? parsedPubDate;
      if (item['pubDate'] != null) {
        parsedPubDate = DateTime.tryParse(item['pubDate'].toString());
      }

      return EpisodeModel(
        id: item['id']?.toString() ?? '',
        audioUrl: parsedAudioUrl,
        title: item['title']?.toString() ?? fallbackTitle,
        podcastName: item['podcastName']?.toString() ?? '',
        imageUrl: item['imageUrl']?.toString() ?? '',
        description:
            item['description']?.toString() ?? 'Aucune description disponible.',
        pubDate: parsedPubDate,
      );
    } catch (e) {
      print('AA_DEBUG_ERROR: EpisodeModel.fromRawData a échoué: $e');
      return EpisodeModel(
        id: '',
        audioUrl: '',
        title: 'Erreur',
        podcastName: '',
        imageUrl: '',
        description: '',
      );
    }
  }

  factory EpisodeModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime? parsedPubDate;
    if (map['pubDate'] != null) {
      parsedPubDate = DateTime.tryParse(map['pubDate'].toString());
    }

    return EpisodeModel(
      id: documentId ?? map['id']?.toString() ?? '',
      audioUrl: map['audioUrl']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Épisode sans titre',
      podcastName: map['podcastName']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString() ?? '',
      description:
          map['description']?.toString() ?? 'Aucune description disponible.',
      pubDate: parsedPubDate,
    );
  }
}
