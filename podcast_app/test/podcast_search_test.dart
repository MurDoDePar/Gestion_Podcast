import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:podcast_app/services/itunes_gateway.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('iTunes Search Gateway Tests (Filtre par Langue / Pays)', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    test('1. Recherche avec langue "fr" doit ajouter &country=FR', () async {
      await prefs.setString('podstream_lang', 'fr');
      String? requestedUrl;
      final dio = Dio();
      dio.httpClientAdapter = FakeHttpClientAdapter((options) async {
        final uriStr = options.uri.toString();
        requestedUrl = uriStr;
        final mockResponse = {
          'resultCount': 1,
          'results': [
            {
              'collectionName': 'Le Potes Cast',
              'artistName': 'Yacine & Dedo',
              'artworkUrl600': 'https://example.com/artwork.jpg',
              'feedUrl': 'https://example.com/feed.xml',
              'collectionId': 12345,
              'country': 'FRA',
              'language': 'fr',
            }
          ]
        };
        return ResponseBody.fromBytes(
          utf8.encode(jsonEncode(mockResponse)),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final gateway = ITunesGateway(dio: dio);
      final results = await gateway.searchPodcasts('dedo');

      expect(requestedUrl, contains('country=FR'));
      expect(requestedUrl, contains('term=dedo'));
      expect(results.length, 1);
      expect(results.first.collectionName, 'Le Potes Cast');
      expect(results.first.artistName, 'Yacine & Dedo');
    });

    test('2. Recherche avec langue "en" doit ajouter &country=US', () async {
      await prefs.setString('podstream_lang', 'en');
      String? requestedUrl;
      final dio = Dio();
      dio.httpClientAdapter = FakeHttpClientAdapter((options) async {
        requestedUrl = options.uri.toString();
        return ResponseBody.fromBytes(
          utf8.encode(jsonEncode({'results': []})),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final gateway = ITunesGateway(dio: dio);
      await gateway.searchPodcasts('finger');

      expect(requestedUrl, contains('country=US'));
      expect(requestedUrl, contains('term=finger'));
    });

    test('3. Recherche avec langue "es" doit ajouter &country=ES', () async {
      await prefs.setString('podstream_lang', 'es');
      String? requestedUrl;
      final dio = Dio();
      dio.httpClientAdapter = FakeHttpClientAdapter((options) async {
        requestedUrl = options.uri.toString();
        return ResponseBody.fromBytes(
          utf8.encode(jsonEncode({'results': []})),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final gateway = ITunesGateway(dio: dio);
      await gateway.searchPodcasts('dedo');

      expect(requestedUrl, contains('country=ES'));
    });

    test('4. Recherche avec langue "de" doit ajouter &country=DE', () async {
      await prefs.setString('podstream_lang', 'de');
      String? requestedUrl;
      final dio = Dio();
      dio.httpClientAdapter = FakeHttpClientAdapter((options) async {
        requestedUrl = options.uri.toString();
        return ResponseBody.fromBytes(
          utf8.encode(jsonEncode({'results': []})),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final gateway = ITunesGateway(dio: dio);
      await gateway.searchPodcasts('finger');

      expect(requestedUrl, contains('country=DE'));
    });

    test('5. Recherche avec langue "all" ne doit pas inclure country',
        () async {
      await prefs.setString('podstream_lang', 'all');
      String? requestedUrl;
      final dio = Dio();
      dio.httpClientAdapter = FakeHttpClientAdapter((options) async {
        requestedUrl = options.uri.toString();
        return ResponseBody.fromBytes(
          utf8.encode(jsonEncode({'results': []})),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final gateway = ITunesGateway(dio: dio);
      await gateway.searchPodcasts('dedo');

      expect(requestedUrl, isNotNull);
      expect(requestedUrl, isNot(contains('country=')));
    });

    test('6. Désérialisation robuste si certains champs sont manquants',
        () async {
      await prefs.setString('podstream_lang', 'en');
      final dio = Dio();
      dio.httpClientAdapter = FakeHttpClientAdapter((options) async {
        final mockResponse = {
          'results': [
            {
              // Pas de collectionName, pas d'artworkUrl600, pas de collectionId
              'artistName': 'Inconnu',
              'feedUrl': 'https://example.com/feed.xml',
              'country': 'USA',
              'language': 'en',
            }
          ]
        };
        return ResponseBody.fromBytes(
          utf8.encode(jsonEncode(mockResponse)),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final gateway = ITunesGateway(dio: dio);
      final results = await gateway.searchPodcasts('test');

      expect(results.length, 1);
      expect(results.first.collectionName, 'Sans titre');
      expect(results.first.artistName, 'Inconnu');
      expect(results.first.artworkUrl, '');
      expect(results.first.collectionId, isNull);
    });
  });
}
