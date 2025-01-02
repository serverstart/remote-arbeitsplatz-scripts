function Get-ServerStartDirectory {
    [CmdletBinding()]
    param()
    
    # Try ProgramData path first
    $programDataPath = "$env:ProgramData\serverstart"
    
    try {
        # Create directory if it doesn't exist
        if (-not (Test-Path $programDataPath)) {
            $null = New-Item -Path $programDataPath -ItemType Directory -Force -ErrorAction Stop
        }
        
        # Test write access with minimal overhead
        [IO.File]::WriteAllText("$programDataPath\test.txt", "test")
        Remove-Item "$programDataPath\test.txt" -Force
        
        return $programDataPath
    }
    catch {
        # Fallback: Create and use AppData path
        $appDataPath = "$env:APPDATA\serverstart"
        $null = New-Item -Path $appDataPath -ItemType Directory -Force -ErrorAction Stop
        return $appDataPath
    }
}

# Script-scoped variable for log file path
$script:LogFile = $null

function Write-ToLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$LogMsg,
        [string]$LogColor = "White"
    )

    if (-not $script:LogFile) {
        $script:LogFile = "$(Get-ServerStartDirectory)\log_$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss-fff').log"
    }
    
    $Log = "$(Get-Date -UFormat '%T.%3N') - $LogMsg"
    
    Write-Host $Log -ForegroundColor $LogColor
    try {
        $Log | Out-File -FilePath $script:LogFile -Append -ErrorAction Stop
    }
    catch {
        Write-Warning "Failed to write to log file: $_"
    }
}