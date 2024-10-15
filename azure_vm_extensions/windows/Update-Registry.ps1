param (
    [Parameter(Mandatory=$true)]
    [string]$ExtensionName,  # Der Name der Erweiterung
    
    [Parameter(Mandatory=$true)]
    [string]$Version,  # Die Versionsnummer der Erweiterung
    
    [bool]$Success  # Ob das Skript erfolgreich war
)

# Erstelle den Schlüssel "serverstart" im Registry-Pfad "HKLM:\SOFTWARE", falls dieser noch nicht existiert
New-Item -Path "HKLM:\SOFTWARE" -Name "serverstart" -ErrorAction Ignore | Out-Null

# Erstelle den Schlüssel "VmExtensions" unter "serverstart" im Registry-Pfad, falls dieser noch nicht existiert
New-Item -Path "HKLM:\SOFTWARE\serverstart" -Name "VmExtensions" -ErrorAction Ignore | Out-Null

# Erstelle den Schlüssel für die spezifische Erweiterung unter "VmExtensions", falls dieser noch nicht existiert
New-Item -Path "HKLM:\SOFTWARE\serverstart\VmExtensions" -Name $ExtensionName -ErrorAction Ignore | Out-Null

# Setze den aktuellen Zeitstempel
$CurrentTimestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"

# Füge oder aktualisiere die Eigenschaft "last_run_at" mit dem aktuellen Zeitstempel
New-ItemProperty -Path "HKLM:\SOFTWARE\serverstart\VmExtensions\$ExtensionName" -Name "last_run_at" -Value $CurrentTimestamp -Force | Out-Null

# Überprüfen, ob das Skript erfolgreich war
if ($Success) {
    # Füge oder aktualisiere die Eigenschaft "version" mit dem angegebenen Wert
    New-ItemProperty -Path "HKLM:\SOFTWARE\serverstart\VmExtensions\$ExtensionName" -Name "version" -Value $Version -Force | Out-Null
    
    # Füge oder aktualisiere die Eigenschaft "last_successful_run_at" mit dem aktuellen Zeitstempel
    New-ItemProperty -Path "HKLM:\SOFTWARE\serverstart\VmExtensions\$ExtensionName" -Name "last_successful_run_at" -Value $CurrentTimestamp -Force | Out-Null
    
    # Entferne den Schlüssel "version_failed", wenn er existiert
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\serverstart\VmExtensions\$ExtensionName" -Name "version_failed" -ErrorAction Ignore | Out-Null
} else {
    # Füge oder aktualisiere die Eigenschaft "version_failed" mit dem angegebenen Wert
    New-ItemProperty -Path "HKLM:\SOFTWARE\serverstart\VmExtensions\$ExtensionName" -Name "version_failed" -Value $Version -Force | Out-Null
}

# Füge oder aktualisiere die Eigenschaft "success" mit dem bool-Wert
New-ItemProperty -Path "HKLM:\SOFTWARE\serverstart\VmExtensions\$ExtensionName" -Name "success" -Value $Success -Force | Out-Null

# Ausgabe zur Bestätigung
Write-Output "Registry keys and properties have been set successfully."
