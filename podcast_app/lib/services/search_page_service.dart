import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/podcast_model.dart';
import 'itunes_search_gateway.dart';

/// Service métier de l'onglet de recherche de podcasts (`SearchTab`).
///
/// Ce service expose les méthodes métier permettant de rechercher des podcasts en ligne
/// en s'appuyant sur l'API iTunes via la passerelle `ITunesSearchGateway`.
class SearchPageService extends ChangeNotifier {
  final ITunesSearchGateway _itunesGateway;

  String query = '';
  List<PodcastModel> searchResults = [];
  bool isLoading = false;
  String? errorMessage;

  /// Initialise le service de recherche avec sa passerelle injectée.
  SearchPageService({ITunesSearchGateway? itunesGateway})
      : _itunesGateway = itunesGateway ?? ITunesSearchGateway();

  /// Effectue une recherche en ligne de podcasts correspondant à un terme.
  ///
  /// **Utilité** : Interroge iTunes pour renvoyer les podcasts pertinents selon les préférences linguistiques actives.
  /// **Point d'entrée** : Appelé par le widget `SearchTab` lors de la validation du formulaire de recherche.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si des filtres locaux ou des tris personnalisés doivent être appliqués post-recherche.
  Future<List<PodcastModel>> searchPodcasts(String term) async {
    return await _itunesGateway.searchPodcasts(term);
  }

  /// Lance ou rafraîchit la recherche active en utilisant le terme stocké.
  ///
  /// **Utilité** : Effectue la recherche sur l'API iTunes, met à jour le statut de chargement, les résultats et notifie les écouteurs de l'UI.
  /// **Point d'entrée** : Appelé lors du rafraîchissement ou de la soumission de recherche.
  /// **Maintenance** : Modifier si les comportements de gestion d'erreurs réseau de recherche changent.
  Future<void> refresh() async {
    if (query.isEmpty) {
      searchResults = [];
      notifyListeners();
      return;
    }
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      searchResults = await _itunesGateway.searchPodcasts(query);
    } catch (e) {
      errorMessage = e.toString();
      searchResults = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Met à jour la requête et déclenche immédiatement la recherche associée.
  ///
  /// **Utilité** : Modifie la propriété de requête interne et appelle la méthode refresh.
  /// **Point d'entrée** : Appelé par l'UI lorsque l'utilisateur saisit ou valide une recherche.
  /// **Maintenance** : Modifier si un délai d'attente (debounce) doit être implémenté ici.
  Future<void> search(String newQuery) async {
    query = newQuery;
    await refresh();
  }
}
