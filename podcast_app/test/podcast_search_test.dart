import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:podcast_app/services/itunes_service.dart';

void main() {
  group('iTunes Search Service Tests (Filtre par Langue / Pays)', () {
    test('1. Recherche avec langue "fr" doit ajouter &country=FR', () async {
      String? requestedUrl;
      final mockClient = MockClient((request) async {
        final uriStr = request.url.toString();
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
              }
            ]
          };
          return http.Response(jsonEncode(mockResponse), 200);
        } else {
          return http.Response(
              '<rss><channel><language>fr-FR</language></channel></rss>', 200);
        }
      });

      final itunesService = ItunesService(client: mockClient);
      final results = await itunesService.searchPodcasts('dedo', lang: 'fr');

      expect(requestedUrl, contains('country=FR'));
      expect(requestedUrl, contains('term=dedo'));
      expect(results.length, 1);
      expect(results.first.collectionName, 'Le Potes Cast');
      expect(results.first.artistName, 'Yacine & Dedo');
    });

    test('2. Recherche avec langue "en" doit ajouter &country=US', () async {
      String? requestedUrl;
      final mockClient = MockClient((request) async {
        requestedUrl = request.url.toString();
        return http.Response(jsonEncode({'results': []}), 200);
      });

      final itunesService = ItunesService(client: mockClient);
      await itunesService.searchPodcasts('finger', lang: 'en');

      expect(requestedUrl, contains('country=US'));
      expect(requestedUrl, contains('term=finger'));
    });

    test('3. Recherche avec langue "es" doit ajouter &country=ES', () async {
      String? requestedUrl;
      final mockClient = MockClient((request) async {
        requestedUrl = request.url.toString();
        return http.Response(jsonEncode({'results': []}), 200);
      });

      final itunesService = ItunesService(client: mockClient);
      await itunesService.searchPodcasts('dedo', lang: 'es');

      expect(requestedUrl, contains('country=ES'));
    });

    test('4. Recherche avec langue "de" doit ajouter &country=DE', () async {
      String? requestedUrl;
      final mockClient = MockClient((request) async {
        requestedUrl = request.url.toString();
        return http.Response(jsonEncode({'results': []}), 200);
      });

      final itunesService = ItunesService(client: mockClient);
      await itunesService.searchPodcasts('finger', lang: 'de');

      expect(requestedUrl, contains('country=DE'));
    });

    test('5. Recherche avec langue "all" ne doit pas inclure country',
        () async {
      String? requestedUrl;
      final mockClient = MockClient((request) async {
        requestedUrl = request.url.toString();
        return http.Response(jsonEncode({'results': []}), 200);
      });

      final itunesService = ItunesService(client: mockClient);
      await itunesService.searchPodcasts('dedo', lang: 'all');

      expect(requestedUrl, isNotNull);
      expect(requestedUrl, isNot(contains('country=')));
    });

    test('6. Recherche avec langue null ne doit pas inclure country', () async {
      String? requestedUrl;
      final mockClient = MockClient((request) async {
        requestedUrl = request.url.toString();
        return http.Response(jsonEncode({'results': []}), 200);
      });

      final itunesService = ItunesService(client: mockClient);
      await itunesService.searchPodcasts('dedo');

      expect(requestedUrl, isNotNull);
      expect(requestedUrl, isNot(contains('country=')));
    });

    test('7. Désérialisation robuste si certains champs sont manquants',
        () async {
      final mockClient = MockClient((request) async {
        final mockResponse = {
          'results': [
            {
              // Pas de collectionName, pas d'artworkUrl600, pas de collectionId
              'artistName': 'Inconnu',
              'feedUrl': 'https://example.com/feed.xml',
            }
          ]
        };
        return http.Response(jsonEncode(mockResponse), 200);
      });

      final itunesService = ItunesService(client: mockClient);
      final results = await itunesService.searchPodcasts('test');

      expect(results.length, 1);
      expect(results.first.collectionName, 'Sans titre');
      expect(results.first.artistName, 'Inconnu');
      expect(results.first.artworkUrl, '');
      expect(results.first.collectionId, isNull);
    });

    test('8. Filtrage strict par langue via RSS', () async {
      final mockClient = MockClient((request) async {
        final uriStr = request.url.toString();
        if (uriStr.contains('itunes.apple.com')) {
          final mockResponse = {
            'results': [
              {
                'collectionName': 'Podcast Français',
                'artistName': 'FR Author',
                'feedUrl': 'https://example.com/fr_feed.xml',
              },
              {
                'collectionName': 'Podcast Anglais',
                'artistName': 'EN Author',
                'feedUrl': 'https://example.com/en_feed.xml',
              },
              {
                'collectionName': 'Podcast Sans Langue',
                'artistName': 'Unknown Author',
                'feedUrl': 'https://example.com/no_lang_feed.xml',
              }
            ]
          };
          return http.Response(jsonEncode(mockResponse), 200);
        } else if (uriStr == 'https://example.com/fr_feed.xml') {
          return http.Response(
              '<rss><channel><language><![CDATA[fr-FR]]></language></channel></rss>',
              200);
        } else if (uriStr == 'https://example.com/en_feed.xml') {
          return http.Response(
              '<rss><channel><language><![CDATA[en-US]]></language></channel></rss>',
              200);
        } else if (uriStr == 'https://example.com/no_lang_feed.xml') {
          return http.Response('<rss><channel></channel></rss>', 200);
        }
        return http.Response('', 404);
      });

      final itunesService = ItunesService(client: mockClient);
      final results = await itunesService.searchPodcasts('test', lang: 'fr');

      // Doit inclure le podcast français et celui sans langue (accepté par défaut)
      // Mais doit EXCLURE le podcast anglais
      expect(results.length, 2);
      expect(
          results.any((p) => p.collectionName == 'Podcast Français'), isTrue);
      expect(results.any((p) => p.collectionName == 'Podcast Sans Langue'),
          isTrue);
      expect(
          results.any((p) => p.collectionName == 'Podcast Anglais'), isFalse);
    });
  });
}
