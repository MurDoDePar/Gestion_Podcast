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
:: ETAPE 1 -- Build du AAB Release avec Flutter
:: ---------------------------------------------------------
echo [1/3] Compilation du bundle Android (AAB Release)...
echo (La preparation et le nettoyage sont realises par _compil.bat)

cd /d "%APP_DIR%"

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
echo [2/3] Verification du fichier de sortie...

if exist "%OUTPUT_AAB%" (
    echo.
    echo ======================================================
    echo     SUCCES ! Fichier AAB pret pour Google Play
    echo ======================================================
    echo.
    echo  Fichier AAB :
    echo    %OUTPUT_AAB%
    echo.
    
    echo [3/3] Commit Git de la version...
    cd /d "%ROOT%"
    git add .
    git commit -m "Release v!APP_VERSION! - !APP_RELEASE_NOTES!"
    
    echo.
    echo  Prochaines etapes :
    echo    1. N'oubliez pas de faire 'git push' si vous voulez synchroniser votre depot.
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
