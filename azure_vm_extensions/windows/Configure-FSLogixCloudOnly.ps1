[CmdletBinding()]

param 
( 
    [Parameter(ValuefromPipeline=$true,Mandatory=$true)] [string]$StorageAccountName,
    [Parameter(ValuefromPipeline=$true,Mandatory=$true)] [string]$ProfileShareName,
    [Parameter(ValuefromPipeline=$true,Mandatory=$true)] [string]$ShareSecret
)

# Load serverstart Windows-Toolkit
Invoke-Expression (Invoke-WebRequest "https://raw.githubusercontent.com/serverstart/windows-toolkit/main/bootstrap.ps1" -UseBasicParsing).Content


Write-Host "serverstart managed IT" -ForegroundColor Blue
Write-Host "Configuring FSLogix" -ForegroundColor Blue


###################
#    Variables    #
###################
$FileServer="$($StorageAccountName).file.core.windows.net"
$ProfilePath="\\$($FileServer)\$($ProfileShareName)"

##########
# CMDKEY #
##########

# Create a user string for the cmdkey command
$user="localhost\$($StorageAccountName)"

# Store credentials to access the storage account
cmdkey.exe /add:$FileServer /user:$($user) /pass:$($ShareSecret)

##################################
#    Configure FSLogix Profile   #
##################################

# Source: https://blog.itprocloud.de/Using-FSLogix-file-shares-with-Azure-AD-cloud-identities-in-Azure-Virtual-Desktop-AVD/

Write-Host "serverstart - Configure FSLogix : Configure FSLogix Profile Settings"

# Create Profiles Path
New-Item -Path "HKLM:\SOFTWARE" -Name "FSLogix" -ErrorAction Ignore
New-Item -Path "HKLM:\SOFTWARE\FSLogix" -Name "Profiles" -ErrorAction Ignore

# Purge profiles path
$path = "HKLM:\SOFTWARE\FSLogix\Profiles"

# Get all properties at the specified path
$properties = Get-ItemProperty -Path $path | Select-Object -Property *

# Build XML Source Folder Path
$RedirectXmlSourceFolder = (Get-ServerStartPowerShellAssetsPath) + "\FSLogix"

# Loop through each property and remove it
foreach ($property in $properties.PSObject.Properties) {
    # Skip default properties
    if ($property.Name -ne "PSPath" -and $property.Name -ne "PSParentPath" -and $property.Name -ne "PSChildName" -and $property.Name -ne "PSDrive" -and $property.Name -ne "PSProvider") {
        Remove-ItemProperty -Path $path -Name $property.Name -ErrorAction Ignore
    }
}

Write-Output "All properties in $path have been removed."

# Apply new settings to profiles path4
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "Enabled" -Value 1 -force
#New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "CCDLocations" -Value "type=smb,connectionString=$ProfilePath" -PropertyType MultiString -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "VHDLocations" -Value "$ProfilePath" -PropertyType MultiString -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "ConcurrentUserSessions" -Value 1 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "DeleteLocalProfileWhenVHDShouldApply" -Value 1 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "FlipFlopProfileDirectoryName" -Value 1 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "IsDynamic" -Value 1 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "KeepLocalDir" -Value 0 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "ProfileType" -Value 0 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "SizeInMBs" -Value 20000 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "VolumeType" -Value "VHDX" -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "OutlookCachedMode" -Value 0 -force
#New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "RedirXMLSourceFolder" -Value $RedirectXmlSourceFolder -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "AccessNetworkAsComputerObject" -Value "1" -force


Write-Host "serverstart - Configure FSLogix : Done configuring FSLogix Profile Settings"


################################################
#    Configure Microsoft Defender Exclisions   #
################################################

#Reference: https://learn.microsoft.com/en-us/azure/architecture/example-scenario/wvd/windows-virtual-desktop-fslogix#add-exclusions-for-microsoft-defender-for-cloud-by-using-powershell

Write-Host "serverstart - Configure FSLogix : Adding exclusions for Microsoft Defender"

