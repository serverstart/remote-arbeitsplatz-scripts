# Datei: ServerStartLogging.ps1
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
function Start-ServerStartLogging {
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
    Show-ServerStartBanner
}

# Funktion zur Überprüfung der Skript-Initialisierung
function Assert-ServerStartInitialized {
    if (-not $script:IsInitialized) {
        throw "Fehler: Logging wurde nicht initialisiert. Bitte Start-ServerStartLogging aufrufen, bevor andere Funktionen verwendet werden."
    }
}

# Funktion zum Schreiben in die Log-Datei
function Write-ServerStartLog {
    param (
        [string]$Message,
        [string]$Type = "INFO"
    )
    Assert-ServerStartInitialized
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Type] $Message"
    Add-Content -Path $script:LogFile -Value $logMessage
}

# Funktion zum Anzeigen des Skript-Banners
function Show-ServerStartBanner {
    Assert-ServerStartInitialized
    $bannerText = @"
serverstart managed IT
$script:ScriptFriendlyName
Datum: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@
    $bannerWidth = ($bannerText -split "`n" | Measure-Object -Property Length -Maximum).Maximum + 4
    $banner = @"
+$('-' * $bannerWidth)+
|$(' ' * $bannerWidth)|
$(($bannerText -split "`n" | ForEach-Object { "| $($_.PadRight($bannerWidth - 2)) |" }) -join "`n")
|$(' ' * $bannerWidth)|
+$('-' * $bannerWidth)+
"@
    Write-Host $banner -ForegroundColor Blue
    Write-ServerStartLog "Skript gestartet: $script:ScriptFriendlyName"
}

# Funktion zum Anzeigen der Skript-Zusammenfassung
function Show-ServerStartSummary {
    Assert-ServerStartInitialized
    $color = if ($LASTEXITCODE -eq 0) { "Green" } else { "Red" }
    $statusMessage = if ($LASTEXITCODE -eq 0) { "Skript-Ausfuehrung ERFOLGREICH beendet" } else { "Skript-Ausfuehrung MIT FEHLERN beendet" }
    
    $summaryText = @"
$statusMessage
Exit Code: $LASTEXITCODE
Endzeit: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@
    $summaryWidth = ($summaryText -split "`n" | Measure-Object -Property Length -Maximum).Maximum + 4
    $summary = @"

+$('-' * $summaryWidth)+
|$(' ' * $summaryWidth)|
$(($summaryText -split "`n" | ForEach-Object { "| $($_.PadRight($summaryWidth - 2)) |" }) -join "`n")
|$(' ' * $summaryWidth)|
+$('-' * $summaryWidth)+
"@
    Write-Host $summary -ForegroundColor $color
    Write-ServerStartLog "Skript beendet: $statusMessage (Exit Code: $LASTEXITCODE)"
}

# Funktion zum Schreiben einer Log-Überschrift
function Write-ServerStartLogHeader {
    param ([string]$Message)
    Assert-ServerStartInitialized
    $header = "`n`n==== $Message ====`n"
    Write-Host $header -ForegroundColor Cyan
    Write-ServerStartLog $Message "HEADER"
}

# Funktion zum Schreiben eines Log-Schritts
function Write-ServerStartLogStep {
    param ([string]$Message)
    Assert-ServerStartInitialized
    Write-Host "> $Message" -ForegroundColor White
    Write-ServerStartLog $Message "STEP"
}

# Funktion zum Schreiben einer Erfolgsmeldung
function Write-ServerStartLogSuccess {
    param ([string]$Message)
    Assert-ServerStartInitialized
    Write-Host "OK $Message`n" -ForegroundColor Green
    Write-ServerStartLog $Message "SUCCESS"
}

# Funktion zum Schreiben einer Fehlermeldung
function Write-ServerStartLogError {
    param ([string]$Message)
    Assert-ServerStartInitialized
    Write-Host "X $Message`n" -ForegroundColor Red
    Write-ServerStartLog $Message "ERROR"
}