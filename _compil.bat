@echo off
setlocal EnableDelayedExpansion

rem Initialise la console et active le support virtuel terminal / ANSI
color 07

echo ==========================================
echo    Verification et Compilation PodStream
echo ==========================================
echo.

rem Get ANSI ESC character for modern console coloring
for /F "tokens=1,2 delims=#" %%a in ('"prompt $H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"

set "CLR_RESET=%ESC%[0m"
set "CLR_GREEN=%ESC%[32m"
set "CLR_RED=%ESC%[31m"
set "CLR_YELLOW=%ESC%[33m"
set "CLR_CYAN=%ESC%[36m"
set "CLR_BOLD=%ESC%[1m"

rem If ANSI is not supported/empty, clean variables to avoid printing raw escape sequences
if "%ESC%"=="" (
    set "CLR_RESET="
    set "CLR_GREEN="
    set "CLR_RED="
    set "CLR_YELLOW="
    set "CLR_CYAN="
    set "CLR_BOLD="
)

echo %CLR_CYAN%[INFO] Mise a jour de la version a partir de version.json...%CLR_RESET%
powershell.exe -ExecutionPolicy Bypass -File update_version.ps1
if !ERRORLEVEL! NEQ 0 (
    echo %CLR_RED%[ERREUR] La mise a jour de la version a echoue !%CLR_RESET%
    exit /b !ERRORLEVEL!
)

:: Se deplacer dans le dossier du projet Flutter
cd podcast_app

:: 1. Arret forcé des processus en arriere-plan qui bloquent les fichiers
echo %CLR_CYAN%[INFO] Arret des processus Gradle en arriere-plan...%CLR_RESET%
cd android && call gradlew.bat --stop >nul 2>&1 && cd ..

:: 2. Nettoyage complet du cache Flutter (peut parfois echouer si un fichier est verrouille)
echo %CLR_CYAN%[INFO] Nettoyage du cache Flutter...%CLR_RESET%
call flutter clean >nul 2>&1

:: 3. Nettoyage force de bas niveau des dossiers caches et fichiers temporaires de build
echo %CLR_CYAN%[INFO] Nettoyage force des dossiers build, .dart_tool et ephemeral...%CLR_RESET%
powershell -Command "Remove-Item -Recurse -Force .dart_tool\* -ErrorAction SilentlyContinue"
powershell -Command "Remove-Item -Recurse -Force build\* -ErrorAction SilentlyContinue"
powershell -Command "Remove-Item -Recurse -Force windows\flutter\ephemeral -ErrorAction SilentlyContinue"
powershell -Command "Remove-Item -Recurse -Force linux\flutter\ephemeral -ErrorAction SilentlyContinue"
powershell -Command "Remove-Item -Recurse -Force macos\flutter\ephemeral -ErrorAction SilentlyContinue"
powershell -Command "Remove-Item -Recurse -Force ios\Flutter\ephemeral -ErrorAction SilentlyContinue"

:: 4. Configuration de la jonction pour le dossier build (contournement Google Drive)
fsutil reparsepoint query build >nul 2>&1
if !ERRORLEVEL! NEQ 0 (
    echo %CLR_CYAN%[INFO] Remplacement du dossier build par une jonction pour eviter les blocages Google Drive...%CLR_RESET%
    rmdir /s /q build 2>nul
    mkdir "C:\temp\podstream_build" 2>nul
    mklink /j build "C:\temp\podstream_build" >nul
)

:: 5. Mise a jour des dependances fraichement nettoyees
echo %CLR_CYAN%[INFO] Recuperation des dependances...%CLR_RESET%
call flutter pub get > "%TEMP%\podstream_pub_get.log" 2>&1
if !ERRORLEVEL! NEQ 0 (
    echo %CLR_RED%[ERREUR] La recuperation des dependances a echoue !%CLR_RESET%
    echo %CLR_YELLOW%Dernieres lignes du log d'erreur [%TEMP%\podstream_pub_get.log] :%CLR_RESET%
    powershell -Command "Get-Content '%TEMP%\podstream_pub_get.log' -Tail 20"
    goto :erreur_fin
)

echo.
echo %CLR_CYAN%[1/7] Compilation de verification (flutter build apk)...%CLR_RESET%
call flutter build apk > "%TEMP%\podstream_verify_apk.log" 2>&1
if !ERRORLEVEL! NEQ 0 (
    echo %CLR_RED%[ERREUR] La compilation de verification a echoue !%CLR_RESET%
    echo %CLR_YELLOW%Dernieres lignes du log d'erreur [%TEMP%\podstream_verify_apk.log] :%CLR_RESET%
    powershell -Command "Get-Content '%TEMP%\podstream_verify_apk.log' -Tail 20"
    goto :erreur_fin
)
echo %CLR_GREEN%[SUCCES] Compilation de verification reussie !%CLR_RESET%
echo.

echo %CLR_CYAN%[2/7] Formatage et correction automatique du code...%CLR_RESET%
call dart format . > "%TEMP%\podstream_format.log" 2>&1
if !ERRORLEVEL! NEQ 0 (
    echo %CLR_YELLOW%[ATTENTION] Des fichiers n'ont pas pu etre formates.%CLR_RESET%
)
call dart fix --apply > "%TEMP%\podstream_fix.log" 2>&1
if !ERRORLEVEL! NEQ 0 (
    echo %CLR_YELLOW%[ATTENTION] Des corrections automatiques ont echoue.%CLR_RESET%
)
echo %CLR_GREEN%[SUCCES] Formatage et corrections automatiques termines.%CLR_RESET%
echo.

echo %CLR_CYAN%[3/7] Lancement de l'analyse statique (flutter analyze)...%CLR_RESET%
call flutter analyze > "%TEMP%\podstream_analyze.log" 2>&1
if !ERRORLEVEL! NEQ 0 (
    echo %CLR_RED%[ERREUR] Des problemes d'analyse statique ont ete trouves !%CLR_RESET%
    echo %CLR_YELLOW%Dernieres lignes du log d'erreur [%TEMP%\podstream_analyze.log] :%CLR_RESET%
    powershell -Command "Get-Content '%TEMP%\podstream_analyze.log' -Tail 20"
    goto :erreur_fin
)
echo %CLR_GREEN%[SUCCES] Analyse statique reussie (aucune erreur ni avertissement) !%CLR_RESET%
echo.

echo %CLR_CYAN%[4/7] Lancement des tests (flutter test)...%CLR_RESET%
call flutter test > "%TEMP%\podstream_test.log" 2>&1
if !ERRORLEVEL! NEQ 0 (
    echo %CLR_RED%[ERREUR] Un ou plusieurs tests ont echoue !%CLR_RESET%
    echo %CLR_YELLOW%Dernieres lignes du log d'erreur [%TEMP%\podstream_test.log] :%CLR_RESET%
    powershell -Command "Get-Content '%TEMP%\podstream_test.log' -Tail 20"
    goto :erreur_fin
)
echo %CLR_GREEN%[SUCCES] Tous les tests unitaires et de widgets sont passes !%CLR_RESET%
echo.

echo %CLR_CYAN%[5/7] Compilation de l'APK Release finale...%CLR_RESET%
call flutter build apk --release > "%TEMP%\podstream_release_apk.log" 2>&1
if !ERRORLEVEL! NEQ 0 (
    echo %CLR_RED%[ERREUR] La compilation de l'APK Release a echoue !%CLR_RESET%
    echo %CLR_YELLOW%Dernieres lignes du log d'erreur [%TEMP%\podstream_release_apk.log] :%CLR_RESET%
    powershell -Command "Get-Content '%TEMP%\podstream_release_apk.log' -Tail 20"
    goto :erreur_fin
)
echo %CLR_GREEN%[SUCCES] APK Release compilee avec succes !%CLR_RESET%
echo.

echo %CLR_CYAN%[6/7] Compilation du bundle Android (AAB Release)...%CLR_RESET%
cd android
call gradlew.bat bundleRelease > "%TEMP%\podstream_release_aab.log" 2>&1
set GRADLE_ERR=!ERRORLEVEL!
cd ..
if !GRADLE_ERR! NEQ 0 (
    echo %CLR_RED%[ERREUR] La compilation du bundle Android AAB a echoue !%CLR_RESET%
    echo %CLR_YELLOW%Dernieres lignes du log d'erreur [%TEMP%\podstream_release_aab.log] :%CLR_RESET%
    powershell -Command "Get-Content '%TEMP%\podstream_release_aab.log' -Tail 20"
    goto :erreur_fin
)
echo %CLR_GREEN%[SUCCES] Bundle Android AAB compile avec succes !%CLR_RESET%
echo.

echo %CLR_CYAN%[7/7] Compilation de l'APK Debug finale...%CLR_RESET%
call flutter build apk --debug > "%TEMP%\podstream_debug_apk.log" 2>&1
if !ERRORLEVEL! NEQ 0 (
    echo %CLR_RED%[ERREUR] La compilation de l'APK Debug a echoue !%CLR_RESET%
    echo %CLR_YELLOW%Dernieres lignes du log d'erreur [%TEMP%\podstream_debug_apk.log] :%CLR_RESET%
    powershell -Command "Get-Content '%TEMP%\podstream_debug_apk.log' -Tail 20"
    goto :erreur_fin
)
echo %CLR_GREEN%[SUCCES] APK Debug compilee avec succes !%CLR_RESET%
echo.

if "%ESC%"=="" (
    color 0A
)
echo ==========================================
echo %CLR_GREEN%%CLR_BOLD%   Verification et compilations terminees avec succes !%CLR_RESET%
echo ==========================================
cd ..
echo.
pause
exit /b 0

:erreur_fin
cd ..
echo.
if "%ESC%"=="" (
    color 0C
)
echo %CLR_RED%%CLR_BOLD%==========================================%CLR_RESET%
echo %CLR_RED%%CLR_BOLD%   [ECHEC] La compilation a du etre stoppee%CLR_RESET%
echo %CLR_RED%%CLR_BOLD%==========================================%CLR_RESET%
echo.
pause
exit /b 1
