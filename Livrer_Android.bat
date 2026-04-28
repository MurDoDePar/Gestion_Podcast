@echo off
setlocal enabledelayedexpansion
title PodStream - Livraison Android

echo.
echo ======================================================
echo     PODSTREAM -- LIVRAISON GOOGLE PLAY
echo ======================================================
echo.

:: ---------------------------------------------------------
:: CONFIGURATION
:: ---------------------------------------------------------
set JAVA_HOME=C:\Program Files\Android\Android Studio\jbr
set ROOT=%~dp0
set ANDROID_DIR=%ROOT%android
set KEYSTORE_FILE=%ROOT%podstream-release.jks
set KEYSTORE_PROPS=%ANDROID_DIR%\keystore.properties
set OUTPUT_AAB=%ANDROID_DIR%\app\build\outputs\bundle\release\app-release.aab

:: ---------------------------------------------------------
:: ETAPE 0 -- Verification du keystore
:: ---------------------------------------------------------
echo [1/4] Verification du keystore de signature...

if not exist "%KEYSTORE_FILE%" (
    echo.
    echo  ATTENTION : Keystore introuvable : podstream-release.jks
    echo.
    echo  Creation d'un nouveau keystore...
    echo  Repondez aux questions qui vont apparaitre.
    echo.
    keytool -genkeypair -v ^
        -keystore "%KEYSTORE_FILE%" ^
        -keyalg RSA -keysize 2048 ^
        -validity 10000 ^
        -alias podstream
    if errorlevel 1 (
        echo.
        echo  ECHEC de la creation du keystore.
        echo  Assurez-vous que JDK est installe.
        echo  Telechargez JDK 17 : https://adoptium.net/
        pause
        exit /b 1
    )
    echo.
    echo  OK : Keystore cree avec succes !
    echo.
)

:: Verification de keystore.properties
if not exist "%KEYSTORE_PROPS%" (
    echo.
    echo  ERREUR : Fichier manquant : android\keystore.properties
    echo  Veuillez creer ce fichier avec vos mots de passe.
    pause
    exit /b 1
)

:: Verification que les mots de passe ont ete configures
findstr /C:"VOTRE_MOT_DE_PASSE" "%KEYSTORE_PROPS%" >nul
if not errorlevel 1 (
    echo.
    echo  ARRET -- Les mots de passe dans keystore.properties n'ont pas ete configures !
    echo.
    echo  Ouvrez le fichier :
    echo    %KEYSTORE_PROPS%
    echo.
    echo  Et remplacez les valeurs :
    echo    storePassword=VOTRE_MOT_DE_PASSE_KEYSTORE
    echo    keyPassword=VOTRE_MOT_DE_PASSE_CLE
    echo.
    start notepad "%KEYSTORE_PROPS%"
    pause
    exit /b 1
)

echo  OK : Keystore configure
echo.

:: ---------------------------------------------------------
:: ETAPE 1 -- Synchronisation Web -> Android
:: ---------------------------------------------------------
echo [2/4] Synchronisation des fichiers web vers Android...
cd /d "%ROOT%"
call npx cap sync android
if errorlevel 1 (
    echo  ECHEC de la synchronisation Capacitor.
    pause
    exit /b 1
)
echo  OK : Synchronisation terminee
echo.

:: ---------------------------------------------------------
:: ETAPE 2 -- Build du AAB Release
:: ---------------------------------------------------------
echo [3/4] Compilation du bundle Android (AAB Release)...
cd /d "%ANDROID_DIR%"
call gradlew.bat bundleRelease
if errorlevel 1 (
    echo.
    echo  ECHEC de la compilation Gradle.
    echo  Consultez les erreurs ci-dessus.
    pause
    exit /b 1
)
echo  OK : Compilation terminee
echo.

:: ---------------------------------------------------------
:: ETAPE 3 -- Resultat
:: ---------------------------------------------------------
echo [4/4] Verification du fichier de sortie...

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
    explorer "%ANDROID_DIR%\app\build\outputs\bundle\release"
) else (
    echo  ERREUR : Fichier AAB non trouve.
    echo  Verifiez les erreurs de compilation ci-dessus.
)

echo.
pause
