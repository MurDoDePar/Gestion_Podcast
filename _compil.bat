@echo off
echo ==========================================
echo    Verification et Compilation PodStream
echo ==========================================
echo.

echo [INFO] Mise a jour de la version a partir de version.json...
powershell.exe -ExecutionPolicy Bypass -File update_version.ps1

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
echo [1/6] Compilation de verification (flutter build apk)...
call flutter build apk
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERREUR] La compilation a echoue.
    echo Veuillez corriger les erreurs avant de continuer.
    goto :fin
)
echo [SUCCES] Compilation reussie !
echo.

echo [2/6] Formatage et correction automatique du code...
call dart format .
call dart fix --apply
echo.

echo [3/6] Lancement de l'analyse statique (flutter analyze)...
call flutter analyze
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERREUR] Des problemes de syntaxe ou d'analyse ont ete trouves.
    echo Veuillez les corriger avant de continuer.
    goto :fin
)
echo [SUCCES] Aucune erreur de syntaxe trouvee !
echo.

echo [4/6] Lancement des tests (flutter test)...
call flutter test
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERREUR] Un ou plusieurs tests ont echoue.
    goto :fin
)
echo [SUCCES] Tous les tests sont passes (ou aucun test n'est configure) !
echo.

echo [5/6] Compilation de l'APK Release finale...
call flutter build apk --release
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERREUR] La recompilation Release a echoue.
    goto :fin
)
echo [SUCCES] Recompilation Release reussie !
echo.

echo [6/6] Compilation de l'APK Debug finale...
call flutter build apk --debug
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERREUR] La recompilation Debug a echoue.
    goto :fin
)
echo [SUCCES] Recompilation Debug reussie !
echo.

echo ==========================================
echo    Verification et compilations terminees avec succes !
echo ==========================================

:fin
:: Revenir au dossier parent
cd ..
echo.
pause
