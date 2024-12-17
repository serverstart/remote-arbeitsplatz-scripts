# ======================================================================
# Azure Virtual Desktop (AVD) Golden Image Localization Script
# Purpose: Sets German regional and language settings for both system and default user profile
# Region: German (Germany)
# ======================================================================

# Region Variables
$Locale = "de-DE"                                    # German culture code
$GeoID = 94                                         # Geographic location ID for Germany
$TimeZone = "W. Europe Standard Time"               # Time zone for Germany/Western Europe
$InputLanguageID = "0407:00000407"                  # German keyboard layout
$LanguageID = "00000407"                           # Windows language ID for German

# ======================================================================
# PART 1: System-Wide Settings
# These settings affect the currently running system
# ======================================================================
try {
    # Set system locale, language, and regional settings
    Set-WinSystemLocale $Locale                     # System locale (for non-Unicode programs)
    Set-WinUserLanguageList -LanguageList $Locale -Force  # Display language
    Set-Culture -CultureInfo $Locale                # User culture settings
    Set-WinHomeLocation -GeoId $GeoID              # Geographic location
    Set-TimeZone -Id $TimeZone                      # Time zone
    Write-Host "1. Systemweite Einstellungen wurden erfolgreich angewendet." -ForegroundColor Green
} catch {
    Write-Host "Fehler bei systemweiten Einstellungen: $_" -ForegroundColor Red
}

# ======================================================================
# PART 2: Input Settings
# Configure keyboard and input method settings
# ======================================================================
try {
    $LanguageList = New-WinUserLanguageList $Locale
    Set-WinUserLanguageList $LanguageList -Force     # Set language list
    Set-WinUILanguageOverride $Locale                # Override UI language
    Set-WinDefaultInputMethodOverride -InputTip $InputLanguageID  # Set keyboard layout
    Write-Host "2. Eingabe- und Tastatureinstellungen wurden erfolgreich angewendet." -ForegroundColor Green
} catch {
    Write-Host "Fehler bei Eingabeeinstellungen: $_" -ForegroundColor Red
}

# ======================================================================
# PART 3: Default User Profile Settings
# These settings will apply to any new user profile created on the system
# Critical for AVD as each user gets a new profile on first login
# ======================================================================

# Path definitions
$ntuserDatPath = "C:\Users\Default\NTUSER.DAT"      # Default user profile registry hive
$tempHivePath = "HKLM:\TempHive"                    # Temporary mounting point

# Mount the default user registry hive
reg load HKLM\TempHive $ntuserDatPath

# Detailed locale settings for new user profiles
$localeSettings = @{
    # Regional format settings
    "sCountry" = "Deutschland"
    "sLanguage" = "Deutsch"
    
    # Date formats
    "sShortDate" = "dd.MM.yyyy"
    "sLongDate" = "dddd, d. MMMM yyyy"
    "sYearMonth" = "MMMM yyyy"
    
    # Time formats
    "sShortTime" = "HH:mm"
    "sTimeFormat" = "HH:mm:ss"
    "s1159" = ""                                    # AM symbol (empty for 24h format)
    "s2359" = ""                                    # PM symbol (empty for 24h format)
    
    # Calendar settings
    "iFirstDayOfWeek" = "0"                        # Monday
    "iFirstWeekOfYear" = "2"                       # First week with 4 days
    
    # Number formats
    "sDecimal" = ","                               # Decimal separator
    "sThousand" = "."                              # Thousand separator
    "iDigits" = "2"                                # Decimal places
    "sNativeDigits" = "0123456789"
    "iNegNumber" = "1"                             # Negative number format
    "sPositiveSign" = ""
    "sNegativeSign" = "-"
    
    # Currency formats
    "sCurrency" = "€"
    "iCurrDigits" = "2"                           # Currency decimal places
    "iNegCurr" = "8"                              # Negative currency format
    "sMonDecimalSep" = ","
    "sMonThousandSep" = "."
    
    # Measurement
    "iMeasure" = "0"                              # Metric
    
    # Additional settings
    "iDate" = "1"                                 # Date format order
    "iTime" = "1"                                 # Time format
    "iTLZero" = "1"                              # Leading zeros in time
}

# Apply locale settings to default user profile
foreach ($key in $localeSettings.Keys) {
    Set-ItemProperty -Path "$tempHivePath\Control Panel\International" -Name $key -Value $localeSettings[$key]
}

# Additional language settings for default user
Set-ItemProperty -Path "$tempHivePath\Control Panel\International" -Name "Locale" -Value $LanguageID
Set-ItemProperty -Path "$tempHivePath\Control Panel\International" -Name "LocaleName" -Value $Locale
Set-ItemProperty -Path "$tempHivePath\Control Panel\Desktop" -Name "PreferredUILanguages" -Value $Locale

Write-Host "3. Benutzerprofileinstellungen (NTUSER.DAT) wurden erfolgreich angewendet." -ForegroundColor Green

# ======================================================================
# PART 4: System Language Settings
# These affect system-wide language and format settings
# ======================================================================

# Set system-wide language settings
$regPathSystem = "HKLM:\SYSTEM\CurrentControlSet\Control\Nls\Language"
Set-ItemProperty -Path $regPathSystem -Name "Default" -Value $LanguageID
Set-ItemProperty -Path $regPathSystem -Name "InstallLanguage" -Value $LanguageID

# Cleanup: Unload the default user registry hive
[gc]::Collect()
reg unload HKLM\TempHive

Write-Host "4. Systemeinstellungen (HKLM) wurden erfolgreich angewendet." -ForegroundColor Green

Write-Host "`nAlle Lokalisierungseinstellungen wurden erfolgreich abgeschlossen." -ForegroundColor Green
Write-Host "Bitte beachten: Ein Neustart wird empfohlen, um alle Änderungen zu aktivieren." -ForegroundColor Yellow