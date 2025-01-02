function Initialize-ServerStartDirectory {
    $path = "$env:ProgramFiles\serverstart"
    if (-not (Test-Path $path)) {
        New-Item -Path $path -ItemType Directory -Force
    }
    return $path
}