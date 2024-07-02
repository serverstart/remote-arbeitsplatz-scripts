#!/bin/sh

# Standardlogdatei
LOGFILE="/var/log/serverstart.log"

# Funktion zur Ausgabe in die Log-Datei
log() {
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") - $1" >> $LOGFILE
}

# Parameter analysieren
while [ "$#" -gt 0 ]; do
  case "$1" in
    --ExtensionName)
      ExtensionName="$2"
      shift 2
      ;;
    --Version)
      Version="$2"
      shift 2
      ;;
    --Timestamp)
      Timestamp="$2"
      shift 2
      ;;
    *)
      printf "Unbekannte Option: $1\n" >&2
      exit 1
      ;;
  esac
done

# Überprüfen, ob die erforderlichen Parameter gesetzt sind
if [ -z "$ExtensionName" ]; then
    log "Error: ExtensionName ist erforderlich."
    exit 1
fi

if [ -z "$Version" ]; then
    log "Error: Version ist erforderlich."
    exit 1
fi

# Wenn kein Timestamp angegeben ist, aktuellen UTC-Zeitstempel im RFC3339-Format verwenden
if [ -z "$Timestamp" ]; then
    Timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
fi

# Informationen in die Log-Datei schreiben
log "ExtensionName: $ExtensionName"
log "Version: $Version"
log "Deployed at: $Timestamp"

# Erfolgsnachricht in die Log-Datei schreiben
log "Extension $ExtensionName was successfully deployed or updated."