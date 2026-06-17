import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/podcast_model.dart';
import 'itunes_search_gateway.dart';

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

class GatewayCancelToken {
  final CancelToken _dioCancelToken = CancelToken();
  void cancel() => _dioCancelToken.cancel();
  bool get isCancelled => _dioCancelToken.isCancelled;
}

class GatewayCancelException implements Exception {}

class GatewayException implements Exception {
  final String message;
  GatewayException(this.message);
  @override
  String toString() => message;
}

class ITunesGateway {
  static ITunesGateway? mockInstance;
  final Dio _dio;

  factory ITunesGateway({Dio? dio}) {
    return mockInstance ?? ITunesGateway.forTesting(dio: dio);
  }

  @visibleForTesting
  ITunesGateway.forTesting({Dio? dio}) : _dio = dio ?? Dio();

  /// Normalise les tags linguistiques de l'API (ex: 'FRA' ou 'fr-FR' en 'fr')
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

  /// Télécharge le contenu brut d'une URL de manière centralisée.
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

  /// Télécharge un fichier de manière centralisée.
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

  /// Récupère la taille d'un fichier distant par requête HTTP HEAD (ou GET Range en secours).
  Future<int> getUrlFileSize(String url) async {
    try {
      final response = await _dio
          .head(
            url,
            options: Options(
              followRedirects: true,
              maxRedirects: 5,
            ),
          )
          .timeout(const Duration(seconds: 5));
      final contentLength = response.headers.value('content-length');
      if (contentLength != null) {
        return int.tryParse(contentLength) ?? 0;
      }
    } catch (_) {
      try {
        final response = await _dio
            .get(
              url,
              options: Options(
                headers: {'Range': 'bytes=0-0'},
                followRedirects: true,
                maxRedirects: 5,
              ),
            )
            .timeout(const Duration(seconds: 5));
        final contentRange = response.headers.value('content-range');
        if (contentRange != null) {
          final parts = contentRange.split('/');
          if (parts.length == 2) {
            return int.tryParse(parts[1]) ?? 0;
          }
        }
        final contentLength = response.headers.value('content-length');
        if (contentLength != null) {
          return int.tryParse(contentLength) ?? 0;
        }
      } catch (_) {}
    }
    return 0;
  }

  /// Interface publique unique pour toute recherche de podcasts.
  /// Gère la langue, le tri, le filtrage des doublons.
  ///
  /// **Utilité** : Recherche des podcasts sur iTunes via la passerelle de recherche centralisée ITunesSearchGateway, avec options d'override.
  /// **Point d'entrée** : Appelé par les anciens modules de recherche ou thèmes.
  /// **Maintenance** : Cette méthode est déléguée à ITunesSearchGateway pour préserver le principe DRY.
  Future<List<PodcastModel>> searchPodcasts(
    String term, {
    String? country,
    String? lang,
    String? genreId,
  }) async {
    return ITunesSearchGateway(dio: _dio).searchPodcasts(
      term,
      country: country,
      lang: lang,
      genreId: genreId,
    );
  }
}
