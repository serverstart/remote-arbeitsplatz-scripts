
function Write-LogHeader($message) {
    Write-Host "`n`n==== $message ====`n" -ForegroundColor Cyan
}

function Write-LogStep($message) {
    Write-Host "> $message" -ForegroundColor White
}

function Write-LogSuccess($message) {
    Write-Host "OK $message`n" -ForegroundColor Green
}

function Write-LogError($message) {
    Write-Host "X $message`n" -ForegroundColor Red
}

function Show-ScriptBanner {
    Write-Host @"
+----------------------------------------------------------------------------+
|                           serverstart managed IT                           |
|       Microsoft OneDrive Installation und Konfiguration für AVD            |
|                                                                            |
|                         Datum: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")                         |
+----------------------------------------------------------------------------+
"@ -ForegroundColor Blue
}

function Show-ScriptSummary {
    $color = if ($LASTEXITCODE -eq 0) { "Green" } else { "Red" }
    $statusMessage = if ($LASTEXITCODE -eq 0) { "Skript-Ausführung ERFOLGREICH beendet" } else { "Skript-Ausführung MIT FEHLERN beendet" }
    
    Write-Host @"

╔════════════════════════════════════════════════════════════════════════════╗
║                   $statusMessage                    ║
║                                                                            ║
║                                Exit Code: $LASTEXITCODE                                ║
║                        Endzeit: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")                        ║
╚════════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor $color
}