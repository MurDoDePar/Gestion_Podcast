import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/episode_model.dart';
import 'sqlite_podcast_repository.dart';
import 'rss_service.dart';
import 'audio_service.dart' as app_audio;

/// Service métier de l'onglet Historique (`HistoryTab`).
///
/// Ce service gère le chargement paginé de l'historique des épisodes écoutés par l'utilisateur,
/// et gère le processus de réparation en arrière-plan des métadonnées manquantes (flux RSS et cache).
class HistoryTabService extends ChangeNotifier {
  final SqlitePodcastRepository _sqliteRepository;
  final RssService _rssService;
  final Set<String> _attemptedRepairIds = {};

  final List<EpisodeModel> episodes = [];
  bool isLoading = false;
  bool hasMore = true;
  int offset = 0;
  static const int limit = 20;

  /// Initialise le service d'historique avec ses dépendances injectées.
  HistoryTabService({
    SqlitePodcastRepository? sqliteRepository,
    RssService? rssService,
  })  : _sqliteRepository = sqliteRepository ?? SqlitePodcastRepository(),
        _rssService = rssService ?? RssService();

  /// Récupère l'historique paginé des épisodes lus et déclenche la réparation automatique si nécessaire.
  ///
  /// **Utilité** : Fournit la liste des épisodes marqués comme lus sur SQLite locale avec pagination. Tente d'associer des métadonnées (titre, image) pour les épisodes orphelins.
  /// **Point d'entrée** : Appelé par la vue `HistoryTab` lors de l'initialisation ou du scroll.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si les critères d'identification des épisodes brisés (ex: titre générique) changent.
  Future<List<EpisodeModel>> getReadEpisodesHistory(
      {int limit = 20, int offset = 0}) async {
    try {
      final List<EpisodeModel> history = await _sqliteRepository
          .getReadEpisodesHistory(limit: limit, offset: offset);

      // Identification des épisodes incomplets
      final brokenEpisodes = history
          .where((ep) =>
              (ep.title == 'Sans titre' ||
                  ep.title == 'Épisode sans titre' ||
                  ep.imageUrl.isEmpty ||
                  ep.podcastName.isEmpty) &&
              !_attemptedRepairIds.contains(ep.id))
          .toList();

      if (brokenEpisodes.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final cachedJson = prefs.getString('cache_episodes_to_listen');
        Map<String, EpisodeModel> cacheMap = {};
        if (cachedJson != null) {
          try {
            final List<dynamic> decoded = jsonDecode(cachedJson);
            for (var item in decoded) {
              final ep = EpisodeModel.fromMap(item as Map<String, dynamic>);
              if (ep.id.isNotEmpty) cacheMap[ep.id] = ep;
              if (ep.audioUrl.isNotEmpty) cacheMap[ep.audioUrl] = ep;
            }
          } catch (_) {}
        }

        bool updatedAny = false;
        final List<EpisodeModel> remainingBroken = [];

        for (var ep in brokenEpisodes) {
          final match = cacheMap[ep.id] ?? cacheMap[ep.audioUrl];
          if (match != null) {
            final idx = history.indexWhere((element) => element.id == ep.id);
            if (idx != -1) {
              history[idx] = EpisodeModel(
                id: ep.id,
                title: match.title,
                audioUrl: ep.audioUrl.isNotEmpty ? ep.audioUrl : match.audioUrl,
                imageUrl: ep.imageUrl.isNotEmpty ? ep.imageUrl : match.imageUrl,
                podcastName: ep.podcastName.isNotEmpty
                    ? ep.podcastName
                    : match.podcastName,
                pubDate: ep.pubDate,
                description: ep.description.isNotEmpty
                    ? ep.description
                    : match.description,
              );
            }

            // Réparation en base locale
            await _sqliteRepository.markEpisodeAsRead(
              ep.id,
              title: match.title,
              audioUrl: ep.audioUrl.isNotEmpty ? ep.audioUrl : match.audioUrl,
              imageUrl: ep.imageUrl.isNotEmpty ? ep.imageUrl : match.imageUrl,
              podcastName: ep.podcastName.isNotEmpty
                  ? ep.podcastName
                  : match.podcastName,
              pubDate: ep.pubDate?.toIso8601String(),
              description: ep.description.isNotEmpty
                  ? ep.description
                  : match.description,
            );
            updatedAny = true;
            _attemptedRepairIds.add(ep.id);
          } else {
            remainingBroken.add(ep);
          }
        }

        if (updatedAny) {
          app_audio.AudioService().listRefreshNotifier.value++;
        }

        // Réparation de fond via requêtes de flux RSS distants
        if (remainingBroken.isNotEmpty) {
          for (var ep in remainingBroken) {
            _attemptedRepairIds.add(ep.id);
          }
          repairHistoryFromFeedsInBackground(remainingBroken);
        }
      }

      return history;
    } catch (e) {
      return [];
    }
  }

