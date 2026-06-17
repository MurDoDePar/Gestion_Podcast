import 'dart:async';
import 'package:firebase_data_connect/firebase_data_connect.dart';
import '../dataconnect-generated/example.dart';

/// Dépôt de données distant SQLConnect (Firebase Data Connect) pour PodStream.
///
/// Cette classe encapsule toutes les mutations et requêtes GraphQL destinées à
/// la base PostgreSQL hébergée via Firebase Data Connect.
/// Elle permet d'isoler la logique de persistance distante et d'injecter la dépendance
/// du connecteur pour faciliter les tests.
class SqlConnectRepository {
  final ExampleConnector _connector;

  /// Initialise le dépôt SQLConnect avec une instance optionnelle de connecteur.
  ///
  /// Si aucune instance n'est fournie, utilise la valeur par défaut `ExampleConnector.instance`.
  SqlConnectRepository({ExampleConnector? connector})
      : _connector = connector ?? ExampleConnector.instance;

  /// Recherche un utilisateur dans la base PostgreSQL via son ID Google unique.
  ///
  /// **Utilité** : Permet de vérifier l'existence de l'utilisateur ou d'obtenir son UUID interne PostgreSQL.
  /// **Point d'entrée** : Appelé lors de la phase d'initialisation de l'application et de synchronisation des comptes (`ensureInitialized`).
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si la structure de l'utilisateur ou le nom de la requête GraphQL `findUserByGoogleId` change.
  Future<QueryResult<FindUserByGoogleIdData, void>> findUserByGoogleId(
      String googleId) async {
    return await _connector.findUserByGoogleId(googleId: googleId).execute();
  }

  /// Insère un nouvel utilisateur dans PostgreSQL.
  ///
  /// **Utilité** : Crée le compte utilisateur interne pour lier les abonnements et l'historique dans la base relationnelle.
  /// **Point d'entrée** : Appelé si un utilisateur se connecte via Google et n'est pas encore présent dans la base relationnelle (`_ensureUserExistsInPostgres`).
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si des métadonnées supplémentaires (ex: langue par défaut de l'utilisateur, paramètres de profil) doivent être sauvées au moment de l'inscription.
  Future<void> insertUser({
    required String googleId,
    required String displayName,
    String? email,
    String? photoUrl,
  }) async {
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _connector
        .insertUser(
          googleId: googleId,
          displayName: displayName,
          createdAt: Timestamp(nowSeconds, 0),
        )
        .email(email)
        .photoUrl(photoUrl)
        .execute();
  }

  /// Récupère la liste des abonnements distants d'un utilisateur sous PostgreSQL.
  ///
  /// **Utilité** : Fournit les abonnements stockés dans le cloud pour synchroniser une base SQLite locale vierge.
  /// **Point d'entrée** : Appelé lors de l'initialisation du premier lancement ou de la synchronisation forcée (`initializeFromFirebase`).
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si le modèle relationnel GraphQL de `getMySubscriptions` est modifié.
  Future<QueryResult<GetMySubscriptionsData, void>> getMySubscriptions(
      String userId) async {
    return await _connector.getMySubscriptions(userId: userId).execute();
  }

  /// Ajoute ou met à jour la fiche descriptive d'un podcast dans la base globale de PostgreSQL.
  ///
  /// **Utilité** : S'assure que le podcast existe dans le dictionnaire mondial PostgreSQL avant d'y lier un abonnement.
  /// **Point d'entrée** : Appelé par le service de synchronisation d'abonnements distants (`syncSubscribe`).
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si la table `podcasts` de PostgreSQL gagne de nouveaux attributs clés (ex: genres, description globale).
  Future<void> upsertPodcast({
    required String id,
    required String title,
    required String feedUrl,
    String? imageUrl,
    String? author,
    List<String>? categories,
  }) async {
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _connector
        .upsertPodcast(
          title: title,
          feedUrl: feedUrl,
          createdAt: Timestamp(nowSeconds, 0),
        )
        .id(id)
        .imageUrl(imageUrl)
        .author(author)
        .categories(categories)
        .execute();
  }

  /// Crée un lien d'abonnement entre un utilisateur et un podcast dans PostgreSQL.
  ///
  /// **Utilité** : Enregistre l'abonnement en spécifiant l'ordre d'affichage préféré dans la bibliothèque.
  /// **Point d'entrée** : Appelé lors de la synchronisation en arrière-plan d'une nouvelle souscription.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si la table de liaison `podcast_subscriptions` change de structure.
  Future<void> subscribeToPodcast({
    required String userId,
    required String podcastId,
    required int listOrder,
  }) async {
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _connector
        .subscribeToPodcast(
          userId: userId,
          podcastId: podcastId,
          subscribedAt: Timestamp(nowSeconds, 0),
        )
        .listOrder(listOrder)
        .execute();
  }

  /// Supprime le lien d'abonnement entre un utilisateur et un podcast dans PostgreSQL.
  ///
  /// **Utilité** : Enregistre le désabonnement au niveau distant dans PostgreSQL.
  /// **Point d'entrée** : Appelé lors de la synchronisation asynchrone des désabonnements.
  /// **Maintenance** : En cas de bug ou d'évolution, modifier si le nom de la mutation `unsubscribeFromPodcast` change.
  Future<void> unsubscribeFromPodcast({
    required String userId,
    required String podcastId,
  }) async {
    await _connector
        .unsubscribeFromPodcast(
          userId: userId,
          podcastId: podcastId,
        )
        .execute();
  }

  /// Exécute la requête SQL/Data Connect d'affinité pour récupérer les podcasts aimés par des auditeurs similaires.
  ///
  /// **Utilité** : Calcule sur PostgreSQL les recommandations d'affinité à partir des co-abonnements.
  /// **Point d'entrée** : Appelé pour alimenter l'onglet "Affinités" (`DiscoverTab`).
  /// **Maintenance** : En cas de bug ou d'évolution, modifier cette section si la requête `getAffinityRecommendations` ou ses paramètres changent dans le schéma Data Connect.
  Future<QueryResult<GetAffinityRecommendationsData, void>>
      getAffinityRecommendations(String userId) async {
    return await _connector
        .getAffinityRecommendations(userId: userId)
        .execute();
  }
}