# Array mit allen auszuschließenden Pfaden
$exclusionPaths = @(
    # FSLogix Treiber und Systemdateien
    "$env:ProgramFiles\FSLogix\Apps\frxdrv.sys",
    "$env:ProgramFiles\FSLogix\Apps\frxdrvvt.sys",
    "$env:ProgramFiles\FSLogix\Apps\frxccd.sys",
    
    # Temporäre VHD(X) Dateien im TEMP-Verzeichnis
    "%TEMP%\*.VHD",
    "%TEMP%\*.VHDX",
    "%TEMP%\*\*.VHD",
    "%TEMP%\*\*.VHDX",
    
    # Temporäre VHD(X) Dateien im Windows TEMP-Verzeichnis
    "%Windir%\TEMP\*.VHD",
    "%Windir%\TEMP\*.VHDX",
    "%Windir%\TEMP\*\*.VHD",
    "%Windir%\TEMP\*\*.VHDX",
    
    # Cloud Cache spezifische Ausschlüsse
    "%ProgramData%\FSLogix\Cache\*",
    "%ProgramData%\FSLogix\Proxy\*"
)

# Netzwerkpfade für VHD(X)-Dateien
$networkPaths = @(
    "$ProfilePath\*\*.VHD",
    "$ProfilePath\*\*.VHD.lock",
    "$ProfilePath\*\*.VHD.meta",
    "$ProfilePath\*\*.VHD.metadata",
    "$ProfilePath\*\*.VHDX",
    "$ProfilePath\*\*.VHDX.lock",
    "$ProfilePath\*\*.VHDX.meta",
    "$ProfilePath\*\*.VHDX.metadata"
)

# Array mit allen auszuschließenden Prozessen
$exclusionProcesses = @(
    "$env:ProgramFiles\FSLogix\Apps\fxccd.exe",
    "$env:ProgramFiles\FSLogix\Apps\frxced.exe",
    "$env:ProgramFiles\FSLogix\Apps\frxsvc.exe"
)

# Füge jeden Pfad zu den Windows Defender Ausschlüssen hinzu
Write-Host "Füge lokale Pfadausschlüsse hinzu..." -ForegroundColor Yellow
foreach ($path in $exclusionPaths) {
    try {
        Add-MpPreference -ExclusionPath $path
        Write-Host "Erfolgreich hinzugefügt: $path" -ForegroundColor Green
    }
    catch {
        Write-Host "Fehler beim Hinzufügen von $path : $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nFüge Netzwerkpfadausschlüsse hinzu..." -ForegroundColor Yellow
foreach ($path in $networkPaths) {
    try {
        Add-MpPreference -ExclusionPath $path
        Write-Host "Erfolgreich hinzugefügt: $path" -ForegroundColor Green
    }
    catch {
        Write-Host "Fehler beim Hinzufügen von $path : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Füge jeden Prozess zu den Windows Defender Ausschlüssen hinzu
Write-Host "`nFüge Prozessausschlüsse hinzu..." -ForegroundColor Yellow
foreach ($process in $exclusionProcesses) {
    try {
        Add-MpPreference -ExclusionProcess $process
        Write-Host "Erfolgreich hinzugefügt: $process" -ForegroundColor Green
    }
    catch {
        Write-Host "Fehler beim Hinzufügen von $process : $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nAlle Ausschlüsse wurden verarbeitet." -ForegroundColor Yellow
Write-Host "`nAktuelle Pfadausschlüsse:" -ForegroundColor Yellow
Get-MpPreference | Select-Object -ExpandProperty ExclusionPath

Write-Host "`nAktuelle Prozessausschlüsse:" -ForegroundColor Yellow
Get-MpPreference | Select-Object -ExpandProperty ExclusionProcess

Write-Host "serverstart - Configure FSLogix : Finished adding exclusions for Microsoft Defender"

################################## 
# Configure FSLogix Exclude List #
##################################

$users = @(
    "Administrator",
    "ServerstartAdmin"
)

$groups = @(
    "FSLogix Profile Exclude List",
    "FSLogix ODFC Exclude List"
)

foreach ($group in $groups) {
    Write-Host "`nBearbeite Gruppe: $group" -ForegroundColor Cyan
    
    if (-not (Get-LocalGroup -Name $group -ErrorAction SilentlyContinue)) {
        Write-Host "Info: Gruppe existiert nicht"
        continue
    }
    
    foreach ($user in $users) {
        try {
            $localUser = Get-LocalUser -Name $user -ErrorAction Stop
            $groupMembers = Get-LocalGroupMember -Group $group
            
            if ($groupMembers.Name -contains "$env:COMPUTERNAME\$user") {
                Write-Host "> Benutzer $user bereits in der Gruppe"
            } else {
                Add-LocalGroupMember -Group $group -Member $user
                Write-Host "> Benutzer $user hinzugefügt"
            }
        } catch [Microsoft.PowerShell.Commands.UserNotFoundException] {
            Write-Host "> Benutzer $user existiert nicht"
        } catch {
            Write-Host "> Fehler bei $user - $($_.Exception.Message)"
        }
    }
}