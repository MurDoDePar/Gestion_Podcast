import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/mini_player.dart';
import 'tabs/my_podcasts_tab.dart';
import 'tabs/themes_tab.dart';
import 'tabs/popular_tab.dart';
import 'tabs/discover_tab.dart';
import 'tabs/search_tab.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _AccueilView(),
    SearchTab(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
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
                  Tab(text: "Populaires"),
                  Tab(text: "Affinités"),
                ],
              ),
            ),
            // Contenu
            const Expanded(
              child: TabBarView(
                children: [
                  MyPodcastsTab(),
                  ThemesTab(),
                  PopularTab(),
                  DiscoverTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
