import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/podcast_model.dart';

class ItunesService {
  Future<List<PodcastModel>> searchPodcasts(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final String encodedQuery = Uri.encodeComponent(query.trim());
    final Uri url = Uri.parse(
      'https://itunes.apple.com/search?term=$encodedQuery&media=podcast&entity=podcast',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        return results
            .map((item) => PodcastModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        print('Erreur iTunes Service : Code statut ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception iTunes Service : $e');
      return [];
    }
  }

  Future<List<PodcastModel>> getTopPodcasts() async {
    final Uri url = Uri.parse(
      'https://itunes.apple.com/search?term=podcast&country=fr&entity=podcast&limit=50',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        return results
            .map((item) => PodcastModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        print(
            'Erreur iTunes Service getTopPodcasts : Code statut ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception iTunes Service getTopPodcasts : $e');
      return [];
    }
  }

  Future<List<PodcastModel>> getPodcastsByTheme(String theme) async {
    final String encodedTheme = Uri.encodeComponent(theme.trim());
    final Uri url = Uri.parse(
      'https://itunes.apple.com/search?term=$encodedTheme&country=fr&entity=podcast&limit=25',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        return results
            .map((item) => PodcastModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        print(
            'Erreur iTunes Service getPodcastsByTheme : Code statut ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception iTunes Service getPodcastsByTheme : $e');
      return [];
    }
  }
}
