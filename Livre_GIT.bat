@echo off
echo === Livraison sur GitHub ===

: --- CONFIGURATION ---
set REPO_URL=https://github.com/MurDoDePar/Gestion_Podcast.git
set USER_NAME=MurDoDePar
set USER_EMAIL=dominique.mura@gmail.com
set BRANCH=main

echo ======================================================
echo   CONFIGURATION ET LIVRAISON : %USER_NAME%
echo ======================================================

:: Configuration de l'identité Git (évite les erreurs de commit)
echo [+] Configuration de l'identite...
git config --global user.name "%USER_NAME%"
git config --global user.email "%USER_EMAIL%"

echo Ajout des fichiers...
git add .

echo Commit...
git commit -m "Livraison version 1.2"

echo Tag de la version...
git tag -a v1.2 -m "Version 1.2"

echo Configuration du remote GitHub...
git remote remove origin 2>nul
git remote add origin https://github.com/MurDoDePar/Gestion_Podcast.git

echo Push vers GitHub...
git branch -M main
git push -u origin main
git push origin v1.2

echo.
echo === Termine ! ===
pause