  /// Tâche de fond pour réparer l'historique en parsant les flux RSS des podcasts abonnés.
  ///
  /// **Utilité** : Parcourt les flux RSS des podcasts abonnés en arrière-plan pour retrouver les métadonnées de l'épisode correspondant à un ID orphelin.
  /// **Point d'entrée** : Déclenché en arrière-plan lors de la détection d'épisodes orphelins non résolus par le cache SharedPreferences.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si le délai de timeout de 15 secondes doit être ajusté en cas de mauvaise bande passante.
  void repairHistoryFromFeedsInBackground(
      List<EpisodeModel> brokenHistory) async {
    try {
      final subscribed = await _sqliteRepository.getSubscribedPodcasts();
      if (subscribed.isEmpty) return;
      Map<String, EpisodeModel> feedEpisodes = {};

      final fetchFutures = subscribed.map((podcast) async {
        try {
          var eps = await _rssService.getEpisodesFromFeed(podcast.feedUrl);
          if (eps == null) {
            eps = await _rssService.getCachedEpisodes(podcast.feedUrl);
          } else {
            if (eps.isNotEmpty) {
              await _sqliteRepository.insertEpisodesMetadata(eps);
            }
          }
          for (var ep in eps) {
            if (ep.id.isNotEmpty) feedEpisodes[ep.id] = ep;
            if (ep.audioUrl.isNotEmpty) feedEpisodes[ep.audioUrl] = ep;
          }
        } catch (_) {}
      }).toList();

      await Future.wait(fetchFutures).timeout(const Duration(seconds: 15));
      bool updatedAny = false;

      for (var ep in brokenHistory) {
        if (ep.title == 'Sans titre' ||
            ep.title == 'Épisode sans titre' ||
            ep.imageUrl.isEmpty ||
            ep.podcastName.isEmpty) {
          final match = feedEpisodes[ep.id] ?? feedEpisodes[ep.audioUrl];
          if (match != null) {
            final finalTitle =
                (ep.title == 'Sans titre' || ep.title == 'Épisode sans titre')
                    ? match.title
                    : ep.title;
            final finalImageUrl =
                ep.imageUrl.isEmpty ? match.imageUrl : ep.imageUrl;
            final finalPodcastName =
                ep.podcastName.isEmpty ? match.podcastName : ep.podcastName;
            final finalDescription =
                ep.description.isEmpty ? match.description : ep.description;
            final finalAudioUrl =
                ep.audioUrl.isEmpty ? match.audioUrl : ep.audioUrl;

            await _sqliteRepository.markEpisodeAsRead(
              ep.id,
              title: finalTitle,
              audioUrl: finalAudioUrl,
              imageUrl: finalImageUrl,
              podcastName: finalPodcastName,
              pubDate: ep.pubDate?.toIso8601String(),
              description: finalDescription,
            );
            updatedAny = true;
          }
        }
      }

      if (updatedAny) {
        app_audio.AudioService().listRefreshNotifier.value++;
      }
    } catch (_) {}
  }

  /// Recharge l'historique complet en réinitialisant la pagination.
  ///
  /// **Utilité** : Réinitialise l'état et recharge la première page d'épisodes lus.
  /// **Point d'entrée** : Appelé lors du pull-to-refresh ou de l'initialisation de l'onglet Historique.
  /// **Maintenance** : Ajuster si la taille limite de la page ou le comportement de tri change.
  Future<void> refresh() async {
    if (isLoading) return;
    isLoading = true;
    episodes.clear();
    offset = 0;
    hasMore = true;
    notifyListeners();

    try {
      final newEpisodes =
          await getReadEpisodesHistory(limit: limit, offset: offset);
      episodes.addAll(newEpisodes);
      offset += newEpisodes.length;
      if (newEpisodes.length < limit) {
        hasMore = false;
      }
    } catch (_) {
      hasMore = false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Charge la page suivante de l'historique des épisodes lus.
  ///
  /// **Utilité** : Gère le défilement infini en récupérant le lot d'épisodes suivant.
  /// **Point d'entrée** : Appelé par le listener de défilement de HistoryTab.
  /// **Maintenance** : Si les filtres ou les index de pagination changent, adapter ici.
  Future<void> loadMore() async {
    if (isLoading || !hasMore) return;
    isLoading = true;
    notifyListeners();

    try {
      final newEpisodes =
          await getReadEpisodesHistory(limit: limit, offset: offset);
      episodes.addAll(newEpisodes);
      offset += newEpisodes.length;
      if (newEpisodes.length < limit) {
        hasMore = false;
      }
    } catch (_) {
      hasMore = false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
