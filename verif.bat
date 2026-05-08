@echo off
echo ==========================================
echo    Verification du code PodStream
echo ==========================================
echo.

:: Se deplacer dans le dossier du projet Flutter
cd podcast_app

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
