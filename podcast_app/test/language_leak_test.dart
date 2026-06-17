import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:podcast_app/services/database_helper.dart';
import 'package:podcast_app/models/podcast_model.dart';
import 'package:podcast_app/services/itunes_search_gateway.dart';

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
    DatabaseHelper.mockInstance = FakeDatabaseHelper();
  });

  group('Tueur de Bug: Language Leak and Absolute Lock Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    test(
        '1. AppSettings en "fr" produit lang="fr", normalise FRA en fr et filtre les résultats',
        () async {
      // Configure AppSettings dynamically to 'fr'
      await prefs.setString('podstream_lang', 'fr');

      final List<Map<String, dynamic>> sentRequests = [];
      final dio = Dio();
      dio.httpClientAdapter = FakeHttpClientAdapter((options) async {
        sentRequests.add(options.uri.queryParameters);

        // Simulate a response with varied language tags: 'FRA' and 'fr'
        final List<Map<String, dynamic>> results = [
          {
            'collectionName': 'Podcast FRA',
            'artistName': 'Auteur FRA',
            'feedUrl': 'https://example.com/fra.xml',
            'country': 'FRA',
            'language': 'FRA',
          },
          {
            'collectionName': 'Podcast fr',
            'artistName': 'Auteur fr',
            'feedUrl': 'https://example.com/fr.xml',
            'country': 'FRA',
            'language': 'fr',
          },
          {
            'collectionName': 'Podcast en',
            'artistName': 'Auteur en',
            'feedUrl': 'https://example.com/en.xml',
            'country': 'USA',
            'language': 'en',
          }
        ];

        return ResponseBody.fromBytes(
          utf8.encode(jsonEncode({'results': results})),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final gateway = ITunesSearchGateway(dio: dio);
      final results = await gateway.searchPodcasts('Tech');

      // 1. Intercept HTTP query parameters checks
      expect(sentRequests.length, 1);
      final queryParams = sentRequests.first;
      expect(queryParams['lang'], equals('fr'));
      expect(queryParams['country'], equals('FR'));

      // 2. Results checks: must be normalized, and only 'fr' (normalized from FRA and fr)
      expect(results.length, 2);
      for (final podcast in results) {
        expect(podcast.language, equals('fr'));
      }
    });

    test(
        '2. Changement de langue à chaud (fr -> en) : doit utiliser la nouvelle langue immédiatement et échouer s\'il reste fr',
        () async {
      // A. Configuration initiale en 'fr'
      await prefs.setString('podstream_lang', 'fr');

      final List<Map<String, dynamic>> sentRequests = [];
      final dio = Dio();
      dio.httpClientAdapter = FakeHttpClientAdapter((options) async {
        sentRequests.add(options.uri.queryParameters);
        return ResponseBody.fromBytes(
          utf8.encode(jsonEncode({'results': []})),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final gateway = ITunesSearchGateway(dio: dio);

      // Premier appel en FR
      await gateway.searchPodcasts('Tech');
      expect(sentRequests.last['lang'], equals('fr'));

      // B. Modification dynamique à chaud en 'en'
      await prefs.setString('podstream_lang', 'en');

      // Deuxième appel : doit immédiatement propager 'en' et ne pas contenir 'fr'
      await gateway.searchPodcasts('Tech');

      expect(sentRequests.length, 2);
      final secondRequestParams = sentRequests.last;

      // Verification que 'fr' ne fuite pas et que 'en' est utilisé
      expect(secondRequestParams['lang'], isNot(equals('fr')),
          reason:
              'La requête ne doit plus contenir "fr" après changement à chaud');
      expect(secondRequestParams['lang'], equals('en'));
      expect(secondRequestParams['country'], equals('US'));
    });
  });
}
