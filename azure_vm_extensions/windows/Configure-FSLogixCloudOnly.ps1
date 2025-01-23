[CmdletBinding()]

param 
( 
    [Parameter(ValuefromPipeline=$true,Mandatory=$true)] [string]$StorageAccountName,
    [Parameter(ValuefromPipeline=$true,Mandatory=$true)] [string]$ProfileShareName
)

Write-Host "serverstart managed IT" -ForegroundColor Blue
Write-Host "Configuring FSLogix" -ForegroundColor Blue


#################################################################
#    Access to Azure File shares for FSLogix profiles           #
#################################################################

# Source: https://github.com/Azure/RDS-Templates/blob/master/CustomImageTemplateScripts/CustomImageTemplateScripts_2024-03-27/FSLogixKerberos.ps1

Write-Host "serverstart - Configure FSLogix : Access to Azure File shares for FSLogix profiles"

# Enable Azure AD Kerberos

Write-Host 'serverstart - Configure FSLogix : Enable Azure AD Kerberos ***'
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters"
$registryKey= "CloudKerberosTicketRetrievalEnabled"
$registryValue = "1"

IF(!(Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
}

try {
    New-ItemProperty -Path $registryPath -Name $registryKey -Value $registryValue -PropertyType DWORD -Force | Out-Null
}
catch {
    Write-Host "serverstart - Configure FSLogix : Enable Azure AD Kerberos - Cannot add the registry key $registryKey : [$($_.Exception.Message)]"
    Write-Host "Message: [$($_.Exception.Message)"]
}

# Disable LsaCfgFlags
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "LsaCfgFlags" -Value 0 -force


# Create new reg key "LoadCredKey"
 
Write-Host 'serverstart - Configure FSLogix : Create new reg key LoadCredKey ***'

$LoadCredRegPath = "HKLM:\Software\Policies\Microsoft\AzureADAccount"
$LoadCredName = "LoadCredKeyFromProfile"
$LoadCredValue = "1"

IF(!(Test-Path $LoadCredRegPath)) {
     New-Item -Path $LoadCredRegPath -Force | Out-Null
}

try {
    New-ItemProperty -Path $LoadCredRegPath -Name $LoadCredName -Value $LoadCredValue -PropertyType DWORD -Force | Out-Null
}
catch {
    Write-Host "serverstart - Configure FSLogix :  LoadCredKey - Cannot add the registry key $LoadCredName *** : [$($_.Exception.Message)]"
    Write-Host "Message: [$($_.Exception.Message)"]
}

Write-Host "serverstart - Configure FSLogix : Access to Azure File shares for FSLogix profiles - Exit Code: $LASTEXITCODE ***"


###################
#    Variables    #
###################
$FileServer="$($StorageAccountName).file.core.windows.net"
$ProfilePath="\\$($FileServer)\$($ProfileShareName)"

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
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "CCDLocations" -Value "type=smb,connectionString=$ProfilePath" -PropertyType MultiString -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "ConcurrentUserSessions" -Value 1 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "DeleteLocalProfileWhenVHDShouldApply" -Value 1 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "FlipFlopProfileDirectoryName" -Value 1 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "IsDynamic" -Value 1 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "KeepLocalDir" -Value 0 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "ProfileType" -Value 0 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "SizeInMBs" -Value 20000 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "VolumeType" -Value "VHDX" -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "OutlookCachedMode" -Value 0 -force

Write-Host "serverstart - Configure FSLogix : Done configuring FSLogix Profile Settings"


################################################
#    Configure Microsoft Defender Exclisions   #
################################################

#Reference: https://learn.microsoft.com/en-us/azure/architecture/example-scenario/wvd/windows-virtual-desktop-fslogix#add-exclusions-for-microsoft-defender-for-cloud-by-using-powershell

Write-Host "serverstart - Configure FSLogix : Adding exclusions for Microsoft Defender"

try {
     $filelist = `
  "%ProgramFiles%\FSLogix\Apps\frxdrv.sys", `
  "%ProgramFiles%\FSLogix\Apps\frxdrvvt.sys", `
  "%ProgramFiles%\FSLogix\Apps\frxccd.sys", `
  "%TEMP%\*.VHD", `
  "%TEMP%\*.VHDX", `
  "%Windir%\TEMP\*.VHD", `
  "%Windir%\TEMP\*.VHDX" `

    $processlist = `
    "%ProgramFiles%\FSLogix\Apps\frxccd.exe", `
    "%ProgramFiles%\FSLogix\Apps\frxccds.exe", `
    "%ProgramFiles%\FSLogix\Apps\frxsvc.exe"

    Foreach($item in $filelist){
        Add-MpPreference -ExclusionPath $item}
    Foreach($item in $processlist){
        Add-MpPreference -ExclusionProcess $item}


    Add-MpPreference -ExclusionPath "%ProgramData%\FSLogix\Cache\*.VHD"
    Add-MpPreference -ExclusionPath "%ProgramData%\FSLogix\Cache\*.VHDX"
    Add-MpPreference -ExclusionPath "%ProgramData%\FSLogix\Proxy\*.VHD"
    Add-MpPreference -ExclusionPath "%ProgramData%\FSLogix\Proxy\*.VHDX"
}
catch {
     Write-Host "serverstart - Configure FSLogix : Exception occurred while adding exclusions for Microsoft Defender"
     Write-Host $PSItem.Exception
}

Write-Host "serverstart - Configure FSLogix : Finished adding exclusions for Microsoft Defender"

