import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';
import '../theme/app_theme.dart';
import '../services/audio_service.dart';
import '../dataconnect-generated/example.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_screen.dart';
import 'package:podcast_app/services/audio_handler_locator.dart'; // Pour globalAudioHandler
import 'package:audio_service/audio_service.dart'; // Pour MediaItem

class ParsedEpisode {
  final xml.XmlElement element;
  final String title;
  final String? audioUrl;
  final DateTime pubDate;
  final int? itunesEpisode;
  final int? itunesOrder;

  ParsedEpisode({
    required this.element,
    required this.title,
    this.audioUrl,
    required this.pubDate,
    this.itunesEpisode,
    this.itunesOrder,
  });
}

class PodcastDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> podcast;

  const PodcastDetailsScreen({super.key, required this.podcast});

  @override
  State<PodcastDetailsScreen> createState() => _PodcastDetailsScreenState();
}

class _PodcastDetailsScreenState extends State<PodcastDetailsScreen> {
  bool _isLoading = true;
  bool _isSubscribed = false;
  String? _realPodcastId;
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

  String get actualPodcastId => _realPodcastId ?? podcastId;

  @override
  void initState() {
    super.initState();
    _isSubscribed = widget.podcast['isSubscribed'] == true;
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
      final currentFeedUrl = widget.podcast['feedUrl'];

      if (currentFeedUrl != null) {
        final existingPodcastResult = await ExampleConnector.instance
            .getPodcastByFeedUrl(feedUrl: currentFeedUrl)
            .execute();
        if (existingPodcastResult.data.podcasts.isNotEmpty) {
          _realPodcastId = existingPodcastResult.data.podcasts.first.id;
        }
      }

      setState(() {
        _isSubscribed = mySubs.any((s) =>
            s.podcast.id == actualPodcastId ||
            (currentFeedUrl != null && s.podcast.feedUrl == currentFeedUrl));

        if (_isSubscribed && _realPodcastId == null) {
          _realPodcastId = mySubs
              .firstWhere((s) =>
                  currentFeedUrl != null && s.podcast.feedUrl == currentFeedUrl)
              .podcast
              .id;
        }
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
              podcastId: actualPodcastId,
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
                  Timestamp(DateTime.now().millisecondsSinceEpoch ~/ 1000, 0),
            )
            .id(actualPodcastId)
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
              podcastId: actualPodcastId,
              subscribedAt:
                  Timestamp(DateTime.now().millisecondsSinceEpoch ~/ 1000, 0),
            )
            .listOrder(currentSubsCount)
            .execute();

        // Sync des épisodes en base maintenant que le podcast existe
        _syncEpisodesFromRSS();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Abonné avec succès !')));

          // Retourner à la page Mes podcasts (MainScreen par défaut)
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
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
        final prefs = await SharedPreferences.getInstance();
        final userOrder = prefs.getString('podstream_order') ?? 'asc';

        final epsList = dbEpisodes.toList();

        // NE PAS MODIFIER CETTE LOGIQUE DE TRI SANS DEMANDE EXPRESSE DU DÉVELOPPEUR
        epsList.sort((a, b) {
          int cmp = 0;
          // Extract episode number from title (e.g., "#14")
          final matchA = RegExp(r'#(\d+)').firstMatch(a.title);
          final matchB = RegExp(r'#(\d+)').firstMatch(b.title);
          if (matchA != null && matchB != null) {
            final numA = int.parse(matchA.group(1)!);
            final numB = int.parse(matchB.group(1)!);
            cmp = numA.compareTo(numB);
          } else {
            cmp = a.publishedAt
                .toDateTime()
                .compareTo(b.publishedAt.toDateTime());
            if (cmp == 0) cmp = a.title.compareTo(b.title);
          }

          if (userOrder == 'asc') {
            return cmp;
          } else {
            return -cmp;
          }
        });

        setState(() {
          _episodes = epsList
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
    String? feedUrl = widget.podcast['feedUrl'];
    if (feedUrl == null || feedUrl.isEmpty) {
      feedUrl = widget.podcast['collectionViewUrl'];
    }

    // Si toujours vide, on tente de le récupérer via l'API iTunes
    if (feedUrl == null || feedUrl.isEmpty || feedUrl.contains('apple.com')) {
      final title = widget.podcast['collectionName'] ?? widget.podcast['title'];
      if (title != null) {
        try {
          final searchRes = await http.get(Uri.parse(
              'https://itunes.apple.com/search?media=podcast&term=${Uri.encodeComponent(title)}&limit=1'));
          if (searchRes.statusCode == 200) {
            final data = json.decode(searchRes.body);
            if (data['results'] != null && data['results'].isNotEmpty) {
              feedUrl = data['results'][0]['feedUrl'];
            }
          }
        } catch (_) {}
      }
    }

    if (feedUrl == null || feedUrl.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(Uri.parse(feedUrl));
      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(utf8.decode(response.bodyBytes));

        final channelDesc =
            document.findAllElements('description').firstOrNull?.innerText ??
                '';
        if (mounted) {
          setState(() {
            _description =
                channelDesc.replaceAll(RegExp(r'<[^>]*>'), '').trim();
          });
        }

        final itunesType = document
                .findAllElements('itunes:type')
                .firstOrNull
                ?.innerText
                .toLowerCase() ??
            'episodic';
        final isSerial = itunesType == 'serial';

        final prefs = await SharedPreferences.getInstance();
        final userOrder = prefs.getString('podstream_order') ?? 'asc';

        final items = document.findAllElements('item');
        final parsedItems = <ParsedEpisode>[];

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
                  } catch (_) {
                    try {
                      // Fallback: remplacer le timezone ex: +0000 par GMT pour HttpDate
                      final cleaned = pubDateStr
                          .replaceAll(RegExp(r'[+-]\d{4}\s*$'), 'GMT')
                          .trim();
                      pubDate = HttpDate.parse(cleaned);
                    } catch (_) {}
                  }
                }
              }

              final itunesEpStr =
                  item.findElements('itunes:episode').firstOrNull?.innerText;
              final itunesEp =
                  itunesEpStr != null ? int.tryParse(itunesEpStr) : null;

              final itunesOrderStr =
                  item.findElements('itunes:order').firstOrNull?.innerText;
              final itunesOrder =
                  itunesOrderStr != null ? int.tryParse(itunesOrderStr) : null;

              parsedItems.add(ParsedEpisode(
                element: item,
                title: title,
                audioUrl: audioUrl,
                pubDate: pubDate,
                itunesEpisode: itunesEp,
                itunesOrder: itunesOrder,
              ));
            }
          }
        }

        // NE PAS MODIFIER CETTE LOGIQUE DE TRI SANS DEMANDE EXPRESSE DU DÉVELOPPEUR
        // Tri des épisodes
        parsedItems.sort((a, b) {
          int cmp = 0;

          final matchA = RegExp(r'#(\d+)').firstMatch(a.title);
          final matchB = RegExp(r'#(\d+)').firstMatch(b.title);

          if (isSerial && a.itunesEpisode != null && b.itunesEpisode != null) {
            cmp = a.itunesEpisode!.compareTo(b.itunesEpisode!);
          } else if (matchA != null && matchB != null) {
            final numA = int.parse(matchA.group(1)!);
            final numB = int.parse(matchB.group(1)!);
            cmp = numA.compareTo(numB);
          } else if (a.itunesOrder != null && b.itunesOrder != null) {
            cmp = a.itunesOrder!.compareTo(b.itunesOrder!);
          } else {
            cmp = a.pubDate.compareTo(b.pubDate);
          }

          if (cmp == 0) {
            cmp = a.title.compareTo(b.title); // fallback
          }
          if (userOrder == 'asc') {
            return cmp;
          } else {
            return -cmp;
          }
        });

        // Ne pas limiter pour que l'épisode #1 soit toujours accessible s'il est non lu
        final topItems = parsedItems;
        final eps = <AudioEpisode>[];

        for (var parsed in topItems) {
          final item = parsed.element;
          final audioUrl = parsed.audioUrl!;
          final stableId = _generateStableUuid(audioUrl);

          eps.add(AudioEpisode(
            id: stableId, // ID stable
            title: parsed.title,
            podcastName: widget.podcast['collectionName'] ??
                widget.podcast['title'] ??
                'Podcast',
            imageUrl:
                widget.podcast['artworkUrl600'] ?? widget.podcast['imageUrl'],
            audioUrl: audioUrl,
          ));

          // Upsert l'épisode en base
          if (_isSubscribed) {
            try {
              await ExampleConnector.instance
                  .upsertEpisode(
                    podcastId: podcastId,
                    title: parsed.title,
                    audioUrl: audioUrl,
                    duration: BigInt.zero,
                    publishedAt: Timestamp(
                        parsed.pubDate.millisecondsSinceEpoch ~/ 1000, 0),
                  )
                  .id(stableId)
                  .description(
                      item.findElements('description').firstOrNull?.innerText)
                  .imageUrl(widget.podcast['artworkUrl600'] ??
                      widget.podcast['imageUrl'])
                  .execute();
            } catch (upsertErr) {
              print("Erreur upsert episode ${parsed.title}: $upsertErr");
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
                    icon: Icon(_isSubscribed ? Icons.remove : Icons.add),
                    label: Text(_isSubscribed ? 'Se désabonner' : 'S\'abonner'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSubscribed
                          ? Colors.red.shade400
                          : AppTheme.primaryColor,
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
                    onTap: () async {
                      print(
                          'AA_DEBUG_UI: Clic détecté sur l\'épisode ${episode.title}');
                      if (globalAudioHandler == null) {
                        print('AA_DEBUG_ERROR: globalAudioHandler is null!');
                        return;
                      }
                      await globalAudioHandler!.playMediaItem(
                        MediaItem(
                          id: episode.audioUrl,
                          title: episode.title,
                          artist: episode.podcastName,
                          artUri: episode.imageUrl != null
                              ? Uri.parse(episode.imageUrl!)
                              : null,
                          extras: {'episodeId': episode.id},
                        ),
                      );
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
