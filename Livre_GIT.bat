@echo off
echo === Livraison sur GitHub ===

echo Ajout des fichiers...
git add .

echo Commit...
git commit -m "Mise a jour - Podcast Manager PWA"

echo Configuration du remote GitHub...
git remote remove origin 2>nul
git remote add origin https://github.com/MurDoDePar/Gestion_Podcast.git

echo Push vers GitHub...
git branch -M main
git push -u origin main

echo.
echo === Termine ! ===
pause
