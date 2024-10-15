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

# Pfad zur NTUSER.DAT-Datei
$ntuserDatPath = "C:\Users\Default\NTUSER.DAT"

# Temporärer Registrierungspfad
$tempHivePath = "HKLM:\TempHive"

# Laden der NTUSER.DAT in den temporären Hive
reg load HKLM\TempHive $ntuserDatPath

# Setzen der Locale-Werte
$localeSettings = @{
    "sCountry" = "Deutschland"
    "sLanguage" = "Deutsch"
    "sShortDate" = "dd.MM.yyyy"
    "sLongDate" = "dddd, d. MMMM yyyy"
    "sShortTime" = "HH:mm"
    "sTimeFormat" = "HH:mm:ss"
    "sYearMonth" = "MMMM yyyy"
    "iFirstDayOfWeek" = "0"
    "iFirstWeekOfYear" = "2"
    "sDecimal" = ","
    "sThousand" = "."
    "sCurrency" = "€"
    "iCurrDigits" = "2"
    "iNegCurr" = "8"
    "sMonDecimalSep" = ","
    "sMonThousandSep" = "."
    "iDate" = "1"
    "iTime" = "1"
    "iTLZero" = "1"
    "iMeasure" = "0"
    "sNativeDigits" = "0123456789"
    "iDigits" = "2"
    "iNegNumber" = "1"
    "sPositiveSign" = ""
    "sNegativeSign" = "-"
    "s1159" = ""
    "s2359" = ""
}

foreach ($key in $localeSettings.Keys) {
    Set-ItemProperty -Path "$tempHivePath\Control Panel\International" -Name $key -Value $localeSettings[$key]
}

# Entladen des temporären Hive
[gc]::Collect()
reg unload HKLM\TempHive

Write-Host "Die Locale-Einstellungen wurden erfolgreich für alle neuen Benutzer auf Deutsch und 24-Stunden-Format gesetzt."

# Log message for completion
Write-Host "Alle regionalen Einstellungen und Eingabemethoden wurden angewendet." -ForegroundColor Green