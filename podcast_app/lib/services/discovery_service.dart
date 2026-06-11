import 'package:dio/dio.dart';
import '../models/podcast_model.dart';
import '../models/app_settings.dart';
import 'database_helper.dart';
import 'itunes_gateway.dart';

class DiscoveryService {
  final Dio _dio;

  DiscoveryService({Dio? dio}) : _dio = dio ?? Dio();

  /// Récupère des podcasts recommandés sur iTunes pour une liste de genres donnés,
  /// en parallèle, puis filtre les abonnements existants et les doublons,
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

    // 3. Lancer les requêtes via ITunesGateway en parallèle pour chaque genre
    final gateway = ITunesGateway(dio: _dio);
    final futures = genres.map((genre) async {
      final String term = genre.trim();
      if (term.isEmpty) return <PodcastModel>[];

      try {
        return await gateway.searchPodcasts(term, lang: targetLang);
      } catch (e) {
        print(
            '❌ Erreur lors du chargement des recommandations pour le genre "$genre" via Gateway: $e');
        return <PodcastModel>[];
      }
    }).toList();

    // Attendre toutes les requêtes en parallèle
    final List<List<PodcastModel>> resultsPerGenre = await Future.wait(futures);

    // 4. Filtrer les doublons globaux, abonnements, et limiter à 10 par genre
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
        if (subscribedFeedUrls.contains(key)) {
          print(
              'DiscoveryService : "${podcast.collectionName}" exclu car déjà abonné');
          continue;
        }

        // Exclure si déjà présent dans les recommandations globales actuelles
        if (seenFeedUrls.contains(key)) {
          print(
              'DiscoveryService : "${podcast.collectionName}" exclu car doublon global');
          continue;
        }

        seenFeedUrls.add(key);
        allRecommendations.add(podcast);
        count++;
      }
    }

    return allRecommendations;
  }
}
