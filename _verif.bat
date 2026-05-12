@echo off
echo ==========================================
echo    Verification du code PodStream
echo ==========================================
echo.

:: Se deplacer dans le dossier du projet Flutter
cd podcast_app

:: 1. Arret forcé des processus en arriere-plan qui bloquent les fichiers
echo [INFO] Arret des processus Gradle en arriere-plan...
cd android && call gradlew.bat --stop >nul 2>&1 && cd ..

:: 2. Nettoyage complet du cache Flutter (peut parfois echouer si un fichier est verrouille)
echo [INFO] Nettoyage du cache Flutter...
call flutter clean >nul 2>&1

:: 3. Nettoyage force de bas niveau des dossiers caches
echo [INFO] Nettoyage force des dossiers build et .dart_tool...
powershell -Command "Remove-Item -Recurse -Force .dart_tool\* -ErrorAction SilentlyContinue"
powershell -Command "Remove-Item -Recurse -Force build\* -ErrorAction SilentlyContinue"

:: 4. Configuration de la jonction pour le dossier build (contournement Google Drive)
fsutil reparsepoint query build >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [INFO] Remplacement du dossier build par une jonction pour eviter les blocages Google Drive...
    rmdir /s /q build 2>nul
    mkdir "C:\temp\podstream_build" 2>nul
    mklink /j build "C:\temp\podstream_build" >nul
)

:: 5. Mise a jour des dependances fraichement nettoyees
echo [INFO] Recuperation des dependances...
call flutter pub get >nul 2>&1
echo.
echo [1/4] Compilation du code (flutter build apk)...
call flutter build apk
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERREUR] La compilation a echoue.
    echo Veuillez corriger les erreurs avant de continuer.
    goto :fin
)
echo [SUCCES] Compilation reussie !
echo.

echo [2/4] Formatage et correction automatique du code...
call dart format .
call dart fix --apply
echo.

echo [3/4] Lancement de l'analyse statique (flutter analyze)...
call flutter analyze
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERREUR] Des problemes de syntaxe ou d'analyse ont ete trouves.
    echo Veuillez les corriger avant de continuer.
    goto :fin
)
echo [SUCCES] Aucune erreur de syntaxe trouvee !
echo.

echo [4/4] Lancement des tests (flutter test)...
call flutter test
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERREUR] Un ou plusieurs tests ont echoue.
    goto :fin
)
echo [SUCCES] Tous les tests sont passes (ou aucun test n'est configure) !
echo.

echo ==========================================
echo    Verification terminee avec succes !
echo ==========================================

:fin
:: Revenir au dossier parent
cd ..
echo.
pause
