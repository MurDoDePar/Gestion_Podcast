====================================================
               PodStream - Gestion Podcast
====================================================

Description
-----------
PodStream est une application mobile de gestion et de lecture de podcasts développée en Flutter. 
Elle permet aux utilisateurs de découvrir de nouveaux podcasts, de s'y abonner, de gérer leur 
collection personnalisée et d'écouter les épisodes directement depuis leur appareil. L'application 
intègre une base de données robuste en temps réel pour synchroniser les données entre les appareils 
et offre une prise en charge complète d'Android Auto.

Technologies Principales
------------------------
- Frontend : Flutter (Dart)
- Backend & Base de données : Firebase Data Connect (PostgreSQL)
- Authentification : Firebase Auth (Google Sign-In)
- Audio : just_audio, audio_session, audio_service
- Recherche : iTunes Search API / Parsing de flux RSS (xml)

Fonctionnalités Clés
--------------------
- Connexion sécurisée via un compte Google.
- Découverte de podcasts (Par thème, Populaire, Affinités croisées) via l'API iTunes et recommandations intelligentes.
- Recherche dynamique et instantanée avec effet "debounce".
- Consultation du détail d'un podcast et description des épisodes consultable en pop-up.
- Abonnement aux favoris avec intégrité des données basée sur les flux RSS (anti-doublons).
- Page d'accueil personnalisée ("Mes podcasts" et "À écouter").
- Réorganisation de "Mes podcasts" par simple glisser-déposer (Drag & Drop), sauvegardée en base.
- Paramètres de l'application : choix de la langue des podcasts, ordre d'affichage chronologique des épisodes.
- Player audio avancé : fonctionnement en arrière-plan, liste de lecture continue, et compatibilité avec Android Auto.

Architecture du projet
----------------------
/podcast_app            : Le code source de l'application Flutter.
/dataconnect            : La configuration et les schémas de Firebase Data Connect (PostgreSQL).
/version.json           : Fichier centralisé gérant le numéro de version de l'application.
_Android_livre.bat      : Script automatisé permettant de builder la version de production (AAB) pour le Play Store.
_compil.bat             : Script automatisé pour formater, tester, et générer les APKs (Release et Debug).
_install.bat            : Script pour installer l'APK Release sur le téléphone connecté via ADB.
_debug.bat              : Script pour installer l'APK Debug sur le téléphone connecté via ADB.
_run.bat                : Script de lancement rapide en mode développement (nettoyage, pub get, et run).
_GIT_livre.bat          : Script pour gérer l'archivage et les envois sur Git.
Generer_Icones.bat      : Outil pour regénérer les assets d'icônes via flutter_launcher_icons.

Description des Composants et Objets de l'Application
-----------------------------------------------------
L'application Flutter est structurée en plusieurs dossiers clés dans /podcast_app/lib :

1. Modèles de Données (/models)
   - PodcastModel (podcast_model.dart) : Représente un podcast avec ses métadonnées (ID, titre, auteur, description, image, flux RSS).
   - EpisodeModel (episode_model.dart) : Représente un épisode avec ses attributs (ID, ID du podcast, titre, description, date de publication, URL audio, durée, statut lu/non-lu).

2. Services Logiques (/services)
   - AudioService (audio_service.dart) & PodstreamAudioHandler (podstream_audio_handler.dart) : Cœur de la gestion de lecture audio. Gèrent la file d'attente (play, pause, skip), le comportement en arrière-plan et l'intégration complète d'Android Auto (avec boutons personnalisés -30s, +30s, Play/Pause, et Lu).
   - AudioHandlerLocator (audio_handler_locator.dart) : Fournit un accès global et unique (Singleton) à l'instance de PodstreamAudioHandler à travers toute l'application.
   - DatabaseRepository (database_repository.dart) & PodcastRepository (podcast_repository.dart) : Couche d'accès aux données. Gèrent les requêtes locales (SQLite) et synchronisent en temps réel les données de l'utilisateur (favoris, ordonnancement drag-and-drop, progression) avec le serveur PostgreSQL via Firebase Data Connect.
   - ITunesService (itunes_service.dart) : Gère l'intégration avec l'API iTunes Search pour rechercher et découvrir des podcasts par thème ou par popularité.
   - RssService (rss_service.dart) : Parse les flux RSS XML des podcasts pour récupérer dynamiquement la liste à jour des épisodes.
   - MarkAsReadService (mark_as_read_service.dart) : Service dédié au marquage des épisodes comme lus/écoutés, synchronisé avec la base de données.
   - CacheManager (cache_manager.dart) : Gère la mise en cache des flux RSS et des images pour réduire la consommation réseau et améliorer la réactivité.

