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

# Load the .DEFAULT registry hive
reg load HKU\.DEFAULT "C:\Users\Default\NTUSER.DAT"

# Set date and time format for the default profile
$registryPath = "HKU\.DEFAULT\Control Panel\International"

if (Test-Path $registryPath) {
    Set-ItemProperty -Path $registryPath -Name "sShortDate" -Value "dd.MM.yyyy"
    Set-ItemProperty -Path $registryPath -Name "sLongDate" -Value "dddd, dd. MMMM yyyy"
    Set-ItemProperty -Path $registryPath -Name "sTimeFormat" -Value "HH:mm:ss"
    Write-Host "Date and time formats for default user profile have been updated."
} else {
    Write-Host "Registry path for default user profile not found."
}

# Unload the .DEFAULT registry hive after making changes
reg unload HKU\.DEFAULT

# Log message for completion
Write-Host "Alle regionalen Einstellungen und Eingabemethoden wurden angewendet." -ForegroundColor Green