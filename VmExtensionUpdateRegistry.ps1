# Definiere die Parameter mit Erklärungen
param (
    [Parameter(Mandatory=$true)]
    [string]$ExtensionName,  # Der Name der Erweiterung
    
    [Parameter(Mandatory=$true)]
    [string]$Version,  # Die Versionsnummer der Erweiterung
    
    [string]$Timestamp = $(Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")  # Der Zeitstempel im RFC3339-Format, optional
)

# Erstelle den Schlüssel "Serverstart" im Registry-Pfad "HKLM:\SOFTWARE", falls dieser noch nicht existiert
New-Item -Path "HKLM:\SOFTWARE" -Name "Serverstart" -ErrorAction Ignore

# Erstelle den Schlüssel "VmExtensions" unter "Serverstart" im Registry-Pfad, falls dieser noch nicht existiert
New-Item -Path "HKLM:\SOFTWARE\Serverstart" -Name "VmExtensions" -ErrorAction Ignore

# Erstelle den Schlüssel für die spezifische Erweiterung unter "VmExtensions", falls dieser noch nicht existiert
New-Item -Path "HKLM:\SOFTWARE\Serverstart\VmExtensions" -Name $ExtensionName -ErrorAction Ignore

# Füge oder aktualisiere die Eigenschaft "version" mit dem angegebenen Wert
New-ItemProperty -Path "HKLM:\SOFTWARE\Serverstart\VmExtensions\$ExtensionName" -Name "version" -Value $Version -Force

# Füge oder aktualisiere die Eigenschaft "deployed_at" mit dem angegebenen Zeitstempel
New-ItemProperty -Path "HKLM:\SOFTWARE\Serverstart\VmExtensions\$ExtensionName" -Name "deployed_at" -Value $Timestamp -Force

# Ausgabe zur Bestätigung
Write-Output "Registry keys and properties have been set successfully."
