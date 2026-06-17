import 'package:flutter/material.dart';
import '../../services/theme_tab_service.dart';
import '../../core/services/service_locator.dart';
import '../../theme/app_theme.dart';
import '../podcast_details_screen.dart';
import '../../services/audio_service.dart' as app_audio;

class ThemesTab extends StatelessWidget {
  /// Le service d'accès aux données par thème.
  ///
  /// Injecté via le constructeur pour permettre l'injection de dépendances (DI).
  /// Cela permet d'isoler le widget pour les tests unitaires en fournissant
  /// un service mocké (ex: `MockThemeTabService`).
  final ThemeTabService service;

  /// Crée un onglet de thèmes.
  ///
  /// Si [service] n'est pas fourni, une instance de [ThemeTabService]
  /// est récupérée depuis le locator.
  ThemesTab({
    super.key,
    ThemeTabService? service,
  }) : service = service ?? locator<ThemeTabService>();

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
          // Contenu correspondant à chaque onglet.
          // On résout une instance distincte de ThemeTabService pour chaque onglet.
          Expanded(
            child: TabBarView(
              children: categories
                  .map((cat) => ThemeResultsView(
                      theme: cat, service: locator<ThemeTabService>()))
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

  /// Le service d'accès aux données par thème.
  ///
  /// Injecté pour permettre de tester la vue indépendamment de la source de données réelle.
  final ThemeTabService service;

  /// Crée une vue affichant les podcasts d'un thème spécifique.
  ///
  /// Si [service] n'est pas fourni, utilise [ThemeTabService] résolu par le locator.
  ThemeResultsView({
    super.key,
    required this.theme,
    ThemeTabService? service,
  }) : service = service ?? locator<ThemeTabService>();

  @override
  State<ThemeResultsView> createState() => _ThemeResultsViewState();
}

class _ThemeResultsViewState extends State<ThemeResultsView>
    with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();
    widget.service.theme = widget.theme;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.service.refresh();
    });
    app_audio.AudioService().listRefreshNotifier.addListener(_onListRefresh);
  }

  @override
  void dispose() {
    app_audio.AudioService().listRefreshNotifier.removeListener(_onListRefresh);
    super.dispose();
  }

  void _onListRefresh() {
    if (mounted) {
      widget.service.refresh();
    }
  }

  Future<void> _loadData() async {
    await widget.service.refresh();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Indispensable pour AutomaticKeepAliveClientMixin

    return ListenableBuilder(
      listenable: widget.service,
      builder: (context, _) {
        final isLoading = widget.service.isLoading;
        final errorMessage = widget.service.errorMessage;
        final podcasts = widget.service.podcasts;

        if (isLoading) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor));
        }

        if (errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  errorMessage,
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
