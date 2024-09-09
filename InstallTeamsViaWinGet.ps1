<#
.SYNOPSIS
    serverstart AVD-Anpassungen: Installiert Microsoft Teams über Winget und konfiguriert es für AVD.
.DESCRIPTION
    Lädt das Winget-Install-Skript herunter, führt es aus, um Microsoft Teams zu installieren,
    und fügt dann die notwendigen Registrierungseinträge für AVD-Umgebungen hinzu.
#>

# Log-Helper-Funktionen
function Write-LogHeader($message) {
    Write-Host "`n`n==== $message ====`n" -ForegroundColor Cyan
}

function Write-LogStep($message) {
    Write-Host "> $message" -ForegroundColor White
}

function Write-LogSuccess($message) {
    Write-Host "✓ $message`n" -ForegroundColor Green
}

function Write-LogError($message) {
    Write-Host "✗ $message`n" -ForegroundColor Red
}

function Show-ScriptBanner {
Write-Host @"
╔════════════════════════════════════════════════════════════════════════════╗
║                           serverstart managed IT                           ║
║         Microsoft Teams Installation und Konfiguration für AVD             ║
║                                                                            ║
║                         Datum: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")                         ║
╚════════════════════════════════════════════════════════════════════════════╝
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

try {
    Show-ScriptBanner

    # Registrierungseinträge hinzufügen
    Write-LogHeader "Registrierungseinträge für AVD hinzufügen"
    Write-LogStep "Erstelle Registrierungsschlüssel für Teams..."
    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Teams" -Force
    Write-LogStep "Setze IsWVDEnvironment-Wert..."
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Teams" -Name IsWVDEnvironment -PropertyType DWORD -Value 1 -Force
    Write-LogSuccess "Registrierungseinträge erfolgreich hinzugefügt"

    # Winget-Install-Skript herunterladen
    Write-LogHeader "Winget-Install Skript herunterladen"
    $wingetInstallScriptUrl = "https://raw.githubusercontent.com/Romanitho/Winget-Install/main/winget-install.ps1"
    $wingetInstallScriptPath = "$env:TEMP\winget-install.ps1"

    Invoke-WebRequest -Uri $wingetInstallScriptUrl -OutFile $wingetInstallScriptPath -UseBasicParsing
    Write-LogSuccess "Winget-Install Skript erfolgreich heruntergeladen"

    # Winget-Install-Skript mit dem Argument für Microsoft Teams ausführen
    Write-LogHeader "Teams Installation Ausführen"
    Write-LogStep "Führe Winget-Install-Skript aus und installiere Microsoft Teams..."
    & $wingetInstallScriptPath -AppIDs Microsoft.Teams

    Write-LogSuccess "Winget-Install-Skript wurde ausgeführt. Überprüfen Sie bitte manuell, ob Microsoft Teams erfolgreich installiert wurde."

    # Aufräumen: Temporäre Datei löschen
    Remove-Item $wingetInstallScriptPath -ErrorAction SilentlyContinue
    Write-LogSuccess "Temporäre Skriptdatei wurde gelöscht"
}
catch {
    Write-LogError "Fehler bei der Ausführung des Skripts"
    Write-LogError $_.Exception.Message
    exit 1
}
finally {
    Show-ScriptSummary
}