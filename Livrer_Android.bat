@echo off
setlocal enabledelayedexpansion
title PodStream - Livraison Android

:: Recuperation de la version
for /f "usebackq tokens=*" %%a in (`powershell -Command "(Get-Content version.json | ConvertFrom-Json).version"`) do set APP_VERSION=%%a
for /f "usebackq tokens=*" %%a in (`powershell -Command "(Get-Content version.json | ConvertFrom-Json).build_number"`) do set APP_BUILD_NUMBER=%%a

echo.
echo ======================================================
echo     PODSTREAM -- LIVRAISON GOOGLE PLAY (v%APP_VERSION% - Build %APP_BUILD_NUMBER%)
echo ======================================================
echo.

:: ---------------------------------------------------------
:: CONFIGURATION
:: ---------------------------------------------------------
set ROOT=%~dp0
set APP_DIR=%ROOT%podcast_app
set OUTPUT_AAB=%APP_DIR%\build\app\outputs\bundle\release\app-release.aab

:: ---------------------------------------------------------
:: ETAPE 1 -- Build du AAB Release avec Flutter
:: ---------------------------------------------------------
echo [1/3] Configuration du dossier build (contournement Google Drive)...
cd /d "%APP_DIR%"

:: Arret des processus pour liberer les fichiers
cd android
call gradlew --stop >nul 2>&1
cd ..

:: Configuration d'un dossier de build externe
set EXT_BUILD=C:\temp\podstream_build
if not exist "%EXT_BUILD%" mkdir "%EXT_BUILD%"

:: Remplacement du dossier build par une jonction (raccourci physique)
:: Cela empeche Google Drive de synchroniser les fichiers de compilation !
fsutil reparsepoint query build >nul 2>&1
if errorlevel 1 (
    echo Suppression de l'ancien dossier build, cela peut prendre un instant...
    rmdir /s /q build >nul 2>&1
    if exist build (
        echo.
        echo [ERREUR] Google Drive bloque toujours le dossier 'build'.
        echo Solution : Quittez Google Drive, clic droit sur l'icone dans la barre des taches -^> Quitter,
        echo relancez ce script, puis vous pourrez rouvrir Google Drive.
        pause
        exit /b 1
    )
    mklink /J build "%EXT_BUILD%"
)

echo Nettoyage rapide...
call flutter clean >nul 2>&1

:: Verifier si flutter clean a supprime la jonction
if not exist build mklink /J build "%EXT_BUILD%" >nul 2>&1

echo.
echo [2/3] Compilation du bundle Android (AAB Release)...

call flutter build appbundle --release --build-name=%APP_VERSION% --build-number=%APP_BUILD_NUMBER%
if errorlevel 1 (
    echo.
    echo  ECHEC de la compilation Flutter.
    echo  Consultez les erreurs ci-dessus.
    pause
    exit /b 1
)
echo  OK : Compilation terminee
echo.

:: ---------------------------------------------------------
:: ETAPE 2 -- Resultat
:: ---------------------------------------------------------
echo [3/3] Verification du fichier de sortie...

if exist "%OUTPUT_AAB%" (
    echo.
    echo ======================================================
    echo     SUCCES ! Fichier AAB pret pour Google Play
    echo ======================================================
    echo.
    echo  Fichier AAB :
    echo    %OUTPUT_AAB%
    echo.
    echo  Prochaines etapes :
    echo    1. Ouvrez Google Play Console
    echo       https://play.google.com/console
    echo    2. Allez dans Production -^> Creer une version
    echo    3. Uploadez le fichier .aab ci-dessus
    echo.
    explorer "%APP_DIR%\build\app\outputs\bundle\release"
) else (
    echo  ERREUR : Fichier AAB non trouve.
    echo  Verifiez les erreurs de compilation ci-dessus.
)

echo.
pause
