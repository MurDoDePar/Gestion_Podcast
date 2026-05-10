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
_verif.bat              : Script automatisé pour formater, corriger (linting) et tester le code avant compilation.
_run.bat                : Script de lancement rapide en mode développement (nettoyage, pub get, et run).
_GIT_livre.bat          : Script pour gérer l'archivage et les envois sur Git.
Generer_Icones.bat      : Outil pour regénérer les assets d'icônes via flutter_launcher_icons.

Instructions de Vérification (Avant Build)
------------------------------------------
Il est fortement recommandé d'exécuter le script `_verif.bat` avant de générer une version de production. Ce script va :
1. Configurer la "jonction" du dossier build pour éviter les plantages avec Google Drive.
2. Formater automatiquement le code (`dart format`).
3. Appliquer les corrections automatiques (`dart fix`).
4. Lancer l'analyse statique pour détecter toute erreur de syntaxe (`flutter analyze`).
5. Exécuter les tests unitaires et de widgets (`flutter test`).

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
