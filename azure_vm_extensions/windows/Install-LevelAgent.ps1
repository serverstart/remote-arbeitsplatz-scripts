[CmdletBinding()]

param 
( 
    [Parameter(ValuefromPipeline=$true,Mandatory=$true)] [string]$LevelApiKey
)

$logFile = Join-Path ([System.IO.Path]::GetTempPath()) level_msiexec_install.log;

$args = "LEVEL_API_KEY=$LevelApiKey LEVEL_LOGS=$logFile";

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;

$tempFile = Join-Path ([System.IO.Path]::GetTempPath()) "level.msi";
$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri "https://downloads.level.io/level.msi" -OutFile $tempFile;
$ProgressPreference = 'Continue';

Start-Process msiexec.exe -Wait -ArgumentList "/i $tempFile $args /qn";

Get-Content -Path $logFile;
