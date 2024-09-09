# Datei: SmitLogging.ps1
# Beschreibung: Enthält Funktionen für Logging, Banner-Anzeige und Skript-Initialisierung
# Autor: [Ihr Name]
# Datum: [Aktuelles Datum]

# Importiere notwendige Module
Import-Module Microsoft.PowerShell.Utility

# Definiere Skript-Variablen
$script:LogPath = "C:\ProgramData\Serverstart\Logs"
$script:ScriptName = ""
$script:ScriptFriendlyName = ""
$script:LogFile = ""
$script:IsInitialized = $false

# Funktion zum Initialisieren des Loggings und Anzeigen des Banners
function Start-Logging {
    param (
        [string]$Name,
        [string]$FriendlyName
    )
    $script:ScriptName = $Name
    $script:ScriptFriendlyName = $FriendlyName
    $script:LogFile = Join-Path $LogPath "$Name-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    $script:IsInitialized = $true
    
    # Erstelle Log-Verzeichnis, falls es nicht existiert
    if (-not (Test-Path $LogPath)) {
        New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
    }

    # Zeige den Banner an
    Show-Banner
}

# Funktion zur Überprüfung der Skript-Initialisierung
function Assert-Initialized {
    if (-not $script:IsInitialized) {
        throw "Fehler: Logging wurde nicht initialisiert. Bitte Start-Logging aufrufen, bevor andere Funktionen verwendet werden."
    }
}

# Funktion zum Schreiben in die Log-Datei
function Write-Log {
    param (
        [string]$Message,
        [string]$Type = "INFO"
    )
    Assert-Initialized
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Type] $Message"
    Add-Content -Path $script:LogFile -Value $logMessage
}

# Funktion zum Anzeigen des Skript-Banners
function Show-Banner {
    Assert-Initialized
    $bannerText = @"
serverstart managed IT
$script:ScriptFriendlyName
Datum: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@
    $banner = @"
====================
$bannerText
====================
"@
    Write-Host $banner -ForegroundColor Blue
    Write-Log "Skript gestartet: $script:ScriptFriendlyName"
}

# Funktion zum Anzeigen der Skript-Zusammenfassung
function Show-Summary {
    Assert-Initialized
    $color = if ($LASTEXITCODE -eq 0) { "Green" } else { "Red" }
    $statusMessage = if ($LASTEXITCODE -eq 0) { "Skript-Ausfuehrung ERFOLGREICH beendet" } else { "Skript-Ausfuehrung MIT FEHLERN beendet" }
    
    $summaryText = @"
$statusMessage
Exit Code: $LASTEXITCODE
Endzeit: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@
    $summary = @"

====================
$summaryText
====================
"@
    Write-Host $summary -ForegroundColor $color
    Write-Log "Skript beendet: $statusMessage (Exit Code: $LASTEXITCODE)"
}

# Funktion zum Schreiben einer Log-Überschrift
function Write-Section {
    param ([string]$Message)
    Assert-Initialized
    $section = "`n`n==== $Message ====`n"
    Write-Host $section -ForegroundColor Cyan
    Write-Log $Message "SECTION"
}

# Funktion zum Schreiben eines Log-Schritts
function Write-Step {
    param ([string]$Message)
    Assert-Initialized
    Write-Host "> $Message" -ForegroundColor White
    Write-Log $Message "STEP"
}

# Funktion zum Schreiben einer Erfolgsmeldung
function Write-Success {
    param ([string]$Message)
    Assert-Initialized
    Write-Host "OK $Message`n" -ForegroundColor Green
    Write-Log $Message "SUCCESS"
}

# Funktion zum Schreiben einer Fehlermeldung
function Write-Error {
    param ([string]$Message)
    Assert-Initialized
    Write-Host "X $Message`n" -ForegroundColor Red
    Write-Log $Message "ERROR"
}

# Funktion zum Ausführen von Befehlen und Loggen der Ausgabe
function Invoke-LoggedCommand {
    param (
        [string]$Command,
        [string]$Description
    )
    Write-Step $Description
    $output = Invoke-Expression $Command
    $output | ForEach-Object { Write-Log $_ }
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Starte $Description erfolgreich"
    } else {
        Write-Error "$Description fehlgeschlagen (Exit Code: $LASTEXITCODE)"
    }
}

# Funktion zum Überprüfen und Initialisieren von WinGet
function Get-WinGetInstallScriptPath {
    Write-Step "Suche WinGet-Installation…"
    $wingetInstallScriptPath = "C:\ProgramData\Winget-AutoUpdate\Winget-install.ps1"
    
    # Überprüfen, ob das Winget-Install-Skript existiert
    if (-not (Test-Path $wingetInstallScriptPath)) {
        Write-Error "Die Datei 'Winget-install.ps1' wurde nicht im Verzeichnis 'C:\ProgramData\Winget-AutoUpdate' gefunden."
        return $null
    }
    
    Write-Success "WinGet gefunden."
    return $wingetInstallScriptPath
}