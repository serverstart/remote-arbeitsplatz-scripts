# Systemstandard Sprache setzen
Set-WinSystemLocale -SystemLocale de-DE

# Benutzersprache für neue Benutzer setzen
$UserLanguageList = New-WinUserLanguageList -Language de-DE
Set-WinDefaultInputMethodOverride -InputTip "0407:00000407"
Set-WinUserLanguageList -LanguageList $UserLanguageList -Force

# Regionale Einstellungen (Land/Region) setzen
Set-WinHomeLocation -GeoId 94  # 94 ist der Code für Deutschland

# Kopieren Sie die Einstellungen in das Standard-Benutzerprofil
Copy-UserInternationalSettingsToSystem -WelcomeScreen $True -NewUser $True

# Optional: Setzen Sie das Regionale Format
Set-Culture -CultureInfo de-DE