import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
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
  group('iTunes Search Gateway Tests (Filtre par Langue / Pays)', () {
    test('1. Recherche avec langue "fr" doit ajouter &country=FR', () async {
      String? requestedUrl;
      final dio = Dio();
      dio.httpClientAdapter = FakeHttpClientAdapter((options) async {
        final uriStr = options.uri.toString();
        if (uriStr.contains('itunes.apple.com')) {
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
        } else {
          return ResponseBody.fromBytes(
            utf8.encode(
                '<rss><channel><language>fr-FR</language></channel></rss>'),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/xml'],
            },
          );
        }
      });

      final gateway = ITunesGateway(dio: dio);
      final results = await gateway.searchPodcasts('dedo', lang: 'fr');

      expect(requestedUrl, contains('country=FR'));
      expect(requestedUrl, contains('term=dedo'));
      expect(results.length, 1);
      expect(results.first.collectionName, 'Le Potes Cast');
      expect(results.first.artistName, 'Yacine & Dedo');
    });

    test('2. Recherche avec langue "en" doit ajouter &country=US', () async {
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
      await gateway.searchPodcasts('finger', lang: 'en');

      expect(requestedUrl, contains('country=US'));
      expect(requestedUrl, contains('term=finger'));
    });

    test('3. Recherche avec langue "es" doit ajouter &country=ES', () async {
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
      await gateway.searchPodcasts('dedo', lang: 'es');

      expect(requestedUrl, contains('country=ES'));
    });

    test('4. Recherche avec langue "de" doit ajouter &country=DE', () async {
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
      await gateway.searchPodcasts('finger', lang: 'de');

      expect(requestedUrl, contains('country=DE'));
    });

    test('5. Recherche avec langue "all" ne doit pas inclure country',
        () async {
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
      await gateway.searchPodcasts('dedo', lang: 'all');

      expect(requestedUrl, isNotNull);
      expect(requestedUrl, isNot(contains('country=')));
    });

    test('6. Désérialisation robuste si certains champs sont manquants',
        () async {
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
      final results = await gateway.searchPodcasts('test', lang: 'en');

      expect(results.length, 1);
      expect(results.first.collectionName, 'Sans titre');
      expect(results.first.artistName, 'Inconnu');
      expect(results.first.artworkUrl, '');
      expect(results.first.collectionId, isNull);
    });

    test('7. Filtrage strict par langue via RSS', () async {
      final dio = Dio();
      dio.httpClientAdapter = FakeHttpClientAdapter((options) async {
        final uriStr = options.uri.toString();
        if (uriStr.contains('itunes.apple.com')) {
          final mockResponse = {
            'results': [
              {
                'collectionName': 'Podcast Français',
                'artistName': 'FR Author',
                'feedUrl': 'https://example.com/fr_feed.xml',
                'country': 'FRA',
                'language': 'fr',
              },
              {
                'collectionName': 'Podcast Anglais',
                'artistName': 'EN Author',
                'feedUrl': 'https://example.com/en_feed.xml',
                'country': 'USA',
                'language': 'en',
              },
              {
                'collectionName': 'Podcast Sans Langue',
                'artistName': 'Unknown Author',
                'feedUrl': 'https://example.com/no_lang_feed.xml',
                'country': null,
                'language': null,
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
        } else if (uriStr == 'https://example.com/fr_feed.xml') {
          return ResponseBody.fromBytes(
            utf8.encode(
                '<rss><channel><language><![CDATA[fr-FR]]></language></channel></rss>'),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/xml'],
            },
          );
        } else if (uriStr == 'https://example.com/en_feed.xml') {
          return ResponseBody.fromBytes(
            utf8.encode(
                '<rss><channel><language><![CDATA[en-US]]></language></channel></rss>'),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/xml'],
            },
          );
        } else if (uriStr == 'https://example.com/no_lang_feed.xml') {
          return ResponseBody.fromBytes(
            utf8.encode('<rss><channel></channel></rss>'),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/xml'],
            },
          );
        }
        return ResponseBody.fromBytes(utf8.encode(''), 404);
      });

      final gateway = ITunesGateway(dio: dio);
      final results = await gateway.searchPodcasts('test', lang: 'fr');

      // Doit inclure le podcast français et exclure le podcast anglais.
      // Le podcast sans langue n'a pas d'indication de langue dans son RSS, donc il sera exclu par sécurité (notre filtrage strict).
      expect(results.length, 1);
      expect(results.first.collectionName, 'Podcast Français');
    });
  });
}
