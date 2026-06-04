@echo off
echo ===========================================
echo Installation de PodStream (Release - Pixel 8)
echo ===========================================
echo.

cd podcast_app

echo.
echo 1. kill-server...
"%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" kill-server

echo.
echo 2. devices
"%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" devices

echo.
echo 3. Copie de l'APK dans le dossier securise du Pixel...
"%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" push "C:\temp\podstream_build\app\outputs\flutter-apk\app-release.apk" /data/local/tmp/app-release.apk
if %errorlevel% neq 0 goto :erreur

echo.
echo 4. Ajustement des permissions du fichier...
"%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" shell chmod 777 /data/local/tmp/app-release.apk

echo.
echo 5. Installation locale (Contournement SELinux)...
"%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" shell pm install -r -d /data/local/tmp/app-release.apk
if %errorlevel% neq 0 goto :erreur

echo.
echo 6. Nettoyage du fichier temporaire sur le telephone...
"%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" shell rm /data/local/tmp/app-release.apk

echo.
echo ===========================================
echo [SUCCES] Installation Release terminee !
echo ===========================================
goto :fin

:erreur
echo.
echo [ERREUR] L'installation a echoue.
echo - Verifiez le cable USB et que l'ecran du Pixel 8 est deverrouille.
echo - Si l'application etait deja installee via Google Play ou avec une autre cle de signature,
echo   l'installation echouera en raison d'un conflit de signature. Dans ce cas, vous devez d'abord
echo   desinstaller manuellement l'ancienne version (Attention : cela supprimera vos donnees locales).
echo Nettoyage du fichier temporaire par securite...
"%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" shell rm /data/local/tmp/app-release.apk >nul 2>&1

:fin
cd ..
pause