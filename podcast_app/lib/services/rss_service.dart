import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart' as xml;
import 'package:html/parser.dart' as html_parser;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/episode_model.dart';
import 'itunes_gateway.dart';

class RssService {
  /// Télécharge et parse le flux RSS pour en extraire la liste des épisodes réels.
  /// Retourne [null] si le serveur renvoie un code 304 (flux non modifié).
  Future<List<EpisodeModel>?> getEpisodesFromFeed(String feedUrl) async {
    if (feedUrl.isEmpty) return [];

    try {
      final prefs = await SharedPreferences.getInstance();
      final etagKey = 'rss_etag_$feedUrl';
      final lastModifiedKey = 'rss_last_modified_$feedUrl';
      final cacheEpisodesKey = 'rss_episodes_$feedUrl';

      final cachedEtag = prefs.getString(etagKey);
      final cachedLastModified = prefs.getString(lastModifiedKey);

      final Map<String, String> headers = {};
      if (cachedEtag != null) {
        headers['If-None-Match'] = cachedEtag;
      }
      if (cachedLastModified != null) {
        headers['If-Modified-Since'] = cachedLastModified;
      }

      final response = await ITunesGateway()
          .fetchUrl(feedUrl, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 304) {
        return null; // Flux non modifié
      }

      if (response.statusCode == 200) {
        String? newEtag;
        String? newLastModified;

        response.headers.forEach((key, value) {
          final lkey = key.toLowerCase();
          if (lkey == 'etag') {
            newEtag = value;
          } else if (lkey == 'last-modified') {
            newLastModified = value;
          }
        });

        if (newEtag != null) {
          await prefs.setString(etagKey, newEtag!);
        } else {
          await prefs.remove(etagKey);
        }

        if (newLastModified != null) {
          await prefs.setString(lastModifiedKey, newLastModified!);
        } else {
          await prefs.remove(lastModifiedKey);
        }

        // Déporter le décodage UTF-8 et le parsing XML dans un Isolate séparé
        final episodes = await compute(_parseRss, response.bodyBytes);

        // Mettre à jour le cache local d'épisodes de ce flux
        final jsonEpisodes =
            jsonEncode(episodes.map((e) => e.toMap()).toList());
        await prefs.setString(cacheEpisodesKey, jsonEpisodes);

        return episodes;
      } else {
        // Erreur HTTP (ex: 500, 404, etc.) : renvoyer null pour forcer le repli sur le cache local
        return null;
      }
    } catch (e) {
      // Exception réseau (ex: Timeout, SocketException) ou de parsing XML : renvoyer null pour forcer le repli sur le cache local
      return null;
    }
  }

  /// Récupère la liste des épisodes sauvegardés localement en cache pour ce flux
  Future<List<EpisodeModel>> getCachedEpisodes(String feedUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheEpisodesKey = 'rss_episodes_$feedUrl';
      final cachedJson = prefs.getString(cacheEpisodesKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(cachedJson);
        return decoded
            .map((item) => EpisodeModel.fromMap(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // print('Exception lors de la lecture du cache RSS local : $e');
    }
    return [];
  }
}

/// Fonction globale exécutée dans un Isolate séparé pour éviter de bloquer l'UI
List<EpisodeModel> _parseRss(Uint8List bodyBytes) {
  // Décodage UTF-8 pour supporter les accents correctement
  final bodyString = utf8.decode(bodyBytes);
  final document = xml.XmlDocument.parse(bodyString);

  // Récupérer le nom du podcast depuis le canal principal (channel)
  final channelElement = document.findAllElements('channel').firstOrNull;
  final podcastName =
      channelElement?.findElements('title').firstOrNull?.innerText ??
          'Podcast inconnu';

  // Récupérer l'image par défaut du podcast
  String defaultImageUrl = '';
  final itunesImage = channelElement?.findElements('itunes:image').firstOrNull;
  if (itunesImage != null) {
    defaultImageUrl = itunesImage.getAttribute('href') ?? '';
  }
  if (defaultImageUrl.isEmpty) {
    final imageEl = channelElement?.findElements('image').firstOrNull;
    defaultImageUrl = imageEl?.findElements('url').firstOrNull?.innerText ?? '';
  }

  final items = document.findAllElements('item');
  final List<EpisodeModel> episodes = [];

  for (var item in items) {
    final title = item.findElements('title').firstOrNull?.innerText ??
        'Épisode sans titre';
    final rawDescription =
        item.findElements('description').firstOrNull?.innerText ??
            item.findElements('itunes:summary').firstOrNull?.innerText ??
            'Aucune description disponible.';
    final description = _sanitizeHtml(rawDescription);

    final enclosure = item.findElements('enclosure').firstOrNull;
    final audioUrl = enclosure?.getAttribute('url') ?? '';

    // Un épisode doit obligatoirement avoir une URL audio pour être jouable
    if (audioUrl.isEmpty) continue;

    // Récupérer l'image de l'épisode, sinon utiliser celle du podcast
    String imageUrl = defaultImageUrl;
    final itemItunesImage = item.findElements('itunes:image').firstOrNull;
    if (itemItunesImage != null) {
      final href = itemItunesImage.getAttribute('href');
      if (href != null && href.isNotEmpty) {
        imageUrl = href;
      }
    }

    // Parser la date de publication
    DateTime? pubDate;
    final pubDateStr = item.findElements('pubDate').firstOrNull?.innerText;
    if (pubDateStr != null && pubDateStr.isNotEmpty) {
      try {
        pubDate = HttpDate.parse(pubDateStr);
      } catch (_) {
        try {
          pubDate = DateTime.parse(pubDateStr);
        } catch (_) {
          try {
            final cleaned =
                pubDateStr.replaceAll(RegExp(r'[+-]\d{4}\s*$'), 'GMT').trim();
            pubDate = HttpDate.parse(cleaned);
          } catch (_) {}
        }
      }
    }

    // L'ID doit être unique et stable (l'audioUrl est idéal)
    final id = audioUrl;

    episodes.add(
      EpisodeModel(
        id: id,
        audioUrl: audioUrl,
        title: title,
        podcastName: podcastName,
        imageUrl: imageUrl,
        description: description,
        pubDate: pubDate,
      ),
    );
  }

  return episodes;
}

/// Fonction utilitaire de nettoyage HTML et de décodage des entités HTML5
String _sanitizeHtml(String htmlString) {
  if (htmlString.isEmpty) return '';
  // Parser la chaîne comme un document HTML
  final document = html_parser.parse(htmlString);
  // Extraire le texte brut combiné (ceci convertit également les balises en retours chariots/texte
  // et décode automatiquement les entités comme &nbsp;, &eacute;, &amp; etc.)
  final String parsedString = document.body?.text ?? '';
  return parsedString.trim();
}
