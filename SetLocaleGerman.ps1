<#
.SYNOPSIS
    serverstart AVD-Anpassungen: Setzt deutsches Datumsformat und Spracheinstellungen für AVD Multi-Session-Umgebungen.
.DESCRIPTION
    Konfiguriert Systemgebietsschema, Benutzergebietsschema, Datumsformat und Tastaturlayout auf Deutsch.
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
║                 AVD-Anpassungen: Locale auf Deutsch setzen                 ║
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

    Write-LogHeader "Systemgebietsschema Konfiguration"
    Write-LogStep "Setze Systemgebietsschema auf Deutsch (de-DE)"
    Set-WinSystemLocale de-DE | Out-Null
    Write-LogSuccess "Systemgebietsschema erfolgreich gesetzt"

    Write-LogHeader "Standardbenutzerprofil Konfiguration"
    Write-LogStep "Lade Standardbenutzerprofil (C:\Users\Default\NTUSER.DAT)"
    $DefaultHKEY = "HKU\DEFAULT_USER"
    reg load $DefaultHKEY C:\Users\Default\NTUSER.DAT | Out-Null
    Write-LogSuccess "Standardbenutzerprofil erfolgreich geladen"

    Write-LogStep "Konfiguriere Sprache und Gebietsschema"
    $regSettings = @{
        "LocaleName" = "de-DE"; "sLanguage" = "DEU"; "sCountry" = "Germany"
        "sShortDate" = "dd.MM.yyyy"; "sLongDate" = "dddd, d. MMMM yyyy"
        "sTimeFormat" = "HH:mm:ss"; "sShortTime" = "HH:mm"
    }
    foreach ($key in $regSettings.Keys) {
        reg add "$DefaultHKEY\Control Panel\International" /v $key /t REG_SZ /d $regSettings[$key] /f | Out-Null
    }
    Write-LogSuccess "Sprache und Gebietsschema konfiguriert"

    Write-LogStep "Setze deutsches Tastaturlayout"
    reg add "$DefaultHKEY\Keyboard Layout\Preload" /v "1" /t REG_SZ /d "00000407" /f | Out-Null
    Write-LogSuccess "Deutsches Tastaturlayout gesetzt"

    Write-LogStep "Entlade Standardbenutzerprofil"
    reg unload $DefaultHKEY | Out-Null
    Write-LogSuccess "Standardbenutzerprofil entladen"

    Write-LogHeader "Systemspracheinstellungen"
    Write-LogStep "Setze Systemspracheinstellungen"
    $languageList = New-WinUserLanguageList -Language "de-DE"
    $languageList[0].InputMethodTips.Clear()
    $languageList[0].InputMethodTips.Add('0407:00000407')
    Set-WinUserLanguageList -LanguageList $languageList -Force | Out-Null
    Write-LogSuccess "Systemspracheinstellungen gesetzt"

    Write-LogStep "Setze Willkommensbildschirm-Sprache auf Deutsch"
    Set-WinUILanguageOverride -Language de-DE | Out-Null
    Write-LogSuccess "Willkommensbildschirm-Sprache gesetzt"

    Write-LogHeader "Gruppenrichtlinien Aktualisierung"
    Write-LogStep "Aktualisiere Gruppenrichtlinien"
    gpupdate /force | Out-Null
    Write-LogSuccess "Gruppenrichtlinien aktualisiert"
}
catch {
    Write-LogError "Fehler bei der Ausführung des Skripts"
    Write-LogError $_.Exception.Message
    exit 1
}
finally {
    Show-ScriptSummary
}