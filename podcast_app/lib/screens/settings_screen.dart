import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../theme/app_theme.dart';
import '../services/database_repository.dart';
import '../services/download_manager.dart';
import '../services/database_helper.dart';
import '../models/app_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _language = 'fr';
  String _order = 'asc';
  String _downloadPolicy = 'always';
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
    final downloadPolicy =
        await DatabaseRepository().getDownloadNetworkPolicy();

    setState(() {
      _language = prefs.getString('podstream_lang') ?? 'fr';
      _order = prefs.getString('podstream_order') ?? 'asc';
      _downloadPolicy = downloadPolicy;
      _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _saveDownloadPolicy(String value) async {
    await DatabaseRepository().setDownloadNetworkPolicy(value);
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', false);
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
//       debugPrint('Erreur de déconnexion : $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion : $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _getStorageData() async {
    final repo = DatabaseRepository();
    final stats = await repo.getCachedEpisodesStats();
    final maxLimit = await AppSettings.getMaxCacheSize();
    final breakdown = await repo.getStorageBreakdownPerPodcast();
    return {
      'stats': stats,
      'maxLimit': maxLimit,
      'breakdown': breakdown,
    };
  }

  Future<void> _confirmClearCache(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text('Confirmer le vidage'),
          content: const Text(
              'Êtes-vous sûr de vouloir supprimer tous les fichiers audio téléchargés ? Les épisodes devront être retéléchargés pour une écoute hors-ligne.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler',
                  style: TextStyle(color: AppTheme.textSecondary)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Vider',
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });
      await DownloadManager().clearAllCache();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache vidé avec succès.'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    }
  }

  Future<void> _forceResetRecommendations(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final helper = DatabaseHelper();
      final db = await helper.database;
      await db.delete('recommended_podcasts');

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_recommended_language');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Cache des recommandations réinitialisé avec succès !'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildStorageSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getStorageData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;
        final stats = data['stats'] as Map<String, dynamic>;
        final maxLimit = data['maxLimit'] as int;
        final breakdown = data['breakdown'] as List<Map<String, dynamic>>;

        final totalBytes = stats['totalBytes'] as int? ?? 0;
        final count = stats['count'] as int? ?? 0;

        final double totalMb = totalBytes / (1024 * 1024);
        final double maxMb = maxLimit / (1024 * 1024);
        final int percent =
            maxLimit > 0 ? ((totalBytes / maxLimit) * 100).round() : 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gestion du Stockage',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 16),
            Card(
              color: AppTheme.surfaceColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Utilisation du cache',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        Text(
                          '$percent%',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.primaryColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: maxLimit > 0
                          ? (totalBytes / maxLimit).clamp(0.0, 1.0)
                          : 0.0,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${totalMb.toStringAsFixed(1)} Mo utilisés sur ${maxMb.toStringAsFixed(0)} Mo configurés ($count épisodes)',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    if (breakdown.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Détail par podcast',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: breakdown.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, color: Colors.white10),
                        itemBuilder: (context, index) {
                          final item = breakdown[index];
                          final name =
                              item['podcastName'] as String? ?? 'Inconnu';
                          final sizeBytes = item['totalSize'] as int? ?? 0;
                          final sizeMb = sizeBytes / (1024 * 1024);
                          final artworkUrl = item['artworkUrl'] as String?;
                          final epCount = item['episodeCount'] as int? ?? 0;

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: artworkUrl != null && artworkUrl.isNotEmpty
                                  ? Image.network(
                                      artworkUrl,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, _, __) =>
                                          Container(
                                        width: 40,
                                        height: 40,
                                        color: Colors.white10,
                                        child: const Icon(Icons.podcasts,
                                            size: 20),
                                      ),
                                    )
                                  : Container(
                                      width: 40,
                                      height: 40,
                                      color: Colors.white10,
                                      child:
                                          const Icon(Icons.podcasts, size: 20),
                                    ),
                            ),
                            title: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: Text(
                              '$epCount épisode(s)',
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12),
                            ),
                            trailing: Text(
                              '${sizeMb.toStringAsFixed(1)} Mo',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () => _confirmClearCache(context),
                        icon: const Icon(Icons.delete_sweep,
                            color: Colors.redAccent),
                        label: const Text(
                          'Vider le cache manuellement',
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red.withValues(alpha: 0.1),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () => _forceResetRecommendations(context),
                        icon: const Icon(Icons.refresh,
                            color: AppTheme.primaryColor),
                        label: const Text(
                          'Forcer la réinitialisation des recommandations',
                          style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor:
                              AppTheme.primaryColor.withValues(alpha: 0.1),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final user = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (user != null) ...[
            // Profil
            Card(
              color: AppTheme.surfaceColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: user.photoURL != null
                          ? NetworkImage(user.photoURL!)
                          : null,
                      child: user.photoURL == null
                          ? const Icon(Icons.person)
                          : null,
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
                              style: const TextStyle(
                                  color: AppTheme.textSecondary)),
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
                const Divider(height: 1, color: Colors.white10),
                ListTile(
                  leading:
                      const Icon(Icons.download, color: AppTheme.textPrimary),
                  title: const Text('Autorisation de téléchargement'),
                  trailing: DropdownButton<String>(
                    value: _downloadPolicy,
                    dropdownColor: AppTheme.surfaceColor,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                          value: 'wifiOnly',
                          child: Text('Uniquement en Wi-Fi')),
                      DropdownMenuItem(
                          value: 'always', child: Text('Tout le temps')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _downloadPolicy = val;
                        });
                        _saveDownloadPolicy(val);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _buildStorageSection(),
          const SizedBox(height: 32),

          // Déconnexion
          ElevatedButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            label: const Text('Se déconnecter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withValues(alpha: 0.2),
              foregroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
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
      ),
    );
  }
}
