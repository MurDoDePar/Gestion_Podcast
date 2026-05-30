import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:html/parser.dart' as html_parser;
import '../models/episode_model.dart';

class RssService {
  /// Télécharge et parse le flux RSS pour en extraire la liste des épisodes réels
  Future<List<EpisodeModel>> getEpisodesFromFeed(String feedUrl) async {
    if (feedUrl.isEmpty) return [];

    try {
      final response = await http
          .get(Uri.parse(feedUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Déporter le décodage UTF-8 et le parsing XML dans un Isolate séparé
        return await compute(_parseRss, response.bodyBytes);
      } else {
        print(
            'Erreur HTTP lors du téléchargement du flux RSS : ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception lors du parsing du flux RSS de $feedUrl : $e');
      return [];
    }
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
