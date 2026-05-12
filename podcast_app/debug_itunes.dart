import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  String? feedUrl;
  const title = 'Fucked Up Movies';

  try {
    final searchRes = await http.get(Uri.parse(
        'https://itunes.apple.com/search?media=podcast&term=${Uri.encodeComponent(title)}&limit=1'));
    if (searchRes.statusCode == 200) {
      final data = json.decode(searchRes.body);
      if (data['results'] != null && data['results'].isNotEmpty) {
        feedUrl = data['results'][0]['feedUrl'];
      }
    }
  } catch (e) {
    print("Error: $e");
  }

  print("Found feedUrl: $feedUrl");
}
