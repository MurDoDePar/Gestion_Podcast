import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import 'home/home_screen.dart';
import 'settings_screen.dart';
import 'search_screen.dart';
import '../widgets/audio_player_widget.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.podcasts, color: AppTheme.primaryColor, size: 28),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppTheme.primaryGradient.createShader(bounds),
              child: const Text(
                'PodStream',
                style: TextStyle(
                    color: Colors.white), // Blanc nécessaire pour le ShaderMask
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _screens[_currentIndex]),
          const AudioPlayerWidget(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            label: 'Recherche',
          ),
          BottomNavigationBarItem(
            icon: user?.photoURL != null
                ? CircleAvatar(
                    radius: 12,
                    backgroundImage: NetworkImage(user!.photoURL!),
                  )
                : const Icon(Icons.settings_rounded),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }
}
