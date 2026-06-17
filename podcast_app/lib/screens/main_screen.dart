import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/mini_player.dart';
import '../services/database_repository.dart';
import 'tabs/my_podcasts_tab.dart';
import 'tabs/themes_tab.dart';
import 'tabs/discover_tab.dart';
import 'tabs/history_tab.dart';
import 'tabs/search_tab.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String?
      _updateRequiredMessage; // Stocke le message d'erreur si la version est obsolète

  final List<Widget> _screens = [
    const _AccueilView(),
    SearchTab(),
    SettingsScreen(),
  ];

  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initApp();
  }

  Future<void> _initApp() async {
    // Initialisation de la base SQLite et retry sous timeout de 10 secondes
    try {
      await DatabaseRepository().init().timeout(
            const Duration(seconds: 10),
            onTimeout: () {},
          );
    } on UpdateRequiredException catch (e) {
      setState(() {
        _updateRequiredMessage = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si une mise à jour est requise, afficher un écran de blocage premium et élégant
    if (_updateRequiredMessage != null) {
      return Scaffold(
        backgroundColor: AppTheme.bgColor,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icone avec cercle dégradé pour un look très premium
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.primaryGradient,
                    ),
                    child: const Icon(
                      Icons.system_update_alt_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Mise à jour obligatoire',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _updateRequiredMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Bouton avec gradient premium
                  InkWell(
                    onTap: () {
                      // Optionnel : ajouter de l'analytics ou un lancement de store ici
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 40,
                        ),
                        child: const Text(
                          'Mettre à jour maintenant',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      // Option de secours : relancer la vérification
                      setState(() {
                        _updateRequiredMessage = null;
                        _initFuture = _initApp();
                      });
                    },
                    child: const Text(
                      'Réessayer la connexion',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.bgColor,
            body: Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ),
          );
        }

        final user = FirebaseAuth.instance.currentUser;

        return Scaffold(
          backgroundColor: AppTheme.bgColor,
          body: Column(
            children: [
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: _screens,
                ),
              ),
              // Espace réservé pour le mini-lecteur violet
              const MiniPlayer(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppTheme.surfaceColor,
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: AppTheme.textSecondary,
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Accueil',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Recherche',
              ),
              BottomNavigationBarItem(
                icon: user?.photoURL != null
                    ? CircleAvatar(
                        radius: 12,
                        backgroundImage: NetworkImage(user!.photoURL!),
                      )
                    : const Icon(Icons.settings),
                activeIcon: user?.photoURL != null
                    ? Container(
                        padding: const EdgeInsets.all(1.5),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 11,
                          backgroundImage: NetworkImage(user!.photoURL!),
                        ),
                      )
                    : const Icon(Icons.settings),
                label: 'Paramètres',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AccueilView extends StatelessWidget {
  const _AccueilView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DefaultTabController(
        length: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo/texte "PodStream" avec un dégradé violet/rose en haut à gauche
            Padding(
              padding:
                  const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
              child: ShaderMask(
                shaderCallback: (bounds) =>
                    AppTheme.primaryGradient.createShader(
                  Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                ),
                child: const Text(
                  'PodStream',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // TabBar sous forme de pilules
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TabBar(
                isScrollable: true,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: AppTheme.primaryGradient,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                tabs: const [
                  Tab(text: "Mes podcasts"),
                  Tab(text: "Par thème"),
                  Tab(text: "Affinités"),
                  Tab(text: "Historique"),
                ],
              ),
            ),
            // Contenu
            Expanded(
              child: TabBarView(
                children: [
                  MyPodcastsTab(),
                  ThemesTab(),
                  DiscoverTab(),
                  HistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
