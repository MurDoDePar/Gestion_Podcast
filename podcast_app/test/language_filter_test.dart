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

  group('Language Filter Firewall & Dynamic Switch Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    test(
        '1. Pare-feu de filtrage linguistique (lang="fr" avec normalisation FRA/fra/fr-FR)',
        () async {
      // 1. Configurer la langue dans AppSettings sur 'fr'
      await prefs.setString('podstream_lang', 'fr');

      final dio = Dio();
      dio.httpClientAdapter = FakeHttpClientAdapter((options) async {
        final queryParams = options.uri.queryParameters;
        final reqLang = queryParams['lang'];
        final reqCountry = queryParams['country'];

        // Si la requête contient bien les bons paramètres imposés par AppSettings (lang=fr, country=FR)
        if (reqLang == 'fr' && reqCountry == 'FR') {
          return ResponseBody.fromBytes(
            utf8.encode(jsonEncode({
              'results': [
                {
                  'collectionName': 'Podcast FR Standard',
                  'artistName': 'Auteur FR',
                  'feedUrl': 'https://example.com/fr1.xml',
                  'country': 'FRA',
                  'language': 'fr',
                },
                {
                  'collectionName': 'Podcast FR ISO-2',
                  'artistName': 'Auteur FRA',
                  'feedUrl': 'https://example.com/fr2.xml',
                  'country': 'FRA',
                  'language': 'FRA', // Devra être normalisé
                },
                {
                  'collectionName': 'Podcast FR CDATA',
                  'artistName': 'Auteur fra',
                  'feedUrl': 'https://example.com/fr3.xml',
                  'country': 'FRA',
                  'language': 'fra', // Devra être normalisé
                },
                {
                  'collectionName': 'Podcast FR Locale',
                  'artistName': 'Auteur fr-FR',
                  'feedUrl': 'https://example.com/fr4.xml',
                  'country': 'FRA',
                  'language': 'fr-FR', // Devra être normalisé
                }
              ]
            })),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        } else {
          // Si les paramètres sont incorrects (ex: contournement ou bug), on renvoie une pollution de langues
          return ResponseBody.fromBytes(
            utf8.encode(jsonEncode({
              'results': [
                {
                  'collectionName': 'Podcast FR',
                  'artistName': 'FR Author',
                  'feedUrl': 'https://example.com/fr.xml',
                  'country': 'FRA',
                  'language': 'fr',
                },
                {
                  'collectionName': "Podcast EN S'Infiltre",
                  'artistName': 'EN Author',
                  'feedUrl': 'https://example.com/en.xml',
                  'country': 'USA',
                  'language': 'en',
                }
              ]
            })),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
      });

      final gateway = ITunesGateway(dio: dio);

      // Appelle la recherche
      final results = await gateway.searchPodcasts('mix');

      // Assertion stricte : expect(results.any((p) => p.language != 'fr'), isFalse);
      // Règle d'assertion : Ne compare jamais directement les chaînes brutes.
      expect(
        results.any((p) => ITunesGateway.normalizeLanguage(p.language) != 'fr'),
        isFalse,
      );

      // Le test doit s'assurer que la liste n'est pas vide et qu'on a bien nos 4 podcasts normalisés
      expect(results.length, 4);
      for (final p in results) {
        expect(p.language,
            'fr'); // La gateway doit avoir appliqué la normalisation !
      }
    });

    test(
        '2. Validation de non-régression - Changement de langue dynamique à chaud',
        () async {
      final dio = Dio();
      String? lastReqLang;
      String? lastReqCountry;

      dio.httpClientAdapter = FakeHttpClientAdapter((options) async {
        final queryParams = options.uri.queryParameters;
        lastReqLang = queryParams['lang'];
        lastReqCountry = queryParams['country'];

        return ResponseBody.fromBytes(
          utf8.encode(jsonEncode({'results': []})),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final gateway = ITunesGateway(dio: dio);

      // A. Recherche initiale en français
      await prefs.setString('podstream_lang', 'fr');
      await gateway.searchPodcasts('news');

      expect(lastReqLang, 'fr');
      expect(lastReqCountry, 'FR');

      // B. Modification immédiate du paramètre dans AppSettings (de 'fr' à 'en')
      await prefs.setString('podstream_lang', 'en');

      // La prochaine recherche doit utiliser la nouvelle valeur immédiatement sans redémarrage
      await gateway.searchPodcasts('news');

      expect(lastReqLang, 'en');
      expect(lastReqCountry, 'US');
    });
  });
}
