@echo off
echo ===========================================
echo Compilation et Installation de PodStream
echo ===========================================

cd podcast_app

echo.
echo 1. Compilation de l'APK (Release)...
call flutter build apk --release
if %errorlevel% neq 0 (
    echo.
    echo Erreur lors de la compilation.
    pause
    exit /b %errorlevel%
)

echo.
echo 2. Installation sur l'appareil connecte...
call flutter install
if %errorlevel% neq 0 (
    echo.
    echo Erreur lors de l'installation. Assurez-vous que le telephone est bien connecte en USB, deverrouille, et que le debogage USB est active.
    pause
    exit /b %errorlevel%
)

echo.
echo Installation terminee avec succes !
pause
