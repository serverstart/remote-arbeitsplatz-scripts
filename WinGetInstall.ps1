# Neuste Version von WinGet installieren
Add-AppxPackage -Path "https://aka.ms/getwinget"

# Serverstart Source zu Winget hinzufügen
winget source add -n serverstart -a https://winget.server-start.net/91fcba9f-58ae-475c-8511-a6f4872871ff -t "Microsoft.Rest"
