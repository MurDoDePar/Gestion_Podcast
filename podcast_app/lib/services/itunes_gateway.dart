import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/podcast_model.dart';

class ITunesGateway {
  final Dio _dio;

  ITunesGateway({Dio? dio}) : _dio = dio ?? Dio();

  /// Interface publique unique pour toute recherche de podcasts.
  /// Gère la langue, le tri, le filtrage des doublons et la validation linguistique.
  Future<List<PodcastModel>> searchPodcasts(String term,
      {required String lang}) async {
    final String trimmed = term.trim();
    if (trimmed.isEmpty) return [];

    String searchTerm = trimmed;
    if (searchTerm.toLowerCase() == 'populaire') {
      searchTerm = 'podcast';
    }

    final targetLang = lang.toLowerCase();
    final langToCountry = {'fr': 'FR', 'en': 'US', 'es': 'ES', 'de': 'DE'};

    try {
      final queryParams = {
        'term': searchTerm,
        'media': 'podcast',
        'entity': 'podcast',
        'limit': 40,
        'lang': targetLang,
      };

      if (targetLang != 'all' && langToCountry.containsKey(targetLang)) {
        queryParams['country'] = langToCountry[targetLang]!;
      }

      print(
          'ITunesGateway.searchPodcasts : term="$searchTerm", lang="$targetLang"');
      final response = await _dio
          .get(
            'https://itunes.apple.com/search',
            queryParameters: queryParams,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = response.data;
        Map<String, dynamic> parsedData;
        if (data is String) {
          parsedData = jsonDecode(data);
        } else if (data is Map<String, dynamic>) {
          parsedData = data;
        } else {
          return [];
        }

        final List<dynamic> results = parsedData['results'] ?? [];
        print(
            'iTunes API : Genre/Term "$searchTerm" - Nombre de résultats reçus avant filtrage = ${results.length}');

        final List<PodcastModel> validPodcasts = [];
        final Set<String> seenFeedUrls = {};

        // Filtrage en parallèle des podcasts reçus (limité à 25 max)
        final candidateList = results.take(25).toList();

        final validationFutures = candidateList.map((item) async {
          if (item is Map<String, dynamic>) {
            final model = PodcastModel.fromJson(item);
            if (model.feedUrl.isNotEmpty) {
              final isValid = await _isPodcastLanguageValid(model, targetLang);
              if (isValid) {
                return model;
              }
            }
          }
          return null;
        }).toList();

        final resolvedPodcasts = await Future.wait(validationFutures);

        for (var podcast in resolvedPodcasts) {
          if (podcast != null) {
            final key = podcast.feedUrl.toLowerCase().trim();
            if (key.isNotEmpty && !seenFeedUrls.contains(key)) {
              seenFeedUrls.add(key);
              validPodcasts.add(podcast.copyWith(recommendedByGenre: trimmed));
            } else if (key.isNotEmpty) {
              print(
                  'Exclusion : "${podcast.collectionName}" rejeté (doublon dans les genres)');
            }
          }
        }

        return validPodcasts;
      }
    } on DioException catch (e) {
      String errMsg = 'Erreur réseau';
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errMsg = 'Délai d\'attente dépassé (Timeout)';
      } else if (e.response != null) {
        errMsg = 'Erreur HTTP ${e.response?.statusCode}';
      } else {
        errMsg = e.message ?? 'Inconnu';
      }
      print(
          '❌ Erreur réseau iTunes API dans ITunesGateway.searchPodcasts ($errMsg) : $e');
    } catch (e) {
      print('❌ Exception inattendue dans ITunesGateway.searchPodcasts : $e');
    }
    return [];
  }

  /// Validation de langue (Rapide + RSS strict)
  Future<bool> _isPodcastLanguageValid(
      PodcastModel podcast, String targetLang) async {
    final fastMatch = _checkLanguageFast(podcast, targetLang);
    if (fastMatch != null) {
      return fastMatch;
    }

    // 3. Repli strict : Analyse de la balise <language> du flux RSS
    if (podcast.feedUrl.isEmpty) return false;
    try {
      final response = await _dio
          .get(
            podcast.feedUrl,
            options: Options(responseType: ResponseType.plain),
          )
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final body = response.data.toString().toLowerCase();
        final langMatch =
            RegExp(r'<language>\s*([\s\S]*?)\s*<\/language>').firstMatch(body);
        if (langMatch != null) {
          var podcastLang = langMatch.group(1)?.toLowerCase() ?? '';
          if (podcastLang.contains('cdata[')) {
            final cdataMatch =
                RegExp(r'cdata\[\s*([^\]\s]+)\s*\]\]').firstMatch(podcastLang);
            if (cdataMatch != null) {
              podcastLang = cdataMatch.group(1) ?? '';
            }
          }
          podcastLang = podcastLang.trim();
          return podcastLang.startsWith(targetLang);
        }
      }
    } on TimeoutException {
      print(
          '⚠️ ITunesGateway._isPodcastLanguageValid : Timeout RSS (2s) pour "${podcast.collectionName}"');
    } on DioException catch (e) {
      String errMsg = 'Erreur réseau';
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errMsg = 'Timeout RSS';
      } else if (e.response != null) {
        errMsg = 'HTTP ${e.response?.statusCode} RSS';
      } else {
        errMsg = e.message ?? 'Inconnu';
      }
      print(
          '⚠️ ITunesGateway._isPodcastLanguageValid : Échec du flux RSS ($errMsg) pour "${podcast.collectionName}"');
    } catch (e) {
      print(
          '⚠️ ITunesGateway._isPodcastLanguageValid : Exception inattendue pour "${podcast.collectionName}" : $e');
    }
    return false;
  }

  /// Validation rapide par pays/langue retourné par iTunes (sans appel réseau).
  /// Retourne `true` si validé positivement, `false` si rejeté positivement,
  /// et `null` si incertain (nécessite le check de flux RSS).
  bool? _checkLanguageFast(PodcastModel podcast, String targetLang) {
    if (targetLang == 'all') return true;

    final country = podcast.country?.toUpperCase().trim() ?? '';
    final modelLang = podcast.language?.toLowerCase().trim() ?? '';

    const langToCountries = {
      'fr': {'FR', 'FRA'},
      'en': {
        'US',
        'USA',
        'GB',
        'GBR',
        'CA',
        'CAN',
        'AU',
        'AUS',
        'NZ',
        'NZL',
        'IE',
        'IRL'
      },
      'es': {'ES', 'ESP', 'MX', 'MEX', 'AR', 'ARG', 'CO', 'COL'},
      'de': {'DE', 'DEU', 'AT', 'AUT', 'CH', 'CHE'},
    };

    // 1. Validation positive par correspondance directe de langue ou de pays
    if (modelLang.isNotEmpty && modelLang.startsWith(targetLang)) {
      return true;
    }
    if (country.isNotEmpty &&
        langToCountries[targetLang]?.contains(country) == true) {
      return true;
    }

    // 2. Si le pays appartient à une autre langue connue de notre dictionnaire,
    // et que la langue du modèle n'infirme pas cette différence (vide ou non-cible),
    // on peut exclure.
    bool hasOtherCountry = false;
    if (country.isNotEmpty) {
      for (var entry in langToCountries.entries) {
        if (entry.key != targetLang && entry.value.contains(country)) {
          hasOtherCountry = true;
          break;
        }
      }
    }

    bool hasOtherLang =
        modelLang.isNotEmpty && !modelLang.startsWith(targetLang);

    if ((hasOtherCountry &&
            (modelLang.isEmpty || !modelLang.startsWith(targetLang))) ||
        (hasOtherLang &&
            (country.isEmpty ||
                langToCountries[targetLang]?.contains(country) != true))) {
      return false;
    }

    return null; // Incertain
  }
}
