import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/settings_page_service.dart';
import '../core/services/service_locator.dart';
import '../services/app_state_notifier.dart';
import '../services/podcast_cache_manager.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsPageService service;

  SettingsScreen({
    super.key,
    SettingsPageService? service,
  }) : service = service ?? locator<SettingsPageService>();

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.service.refresh();
    });
    AppStateNotifier().addListener(_onCacheUpdateSignal);
    locator<PodcastCacheManager>().addListener(_onCacheUpdateSignal);
  }

  @override
  void dispose() {
    AppStateNotifier().removeListener(_onCacheUpdateSignal);
    locator<PodcastCacheManager>().removeListener(_onCacheUpdateSignal);
    super.dispose();
  }

  void _onCacheUpdateSignal() {
    if (mounted) {
      widget.service.refresh();
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isSigningOut = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', false);
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger != null) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la déconnexion : $e'),
              backgroundColor: AppTheme.dangerColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmClearCache(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text('Confirmer le vidage'),
          content: const Text(
              'Êtes-vous sûr de vouloir vider le cache ? Cela supprimera tous les fichiers audio téléchargés, ainsi que la liste d\'affinités.'),
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
      await widget.service.clearAllCache();
      if (mounted) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger != null) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Cache vidé avec succès.'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
        }
      }
    }
  }

  Widget _buildStorageSection() {
    final totalBytes = widget.service.cacheStats.totalBytes;
    final count = widget.service.cacheStats.count;

    final double totalMb = totalBytes / (1024 * 1024);
    final double maxMb = widget.service.maxLimit / (1024 * 1024);
    final int percent = widget.service.maxLimit > 0
        ? ((totalBytes / widget.service.maxLimit) * 100).round()
        : 0;

    final isCacheStatsLoading = widget.service.isCacheStatsLoading;
    final storageBreakdown = widget.service.storageBreakdown;

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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    isCacheStatsLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryColor),
                            ),
                          )
                        : Text(
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
                  value: isCacheStatsLoading
                      ? null
                      : (widget.service.maxLimit > 0
                          ? (totalBytes / widget.service.maxLimit)
                              .clamp(0.0, 1.0)
                          : 0.0),
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor),
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                isCacheStatsLoading
                    ? const Text(
                        'Calcul de l\'utilisation...',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                      )
                    : Text(
                        '${totalMb.toStringAsFixed(1)} Mo utilisés sur ${maxMb.toStringAsFixed(0)} Mo configurés ($count épisodes)',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                if (!isCacheStatsLoading && storageBreakdown.isNotEmpty) ...[
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
                    itemCount: storageBreakdown.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: Colors.white10),
                    itemBuilder: (context, index) {
                      final item = storageBreakdown[index];
                      final name = item['podcastName'] as String? ?? 'Inconnu';
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
                                  errorBuilder: (context, _, __) => Container(
                                    width: 40,
                                    height: 40,
                                    color: Colors.white10,
                                    child: const Icon(Icons.podcasts, size: 20),
                                  ),
                                )
                              : Container(
                                  width: 40,
                                  height: 40,
                                  color: Colors.white10,
                                  child: const Icon(Icons.podcasts, size: 20),
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
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: isCacheStatsLoading
                        ? null
                        : () => _confirmClearCache(context),
                    icon:
                        const Icon(Icons.delete_sweep, color: Colors.redAccent),
                    label: const Text(
                      'Vide le cache',
                      style: TextStyle(
                          color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.1),
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
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.service,
      builder: (context, _) {
        final isLoading = widget.service.isLoading || _isSigningOut;
        final language = widget.service.language;
        final order = widget.service.order;
        final downloadPolicy = widget.service.downloadPolicy;
        final appVersion = widget.service.appVersion;

        if (isLoading && widget.service.appVersion.isEmpty) {
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
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.language,
                          color: AppTheme.textPrimary),
                      title: const Text('Langue des podcasts'),
                      trailing: DropdownButton<String>(
                        value: language,
                        dropdownColor: AppTheme.surfaceColor,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Toutes')),
                          DropdownMenuItem(
                              value: 'fr', child: Text('Français')),
                          DropdownMenuItem(value: 'en', child: Text('Anglais')),
                          DropdownMenuItem(
                              value: 'es', child: Text('Espagnol')),
                          DropdownMenuItem(
                              value: 'de', child: Text('Allemand')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            widget.service.saveSettings('podstream_lang', val);
                          }
                        },
                      ),
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    ListTile(
                      leading:
                          const Icon(Icons.sort, color: AppTheme.textPrimary),
                      title: const Text('Ordre des épisodes'),
                      trailing: DropdownButton<String>(
                        value: order,
                        dropdownColor: AppTheme.surfaceColor,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(
                              value: 'desc',
                              child: Text('Plus récent d\'abord')),
                          DropdownMenuItem(
                              value: 'asc',
                              child: Text('Plus ancien d\'abord')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            widget.service.saveSettings('podstream_order', val);
                          }
                        },
                      ),
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    ListTile(
                      leading: const Icon(Icons.download,
                          color: AppTheme.textPrimary),
                      title: const Text('Autorisation de téléchargement'),
                      trailing: DropdownButton<String>(
                        value: downloadPolicy,
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
                            widget.service.saveDownloadPolicy(val);
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
                  'Version $appVersion',
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
      },
    );
  }
}
