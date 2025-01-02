function Get-ServerStartDirectory {
    [CmdletBinding()]
    param()
    
    # Try ProgramData first
    $programDataPath = "$env:ProgramData\serverstart"
    
    if (-not (Test-Path $programDataPath)) {
        try {
            $null = New-Item -Path $programDataPath -ItemType Directory -Force -ErrorAction Stop
            Write-Verbose "Created directory at ProgramData: $programDataPath"
            return $programDataPath
        }
        catch {
            Write-Verbose "Failed to create directory in ProgramData: $_"
        }
    }
    else {
        return $programDataPath
    }
    
    # Fallback to AppData
    $appDataPath = "$env:APPDATA\serverstart"
    
    if (-not (Test-Path $appDataPath)) {
        try {
            $null = New-Item -Path $appDataPath -ItemType Directory -Force -ErrorAction Stop
            Write-Verbose "Created directory at AppData: $appDataPath"
        }
        catch {
            throw "Failed to create directory in both ProgramData and AppData: $_"
        }
    }
    
    return $appDataPath
}