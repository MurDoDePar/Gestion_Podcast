import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/podcast_model.dart';
import '../models/app_settings.dart';
import 'database_helper.dart';

class DiscoveryService {
  final Dio _dio;

  DiscoveryService({Dio? dio}) : _dio = dio ?? Dio();

  /// Récupère des podcasts recommandés sur iTunes pour une liste de genres donnés,
  /// en parallèle, puis filtre les abonnements existants, les doublons et les langues,
  /// et limite à 10 par genre.
  Future<List<PodcastModel>> fetchRecommendationsForGenres(
    List<String> genres, {
    String? lang,
  }) async {
    if (genres.isEmpty) return [];

    // 1. Récupérer la langue préférée
    final targetLang = lang ?? await AppSettings.getLanguage();

    // 2. Récupérer les abonnements locaux pour exclure les podcasts déjà abonnés
    final dbHelper = DatabaseHelper();
    final List<PodcastModel> subscribedPodcasts =
        await dbHelper.getSubscribedPodcasts();
    final Set<String> subscribedFeedUrls = subscribedPodcasts
        .map((p) => p.feedUrl.toLowerCase().trim())
        .where((url) => url.isNotEmpty)
        .toSet();

    final langToCountry = {'fr': 'FR', 'en': 'US', 'es': 'ES', 'de': 'DE'};

    // 3. Lancer les requêtes API iTunes en parallèle pour chaque genre
    final futures = genres.map((genre) async {
      final String term = genre.trim();
      if (term.isEmpty) return <PodcastModel>[];

      try {
        final queryParams = {
          'term': term,
          'media': 'podcast',
          'entity': 'podcast',
          'limit':
              40, // Augmenté pour avoir suffisamment d'éléments après filtrage de langue
          'lang': targetLang, // Ajout systématique du paramètre lang
        };
        if (targetLang != 'all' && langToCountry.containsKey(targetLang)) {
          queryParams['country'] = langToCountry[targetLang]!;
        }

        print('Appel iTunes avec paramètres : lang=$targetLang');
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
            return <PodcastModel>[];
          }

          final List<dynamic> results = parsedData['results'] ?? [];
          final List<PodcastModel> podcasts = [];

          final userLang = targetLang.toLowerCase();
          for (var item in results) {
            if (item is Map<String, dynamic>) {
              final model = PodcastModel.fromJson(item);
              if (model.feedUrl.isNotEmpty) {
                // Validation stricte en sortie (Post-processing)
                final podcastLang = model.language?.toLowerCase().trim();
                final podcastCountry = model.country?.toLowerCase().trim();
                if (userLang != 'all' &&
                    podcastLang != userLang &&
                    podcastCountry != userLang) {
                  print(
                      'Exclusion linguistique : ${model.collectionName} rejeté');
                  continue; // Exclure impérativement tout résultat non conforme
                }
                // Assigne le genre déclencheur à la recommandation
                podcasts.add(model.copyWith(recommendedByGenre: term));
              }
            }
          }
          return podcasts;
        }
      } catch (e) {
        // En cas d'erreur sur un genre spécifique, on retourne une liste vide
        // print('Erreur lors du chargement des recommandations pour le genre "$genre": $e');
      }
      return <PodcastModel>[];
    }).toList();

    // Attendre toutes les requêtes en parallèle
    final List<List<PodcastModel>> resultsPerGenre = await Future.wait(futures);

    // 4. Filtrer les doublons, abonnements, langues et limiter à 10 par genre
    final List<PodcastModel> allRecommendations = [];
    final Set<String> seenFeedUrls = {};

    for (int i = 0; i < genres.length; i++) {
      final List<PodcastModel> rawList = resultsPerGenre[i];
      int count = 0;

      for (var podcast in rawList) {
        if (count >= 10) break; // Limite stricte de 10 par genre

        final key = podcast.feedUrl.toLowerCase().trim();
        if (key.isEmpty) continue;

        // Exclure si déjà abonné
        if (subscribedFeedUrls.contains(key)) continue;

        // Exclure si déjà présent dans les recommandations globales actuelles
        if (seenFeedUrls.contains(key)) continue;

        // Validation de langue stricte
        final isMatch = await _isLanguageMatch(podcast, targetLang);
        if (!isMatch) continue;

        seenFeedUrls.add(key);
        allRecommendations.add(podcast);
        count++;
      }
    }

    return allRecommendations;
  }

  /// Détermine si un podcast correspond à la langue cible
  Future<bool> _isLanguageMatch(PodcastModel podcast, String targetLang) async {
    if (targetLang == 'all') return true;

    // 1. Validation rapide par pays/langue retourné par iTunes (sans appel réseau)
    final country = podcast.country?.toUpperCase().trim() ?? '';
    if (country.isNotEmpty) {
      final langToCountries = {
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
      if (langToCountries.containsKey(targetLang)) {
        if (langToCountries[targetLang]!.contains(country)) {
          return true;
        }
      }
    }

    // 2. Validation par le champ language s'il est déjà défini
    final modelLang = podcast.language?.toLowerCase().trim() ?? '';
    if (modelLang.isNotEmpty) {
      if (modelLang.startsWith(targetLang)) {
        return true;
      }
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
    } catch (_) {
      // Rejeter en cas d'erreur de récupération/parsing du flux XML pour un filtrage strict
    }
    return false;
  }
}
