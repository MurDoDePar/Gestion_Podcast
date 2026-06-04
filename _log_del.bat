@echo off
setlocal EnableDelayedExpansion
title PodStream - Nettoyage des Logs

:: Initialise la console et active le support virtuel terminal / ANSI
color 07

:: Get ANSI ESC character for modern console coloring
for /F "tokens=1,2 delims=#" %%a in ('"prompt $H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"
set "CLR_RESET=%ESC%[0m"
set "CLR_RED=%ESC%[31m"
set "CLR_YELLOW=%ESC%[33m"

if "%ESC%"=="" (
    set "CLR_RESET="
    set "CLR_RED="
    set "CLR_YELLOW="
)

:: Vérification si Python est installé
python --version >nul 2>&1
if !ERRORLEVEL! NEQ 0 (
    echo %CLR_RED%[ERREUR] Python n'est pas installe ou n'est pas accessible dans le PATH.%CLR_RESET%
    echo Veuillez installer Python ou l'ajouter aux variables d'environnement.
    echo.
    pause
    exit /b 1
)

:: Exécution du script Python de nettoyage, transmettant tous les arguments reçus
python "%~dp0_log_del.py" %*

exit /b !ERRORLEVEL!
