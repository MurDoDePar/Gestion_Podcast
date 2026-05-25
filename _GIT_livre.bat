@echo off
setlocal
echo === Livraison sur GitHub ===

:: 1. Recuperation de la version
for /f "usebackq tokens=*" %%a in (`powershell -Command "(Get-Content version.json | ConvertFrom-Json).version"`) do set APP_VERSION=%%a
for /f "usebackq tokens=*" %%a in (`powershell -Command "(Get-Content version.json | ConvertFrom-Json).release_notes"`) do set APP_RELEASE_NOTES=%%a
echo Version detectee : %APP_VERSION%

:: 2. Nettoyage de l'index Git (Fixe l'erreur de "Filename too long")
echo [+] Nettoyage de l'index pour appliquer le .gitignore...
git rm -r --cached .

:: 3. Ajout des fichiers
echo [+] Ajout des fichiers...
git add .

:: 4. Commit
echo [+] Commit...
git commit -m "Livraison version %APP_VERSION% - %APP_RELEASE_NOTES%"

:: 5. Tag et Push
echo [+] Tag de la version...
git tag -a v%APP_VERSION% -m "Version %APP_VERSION% - %APP_RELEASE_NOTES%"

echo [+] Push vers GitHub...
git push -u origin main
git push origin v%APP_VERSION%

echo.
echo === Livraison Terminee avec succes ! ===
pause