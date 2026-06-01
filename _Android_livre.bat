@echo off
setlocal enabledelayedexpansion
title PodStream - Livraison Android

:: Recuperation de la version
for /f "usebackq tokens=*" %%a in (`powershell -Command "(Get-Content version.json | ConvertFrom-Json).version"`) do set APP_VERSION=%%a
for /f "usebackq tokens=*" %%a in (`powershell -Command "(Get-Content version.json | ConvertFrom-Json).build_number"`) do set APP_BUILD_NUMBER=%%a
for /f "usebackq tokens=*" %%a in (`powershell -Command "(Get-Content version.json | ConvertFrom-Json).release_notes"`) do set APP_RELEASE_NOTES=%%a

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
:: ETAPE 1 -- Verification ou compilation du AAB Release
:: ---------------------------------------------------------
echo [1/2] Verification du bundle Android (AAB Release)...

if not exist "%OUTPUT_AAB%" (
    echo [INFO] Aucun fichier AAB trouve dans le dossier de build.
    echo Lancement d'une compilation propre complete via _compil.bat...
    echo.
    cd /d "%ROOT%"
    call _compil.bat
    cd /d "%APP_DIR%"
) else (
    echo [INFO] Un bundle AAB recemment compile a ete trouve :
    echo    %OUTPUT_AAB%
    echo.
    echo [INFO] Utilisation automatique du bundle AAB existant.
)

:: ---------------------------------------------------------
:: ETAPE 2 -- Resultat
:: ---------------------------------------------------------
echo [2/2] Verification du fichier de sortie...

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
    echo    1. Lancez _GIT_livre.bat pour commiter et tagger votre version dans Git.
    echo    2. Ouvrez Google Play Console : https://play.google.com/console
    echo    3. Uploadez le fichier .aab
    echo.
    explorer "%APP_DIR%\build\app\outputs\bundle\release"
) else (
    echo  ERREUR : Fichier AAB non trouve.
    echo  Verifiez les erreurs de compilation ci-dessus.
)

echo.
pause
