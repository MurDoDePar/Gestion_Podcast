import 'package:flutter/material.dart';
import '../../models/podcast_model.dart';
import '../../services/database_repository.dart';
import '../../theme/app_theme.dart';
import '../podcast_details_screen.dart';

class ThemesTab extends StatelessWidget {
  /// Le repository d'accès aux données.
  ///
  /// Injecté via le constructeur pour permettre l'injection de dépendances (DI).
  /// Cela permet d'isoler le widget pour les tests unitaires en fournissant
  /// un repository mocké (ex: `MockDatabaseRepository`) plutôt qu'une instance réelle SQLite/Firebase.
  final DatabaseRepository repository;

  /// Crée un onglet de thèmes.
  ///
  /// Si [repository] n'est pas fourni, une instance par défaut de [DatabaseRepository]
  /// sera utilisée.
  ThemesTab({
    super.key,
    DatabaseRepository? repository,
  }) : repository = repository ?? DatabaseRepository();

  static const List<String> categories = [
    'Humour',
    'Culture',
    'Technologie',
    'Histoire',
    'Santé',
    'Sciences',
    'Sport',
    'Actualités',
    'Populaire',
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
                  .map((cat) =>
                      ThemeResultsView(theme: cat, repository: repository))
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

  /// Le repository d'accès aux données.
  ///
  /// Injecté pour permettre de tester la vue indépendamment de la source de données réelle.
  final DatabaseRepository repository;

  /// Crée une vue affichant les podcasts d'un thème spécifique.
  ///
  /// Si [repository] n'est pas fourni, utilise [DatabaseRepository] par défaut.
  ThemeResultsView({
    super.key,
    required this.theme,
    DatabaseRepository? repository,
  }) : repository = repository ?? DatabaseRepository();

  @override
  State<ThemeResultsView> createState() => _ThemeResultsViewState();
}

class _ThemeResultsViewState extends State<ThemeResultsView>
    with AutomaticKeepAliveClientMixin {
  List<PodcastModel>? _podcasts;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        widget.repository.getPodcastsByThemeWithCache(widget.theme),
        widget.repository.getSubscribedPodcastIds(),
      ]);

      if (mounted) {
        setState(() {
          final allPodcasts = results[0] as List<PodcastModel>;
          final subscribedIds = results[1] as Set<String>;

          // Filtrer les podcasts déjà abonnés
          _podcasts = allPodcasts
              .where((p) => !subscribedIds.contains(p.feedUrl))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Erreur lors du chargement des podcasts de ${widget.theme}.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Indispensable pour AutomaticKeepAliveClientMixin

    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }

    if (_errorMessage != null || _podcasts == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage ?? 'Une erreur est survenue.',
              style: const TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Réessayer',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final podcasts = _podcasts!;

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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            trailing:
                const Icon(Icons.chevron_right, color: AppTheme.primaryColor),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        PodcastDetailsScreen(podcast: podcast.toMap()))),
          ),
        );
      },
    );
  }
}
