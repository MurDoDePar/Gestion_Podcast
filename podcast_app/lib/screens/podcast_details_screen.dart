import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';
import '../theme/app_theme.dart';
import '../services/audio_service.dart';
import '../dataconnect-generated/example.dart';

class PodcastDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> podcast;

  const PodcastDetailsScreen({super.key, required this.podcast});

  @override
  State<PodcastDetailsScreen> createState() => _PodcastDetailsScreenState();
}

class _PodcastDetailsScreenState extends State<PodcastDetailsScreen> {
  bool _isLoading = true;
  bool _isSubscribed = false;
  List<AudioEpisode> _episodes = [];
  String _description = '';
  
  // DataConnect ID extraction (using collectionId as UUID base like in JS)
  String get podcastId => widget.podcast['collectionId'].toString();

  @override
  void initState() {
    super.initState();
    _checkSubscription();
    _fetchEpisodes();
  }

  Future<void> _checkSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      final userResult = await ExampleConnector.instance.findUserByGoogleId(googleId: user.uid).execute();
      if (userResult.data.users.isEmpty) return;
      final postgresUuid = userResult.data.users.first.id;

      final subsResult = await ExampleConnector.instance.getMySubscriptions(userId: postgresUuid).execute();
      final mySubs = subsResult.data.subscriptionTypes;

      setState(() {
        _isSubscribed = mySubs.any((s) => s.podcast.id == podcastId);
      });
    } catch (e) {
      print("Erreur vérif abonnement: $e");
    }
  }

  Future<void> _toggleSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour vous abonner')),
      );
      return;
    }

    try {
      final userResult = await ExampleConnector.instance.findUserByGoogleId(googleId: user.uid).execute();
      if (userResult.data.users.isEmpty) return;
      final postgresUuid = userResult.data.users.first.id;

      if (_isSubscribed) {
        // Se désabonner
        await ExampleConnector.instance.unsubscribeFromPodcast(
          userId: postgresUuid,
          podcastId: podcastId,
        ).execute();
        
        setState(() {
          _isSubscribed = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Désabonné avec succès')));
      } else {
        // S'abonner : Upsert podcast d'abord
        final title = widget.podcast['collectionName'] ?? widget.podcast['title'] ?? 'Podcast';
        final feedUrl = widget.podcast['feedUrl'];
        if (feedUrl == null) throw Exception("Feed URL manquant");
        
        // Upsert Podcast dans DataConnect
        await ExampleConnector.instance.upsertPodcast(
          title: title,
          feedUrl: feedUrl,
          createdAt: Timestamp(0, DateTime.now().millisecondsSinceEpoch ~/ 1000),
        ).id(podcastId)
         .description(_description.substring(0, _description.length > 500 ? 500 : _description.length))
         .imageUrl(widget.podcast['artworkUrl600'] ?? widget.podcast['imageUrl'])
         .author(widget.podcast['artistName'] ?? widget.podcast['author'])
         .execute();

        // Créer l'abonnement
        await ExampleConnector.instance.subscribeToPodcast(
          userId: postgresUuid,
          podcastId: podcastId,
          subscribedAt: Timestamp(0, DateTime.now().millisecondsSinceEpoch ~/ 1000),
        ).execute();

        setState(() {
          _isSubscribed = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abonné avec succès !')));
      }
    } catch (e) {
      print("Erreur abonnement: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _fetchEpisodes() async {
    final feedUrl = widget.podcast['feedUrl'];
    if (feedUrl == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(Uri.parse(feedUrl));
      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);
        
        // Chercher la description du podcast
        final channelDesc = document.findAllElements('description').firstOrNull?.innerText ?? '';
        _description = channelDesc.replaceAll(RegExp(r'<[^>]*>'), '').trim();

        // Récupérer les items
        final items = document.findAllElements('item');
        final eps = <AudioEpisode>[];

        for (var item in items) {
          final title = item.findElements('title').firstOrNull?.innerText ?? 'Épisode inconnu';
          final enclosure = item.findElements('enclosure').firstOrNull;
          if (enclosure != null) {
            final audioUrl = enclosure.getAttribute('url');
            if (audioUrl != null) {
              eps.add(AudioEpisode(
                id: audioUrl, // Utilisation de l'URL comme ID
                title: title,
                podcastName: widget.podcast['collectionName'] ?? widget.podcast['title'] ?? 'Podcast',
                imageUrl: widget.podcast['artworkUrl600'] ?? widget.podcast['imageUrl'],
                audioUrl: audioUrl,
              ));
            }
          }
        }

        setState(() {
          _episodes = eps;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Erreur parsing episodes: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.podcast['artworkUrl600'] ?? widget.podcast['imageUrl'];
    final title = widget.podcast['collectionName'] ?? widget.podcast['title'] ?? 'Podcast';
    final author = widget.podcast['artistName'] ?? widget.podcast['author'] ?? 'Auteur inconnu';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      image: imageUrl != null
                          ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                          : null,
                    ),
                    child: imageUrl == null
                        ? const Icon(Icons.podcasts, size: 80, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    author,
                    style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _toggleSubscription,
                    icon: Icon(_isSubscribed ? Icons.check : Icons.add),
                    label: Text(_isSubscribed ? 'Abonné' : 'S\'abonner'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSubscribed ? Colors.green : AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_description.isNotEmpty) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('À propos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _description,
                      style: TextStyle(color: AppTheme.textSecondary),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 24),
                  ],
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Tous les épisodes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_episodes.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Text('Aucun épisode trouvé', style: TextStyle(color: AppTheme.textSecondary)),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final episode = _episodes[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.play_arrow, color: AppTheme.primaryColor),
                    ),
                    title: Text(episode.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      AudioService().playEpisode(episode);
                    },
                  );
                },
                childCount: _episodes.length,
              ),
            ),
        ],
      ),
    );
  }
}
