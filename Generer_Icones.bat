@echo off
chcp 65001 >nul
title PodStream - Génération des icônes Android

echo.
echo ╔══════════════════════════════════════════════════════╗
echo ║       PODSTREAM — GÉNÉRATION DES ICÔNES              ║
echo ╚══════════════════════════════════════════════════════╝
echo.

set ROOT=%~dp0
set ICON_SRC=%ROOT%www\icon.svg
set RES_DIR=%ROOT%android\app\src\main\res

:: Vérifier si ImageMagick est disponible
where magick >nul 2>&1
if errorlevel 1 (
    echo  ⚠  ImageMagick non détecté.
    echo.
    echo  Pour générer les icônes automatiquement, installez ImageMagick :
    echo     https://imagemagick.org/script/download.php#windows
    echo.
    echo  Alternative rapide : utilisez Android Studio
    echo     1. Ouvrez le projet android/ dans Android Studio
    echo     2. Clic droit sur res/ → New → Image Asset
    echo     3. Choisissez votre fichier icon.svg ou icon.png
    echo     4. Android Studio génère toutes les tailles automatiquement
    echo.
    echo  Votre icône source est : %ICON_SRC%
    echo.
    pause
    exit /b 1
)

echo  ✔ ImageMagick détecté
echo.
echo  Génération des icônes dans toutes les résolutions...
echo.

:: Tailles requises par Android
:: mdpi = 48px, hdpi = 72px, xhdpi = 96px, xxhdpi = 144px, xxxhdpi = 192px

magick "%ICON_SRC%" -resize 48x48  "%RES_DIR%\mipmap-mdpi\ic_launcher.png"
magick "%ICON_SRC%" -resize 48x48  "%RES_DIR%\mipmap-mdpi\ic_launcher_round.png"
magick "%ICON_SRC%" -resize 72x72  "%RES_DIR%\mipmap-hdpi\ic_launcher.png"
magick "%ICON_SRC%" -resize 72x72  "%RES_DIR%\mipmap-hdpi\ic_launcher_round.png"
magick "%ICON_SRC%" -resize 96x96  "%RES_DIR%\mipmap-xhdpi\ic_launcher.png"
magick "%ICON_SRC%" -resize 96x96  "%RES_DIR%\mipmap-xhdpi\ic_launcher_round.png"
magick "%ICON_SRC%" -resize 144x144 "%RES_DIR%\mipmap-xxhdpi\ic_launcher.png"
magick "%ICON_SRC%" -resize 144x144 "%RES_DIR%\mipmap-xxhdpi\ic_launcher_round.png"
magick "%ICON_SRC%" -resize 192x192 "%RES_DIR%\mipmap-xxxhdpi\ic_launcher.png"
magick "%ICON_SRC%" -resize 192x192 "%RES_DIR%\mipmap-xxxhdpi\ic_launcher_round.png"

:: ic_launcher_foreground (avec padding pour adaptive icon)
magick "%ICON_SRC%" -resize 108x108 -gravity center -background none -extent 108x108 "%RES_DIR%\mipmap-mdpi\ic_launcher_foreground.png"
magick "%ICON_SRC%" -resize 162x162 -gravity center -background none -extent 162x162 "%RES_DIR%\mipmap-hdpi\ic_launcher_foreground.png"
magick "%ICON_SRC%" -resize 216x216 -gravity center -background none -extent 216x216 "%RES_DIR%\mipmap-xhdpi\ic_launcher_foreground.png"
magick "%ICON_SRC%" -resize 324x324 -gravity center -background none -extent 324x324 "%RES_DIR%\mipmap-xxhdpi\ic_launcher_foreground.png"
magick "%ICON_SRC%" -resize 432x432 -gravity center -background none -extent 432x432 "%RES_DIR%\mipmap-xxxhdpi\ic_launcher_foreground.png"

if errorlevel 1 (
    echo  ✗ Erreur lors de la génération des icônes.
) else (
    echo  ✔ Toutes les icônes générées avec succès !
    echo.
    echo  Dossier : %RES_DIR%
)

echo.
pause
