# run_compil_monitored.ps1
# Wrapper pour _compil.bat avec monitoring, heartbeat, logging asynchrone et tail sur erreur.

$logFile = Join-Path $env:TEMP "podstream_compil_monitored.log"
Remove-Item $logFile -ErrorAction SilentlyContinue

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   Compilateur Monitoré - PodStream" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "[INFO] Journalisation vers : $logFile" -ForegroundColor Gray
Write-Host "[INFO] Lancement de la compilation..." -ForegroundColor Cyan

# Lancement du script de compilation en arrière-plan en redirigeant la sortie standard et d'erreur via CMD
$process = Start-Process cmd.exe -ArgumentList "/c _compil.bat < NUL > `"$logFile`" 2>&1" -NoNewWindow -PassThru

$elapsed = 0
$timeout = 600 # Limite de 10 minutes
$checkInterval = 5 # Vérification toutes les 5 secondes
$heartbeatInterval = 15 # Message toutes les 15 secondes après 60s

while (-not $process.HasExited) {
    Start-Sleep -Seconds $checkInterval
    $elapsed += $checkInterval
    
    # Affichage du Heartbeat si le traitement dépasse 60 secondes
    if ($elapsed -ge 60 -and ($elapsed % $heartbeatInterval -eq 0)) {
        Write-Host "Travail en cours... [$elapsed secondes écoulées]" -ForegroundColor Yellow
    }
    
    # Gestion du timeout de sécurité
    if ($elapsed -ge $timeout) {
        Write-Host "[ERREUR] Timeout de 10 minutes dépassé ! Arrêt du processus." -ForegroundColor Red
        Stop-Process -Id $process.Id -Force
        break
    }
}

# Analyse du résultat de l'exécution
if ($process.ExitCode -ne 0) {
    Write-Host ""
    Write-Host "[ERREUR] La compilation a échoué avec le code de sortie : $($process.ExitCode)" -ForegroundColor Red
    Write-Host "------------------------------------------" -ForegroundColor Yellow
    Write-Host "Dernières lignes du journal d'erreur :" -ForegroundColor Yellow
    Write-Host "------------------------------------------" -ForegroundColor Yellow
    if (Test-Path $logFile) {
        Get-Content $logFile -Tail 25 | ForEach-Object { Write-Host $_ -ForegroundColor Red }
    } else {
        Write-Host "Fichier de log introuvable." -ForegroundColor Red
    }
    Write-Host "------------------------------------------" -ForegroundColor Yellow
    exit $process.ExitCode
} else {
    Write-Host ""
    Write-Host "[SUCCÈS] La compilation et les tests ont réussi en $elapsed secondes !" -ForegroundColor Green
}
