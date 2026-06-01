@echo off
setlocal
echo === Livraison sur GitHub ===

:: 1. Recuperation de la version
for /f "usebackq tokens=*" %%a in (`powershell -Command "(Get-Content version.json | ConvertFrom-Json).version"`) do set APP_VERSION=%%a
for /f "usebackq tokens=*" %%a in (`powershell -Command "(Get-Content version.json | ConvertFrom-Json).release_notes"`) do set APP_RELEASE_NOTES=%%a
echo Version detectee : %APP_VERSION%

:: 2. SUPPRIME CETTE LIGNE : git rm -r --cached . 
:: Au lieu de cela, on ajoute simplement les changements
echo [+] Ajout des fichiers...
echo n| git add .

:: 3. Commit
echo [+] Commit...
echo n| git commit -m "Livraison version %APP_VERSION% - %APP_RELEASE_NOTES%"

:: 4. Tag et Push
echo [+] Tag de la version...
echo n| git tag -a v%APP_VERSION% -m "Version %APP_VERSION% - %APP_RELEASE_NOTES%"

echo [+] Push vers GitHub...
echo n| git push -u origin main
echo n| git push origin v%APP_VERSION%

echo.
echo === Livraison Terminee avec succes ! ===
pause