import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _language = 'fr';
  String _order = 'asc';
  bool _isLoading = true;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final packageInfo = await PackageInfo.fromPlatform();

    setState(() {
      _language = prefs.getString('podstream_lang') ?? 'fr';
      _order = prefs.getString('podstream_order') ?? 'asc';
      _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _shareLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logFile1 = File('${directory.path}/logs_android_auto.txt');
      if (await logFile1.exists()) {
        await Share.shareXFiles([XFile(logFile1.path)],
            text: 'Logs Android Auto');
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun log enregistré pour le moment')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du partage : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final user = FirebaseAuth.instance.currentUser;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (user != null) ...[
          // Profil
          Card(
            color: AppTheme.surfaceColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : null,
                    child:
                        user.photoURL == null ? const Icon(Icons.person) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.displayName ?? 'Utilisateur',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(user.email ?? '',
                            style:
                                const TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Préférences
        const Text(
          'Préférences d\'écoute',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor),
        ),
        const SizedBox(height: 16),

        Card(
          color: AppTheme.surfaceColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              ListTile(
                leading:
                    const Icon(Icons.language, color: AppTheme.textPrimary),
                title: const Text('Langue des podcasts'),
                trailing: DropdownButton<String>(
                  value: _language,
                  dropdownColor: AppTheme.surfaceColor,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Toutes')),
                    DropdownMenuItem(value: 'fr', child: Text('Français')),
                    DropdownMenuItem(value: 'en', child: Text('Anglais')),
                    DropdownMenuItem(value: 'es', child: Text('Espagnol')),
                    DropdownMenuItem(value: 'de', child: Text('Allemand')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _language = val;
                      });
                      _saveSettings('podstream_lang', val);
                    }
                  },
                ),
              ),
              const Divider(height: 1, color: Colors.white10),
              ListTile(
                leading: const Icon(Icons.sort, color: AppTheme.textPrimary),
                title: const Text('Ordre des épisodes'),
                trailing: DropdownButton<String>(
                  value: _order,
                  dropdownColor: AppTheme.surfaceColor,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                        value: 'desc', child: Text('Plus récent d\'abord')),
                    DropdownMenuItem(
                        value: 'asc', child: Text('Plus ancien d\'abord')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _order = val;
                      });
                      _saveSettings('podstream_order', val);
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Déconnexion
        ElevatedButton.icon(
          onPressed: _signOut,
          icon: const Icon(Icons.logout),
          label: const Text('Se déconnecter'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.withOpacity(0.2),
            foregroundColor: Colors.redAccent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),

        const SizedBox(height: 24),

        // Partager les logs
        ElevatedButton.icon(
          onPressed: _shareLogs,
          icon: const Icon(Icons.share),
          label: const Text('Partager les Logs AA'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.surfaceColor,
            foregroundColor: AppTheme.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),

        const SizedBox(height: 24),

        // Version de l'application
        Center(
          child: Text(
            'Version $_appVersion',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
