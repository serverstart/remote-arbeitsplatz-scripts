<#
.SYNOPSIS
    serverstart AVD-Anpassungen: Installiert Microsoft OneDrive über Winget und konfiguriert es für AVD.
.DESCRIPTION
    Lädt das Winget-Install-Skript herunter, führt es aus, um Microsoft OneDrive zu installieren,
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
║       Microsoft OneDrive Installation und Konfiguration für AVD            ║
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

    # Variablen definieren
    $oneDriveSetupUrl = "https://go.microsoft.com/fwlink/p/?LinkId=844652"
    $oneDriveSetupPath = "$($env:TEMP)\OneDriveSetup.exe"
    $wingetInstallScriptUrl = "https://raw.githubusercontent.com/Romanitho/Winget-Install/main/winget-install.ps1"
    $wingetInstallScriptPath = "$env:TEMP\winget-install.ps1"

    # Alte OneDrive-Versionen deinstallieren
    Write-LogHeader "Alte OneDrive-Versionen deinstallieren"

    Write-LogStep "OneDrive Setup herunterladen, um Setup-Funktion zum Deinstallieren zu nutzen..."
    Invoke-WebRequest -Uri $oneDriveSetupUrl -OutFile $oneDriveSetupPath
    Write-LogSuccess "Setup heruntergeladen"

    Write-LogStep "Über OneDriveSetup.exe deinstallieren..."
    Start-Process -FilePath $oneDriveSetupPath -Wait -ArgumentList "/silent /uninstall" -ErrorAction SilentlyContinue
    Write-LogSuccess "Alte Version deinstalliert"

    # Registrierungseinträge hinzufügen
    Write-LogHeader "Registrierungseinträge für AVD hinzufügen"

    Write-LogStep "Erstelle Registrierungsschlüssel für OneDrive..."
    New-Item -Path "HKLM:\SOFTWARE\Microsoft" -Name "OneDrive" -Force -ErrorAction Ignore

    Write-LogStep "Setze AllUsersInstall..."
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\OneDrive" -Name "AllUsersInstall" -PropertyType DWord -Value 1 -Force

    Write-LogStep "Erstelle Policy-Registrierungsschlüssel für OneDrive..."
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft" -Name "OneDrive" -Force -ErrorAction Ignore

    Write-LogStep "Setze SilentAccountConfig..."
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive" -Name "SilentAccountConfig" -PropertyType DWord -Value 1 -Force

    Write-LogStep "Setze OneDrive Background Run on signin..."
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -PropertyType String -Value "C:\Program Files\Microsoft OneDrive\OneDrive.exe /background" -Force
    Write-LogSuccess "Registrierungseinträge erfolgreich hinzugefügt"

    # Winget-Install-Skript herunterladen und ausführen
    Write-LogHeader "Winget-Install Skript herunterladen"
    
    Invoke-WebRequest -Uri $wingetInstallScriptUrl -OutFile $wingetInstallScriptPath -UseBasicParsing
    Write-LogSuccess "Winget-Install Skript erfolgreich heruntergeladen"

    Write-LogHeader "OneDrive Installation Ausführen"
    Write-LogStep "Führe Winget-Install-Skript aus und installiere Microsoft OneDrive..."
    & $wingetInstallScriptPath -AppIDs Microsoft.OneDrive

    Write-LogSuccess "Winget-Install-Skript wurde ausgeführt. Überprüfen Sie bitte manuell, ob Microsoft OneDrive erfolgreich installiert wurde."

    # Aufräumen: Temporäre Dateien löschen
    Remove-Item $wingetInstallScriptPath -ErrorAction SilentlyContinue
    Remove-Item $oneDriveSetupPath -ErrorAction SilentlyContinue
    Write-LogSuccess "Temporäre Dateien wurden gelöscht"
}
catch {
    Write-LogError "Fehler bei der Ausführung des Skripts"
    Write-LogError $_.Exception.Message
    exit 1
}
finally {
    Show-ScriptSummary
}