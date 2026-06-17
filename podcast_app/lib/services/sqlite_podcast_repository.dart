import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import 'download_manager.dart';
import '../models/podcast_model.dart';
import '../models/episode_model.dart';
import 'database_repository.dart'; // Pour la compatibilité des types et la structure de CacheStats/DownloadTask

/// Dépôt de données SQLite local pour l'application PodStream.
///
/// Cette classe centralise toutes les opérations d'accès et d'écriture à la base de données
/// locale sqflite de l'appareil (abonnements aux podcasts, métadonnées, état de lecture, cache thématique, etc.).
/// Les dépendances sont injectées via le constructeur.
class SqlitePodcastRepository {
  final DatabaseHelper _dbHelper;
  Map<String, dynamic>? _cachedStats;
  int _cachedStatsTime = 0;

  /// Initialise le dépôt SQLite avec un helper de base de données.
  SqlitePodcastRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  /// Récupère la liste des podcasts auxquels l'utilisateur est abonné localement.
  ///
  /// **Utilité** : Fournit la liste des abonnements triée par l'ordre défini par l'utilisateur.
  /// **Point d'entrée** : Appelé à l'initialisation de l'onglet "Mes podcasts" (`MyPodcastsTab`).
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si la table `my_podcasts` ou ses colonnes changent.
  Future<List<PodcastModel>> getSubscribedPodcasts() async {
    return await _dbHelper.getSubscribedPodcasts();
  }

  /// Récupère la catégorie/genre principal d'un podcast via son identifiant (UUID ou ID iTunes).
  ///
  /// **Utilité** : Extrait le genre principal d'un podcast localement pour cibler les recommandations.
  /// **Point d'entrée** : Appelé lors du calcul des recommandations dans `DiscoveryTabService`.
  /// **Maintenance** : Si le format de stockage des genres évolue (ex: table de jointure dédiée), modifier ici.
  Future<String?> getPodcastCategory(String podcastId) async {
    try {
      final db = await _dbHelper.database;
      List<Map<String, dynamic>> maps = await db.query(
        'my_podcasts',
        columns: ['genres'],
        where: 'id = ?',
        whereArgs: [podcastId],
      );

      if (maps.isEmpty) {
        final intId = int.tryParse(podcastId);
        if (intId != null) {
          maps = await db.query(
            'my_podcasts',
            columns: ['genres'],
            where: 'collectionId = ?',
            whereArgs: [intId],
          );
        }
      }

      if (maps.isEmpty) return null;

      final String genresRaw = maps.first['genres'] as String? ?? '';
      print(
          '[DEBUG_TAGS] Podcast ID : $podcastId | Données genres brutes : $genresRaw');
      if (genresRaw.trim().isEmpty) return null;

      List<String> parsedGenres = [];
      final trimmedRaw = genresRaw.trim();
      if (trimmedRaw.startsWith('[') && trimmedRaw.endsWith(']')) {
        try {
          final decoded = jsonDecode(trimmedRaw);
          if (decoded is List) {
            parsedGenres = decoded.map((g) => g.toString().trim()).toList();
          }
        } catch (_) {}
      }

      if (parsedGenres.isEmpty) {
        parsedGenres = trimmedRaw.split(',').map((g) => g.trim()).toList();
      }

      // Filtrer les chaînes vides
      parsedGenres = parsedGenres.where((g) => g.isNotEmpty).toList();
      print('[DEBUG_TAGS] Liste des catégories identifiées : $parsedGenres');

      // Retourner le premier genre qui n'est pas dans la liste noire
      final blacklist = {
        'news',
        'daily',
        'general',
        'général',
        'actualités',
        'actualité',
        'podcasts',
        'podcast',
        'arts',
        'art'
      };
      for (final genre in parsedGenres) {
        if (!blacklist.contains(genre.toLowerCase())) {
          return genre;
        } else {
          print('[DEBUG_TAGS] Catégorie ignorée (Blacklist) : $genre');
        }
      }

      // Si tous sont dans la blacklist, on retourne le premier disponible (ou null)
      return parsedGenres.isNotEmpty ? parsedGenres.first : null;
    } catch (_) {
      return null;
    }
  }

