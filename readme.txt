====================================================
               PodStream - Gestion Podcast
====================================================

Description
-----------
PodStream est une application mobile de gestion et de lecture de podcasts développée en Flutter. 
Elle permet aux utilisateurs de découvrir de nouveaux podcasts, de s'y abonner, de gérer leur 
collection personnalisée et d'écouter les épisodes directement depuis leur appareil. L'application 
intègre une base de données robuste en temps réel pour synchroniser les données entre les appareils.

Technologies Principales
------------------------
- Frontend : Flutter (Dart)
- Backend & Base de données : Firebase Data Connect (PostgreSQL)
- Authentification : Firebase Auth (Google Sign-In)
- Audio : just_audio, audio_session
- Recherche : iTunes Search API / Parsing de flux RSS (xml)

Fonctionnalités Clés
--------------------
- Connexion sécurisée via un compte Google.
- Découverte de podcasts (Par thème, Populaire, Affinités) via l'API iTunes.
- Consultation du détail d'un podcast et de la liste de ses épisodes (lus directement depuis le flux RSS).
- Abonnement aux podcasts favoris (synchronisés en base de données).
- Page d'accueil personnalisée ("Mes podcasts" et "À écouter").
- Réorganisation de "Mes podcasts" par simple glisser-déposer (Drag & Drop), sauvegardée en base.
- Paramètres de l'application : choix de la langue des podcasts, ordre d'affichage (plus ancien / plus récent) et affichage de la version.
- Player audio intégré avec contrôle de lecture.

Architecture du projet
----------------------
/podcast_app            : Le code source de l'application Flutter.
/dataconnect            : La configuration et les schémas de Firebase Data Connect (PostgreSQL).
/version.json           : Fichier centralisé gérant le numéro de version de l'application.
Livrer_Android.bat      : Script automatisé permettant de builder la version de production (AAB) pour le Play Store en se basant sur le version.json.
verif.bat               : Script automatisé pour formater, corriger (linting) et tester le code avant compilation.

Instructions de Vérification (Avant Build)
------------------------------------------
Il est fortement recommandé d'exécuter le script `verif.bat` avant de générer une version de production. Ce script va :
1. Formater automatiquement le code (`dart format`).
2. Appliquer les corrections automatiques (`dart fix`).
3. Lancer l'analyse statique pour détecter toute erreur de syntaxe (`flutter analyze`).
4. Exécuter les tests unitaires et de widgets (`flutter test`).

Instructions de Build (Android)
-------------------------------
1. Assurez-vous d'avoir Flutter correctement configuré sur votre environnement.
2. Pour générer une version de production, double-cliquez simplement sur le script `Livrer_Android.bat` situé à la racine du projet.
3. Le script se chargera de :
   - Lire la version actuelle dans `version.json`.
   - Lancer la commande `flutter build appbundle`.
   - Copier le fichier `.aab` généré vers votre bureau pour faciliter son importation sur la Google Play Console.
4. Pour incrémenter la version, modifiez les valeurs "version" et "build_number" dans le fichier `version.json` AVANT de lancer le script.

Remarques
---------
- Lors de l'exécution locale en mode "Debug" (flutter run), la version affichée est lue depuis le pubspec.yaml. Ce dernier a été synchronisé avec version.json.
- Le dossier build ne doit pas être synchronisé sur Google Drive pour éviter des conflits de verrouillage de fichiers (ex: app-debug.apk). Le projet a été configuré pour gérer cela.
