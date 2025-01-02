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