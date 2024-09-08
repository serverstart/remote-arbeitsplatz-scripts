<#
.SYNOPSIS
Optimiertes Windows Locale Konfigurationsskript
.DESCRIPTION
Dieses Skript konfiguriert die Windows-Locale-Einstellungen mithilfe von PowerShell-Cmdlets und minimalen Registrierungsänderungen.
.PARAMETER LocaleName
Der Name der zu setzenden Locale (z.B. "de-DE" für Deutsch).
.PARAMETER GeoId
Die zu setzende geografische ID (z.B. 94 für Deutschland).
.EXAMPLE
.\Set-WindowsLocale.ps1 -LocaleName "de-DE" -GeoId 94
#>

param(
    [string]$LocaleName = "de-DE",
    [int]$GeoId = 94
)

# Funktion zum Schreiben von Protokollnachrichten
function Write-Log {
    param([string]$Message)
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Message"
}

Write-Log "Starte Windows Locale Konfiguration"

# Importiere notwendige Module
Import-Module International

try {
    # Setze Systemlocale
    Set-WinSystemLocale -SystemLocale $LocaleName
    Write-Log "Systemlocale auf $LocaleName gesetzt"

    # Setze Benutzersprachenliste
    Set-WinUserLanguageList -LanguageList $LocaleName -Force
    Write-Log "Benutzersprachenliste auf $LocaleName gesetzt"

    # Setze geografischen Standort
    Set-WinHomeLocation -GeoId $GeoId
    Write-Log "Geografischer Standort auf $GeoId gesetzt"

    # Setze Windows UI-Sprache
    Set-WinUILanguageOverride -Language $LocaleName
    Write-Log "Windows UI-Sprache auf $LocaleName gesetzt"

    # Setze Kultur
    Set-Culture -CultureInfo $LocaleName
    Write-Log "Kultur auf $LocaleName gesetzt"

    # Überprüfe Einstellungen
    $setSystemLocale = (Get-WinSystemLocale).Name
    $setUserLocale = (Get-WinUserLanguageList)[0].LanguageTag
    $setGeoLocation = (Get-WinHomeLocation).GeoId
    $setCulture = (Get-Culture).Name

    Write-Log "Überprüfung:"
    Write-Log "Systemlocale: $setSystemLocale (Erwartet: $LocaleName)"
    Write-Log "Benutzerlocale: $setUserLocale (Erwartet: $LocaleName)"
    Write-Log "Geografischer Standort: $setGeoLocation (Erwartet: $GeoId)"
    Write-Log "Kultur: $setCulture (Erwartet: $LocaleName)"

    if ($setSystemLocale -eq $LocaleName -and $setUserLocale -eq $LocaleName -and $setGeoLocation -eq $GeoId -and $setCulture -eq $LocaleName) {
        Write-Log "Alle Haupteinstellungen erfolgreich überprüft."
    }
    else {
        Write-Log "Warnung: Einige Einstellungen stimmen nicht mit den erwarteten Werten überein."
    }
}
catch {
    Write-Log "Fehler aufgetreten: $($_.Exception.Message)"
}

Write-Log "Windows Locale Konfiguration abgeschlossen"