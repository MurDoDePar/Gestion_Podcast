import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/podcast_model.dart';

class ItunesService {
  final http.Client _client;

  ItunesService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<PodcastModel>> searchPodcasts(String query,
      {String? lang}) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final String encodedQuery = Uri.encodeComponent(query.trim());
    String countryParam = '';
    if (lang != null && lang != 'all') {
      final langToCountry = {'fr': 'FR', 'en': 'US', 'es': 'ES', 'de': 'DE'};
      if (langToCountry.containsKey(lang)) {
        countryParam = '&country=${langToCountry[lang]}';
      }
    }

    final Uri url = Uri.parse(
      'https://itunes.apple.com/search?term=$encodedQuery&media=podcast&entity=podcast$countryParam',
    );

    try {
      final response = await _client.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> results = data['results'] ?? [];

        if (lang == null || lang == 'all') {
          return results
              .map(
                  (item) => PodcastModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }

        // Filtrage strict par langue via RSS en parallèle (max 3 secondes total)
        final candidateList = results.take(25).toList();
        final futures = candidateList.map((item) async {
          final feedUrl = item['feedUrl']?.toString();
          if (feedUrl == null || feedUrl.isEmpty) return null;

          final model = PodcastModel.fromJson(item as Map<String, dynamic>);
          try {
            final feedRes = await _client
                .get(Uri.parse(feedUrl))
                .timeout(const Duration(seconds: 3));
            if (feedRes.statusCode == 200) {
              final body = feedRes.body.toLowerCase();
              final langMatch =
                  RegExp(r'<language>\s*([\s\S]*?)\s*<\/language>')
                      .firstMatch(body);
              if (langMatch != null) {
                var podcastLang = langMatch.group(1)?.toLowerCase() ?? '';
                if (podcastLang.contains('cdata[')) {
                  final cdataMatch = RegExp(r'cdata\[\s*([^\]\s]+)\s*\]\]')
                      .firstMatch(podcastLang);
                  if (cdataMatch != null) {
                    podcastLang = cdataMatch.group(1) ?? '';
                  }
                }
                podcastLang = podcastLang.trim();
                if (podcastLang.startsWith(lang.toLowerCase())) {
                  return model;
                } else {
                  return null; // Filtré car langue différente
                }
              }
            }
            return model; // Si pas de balise ou status différent, accepté par défaut
          } catch (e) {
            return model; // En cas de timeout ou erreur, accepté par défaut
          }
        }).toList();

        final resolved = await Future.wait(futures);
        return resolved.whereType<PodcastModel>().toList();
      } else {
        // print('Erreur iTunes Service : Code statut ${response.statusCode}');
        return [];
      }
    } catch (e) {
      // print('Exception iTunes Service : $e');
      return [];
    }
  }

  Future<List<PodcastModel>> getTopPodcasts() async {
    final Uri url = Uri.parse(
      'https://itunes.apple.com/search?term=podcast&country=fr&entity=podcast&limit=50',
    );

    try {
      final response = await _client.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        return results
            .map((item) => PodcastModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        // print(
        // 'Erreur iTunes Service getTopPodcasts : Code statut ${response.statusCode}');
        return [];
      }
    } catch (e) {
      // print('Exception iTunes Service getTopPodcasts : $e');
      return [];
    }
  }

  Future<List<PodcastModel>> getPodcastsByTheme(String theme) async {
    if (theme.trim().toLowerCase() == 'populaire') {
      return getTopPodcasts();
    }
    final String encodedTheme = Uri.encodeComponent(theme.trim());
    final Uri url = Uri.parse(
      'https://itunes.apple.com/search?term=$encodedTheme&country=fr&entity=podcast&limit=25',
    );

    try {
      final response = await _client.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        return results
            .map((item) => PodcastModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        // print(
        // 'Erreur iTunes Service getPodcastsByTheme : Code statut ${response.statusCode}');
        return [];
      }
    } catch (e) {
      // print('Exception iTunes Service getPodcastsByTheme : $e');
      return [];
    }
  }
}
