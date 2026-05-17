@echo off
echo ===========================================
echo Installation de PodStream (Debug - Pixel 8)
echo ===========================================
echo.

cd podcast_app

echo 1. Desinstallation de l'ancienne version...
"%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" uninstall com.podstream

echo.
echo 2. Copie de l'APK dans le dossier securise du Pixel...
"%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" push "C:\temp\podstream_build\app\outputs\flutter-apk\app-debug.apk" /data/local/tmp/app-debug.apk
if %errorlevel% neq 0 goto :erreur

echo.
echo 3. Ajustement des permissions du fichier...
"%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" shell chmod 777 /data/local/tmp/app-debug.apk

echo.
echo 4. Installation locale (Contournement SELinux)...
"%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" shell pm install -r -d -t /data/local/tmp/app-debug.apk
if %errorlevel% neq 0 goto :erreur

echo.
echo 5. Nettoyage du fichier temporaire sur le telephone...
"%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" shell rm /data/local/tmp/app-debug.apk

echo.
echo ===========================================
echo [SUCCES] Installation Debug terminee !
echo ===========================================
goto :fin

:erreur
echo.
echo [ERREUR] L'installation a echoue. Verifiez le cable et l'ecran du Pixel 8.
echo Nettoyage du fichier temporaire par securite...
"%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" shell rm /data/local/tmp/app-debug.apk >nul 2>&1

:fin
cd ..
pause