  /// Met à jour les catégories/genres d'un podcast localement dans SQLite.
  ///
  /// **Utilité** : Permet de corriger ou de mettre à jour rétroactivement les genres d'un podcast.
  /// **Point d'entrée** : Appelé lors de la réparation/auto-correction des genres dans `DiscoveryTabService`.
  /// **Maintenance** : Si la table `my_podcasts` ou le format des genres change, adapter ici.
  Future<void> updatePodcastGenres(String id, List<String> genres) async {
    try {
      final db = await _dbHelper.database;
      await db.update(
        'my_podcasts',
        {'genres': genres.join(',')},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (_) {
      // Ignorer silencieusement
    }
  }

  /// Insère ou met à jour un podcast abonné dans la base SQLite locale.
  ///
  /// **Utilité** : Enregistre l'abonnement à un podcast avec son ordre de tri et son statut de synchronisation.
  /// **Point d'entrée** : Appelé lors du clic sur le bouton s'abonner (`subscribeToPodcast`).
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si le modèle de données de `PodcastModel` gagne de nouveaux attributs persistants (ex: catégorie, favori).
  Future<int> insertPodcast(PodcastModel podcast, int sortOrder,
      {int isSynced = 1}) async {
    return await _dbHelper.insertPodcast(podcast, sortOrder,
        isSynced: isSynced);
  }

  /// Supprime un podcast abonné de la base SQLite locale via son flux RSS.
  ///
  /// **Utilité** : Désabonne l'utilisateur d'un podcast au niveau local.
  /// **Point d'entrée** : Appelé lors du clic sur le bouton se désabonner (`unsubscribeFromPodcast`).
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si la clé de désabonnement change de `feedUrl` à `collectionId`.
  Future<int> deletePodcast(String feedUrl) async {
    return await _dbHelper.deletePodcast(feedUrl);
  }

  /// Met à jour en bloc l'ordre de tri des abonnements dans SQLite.
  ///
  /// **Utilité** : Assure la persistance de la réorganisation des podcasts effectuée par l'utilisateur par drag-and-drop.
  /// **Point d'entrée** : Appelé lors du déplacement d'une tuile de podcast dans l'onglet "Mes podcasts".
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si le comportement transactionnel doit être ajusté pour gérer des volumes massifs d'abonnements.
  Future<void> updatePodcastsSortOrder(
      List<Map<String, dynamic>> orderUpdates) async {
    await _dbHelper.updatePodcastsSortOrder(orderUpdates);
  }

  /// Met à jour le statut de synchronisation Firebase d'un podcast local.
  ///
  /// **Utilité** : Marque un abonnement local comme synchronisé (ou non) avec le cloud.
  /// **Point d'entrée** : Appelé après qu'un abonnement a été sauvegardé sur Firebase.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si le flag `isSynced` change de type en BDD (ex: booléen ou entier).
  Future<void> setPodcastSyncStatus(String feedUrl, int isSynced) async {
    await _dbHelper.setPodcastSyncStatus(feedUrl, isSynced);
  }

  /// Récupère tous les abonnements locaux non encore synchronisés avec Firebase (isSynced = 0).
  ///
  /// **Utilité** : Identifie les abonnements en attente de synchronisation pour les envoyer vers le cloud en arrière-plan.
  /// **Point d'entrée** : Appelé lors de la tâche de resynchronisation périodique/au démarrage (`retryUnsyncedOrders`).
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si le filtre de sélection `isSynced = 0` doit intégrer des règles additionnelles.
  Future<List<Map<String, dynamic>>> getUnsyncedPodcasts() async {
    return await _dbHelper.getUnsyncedPodcasts();
  }

  /// Marque un épisode comme lu localement et enregistre ses métadonnées.
  ///
  /// **Utilité** : Modifie l'état de lecture d'un épisode à "lu" et copie ses infos dans `episodes_metadata`.
  /// **Point d'entrée** : Appelé à la fin de la lecture audio d'un épisode ou via l'option de marquage comme lu dans l'UI.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si les tables `episodes_status` ou `episodes_metadata` voient leur structure évoluer.
  Future<void> markEpisodeAsRead(
    String episodeId, {
    String? title,
    String? audioUrl,
    String? imageUrl,
    String? podcastName,
    String? pubDate,
    String? description,
  }) async {
    await _dbHelper.markEpisodeAsRead(
      episodeId,
      title: title,
      audioUrl: audioUrl,
      imageUrl: imageUrl,
      podcastName: podcastName,
      pubDate: pubDate,
      description: description,
    );
  }

  /// Vérifie si un épisode a été marqué comme lu localement.
  ///
  /// **Utilité** : Permet de filtrer à la volée les épisodes déjà lus dans les flux RSS.
  /// **Point d'entrée** : Appelé lors de la récupération et du filtrage de la liste "À écouter" (`getEpisodesToListen`).
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si la requête de sélection SQL ou la valeur par défaut change.
  Future<bool> isEpisodeRead(String episodeId) async {
    return await _dbHelper.isEpisodeRead(episodeId);
  }

  /// Récupère la liste de tous les IDs d'épisodes marqués comme lus en local.
  ///
  /// **Utilité** : Fournit un ensemble d'identifiants uniques pour filtrer instantanément les listes de lecture.
  /// **Point d'entrée** : Appelé lors de la ré-agrégation d'épisodes et du filtrage hors-ligne.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si le stockage de l'ID d'épisode évolue (ex: hachage MD5 ou UUID).
  Future<List<String>> getReadEpisodeIds() async {
    return await _dbHelper.getReadEpisodeIds();
  }

  /// Enregistre les métadonnées d'un lot d'épisodes dans la table episodes_metadata.
  ///
  /// **Utilité** : Sauvegarde les titres, descriptions et URLs des épisodes fraîchement lus ou téléchargés pour une consultation hors-ligne stable.
  /// **Point d'entrée** : Appelé lors de l'analyse du flux RSS d'un podcast.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si des colonnes de métadonnées sont ajoutées ou supprimées.
  Future<void> insertEpisodesMetadata(List<EpisodeModel> episodes) async {
    await _dbHelper.insertEpisodesMetadata(episodes);
  }

  /// Récupère la politique réseau des téléchargements (Wi-Fi uniquement ou Mobile autorisés).
  ///
  /// **Utilité** : Fournit le paramètre de politique de téléchargement stocké dans SQLite.
  /// **Point d'entrée** : Appelé par le `DownloadManager` avant de démarrer un téléchargement.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si la clé de réglage `download_network_policy` change de nom.
  Future<String> getDownloadNetworkPolicy() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: ['download_network_policy'],
      );
      if (maps.isEmpty) return 'always';
      return maps.first['value'] as String? ?? 'always';
    } catch (e) {
      return 'always';
    }
  }

  /// Enregistre la politique réseau pour les téléchargements.
  ///
  /// **Utilité** : Persiste le choix de l'utilisateur dans SQLite.
  /// **Point d'entrée** : Appelé dans l'écran des réglages lors du changement de valeur de la politique réseau.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si un nouveau comportement de conflit doit être appliqué.
  Future<void> setDownloadNetworkPolicy(String policy) async {
    try {
      final db = await _dbHelper.database;
      await db.insert(
        'settings',
        {
          'key': 'download_network_policy',
          'value': policy,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {}
  }

  /// Enregistre ou met à jour le chemin local du fichier MP3 téléchargé pour un épisode.
  ///
  /// **Utilité** : Associe un fichier MP3 physique stocké sur l'appareil à son épisode dans SQLite.
  /// **Point d'entrée** : Appelé à la fin d'un téléchargement réussi ou lors de la suppression de cache.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si la logique de conversion de chemin absolu/relatif doit être modifiée (changement d'OS).
  Future<void> updateEpisodeLocalPath(String episodeId, String? localPath,
      {int fileSize = 0}) async {
    try {
      final db = await _dbHelper.database;
      final int status = localPath != null ? 1 : 0;

      String? relativePath;
      if (localPath != null) {
        final directory = await getApplicationDocumentsDirectory();
        final docDirPrefix = directory.path;
        if (localPath.startsWith(docDirPrefix)) {
          relativePath = localPath.substring(docDirPrefix.length);
          if (relativePath.startsWith('/') || relativePath.startsWith('\\')) {
            relativePath = relativePath.substring(1);
          }
        } else {
          relativePath = localPath;
        }
      }

      final List<Map<String, dynamic>> existing = await db.query(
        'episodes_status',
        where: 'episodeId = ?',
        whereArgs: [episodeId],
      );
      if (existing.isNotEmpty) {
        await db.update(
          'episodes_status',
          {
            'localPath': relativePath,
            'status': status,
            'fileSize': fileSize,
          },
          where: 'episodeId = ?',
          whereArgs: [episodeId],
        );
      } else {
        await db.insert(
          'episodes_status',
          {
            'episodeId': episodeId,
            'localPath': relativePath,
            'isRead': 0,
            'readAt': null,
            'status': status,
            'fileSize': fileSize,
          },
        );
      }
    } catch (e) {}
  }

  /// Met à jour uniquement le statut de téléchargement d'un épisode.
  ///
  /// **Utilité** : Indique si le fichier est en cours, téléchargé ou en erreur.
  /// **Point d'entrée** : Appelé par le `DownloadManager` pendant le cycle de vie du téléchargement.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si la table `episodes_status` change.
  Future<void> updateEpisodeDownloadStatus(String episodeId, int status) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> existing = await db.query(
        'episodes_status',
        where: 'episodeId = ?',
        whereArgs: [episodeId],
      );
      if (existing.isNotEmpty) {
        await db.update(
          'episodes_status',
          {'status': status},
          where: 'episodeId = ?',
          whereArgs: [episodeId],
        );
      } else {
        await db.insert(
          'episodes_status',
          {
            'episodeId': episodeId,
            'isRead': 0,
            'readAt': null,
            'localPath': null,
            'status': status,
          },
        );
      }
    } catch (e) {}
  }

  /// Récupère le chemin local enregistré pour un épisode de podcast.
  ///
  /// **Utilité** : Permet au lecteur audio d'écouter le fichier MP3 hors-ligne au lieu de streamer.
  /// **Point d'entrée** : Appelé par le service audio (`AudioService`) lors du chargement de la piste.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si le stockage SQLite local est réorganisé.
  Future<String?> getEpisodeLocalPath(String episodeId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'episodes_status',
        columns: ['localPath'],
        where: 'episodeId = ?',
        whereArgs: [episodeId],
      );
      if (maps.isEmpty) return null;
      return maps.first['localPath'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Récupère la taille du fichier d'un épisode enregistré en base.
  ///
  /// **Utilité** : Permet d'obtenir la taille en octets enregistrée en base pour le calcul du cache.
  /// **Point d'entrée** : Appelé par le gestionnaire de cache (`PodcastCacheManager`).
  /// **Maintenance** : Si le schéma de la table `episodes_status` change, modifier ici.
  Future<int> getEpisodeFileSize(String episodeId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'episodes_status',
        columns: ['fileSize'],
        where: 'episodeId = ?',
        whereArgs: [episodeId],
      );
      if (maps.isEmpty) return 0;
      return maps.first['fileSize'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Récupère le statut de téléchargement d'un épisode.
  ///
  /// **Utilité** : Fournit le statut local pour adapter l'affichage du widget de téléchargement.
  /// **Point d'entrée** : Appelé par le widget d'épisode dans les listes.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si les valeurs d'énumération de statut changent.
  Future<int> getEpisodeDownloadStatus(String episodeId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'episodes_status',
        columns: ['status'],
        where: 'episodeId = ?',
        whereArgs: [episodeId],
      );
      if (maps.isEmpty) return 0;
      return maps.first['status'] as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Ajoute une tâche à la file de téléchargement persistante pour reprise sur crash.
  ///
  /// **Utilité** : Assure la résilience des téléchargements lors des fermetures intempestives.
  /// **Point d'entrée** : Appelé au moment de mettre en file d'attente un téléchargement.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si le schéma de `download_queue` change.
  Future<void> enqueueDownloadTask(
      String episodeId, String audioUrl, String tempPath) async {
    try {
      final db = await _dbHelper.database;
      await db.insert(
        'download_queue',
        {
          'episodeId': episodeId,
          'audioUrl': audioUrl,
          'tempPath': tempPath,
          'status': 'queued',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {}
  }

  /// Supprime une tâche de la file de téléchargement.
  ///
  /// **Utilité** : Nettoie la file de téléchargement à la fin (succès ou échec).
  /// **Point d'entrée** : Appelé par le `DownloadManager` pour finaliser une tâche.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si la table `download_queue` évolue.
  Future<void> dequeueDownloadTask(String episodeId) async {
    try {
      final db = await _dbHelper.database;
      await db.delete(
        'download_queue',
        where: 'episodeId = ?',
        whereArgs: [episodeId],
      );
    } catch (e) {}
  }

  /// Récupère toutes les tâches de téléchargement non terminées.
  ///
  /// **Utilité** : Permet au `DownloadManager` de relancer les téléchargements suspendus au démarrage.
  /// **Point d'entrée** : Appelé au démarrage du gestionnaire de téléchargement.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si la classe `DownloadTask` est renommée ou enrichie.
  Future<List<DownloadTask>> getDownloadQueueTasks() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query('download_queue');
      return maps
          .map((m) => DownloadTask(
                episodeId: m['episodeId'] as String,
                audioUrl: m['audioUrl'] as String,
                tempPath: m['tempPath'] as String,
                status: m['status'] as String,
              ))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Lit une valeur numérique de configuration dans la table settings.
  ///
  /// **Utilité** : Centralise le stockage de clés de configuration simples comme la limite du cache.
  /// **Point d'entrée** : Appelé par les réglages pour récupérer la taille du cache autorisée.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si la table `settings` change de schéma.
  Future<int> getSettingInt(String key, {required int defaultValue}) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: [key],
      );
      if (maps.isEmpty || maps.first['value'] == null) {
        return defaultValue;
      }
      return int.tryParse(maps.first['value'] as String) ?? defaultValue;
    } catch (_) {
      return defaultValue;
    }
  }

  /// Écrit une clé/valeur de configuration dans SQLite.
  ///
  /// **Utilité** : Persiste un réglage numérique ou textuel.
  /// **Point d'entrée** : Appelé lors de la modification des préférences de cache par l'utilisateur.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si la clé doit être cryptée ou typée différemment.
  Future<void> setSetting(String key, String value) async {
    try {
      final db = await _dbHelper.database;
      await db.insert(
        'settings',
        {
          'key': key,
          'value': value,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  /// Récupère la liste des épisodes lus dont la date de lecture dépasse la date limite de conservation.
  ///
  /// **Utilité** : Permet de nettoyer périodiquement les vieux fichiers MP3 lus du stockage local.
  /// **Point d'entrée** : Appelé par le planificateur de nettoyage de cache de `DownloadManager`.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si la condition de conservation doit être affinée.
  Future<List<EpisodeCacheInfo>> getOldReadEpisodes(int ageLimitEpoch) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'episodes_status',
        columns: ['episodeId', 'localPath', 'fileSize'],
        where: 'isRead = 1 AND readAt < ? AND localPath IS NOT NULL',
        whereArgs: [ageLimitEpoch],
      );
      return maps
          .map((m) => EpisodeCacheInfo(
                episodeId: m['episodeId'] as String,
                fileSize: m['fileSize'] as int? ?? 0,
                localPath: m['localPath'] as String?,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Récupère la liste de tous les chemins de fichiers téléchargés en cache local.
  ///
  /// **Utilité** : Utilisé pour l'audit de fichiers orphelins sur le stockage physique.
  /// **Point d'entrée** : Appelé lors de la ré-indexation du dossier de téléchargement.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si la structure d'indexation change.
  Future<Set<String>> getAllCachedLocalPaths() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> results = await db.query(
        'episodes_status',
        columns: ['localPath'],
        where: 'localPath IS NOT NULL',
      );
      return results
          .map((row) => row['localPath'] as String?)
          .where((path) => path != null && path.isNotEmpty)
          .cast<String>()
          .toSet();
    } catch (_) {
      return {};
    }
  }

  /// Récupère la liste de tous les chemins temporaires de téléchargements en cours.
  ///
  /// **Utilité** : Permet de ne pas supprimer accidentellement les téléchargements actifs lors d'un nettoyage.
  /// **Point d'entrée** : Appelé lors du nettoyage de printemps du stockage.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si la table `download_queue` change de schéma.
  Future<Set<String>> getAllQueuedTempPaths() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> results = await db.query(
        'download_queue',
        columns: ['tempPath'],
      );
      return results
          .map((row) => row['tempPath'] as String?)
          .where((path) => path != null && path.isNotEmpty)
          .cast<String>()
          .toSet();
    } catch (_) {
      return {};
    }
  }

  /// Récupère l'ensemble des métadonnées d'épisodes stockés localement en cache.
  ///
  /// **Utilité** : Permet d'analyser la taille et les chemins de tous les fichiers MP3 gérés.
  /// **Point d'entrée** : Appelé lors de l'exécution de tâches de synchronisation de cache.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si la table `episodes_status` change.
  Future<List<EpisodeCacheInfo>> getAllCachedEpisodes() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> results = await db.query(
        'episodes_status',
        columns: ['episodeId', 'localPath', 'fileSize'],
        where: 'localPath IS NOT NULL',
      );
      return results
          .map((m) => EpisodeCacheInfo(
                episodeId: m['episodeId'] as String,
                fileSize: m['fileSize'] as int? ?? 0,
                localPath: m['localPath'] as String?,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Nettoie en BDD un ensemble d'épisodes supprimés du cache local (Atomicité via transaction).
  ///
  /// **Utilité** : Met à jour plusieurs états locaux à la suite d'une purge de fichiers MP3 sur le disque.
  /// **Point d'entrée** : Appelé par le planificateur de cache ou le vidage manuel.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si d'autres tables doivent être modifiées lors de la suppression.
  Future<void> removeEpisodesFromCache(List<String> episodeIds) async {
    if (episodeIds.isEmpty) return;
    try {
      final db = await _dbHelper.database;
      await db.transaction((txn) async {
        for (var episodeId in episodeIds) {
          await txn.update(
            'episodes_status',
            {
              'localPath': null,
              'status': 0,
              'fileSize': 0,
            },
            where: 'episodeId = ?',
            whereArgs: [episodeId],
          );
        }
      });
    } catch (_) {}
  }

  /// Supprime un unique épisode du cache en BDD.
  ///
  /// **Utilité** : Dé-indexe un fichier MP3 unique de la base après suppression physique.
  /// **Point d'entrée** : Appelé lors de la suppression manuelle d'un épisode téléchargé.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si des actions additionnelles s'imposent.
  Future<void> removeEpisodeFromCache(String episodeId) async {
    await removeEpisodesFromCache([episodeId]);
  }

  /// Retourne la taille cumulée (en octets) de tous les fichiers en cache sur l'appareil.
  ///
  /// **Utilité** : Permet de calculer précisément la part occupée par PodStream sur le stockage.
  /// **Point d'entrée** : Appelé lors du calcul des statistiques pour l'écran des paramètres.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si la colonne `fileSize` change de nom ou de type.
  Future<int> getTotalCacheSize() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> result = await db.rawQuery('''
        SELECT SUM(fileSize) as totalSize 
        FROM episodes_status 
        WHERE localPath IS NOT NULL
      ''');
      if (result.isNotEmpty && result.first['totalSize'] != null) {
        return result.first['totalSize'] as int;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  /// Récupère la liste des épisodes en cache triée par date de publication (les plus anciens d'abord).
  ///
  /// **Utilité** : Identifie les épisodes à purger en premier selon le principe FIFO / date de sortie.
  /// **Point d'entrée** : Appelé lors du dépassement de la limite de cache de stockage.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si la jointure ou le critère de tri (ex: date de lecture) change.
  Future<List<EpisodeCacheInfo>> getCacheCandidates() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> candidates = await db.rawQuery('''
        SELECT s.episodeId, s.fileSize, s.localPath
        FROM episodes_status s
        LEFT JOIN episodes_metadata m ON s.episodeId = m.episodeId
        WHERE s.localPath IS NOT NULL
        ORDER BY m.pubDate ASC
      ''');
      return candidates
          .map((m) => EpisodeCacheInfo(
                episodeId: m['episodeId'] as String,
                fileSize: m['fileSize'] as int? ?? 0,
                localPath: m['localPath'] as String?,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Calcule l'utilisation du stockage par podcast.
  ///
  /// **Utilité** : Regroupe la consommation de cache par chaîne de podcast pour affichage détaillé.
  /// **Point d'entrée** : Appelé dans l'écran des paramètres (`SettingsScreen`).
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si la table `episodes_status` ou `my_podcasts` voit ses liaisons modifiées.
  Future<List<Map<String, dynamic>>> getStorageBreakdownPerPodcast() async {
    try {
      final db = await _dbHelper.database;
      return await db.rawQuery('''
        SELECT 
          m.podcastName as podcastName,
          p.artworkUrl as artworkUrl,
          COUNT(s.episodeId) as episodeCount,
          SUM(s.fileSize) as totalSize
        FROM episodes_status s
        JOIN episodes_metadata m ON s.episodeId = m.episodeId
        LEFT JOIN my_podcasts p ON m.podcastName = p.collectionName
        WHERE s.localPath IS NOT NULL
        GROUP BY m.podcastName
        ORDER BY totalSize DESC
      ''');
    } catch (e) {
      return [];
    }
  }

  /// Extrait le top 3 des genres les plus représentés dans les abonnements locaux.
  ///
  /// **Utilité** : Sert de base pour calculer les recommandations d'écoutes adaptées.
  /// **Point d'entrée** : Appelé lors du calcul automatique des recommandations thématiques.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si le parsing des chaînes de genres (séparateurs) change.
  /// Nettoie la BDD et ré-indexe les fichiers MP3 trouvés sur le disque (Atomicité).
  ///
  /// **Utilité** : Recrée la correspondance entre le stockage physique et la base SQLite après modifications manuelles externes.
  /// **Point d'entrée** : Appelé au démarrage de l'app ou lors d'actions de réparation de cache.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si la structure des dossiers de téléchargement change.
  Future<void> syncFileSystemToDatabase() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${directory.path}/downloads');
      if (!await downloadDir.exists()) return;

      final List<FileSystemEntity> files = await downloadDir.list().toList();
      final List<File> mp3Files = files
          .whereType<File>()
          .where((f) => f.path.endsWith('.mp3'))
          .toList();

      if (mp3Files.isEmpty) return;

      final db = await _dbHelper.database;

      final List<Map<String, dynamic>> metaRows = await db.query(
        'episodes_metadata',
        columns: ['episodeId'],
      );
      final List<Map<String, dynamic>> statusRows = await db.query(
        'episodes_status',
        columns: ['episodeId'],
      );

      final Set<String> allKnownIds = {
        ...metaRows.map((r) => r['episodeId'] as String),
        ...statusRows.map((r) => r['episodeId'] as String),
      };

      final Map<String, String> filenameToId = {};
      final downloadManager = DownloadManager();
      for (var id in allKnownIds) {
        final expectedName = downloadManager.getSafeFileName(id);
        filenameToId[expectedName] = id;
      }

      await db.transaction((txn) async {
        for (var file in mp3Files) {
          final filename = p.basename(file.path);
          final episodeId = filenameToId[filename];

          if (episodeId != null) {
            int size = 0;
            try {
              if (await file.exists()) {
                size = await file.length();
              } else {
                continue;
              }
            } catch (_) {
              continue;
            }
            final relativePath = 'downloads/$filename';

            final List<Map<String, dynamic>> existing = await txn.query(
              'episodes_status',
              where: 'episodeId = ?',
              whereArgs: [episodeId],
            );

            if (existing.isEmpty) {
              await txn.insert('episodes_status', {
                'episodeId': episodeId,
                'isRead': 0,
                'readAt': null,
                'localPath': relativePath,
                'status': 1,
                'fileSize': size,
              });
            } else {
              final row = existing.first;
              final currentPath = row['localPath'] as String?;
              final currentStatus = row['status'] as int? ?? 0;
              final currentSize = row['fileSize'] as int? ?? 0;

              if (currentPath == null ||
                  currentStatus != 1 ||
                  currentSize != size) {
                await txn.update(
                  'episodes_status',
                  {
                    'localPath': relativePath,
                    'status': 1,
                    'fileSize': size,
                  },
                  where: 'episodeId = ?',
                  whereArgs: [episodeId],
                );
              }
            }
          }
        }
      });
    } catch (_) {}
  }

  /// Répare les métadonnées d'épisodes orphelins (taille nulle ou manquants sur disque) en transaction SQLite.
  ///
  /// **Utilité** : Scanne la base locale et répare ou dé-indexe les fichiers endommagés ou absents.
  /// **Point d'entrée** : Appelé au démarrage de l'app ou lors du déclenchement manuel de réparation.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si des tables additionnelles doivent être corrigées en cas d'incohérence.
  Future<void> repairZeroSizeEpisodes() async {
    try {
      final db = await _dbHelper.database;
      final directory = await getApplicationDocumentsDirectory();

      final List<Map<String, dynamic>> results = await db.rawQuery('''
        SELECT s.episodeId, s.localPath, m.title, m.podcastName
        FROM episodes_status s
        LEFT JOIN episodes_metadata m ON s.episodeId = m.episodeId
        WHERE s.localPath IS NOT NULL AND (s.fileSize IS NULL OR s.fileSize = 0)
      ''');

      if (results.isEmpty) {
        return;
      }

      await db.transaction((txn) async {
        for (var row in results) {
          final episodeId = row['episodeId'] as String;
          final dbPath = row['localPath'] as String;

          String? absolutePath =
              p.isAbsolute(dbPath) ? dbPath : p.join(directory.path, dbPath);
          final file = File(absolutePath);

          try {
            if (await file.exists()) {
              final size = await file.length();
              if (size > 0) {
                await txn.update(
                  'episodes_status',
                  {
                    'fileSize': size,
                    'status': 1,
                  },
                  where: 'episodeId = ?',
                  whereArgs: [episodeId],
                );
              }
            } else {
              await txn.update(
                'episodes_status',
                {
                  'localPath': null,
                  'status': 0,
                  'fileSize': 0,
                },
                where: 'episodeId = ?',
                whereArgs: [episodeId],
              );
            }
          } catch (_) {}
        }
      });
    } catch (_) {}
  }

  /// Ferme la connexion à la base de données.
  ///
  /// **Utilité** : Nettoie proprement les ressources SQLite actives.
  /// **Point d'entrée** : Appelé lors du déchargement complet des services.
  /// **Maintenance** : Modifier en cas de changement de mécanisme de fermeture.
  Future<void> closeDatabase() async {
    await _dbHelper.closeDatabase();
  }

  /// Enregistre les métadonnées pour le cache des thèmes.
  ///
  /// **Utilité** : Met en cache les podcasts d'un thème pendant 7 jours.
  /// **Point d'entrée** : Appelé par le service de thèmes après requêtage.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier si le schéma de table `themes_cache` change.
  Future<void> saveThemeCache(String theme, List<PodcastModel> podcasts) async {
    await _dbHelper.saveThemeCache(theme, podcasts);
  }

  /// Récupère le cache de thèmes depuis la BDD SQLite.
  ///
  /// **Utilité** : Permet le chargement hors-ligne rapide des thèmes de podcasts.
  /// **Point d'entrée** : Appelé par le service de thèmes.
  /// **Maintenance** : Modifier si les colonnes retournées changent.
  Future<List<PodcastModel>> getThemeCache(String theme) async {
    return await _dbHelper.getThemeCache(theme);
  }

  /// Récupère le timestamp du cache thématique.
  ///
  /// **Utilité** : Permet de vérifier la validité (7 jours) du cache d'un thème.
  /// **Point d'entrée** : Appelé par le service de thèmes.
  /// **Maintenance** : Modifier si le format du timestamp évolue.
  Future<int?> getThemeCacheTime(String theme) async {
    return await _dbHelper.getThemeCacheTime(theme);
  }

  /// Récupère les statistiques globales du cache sous forme typée (CacheStats).
  ///
  /// **Utilité** : Calcule le nombre d'épisodes téléchargés en local et l'espace disque consommé (en octets).
  /// **Point d'entrée** : Appelé par `PodcastCacheManager` pour l'affichage de l'UI.
  /// **Maintenance** : Si les critères de détection des fichiers en cache sur disque changent, modifier ici.
  Future<CacheStats> getCachedEpisodesStats() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_cachedStats != null && (now - _cachedStatsTime) < 3000) {
      return CacheStats(
        count: _cachedStats!['count'] as int? ?? 0,
        totalBytes: _cachedStats!['totalBytes'] as int? ?? 0,
      );
    }
    try {
      final db = await _dbHelper.database;

      final List<Map<String, dynamic>> results = await db.query(
        'episodes_status',
        columns: ['episodeId', 'localPath', 'fileSize'],
        where: 'localPath IS NOT NULL',
      );

      final directory = await getApplicationDocumentsDirectory();

      int count = 0;
      int totalBytes = 0;

      final checkFutures = results.map((row) async {
        final dbPath = row['localPath'] as String;
        final size = row['fileSize'] as int? ?? 0;

        String resolvedPath =
            p.isAbsolute(dbPath) ? dbPath : p.join(directory.path, dbPath);

        final exists = await File(resolvedPath).exists();
        if (exists) {
          return size;
        }
        return -1;
      }).toList();

      final sizes = await Future.wait(checkFutures);
      for (var size in sizes) {
        if (size >= 0) {
          count++;
          totalBytes += size;
        }
      }

      final Map<String, dynamic> data = {
        'count': count,
        'totalBytes': totalBytes,
      };

      _cachedStats = data;
      _cachedStatsTime = now;
      return CacheStats(count: count, totalBytes: totalBytes);
    } catch (e) {
      return CacheStats(count: 0, totalBytes: 0);
    }
  }

  /// Récupère la liste paginée de l'historique des épisodes lus (isRead = 1).
  ///
  /// **Utilité** : Effectue une jointure entre `episodes_status` et `episodes_metadata` pour extraire l'historique local.
  /// **Point d'entrée** : Appelé par `HistoryTabService` lors du chargement ou du défilement de l'historique.
  /// **Maintenance** : Si le schéma de jointure ou le tri change, modifier ici.
  Future<List<EpisodeModel>> getReadEpisodesHistory(
      {int limit = 20, int offset = 0}) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT 
          s.episodeId, 
          s.isRead, 
          s.readAt, 
          s.localPath,
          s.status,
          m.title, 
          m.audioUrl, 
          m.imageUrl, 
          m.podcastName, 
          m.pubDate, 
          m.description
        FROM episodes_status s
        LEFT JOIN episodes_metadata m ON s.episodeId = m.episodeId
        WHERE s.isRead = 1
        ORDER BY s.readAt DESC
        LIMIT ? OFFSET ?
      ''', [limit, offset]);

      return maps.map((map) {
        return EpisodeModel(
          id: map['episodeId'] as String,
          title: map['title'] as String? ?? 'Sans titre',
          audioUrl: map['audioUrl'] as String? ?? '',
          imageUrl: map['imageUrl'] as String? ?? '',
          podcastName: map['podcastName'] as String? ?? '',
          pubDate: map['pubDate'] != null
              ? DateTime.tryParse(map['pubDate'] as String) ?? DateTime.now()
              : DateTime.now(),
          description: map['description'] as String? ?? '',
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Vide complètement la table de cache thématique dans SQLite.
  ///
  /// **Utilité** : Supprime tous les podcasts thématiques mis en cache.
  /// **Point d'entrée** : Appelé par `ThemeTabService` lorsque la langue de l'application change.
  /// **Maintenance** : Si le nom de la table `themes_cache` change, modifier ici.
  Future<void> clearThemeCache() async {
    try {
      final db = await _dbHelper.database;
      await db.delete('themes_cache');
    } catch (_) {}
  }
}
