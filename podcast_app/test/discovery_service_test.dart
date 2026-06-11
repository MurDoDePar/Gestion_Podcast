import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:podcast_app/services/discovery_service.dart';
import 'package:podcast_app/services/database_helper.dart';
import 'package:podcast_app/models/podcast_model.dart';

class FakeHttpClientAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  FakeHttpClientAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

class FakeDatabaseHelper implements DatabaseHelper {
  @override
  Future<List<PodcastModel>> getSubscribedPodcasts() async {
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Override DatabaseHelper singleton with our fake for testing
    DatabaseHelper.mockInstance = FakeDatabaseHelper();
  });

  group('DiscoveryService Language Filtering Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    test(
        '1. Recherche avec langue "fr" conserve les podcasts FR et exclut les EN',
        () async {
      // Configure target language to 'fr'
      await prefs.setString('podstream_lang', 'fr');

      final mockItunesResponse = {
        'results': [
          {
            'collectionName': 'Podcast Français',
            'artistName': 'Auteur FR',
            'feedUrl': 'https://example.com/fr.xml',
            'country': 'FRA',
            'language': 'fr',
          },
          {
            'collectionName': 'Podcast Anglais',
            'artistName': 'Auteur EN',
            'feedUrl': 'https://example.com/en.xml',
            'country': 'USA',
            'language': 'en',
          }
        ]
      };

      final dio = Dio();
      dio.httpClientAdapter = FakeHttpClientAdapter((options) async {
        return ResponseBody.fromBytes(
          utf8.encode(jsonEncode(mockItunesResponse)),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final discoveryService = DiscoveryService(dio: dio);
      final results =
          await discoveryService.fetchRecommendationsForGenres(['Tech']);

      // Verification : Only French podcast should be kept
      expect(results.length, 1);
      expect(results.first.collectionName, 'Podcast Français');
      expect(results.first.language, 'fr');
    });

    test(
        '1b. Podcast avec pays "FRA" et langue nulle n\'est pas exclu en langue "fr"',
        () async {
      await prefs.setString('podstream_lang', 'fr');

      final mockItunesResponse = {
        'results': [
          {
            'collectionName': 'Podcast Français Sans Langue',
            'artistName': 'Auteur FR',
            'feedUrl': 'https://example.com/fr-nolang.xml',
            'country': 'FRA',
            'language': null,
          }
        ]
      };

      final dio = Dio();
      dio.httpClientAdapter = FakeHttpClientAdapter((options) async {
        if (options.path.contains('itunes.apple.com')) {
          return ResponseBody.fromBytes(
            utf8.encode(jsonEncode(mockItunesResponse)),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        } else {
          const mockRssXml =
              '<?xml version="1.0" encoding="UTF-8"?><rss><channel><language>fr</language></channel></rss>';
          return ResponseBody.fromBytes(
            utf8.encode(mockRssXml),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/xml; charset=utf-8'],
            },
          );
        }
      });

      final discoveryService = DiscoveryService(dio: dio);
      final results =
          await discoveryService.fetchRecommendationsForGenres(['Tech']);

      // Verification : The podcast should be kept because country FRA matches target language 'fr'
      expect(results.length, 1);
      expect(results.first.collectionName, 'Podcast Français Sans Langue');
    });

    test(
        '2. Recherche avec langue "en" exclut les podcasts français et conserve les EN',
        () async {
      // Configure target language to 'en'
      await prefs.setString('podstream_lang', 'en');

      final mockItunesResponse = {
        'results': [
          {
            'collectionName': 'Podcast Français',
            'artistName': 'Auteur FR',
            'feedUrl': 'https://example.com/fr.xml',
            'country': 'FRA',
            'language': 'fr',
          },
          {
            'collectionName': 'Podcast Anglais',
            'artistName': 'Auteur EN',
            'feedUrl': 'https://example.com/en.xml',
            'country': 'USA',
            'language': 'en',
          }
        ]
      };

      final dio = Dio();
      dio.httpClientAdapter = FakeHttpClientAdapter((options) async {
        return ResponseBody.fromBytes(
          utf8.encode(jsonEncode(mockItunesResponse)),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final discoveryService = DiscoveryService(dio: dio);
      final results =
          await discoveryService.fetchRecommendationsForGenres(['Tech']);

      // Verification : Only English podcast should be kept
      expect(results.length, 1);
      expect(results.first.collectionName, 'Podcast Anglais');
      expect(results.first.language, 'en');
    });

    test(
        '3. Recherche avec données manquantes (language et country absents) exclut les podcasts par sécurité',
        () async {
      // Configure target language to 'fr'
      await prefs.setString('podstream_lang', 'fr');

      final mockItunesResponse = {
        'results': [
          {
            'collectionName': 'Podcast Incomplet',
            'artistName': 'Auteur Mystère',
            'feedUrl': 'https://example.com/mystery.xml',
            // fields language and country are missing
          }
        ]
      };

      final dio = Dio();
      dio.httpClientAdapter = FakeHttpClientAdapter((options) async {
        return ResponseBody.fromBytes(
          utf8.encode(jsonEncode(mockItunesResponse)),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final discoveryService = DiscoveryService(dio: dio);
      final results =
          await discoveryService.fetchRecommendationsForGenres(['Tech']);

      // Verification : Should be empty because language/country are missing, so it doesn't match 'fr'
      expect(results.isEmpty, isTrue);
    });
  });
}
