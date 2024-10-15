# Script to define regional settings on Azure Virtual Machines deployed from the market place
# Locale: German (Germany)
# Author: Adapted by ChatGPT from original script by Alexandre Verkinderen
# Simplified for Azure VM Extension use (no restart, error handling without exit)

# Variables for region and settings
$Locale = "de-DE"
$GeoID = 94
$TimeZone = "W. Europe Standard Time"  # Correct time zone for Western Europe
$InputLanguageID = "0407:00000407"

# Set languages/culture
try {
    Set-WinSystemLocale $Locale
    Set-WinUserLanguageList -LanguageList $Locale -Force
    Set-Culture -CultureInfo $Locale
    Set-WinHomeLocation -GeoId $GeoID
    Set-TimeZone -Id $TimeZone  # Use -Id to set time zone
    Write-Host "Die Regionaleinstellungen wurden erfolgreich angewendet." -ForegroundColor Green
} catch {
    Write-Host "Fehler beim Anwenden der Regionaleinstellungen: $_" -ForegroundColor Red
}

# Apply the input preferences for keyboard layout
try {
    $LanguageList = New-WinUserLanguageList $Locale
    Set-WinUserLanguageList $LanguageList -Force
    Set-WinUILanguageOverride $Locale
    Set-WinDefaultInputMethodOverride -InputTip $InputLanguageID
    Write-Host "Die Tastatureinstellungen wurden erfolgreich angewendet." -ForegroundColor Green
} catch {
    Write-Host "Fehler beim Anwenden der Eingabemethoden: $_" -ForegroundColor Red
}

# Log message for completion
Write-Host "Alle regionalen Einstellungen und Eingabemethoden wurden angewendet." -ForegroundColor Green
