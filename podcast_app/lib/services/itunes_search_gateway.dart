import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../models/podcast_model.dart';
import '../models/app_settings.dart';

/// Réponse brute renvoyée par la passerelle réseau.
class GatewayResponse {
  final int statusCode;
  final Uint8List bodyBytes;
  final Map<String, String> headers;

  GatewayResponse({
    required this.statusCode,
    required this.bodyBytes,
    required this.headers,
  });
}

/// Jeton permettant d'annuler une requête en cours.
class GatewayCancelToken {
  final CancelToken _dioCancelToken = CancelToken();
  void cancel() => _dioCancelToken.cancel();
  bool get isCancelled => _dioCancelToken.isCancelled;
}

/// Exception levée lors de l'annulation d'une requête réseau.
class GatewayCancelException implements Exception {}

/// Exception réseau générique.
class GatewayException implements Exception {
  final String message;
  GatewayException(this.message);
  @override
  String toString() => message;
}

/// Passerelle d'accès à l'API iTunes pour la recherche de podcasts.
///
/// Cette classe encapsule toutes les requêtes réseau sortantes destinées à
/// l'API publique d'iTunes et au téléchargement de flux/fichiers.
/// Elle permet d'isoler la couche HTTP et facilite le mock des tests.
class ITunesSearchGateway {
  final Dio _dio;

  /// Initialise la passerelle avec une instance facultative de [Dio].
  ///
  /// Si aucune instance n'est fournie, une nouvelle instance par défaut de [Dio] est créée.
  ITunesSearchGateway({Dio? dio}) : _dio = dio ?? Dio();

  /// Normalise les tags de langue reçus de l'API iTunes ou des réglages de l'application.
  ///
  /// **Utilité** : Traduit les formats complexes de langues (ex: 'fr-FR', 'fra') en code ISO simple à 2 lettres ('fr').
  /// **Point d'entrée** : Appelé lors de la préparation des filtres de recherche.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si une nouvelle langue (ex: 'it' ou 'ja') n'est pas correctement détectée ou normalisée.
  static String normalizeLanguage(String? lang) {
    if (lang == null) return '';
    final clean = lang.trim().toLowerCase();
    if (clean == 'all') return 'all';
    if (clean == 'fra' || clean == 'fre' || clean == 'fr' || clean == 'fr-fr') {
      return 'fr';
    }
    if (clean == 'eng' ||
        clean == 'en' ||
        clean == 'en-us' ||
        clean == 'en-gb' ||
        clean == 'usa' ||
        clean == 'us' ||
        clean == 'gbr' ||
        clean == 'gb' ||
        clean == 'can' ||
        clean == 'ca' ||
        clean == 'aus' ||
        clean == 'au') {
      return 'en';
    }
    if (clean == 'spa' || clean == 'es' || clean == 'esp') return 'es';
    if (clean == 'deu' || clean == 'ger' || clean == 'de') return 'de';
    if (clean.length > 2) {
      return clean.substring(0, 2);
    }
    return clean;
  }

  /// Détecte la présence de stop-words anglais dans un texte pour le filtrage heuristique.
  ///
  /// **Utilité** : Identifie les podcasts anglophones dont les métadonnées de langue sont absentes de l'API iTunes en analysant leur titre.
  /// **Point d'entrée** : Appelé en secours dans `searchPodcasts` lors de la normalisation de la langue par rapport au pays du store.
  /// **Maintenance** : Si un nouveau podcast anglophone populaire passe à travers, ajouter de nouveaux stop-words très spécifiques dans l'ensemble.
  static bool _hasEnglishStopWords(String text) {
    final cleanText = text.toLowerCase();
    const stopWords = {
      'the',
      'of',
      'with',
      'and',
      'for',
      'from',
      'by',
      'this',
      'that',
      'who',
      'what',
      'which',
      'where',
      'when',
      'why',
      'how',
      'is',
      'are',
      'was',
      'were',
      'be',
      'been',
      'have',
      'has',
      'had',
      'you',
      'your',
      'yours',
      'he',
      'him',
      'his',
      'she',
      'her',
      'hers',
      'they',
      'them',
      'their',
      'theirs',
      'we',
      'us',
      'our',
      'ours'
    };
    final words = cleanText.split(RegExp(r'\W+'));
    for (final word in words) {
      if (stopWords.contains(word)) {
        return true;
      }
    }
    return false;
  }

  /// Télécharge le contenu brut (octets) d'une URL.
  ///
  /// **Utilité** : Récupérer des fichiers ou des flux XML/RSS distants sous forme de flux binaire brut.
  /// **Point d'entrée** : Appelé par le service d'agrégation d'épisodes et de lecture de flux RSS (`RssService`).
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si les en-têtes réseau (ex: User-Agent) doivent être adaptés pour éviter des blocages HTTP 403.
  Future<GatewayResponse> fetchUrl(String url,
      {Map<String, String>? headers}) async {
    try {
      final response = await _dio.get<List<int>>(
        url,
        options: Options(
          headers: headers,
          responseType: ResponseType.bytes,
        ),
      );

      final responseHeaders = <String, String>{};
      response.headers.forEach((name, values) {
        if (values.isNotEmpty) {
          responseHeaders[name] = values.first;
        }
      });

      return GatewayResponse(
        statusCode: response.statusCode ?? 200,
        bodyBytes: Uint8List.fromList(response.data ?? []),
        headers: responseHeaders,
      );
    } on DioException catch (e) {
      final responseHeaders = <String, String>{};
      e.response?.headers.forEach((name, values) {
        if (values.isNotEmpty) {
          responseHeaders[name] = values.first;
        }
      });
      return GatewayResponse(
        statusCode: e.response?.statusCode ?? 500,
        bodyBytes: Uint8List.fromList([]),
        headers: responseHeaders,
      );
    } catch (_) {
      return GatewayResponse(
        statusCode: 500,
        bodyBytes: Uint8List.fromList([]),
        headers: const {},
      );
    }
  }

