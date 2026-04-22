@echo off
echo Arret du serveur (s'il est en cours d'execution)...

:: Recherche et tue le processus qui utilise le port 3000
FOR /F "tokens=5" %%T IN ('netstat -a -n -o ^| findstr :3000') DO (
    taskkill /pid %%T /f >nul 2>&1
)

echo Lancement du serveur...
cmd /c npx serve www
