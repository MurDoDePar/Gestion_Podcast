import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

class ParsedEpisode {
  final String title;
  final DateTime pubDate;

  ParsedEpisode({required this.title, required this.pubDate});

  @override
  String toString() => '$title | ${pubDate.toIso8601String().substring(0, 10)}';
}

void main() async {
  const feedUrl = 'https://feed.ausha.co/omN08urqM3Yx';
  final response = await http.get(Uri.parse(feedUrl));
  final document = xml.XmlDocument.parse(utf8.decode(response.bodyBytes));
  final items = document.findAllElements('item');

  final parsedItems = <ParsedEpisode>[];

  for (var item in items) {
    final title = item.findElements('title').firstOrNull?.innerText ?? '';
    DateTime pubDate = DateTime.now();
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
    parsedItems.add(ParsedEpisode(title: title, pubDate: pubDate));
  }

  String userOrder = 'asc';

  parsedItems.sort((a, b) {
    int cmp = a.pubDate.compareTo(b.pubDate);
    if (cmp == 0) cmp = a.title.compareTo(b.title);
    return userOrder == 'asc' ? cmp : -cmp;
  });

  print('=== TOP 5 (asc) ===');
  for (var i = 0; i < 5; i++) {
    print(parsedItems[i]);
  }
}
