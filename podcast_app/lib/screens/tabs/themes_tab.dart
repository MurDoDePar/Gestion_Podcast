import 'package:flutter/material.dart';
import '../../models/podcast_model.dart';
import '../../services/itunes_service.dart';
import '../../services/database_repository.dart';
import '../../theme/app_theme.dart';
import '../podcast_details_screen.dart';

class ThemesTab extends StatelessWidget {
  const ThemesTab({super.key});

  static const List<String> categories = [
    'Humour',
    'Actualités',
    'Sciences',
    'Culture',
    'Sport',
    'Technologie',
    'Histoire',
    'Santé',
  ];

  @override
  Widget build(BuildContext context) {
    // Le DefaultTabController lie le TabBar et le TabBarView
    return DefaultTabController(
      length: categories.length,
      child: Column(
        children: [
          // Barre d'onglets défilante
          Container(
            color: AppTheme.bgColor,
            child: TabBar(
              isScrollable: true,
              indicatorColor: AppTheme.primaryColor,
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textSecondary,
              tabs: categories.map((cat) => Tab(text: cat)).toList(),
            ),
          ),
          // Contenu correspondant à chaque onglet
          Expanded(
            child: TabBarView(
              children: categories
                  .map((cat) => ThemeResultsView(theme: cat))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget qui affiche la liste pour une catégorie donnée
class ThemeResultsView extends StatefulWidget {
  final String theme;

  const ThemeResultsView({super.key, required this.theme});

  @override
  State<ThemeResultsView> createState() => _ThemeResultsViewState();
}

class _ThemeResultsViewState extends State<ThemeResultsView>
    with AutomaticKeepAliveClientMixin {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = Future.wait([
      ItunesService().getPodcastsByTheme(widget.theme),
      DatabaseRepository().getSubscribedPodcastIds(),
    ]);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Indispensable pour AutomaticKeepAliveClientMixin
    return FutureBuilder<List<dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
              child: Text(
                  'Erreur lors du chargement des podcasts de ${widget.theme}.',
                  style: const TextStyle(color: AppTheme.textSecondary)));
        }

        final results = snapshot.data!;
        final allPodcasts = results[0] as List<PodcastModel>;
        final subscribedIds = results[1] as Set<String>;

        // Filtrer les podcasts déjà abonnés
        final podcasts = allPodcasts
            .where((p) => !subscribedIds.contains(p.feedUrl))
            .toList();

        if (podcasts.isEmpty) {
          return const Center(
              child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Tous les podcasts de ce thème sont dans vos abonnements !',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            ),
          ));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: podcasts.length,
          itemBuilder: (context, index) {
            final podcast = podcasts[index];
            return Card(
              color: AppTheme.surfaceColor,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: podcast.artworkUrl.isNotEmpty
                      ? Image.network(podcast.artworkUrl,
                          width: 60, height: 60, fit: BoxFit.cover)
                      : Container(
                          width: 60,
                          height: 60,
                          color: AppTheme.bgColor,
                          child: const Icon(Icons.podcasts,
                              color: AppTheme.textSecondary)),
                ),
                title: Text(podcast.collectionName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                subtitle: Text(podcast.artistName,
                    style: const TextStyle(color: AppTheme.textSecondary),
                    maxLines: 1),
                trailing: const Icon(Icons.chevron_right,
                    color: AppTheme.primaryColor),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            PodcastDetailsScreen(podcast: podcast.toMap()))),
              ),
            );
          },
        );
      },
    );
  }
}
