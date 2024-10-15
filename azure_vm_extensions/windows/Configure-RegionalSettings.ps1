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

$LocaleSettings = @"
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Control Panel\International]
"Locale"="00000407"
"sShortDate"="dd.MM.yyyy"
"sDate"="."
"sLongDate"="dddd, d. MMMM yyyy"
"sTime"="HH:mm:ss"
"s1159"=""
"s2359"=""
"sTimeFormat"="HH:mm:ss"
"iCountry"="49"
"iDate"="1"
"iTime"="1"
"iTLZero"="1"
"iCurrency"="3"
"iNegCurr"="1"
"sCurrency"="€"
"sMonDecimalSep"=","
"sMonThousandSep"="."
"iDigits"="2"
"iLZero"="1"
"sDecimal"=","
"sThousand"="."
"iMeasure"="0"
"iPaperSize"="9"
"iDefaultUILanguage"="1031"
"iLangID"="1031"
"LocaleName"="de-DE"
"@
  
# Default Profile:
Write-Verbose ('Writing registry values for profile: DEFAULT') -Verbose
Write-RegistryWithHiveLoad -RegFileContents $LocaleSettings -DatFilePath C:\Users\Default\NTUSER.DAT

# Log message for completion
Write-Host "Alle regionalen Einstellungen und Eingabemethoden wurden angewendet." -ForegroundColor Green









function Get-TempRegFilePath {
    (Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath ([guid]::NewGuid().Guid)) + '.reg'
}

function Write-Registry {
    param($RegFileContents, $UserSid)
    
    $TempRegFile = Get-TempRegFilePath
    $regFileContents = $regFileContents -replace 'HKEY_CURRENT_USER', "HKEY_USERS\$userSid"
    $regFileContents | Out-File -FilePath $TempRegFile
    
    $p = Start-Process -FilePath C:\Windows\regedit.exe -ArgumentList @('/s', $TempRegFile) -PassThru
    do { Start-Sleep -Seconds 1 } while (-not $p.HasExited)
    
    Remove-Item -Path $TempRegFile -Force
}

function Write-RegistryWithHiveLoad {
    param($RegFileContents, $DatFilePath)
    
    $hiveName = 'x_' +  ($user = (($datFilePath -split '\\')[-2]).ToUpper())

    try {
        if(-not (IsFileLocked -Path $DatFilePath)) {
            $null = C:\Windows\System32\reg.exe load "HKU\$hiveName" $DatFilePath
            if($LASTEXITCODE -ne 0) { throw 'Error loading the DAT file' }
    
            $TempRegFile = Get-TempRegFilePath
            $regFileContents = $regFileContents -replace 'HKEY_CURRENT_USER', "HKEY_USERS\$hiveName"
            $regFileContents | Out-File -FilePath $TempRegFile

            $p = Start-Process -FilePath C:\Windows\regedit.exe -ArgumentList @('/s', $TempRegFile) -PassThru
            do { Start-Sleep -Seconds 1 } while (-not $p.HasExited)

            $null = C:\Windows\System32\reg.exe unload "HKU\$hiveName"

            Remove-Item -Path $TempRegFile -Force
        } else {
            Write-Verbose ('Skipped user {0}. File {1} is locked by another process' -f $user, $DatFilePath) -Verbose
        }
    } catch {
        Write-Verbose $_.Exception.Message -Verbose
    }
}

function IsFileLocked {
    param([string]$Path)

    [bool] $isFileLocked = $true
    $file = $null

    try {
        $file = [IO.File]::Open(
            $Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::None
        )
        $isFileLocked = $false
    } catch [IO.IOException] {
        if ($_.Exception.Message -notmatch 'used by another process') {
            throw $_.Exception
        }
    } finally {
        if ($null -ne $file) {
            $file.Close()
        }
    }
    $isFileLocked
}
