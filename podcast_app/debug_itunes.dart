import 'package:podcast_app/services/itunes_gateway.dart';

void main() async {
  String? feedUrl;
  const title = 'Fucked Up Movies';

  try {
    final results = await ITunesGateway().searchPodcasts(title);
    if (results.isNotEmpty) {
      feedUrl = results.first.feedUrl;
    }
  } catch (e) {
    print("Error: $e");
  }

  print("Found feedUrl: $feedUrl");
}