3. Écrans et Onglets (/screens)
   - LoginScreen (login_screen.dart) : Gère l'authentification sécurisée des utilisateurs via Google Sign-In.
   - MainScreen (main_screen.dart) : Structure principale de navigation avec le menu à onglets du bas (BottomNavigationBar).
   - HomeScreen (home_screen.dart) : Page d'accueil affichant les podcasts favoris de l'utilisateur ("Mes podcasts") et la liste des épisodes à écouter.
   - PodcastDetailsScreen (podcast_details_screen.dart) : Affiche la fiche détaillée d'un podcast (description, abonnements, liste des épisodes associés avec filtrage et tri).
   - SettingsScreen (settings_screen.dart) : Écran des préférences utilisateur (langue de recherche, tri des épisodes).
   - Onglets (/screens/tabs) :
     - MyPodcastsTab : Vue personnalisée des podcasts de l'utilisateur avec prise en charge du Drag & Drop pour réorganiser l'affichage.
     - ThemesTab : Organise la recherche et la découverte par thématiques (Humour, Sciences, Actualités, etc.) sous forme d'onglets réactifs.
     - PopularTab & SearchTab : Vues dédiées à la découverte de podcasts tendances et à la recherche textuelle instantanée.

4. Widgets Réutilisables (/widgets)
   - AudioPlayerWidget (audio_player_widget.dart) : Lecteur audio plein écran complet avec barre de progression, vitesse de lecture, et commandes physiques (-30s, +30s, Play/Pause, Lu).
   - MiniPlayer (mini_player.dart) : Lecteur compact persistant en bas de l'écran qui permet de contrôler la lecture tout en naviguant dans l'application.
   - EpisodeListTile (episode_list_tile.dart) : Composant graphique représentant un épisode avec son bouton de lecture rapide, son indicateur de lecture (pastille de statut) et son résumé disponible en popup.

Instructions de Compilation et Vérification
-------------------------------------------
Il est fortement recommandé d'exécuter le script `_compil.bat` pour générer vos fichiers. Ce script va :
1. Mettre à jour la version depuis `version.json`.
2. Configurer la "jonction" du dossier build pour éviter les plantages avec Google Drive.
3. Formater automatiquement le code et lancer l'analyse statique (`dart format`, `dart fix`, `flutter analyze`).
4. Exécuter les tests unitaires et de widgets (`flutter test`).
5. Compiler les APKs en mode Release (`app-release.apk`) et Debug (`app-debug.apk`).

Instructions de Build (Android)
-------------------------------
1. Assurez-vous d'avoir Flutter correctement configuré sur votre environnement.
2. Pour générer une version de production, double-cliquez simplement sur le script `_Android_livre.bat` situé à la racine du projet.
3. Le script se chargera de :
   - Mettre en place un environnement de build hors de Google Drive.
   - Lire la version actuelle dans `version.json`.
   - Lancer la commande `flutter build appbundle`.
   - Copier le fichier `.aab` généré vers votre bureau pour faciliter son importation sur la Google Play Console.
4. Pour incrémenter la version, modifiez les valeurs "version" et "build_number" dans le fichier `version.json` AVANT de lancer le script.

Remarques
---------
- Lors de l'exécution locale en mode "Debug" (flutter run), la version affichée est lue depuis le pubspec.yaml. Ce dernier doit rester synchronisé avec version.json.
- Les scripts `.bat` utilisent automatiquement la commande "mklink /j" pour déporter le lourd dossier "build" vers C:\temp afin de contourner le verrouillage intempestif imposé par la synchronisation Google Drive.