  /// Télécharge un fichier binaire et l'enregistre localement sur le disque.
  ///
  /// **Utilité** : Permet de télécharger physiquement un épisode de podcast pour une lecture hors-ligne.
  /// **Point d'entrée** : Appelé par le gestionnaire de téléchargement (`DownloadManager`) lors du traitement de la file.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si les délais d'attente (timeouts) ou les politiques de reprise de téléchargement doivent être ajustés.
  Future<void> downloadFile(
    String url,
    String savePath, {
    GatewayCancelToken? cancelToken,
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    try {
      await _dio.download(
        url,
        savePath,
        cancelToken: cancelToken?._dioCancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        throw GatewayCancelException();
      }
      throw GatewayException(e.message ?? 'Erreur de téléchargement');
    } catch (e) {
      throw GatewayException(e.toString());
    }
  }

  /// Recherche des podcasts via l'API publique iTunes en filtrant par langue.
  ///
  /// **Utilité** : Interroge l'API iTunes pour trouver des podcasts correspondant à un terme de recherche textuel, avec support d'overrides pour le pays, la langue et l'ID de genre.
  /// **Point d'entrée** : Appelé lors d'une recherche utilisateur manuelle dans l'onglet de recherche, par les thèmes prédéfinis, ou par le service de découvertes.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si les paramètres de l'API iTunes changent (limites, formats d'entités, ou pays pris en charge).
  Future<List<PodcastModel>> searchPodcasts(
    String term, {
    String? country,
    String? lang,
    String? genreId,
  }) async {
    final String trimmed = term.trim();
    if (trimmed.isEmpty) return [];

    String searchTerm = trimmed;
    if (searchTerm.toLowerCase() == 'populaire') {
      searchTerm = 'podcast';
    }

    final String rawLang = lang ?? await AppSettings.getLanguage();
    final String targetLang = normalizeLanguage(rawLang);
    final langToCountry = {'fr': 'FR', 'en': 'US', 'es': 'ES', 'de': 'DE'};

    try {
      final queryParams = {
        'term': searchTerm,
        'media': 'podcast',
        'entity': 'podcast',
        'limit': 40,
        'lang': targetLang,
      };

      if (country != null) {
        queryParams['country'] = country;
      } else if (targetLang != 'all' && langToCountry.containsKey(targetLang)) {
        queryParams['country'] = langToCountry[targetLang]!;
      }

      if (genreId != null) {
        queryParams['genreId'] = genreId;
      }

      final String generatedUrl = Uri.https(
        'itunes.apple.com',
        '/search',
        queryParams.map((k, v) => MapEntry(k, v.toString())),
      ).toString();
      print('[DEBUG_ITUNES_REQ] URL générée : $generatedUrl');
      print('[DEBUG_ITUNES_REQ] Langue cible injectée : $targetLang');

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
        final List<PodcastModel> validPodcasts = [];
        final Set<String> seenFeedUrls = {};

        for (var item in results) {
          if (item is Map<String, dynamic>) {
            final String rawItemLang = item['language']?.toString() ?? '';
            final String rawItemCountry = item['country']?.toString() ?? '';

            String normalizedLang = normalizeLanguage(rawItemLang);
            if (normalizedLang.isEmpty && rawItemCountry.isNotEmpty) {
              final String normalizedCountry =
                  normalizeLanguage(rawItemCountry);
              if (normalizedCountry == 'fr') {
                // Heuristique de secours pour le store français si language est absent :
                // On vérifie le titre pour exclure les faux positifs anglophones.
                final String title = item['collectionName']?.toString() ?? '';
                if (_hasEnglishStopWords(title)) {
                  normalizedLang =
                      'en'; // Forcer en 'en' car c'est un podcast anglophone
                } else {
                  normalizedLang = 'fr';
                }
              } else {
                normalizedLang = normalizedCountry;
              }
            }

            print(
                '[DEBUG_ITUNES_RES] Podcast reçu : ${item['collectionName'] ?? 'Sans nom'} | Pays détecté : $rawItemCountry | Langue résolue : $normalizedLang');

            // Filtrage de langue strict (Normalisation Hardcore)
            if (targetLang != 'all' && normalizedLang != targetLang) {
              print(
                  '[DEBUG_ITUNES_FILTER] Podcast exclus : ${item['collectionName'] ?? 'Sans nom'} (Raison : Langue $normalizedLang != $targetLang)');
              continue;
            }

            // Assert de langue strict
            assert(targetLang == 'all' || normalizedLang == targetLang,
                'L\'item retourné a une langue incohérente avec la configuration');

            final model = PodcastModel.fromJson(item);
            final updatedModel = model.copyWith(
              language:
                  normalizedLang.isNotEmpty ? normalizedLang : model.language,
              recommendedByGenre: trimmed,
            );
            final key = updatedModel.feedUrl.toLowerCase().trim();
            if (key.isNotEmpty && !seenFeedUrls.contains(key)) {
              seenFeedUrls.add(key);
              validPodcasts.add(updatedModel);
            }
          }
        }
        return validPodcasts;
      }
    } catch (_) {
      // Échec silencieux
    }
    return [];
  }
}
