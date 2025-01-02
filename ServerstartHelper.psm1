$private:ServerstartPath = $null

function Get-ServerstartDirectory {
    <# 
    .SYNOPSIS
    Ermittelt und erstellt bei Bedarf das Serverstart-Verzeichnis.
    Versucht erst %ProgramFiles%\serverstart, dann %AppData%\serverstart.
    Ergebnis wird für weitere Aufrufe gecached.
    #>
    if (-not $private:ServerstartPath) {
        $paths = @(
            "$env:ProgramFiles\serverstart",
            "$env:APPDATA\serverstart"
        )
        $private:ServerstartPath = $paths | Where-Object { 
            Test-Path $_ -ErrorAction SilentlyContinue -or 
            (New-Item -Path $_ -ItemType Directory -Force -ErrorAction SilentlyContinue) 
        } | Select-Object -First 1
    }
    return $private:ServerstartPath
}