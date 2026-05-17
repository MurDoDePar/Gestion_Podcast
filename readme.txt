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
