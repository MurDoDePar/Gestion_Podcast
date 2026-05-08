import 'package:flutter/material.dart';
import 'dart:io';
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

  String get podcastId {
    final rawId = widget.podcast['collectionId'].toString();
    if (rawId.contains('-')) return rawId;

    // Si la base de données (Data Connect) renvoie le UUID sans tirets (32 caractères)
    if (rawId.length == 32) {
      return '${rawId.substring(0, 8)}-${rawId.substring(8, 12)}-${rawId.substring(12, 16)}-${rawId.substring(16, 20)}-${rawId.substring(20, 32)}';
    }

    // Sinon, on assume que c'est un ID iTunes et on le pad pour le formater en UUID
    final paddedId = rawId.padLeft(12, '0');
    return '00000000-0000-4000-8000-$paddedId';
  }

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
      final userResult = await ExampleConnector.instance
          .findUserByGoogleId(googleId: user.uid)
          .execute();
      if (userResult.data.users.isEmpty) return;
      final postgresUuid = userResult.data.users.first.id;

      final subsResult = await ExampleConnector.instance
          .getMySubscriptions(userId: postgresUuid)
          .execute();
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
      final userResult = await ExampleConnector.instance
          .findUserByGoogleId(googleId: user.uid)
          .execute();
      if (userResult.data.users.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Profil introuvable. Allez dans les paramètres, déconnectez-vous puis reconnectez-vous pour finaliser la création de votre profil.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }
      final postgresUuid = userResult.data.users.first.id;

      if (_isSubscribed) {
        // Mise à jour optimiste de l'UI
        setState(() {
          _isSubscribed = false;
        });

        // Se désabonner
        await ExampleConnector.instance
            .unsubscribeFromPodcast(
              userId: postgresUuid,
              podcastId: podcastId,
            )
            .execute();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Désabonné avec succès')));
        }
      } else {
        // Mise à jour optimiste de l'UI
        setState(() {
          _isSubscribed = true;
        });

        // S'abonner : Upsert podcast d'abord
        final title = widget.podcast['collectionName'] ??
            widget.podcast['title'] ??
            'Podcast';
        final feedUrl = widget.podcast['feedUrl'];
        if (feedUrl == null) throw Exception("Feed URL manquant");

        // Upsert Podcast dans DataConnect
        await ExampleConnector.instance
            .upsertPodcast(
              title: title,
              feedUrl: feedUrl,
              createdAt:
                  Timestamp(0, DateTime.now().millisecondsSinceEpoch ~/ 1000),
            )
            .id(podcastId)
            .description(_description.substring(
                0, _description.length > 500 ? 500 : _description.length))
            .imageUrl(
                widget.podcast['artworkUrl600'] ?? widget.podcast['imageUrl'])
            .author(widget.podcast['artistName'] ?? widget.podcast['author'])
            .execute();

        // Récupérer le nombre d'abonnements actuels pour définir l'ordre
        final subsResult = await ExampleConnector.instance
            .getMySubscriptions(userId: postgresUuid)
            .execute();
        final currentSubsCount = subsResult.data.subscriptionTypes.length;

        // Créer l'abonnement
        await ExampleConnector.instance
            .subscribeToPodcast(
              userId: postgresUuid,
              podcastId: podcastId,
              subscribedAt:
                  Timestamp(0, DateTime.now().millisecondsSinceEpoch ~/ 1000),
            )
            .listOrder(currentSubsCount)
            .execute();

        // Sync des épisodes en base maintenant que le podcast existe
        _syncEpisodesFromRSS();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Abonné avec succès !')));
        }
      }
    } catch (e) {
      // En cas d'erreur, on annule la mise à jour optimiste
      if (mounted) {
        setState(() {
          // On inverse pour revenir à l'état précédent
          // Wait, actually we can just re-check or just invert.
          // The simplest is to assume we invert what we just did.
          // To be perfectly safe we could re-call _checkSubscription,
          // but _isSubscribed = !_isSubscribed works.
          _isSubscribed = !_isSubscribed;
        });
      }

      print("Erreur abonnement: $e");
      if (e is DataConnectError) {
        print("Data Connect Exception Message: ${e.message}");
        try {
          final dynamic dynE = e;
          if (dynE.errors != null) {
            for (var err in dynE.errors) {
              print("Détail Backend: ${err.message}");
            }
          }
        } catch (_) {}
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _fetchEpisodes() async {
    // 1. Lire d'abord depuis la DB pour un affichage rapide
    await _loadEpisodesFromDB();

    // 2. Lancer la synchronisation en arrière-plan
    _syncEpisodesFromRSS();
  }

  Future<void> _loadEpisodesFromDB() async {
    try {
      final result = await ExampleConnector.instance
          .getEpisodesByPodcast(podcastId: podcastId)
          .execute();
      final dbEpisodes = result.data.episodes;

      if (dbEpisodes.isNotEmpty && mounted) {
        setState(() {
          _episodes = dbEpisodes
              .map((e) => AudioEpisode(
                    id: e.id,
                    title: e.title,
                    podcastName: widget.podcast['collectionName'] ??
                        widget.podcast['title'] ??
                        'Podcast',
                    imageUrl: e.imageUrl ??
                        widget.podcast['artworkUrl600'] ??
                        widget.podcast['imageUrl'],
                    audioUrl: e.audioUrl,
                  ))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Erreur chargement episodes DB: $e");
    }
  }

  Future<void> _syncEpisodesFromRSS() async {
    final feedUrl = widget.podcast['feedUrl'];
    if (feedUrl == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(Uri.parse(feedUrl));
      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final channelDesc =
            document.findAllElements('description').firstOrNull?.innerText ??
                '';
        if (mounted) {
          setState(() {
            _description =
                channelDesc.replaceAll(RegExp(r'<[^>]*>'), '').trim();
          });
        }

        final items = document
            .findAllElements('item')
            .take(20); // Limiter aux 20 derniers
        final eps = <AudioEpisode>[];

        for (var item in items) {
          final title = item.findElements('title').firstOrNull?.innerText ??
              'Épisode inconnu';
          final enclosure = item.findElements('enclosure').firstOrNull;

          if (enclosure != null) {
            final audioUrl = enclosure.getAttribute('url');
            if (audioUrl != null) {
              DateTime pubDate = DateTime.now();
              final pubDateStr =
                  item.findElements('pubDate').firstOrNull?.innerText;
              if (pubDateStr != null && pubDateStr.isNotEmpty) {
                try {
                  pubDate = HttpDate.parse(pubDateStr);
                } catch (_) {
                  try {
                    pubDate = DateTime.parse(pubDateStr);
                  } catch (_) {}
                }
              }
              // Very basic parsing fallback, in a real app use intl or specific date parser
              // We just use now() to ensure it saves if parsing is complex, or try to parse
              // But for RSS dates RFC-822, Dart's DateTime.parse doesn't always work perfectly.

              // We use audioUrl as an ID base
              // But UUID format is needed for Data Connect. So we hash or ignore ID to auto-generate
              // Actually, UpsertEpisode ID is optional (UUID?). If not provided, it generates one?
              // Wait, in schema, Episode ID is generated by default if UUID is default.
              // Oh wait, in Data Connect, if ID is omitted, it auto-generates!
              // But to avoid duplicates on upsert, we need a stable ID!
              // Let's create a stable UUID from the audioUrl.
              final stableId = _generateStableUuid(audioUrl);

              eps.add(AudioEpisode(
                id: stableId, // ID stable
                title: title,
                podcastName: widget.podcast['collectionName'] ??
                    widget.podcast['title'] ??
                    'Podcast',
                imageUrl: widget.podcast['artworkUrl600'] ??
                    widget.podcast['imageUrl'],
                audioUrl: audioUrl,
              ));

              // Upsert l'épisode en base
              if (_isSubscribed) {
                try {
                  await ExampleConnector.instance
                      .upsertEpisode(
                        podcastId: podcastId,
                        title: title,
                        audioUrl: audioUrl,
                        duration: BigInt.zero,
                        publishedAt: Timestamp(
                            0, pubDate.millisecondsSinceEpoch ~/ 1000),
                      )
                      .id(stableId)
                      .description(item
                          .findElements('description')
                          .firstOrNull
                          ?.innerText)
                      .imageUrl(widget.podcast['artworkUrl600'] ??
                          widget.podcast['imageUrl'])
                      .execute();
                } catch (upsertErr) {
                  print("Erreur upsert episode $title: $upsertErr");
                }
              }
            }
          }
        }

        // Mettre à jour l'UI avec les épisodes rafraîchis si la DB était vide ou différente
        if (mounted) {
          setState(() {
            _episodes = eps;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Erreur parsing episodes RSS: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _generateStableUuid(String input) {
    // Very simple pseudo-hash to make a UUID-like string from audioUrl for stable upserts
    String hash = input.hashCode.abs().toString().padLeft(12, '0');
    if (hash.length > 12) hash = hash.substring(0, 12);
    String hash2 = (input.length * 31).toString().padLeft(3, '0');
    if (hash2.length > 3) hash2 = hash2.substring(0, 3);
    return '11111111-2222-4000-8$hash2-$hash';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        widget.podcast['artworkUrl600'] ?? widget.podcast['imageUrl'];
    final title = widget.podcast['collectionName'] ??
        widget.podcast['title'] ??
        'Podcast';
    final author = widget.podcast['artistName'] ??
        widget.podcast['author'] ??
        'Auteur inconnu';

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
                          ? DecorationImage(
                              image: NetworkImage(imageUrl), fit: BoxFit.cover)
                          : null,
                    ),
                    child: imageUrl == null
                        ? const Icon(Icons.podcasts,
                            size: 80, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    author,
                    style: const TextStyle(
                        fontSize: 16, color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _toggleSubscription,
                    icon: Icon(_isSubscribed ? Icons.check : Icons.add),
                    label: Text(_isSubscribed ? 'Abonné' : 'S\'abonner'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isSubscribed ? Colors.green : AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_description.isNotEmpty) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('À propos',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _description,
                      style: const TextStyle(color: AppTheme.textSecondary),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 24),
                  ],
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Tous les épisodes',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
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
            const SliverToBoxAdapter(
              child: Center(
                child: Text('Aucun épisode trouvé',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final episode = _episodes[index];
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.play_arrow,
                          color: AppTheme.primaryColor),
                    ),
                    title: Text(episode.title,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      AudioService().playEpisode(episode, playlist: _episodes);
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
