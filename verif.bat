@echo off
echo ==========================================
echo    Verification du code PodStream
echo ==========================================
echo.

:: Se deplacer dans le dossier du projet Flutter
cd podcast_app

echo [1/3] Formatage et correction automatique du code...
call dart format .
call dart fix --apply
echo.

echo [2/3] Lancement de l'analyse statique (flutter analyze)...
call flutter analyze
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERREUR] Des problemes de syntaxe ou d'analyse ont ete trouves.
    echo Veuillez les corriger avant de continuer.
    goto :fin
)
echo [SUCCES] Aucune erreur de syntaxe trouvee !
echo.

echo [3/3] Lancement des tests (flutter test)...
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
