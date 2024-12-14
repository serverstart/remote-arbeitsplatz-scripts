#!/bin/bash

# Farben definieren
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # Keine Farbe

# Begrüßung
echo -e "${BLUE}serverstart managed IT${NC}"
echo -e "${BLUE}Azure Subscription Setup${NC}"
echo -e ""

# Prüfen, ob `az` verfügbar ist
if ! command -v az &> /dev/null; then
    echo -e "${RED}Fehler: Die Azure CLI (az) ist nicht installiert oder nicht im Pfad verfügbar.${NC}" >&2
    exit 1
fi

# Prüfen, ob jemand eingeloggt ist
if ! az account show &> /dev/null; then
    echo -e "${RED}Fehler: Es ist kein Benutzer in der Azure CLI eingeloggt. Bitte loggen Sie sich ein und versuchen Sie es erneut.${NC}" >&2
    exit 1
fi

# Tenant Informationen abrufen
tenantId=$(az account show --query "tenantId" --output tsv)
subscriptionName=$(az account show --query "name" --output tsv)
subscriptionId=$(az account show --query "id" --output tsv)
username=$(az account show --query "user.name" --output tsv)

# Bestätigung des Tenants abfragen
echo -e "Aktuell eingeloggt in Tenant $tenantId"
read -p "Ist dies der richtige Tenant? (y/n): " confirmTenant
if [[ $confirmTenant != "y" ]]; then
    echo -e "${RED}Abgebrochen. Bitte loggen Sie sich in den richtigen Tenant ein und starten Sie das Skript erneut.${NC}"
    exit 1
fi

# Bestätigung der Subscription abfragen
echo -e "\nAktuell aktive Subscription $subscriptionName mit der ID $subscriptionId"
read -p "Ist dies die richtige Subscription? (y/n): " confirmSubscription
if [[ $confirmSubscription != "y" ]]; then
    echo -e "${RED}Abgebrochen. Bitte wählen Sie die korrekte Subscription (az account set --subscription mysubscription) und starten Sie das Skript erneut.${NC}"
    exit 1
fi

# Bestätigung des Users abfragen
echo -e "\nAktueller User: $username"
read -p "Ist dies der richtige User? (y/n): " confirmUser
if [[ $confirmUser != "y" ]]; then
    echo -e "${RED}Abgebrochen. Bitte loggen Sie sich in den richtigen User ein (az logout und az login) und starten Sie das Skript erneut.${NC}"
    exit 1
fi

# Owner Rolle zuweisen
echo -e "\nGebe dem Benutzer $username die Owner Rolle für die Subscription..."
if az role assignment create --assignee $username --role "Owner" --scope "/subscriptions/$subscriptionId" &> /dev/null; then
    echo -e "${GREEN}Die Owner Rolle wurde dem Benutzer zugewiesen${NC}"
else
    echo -e "${RED}Fehler: Zuweisung der Owner Rolle fehlgeschlagen${NC}" >&2
    exit 1
fi

# Cognitive Services Contributor Rolle zuweisen
echo -e "\nGebe dem Benutzer $username die Cognitive Services Contributor Rolle für die Subscription..."
if az role assignment create --assignee $username --role "Cognitive Services Contributor" --scope "/subscriptions/$subscriptionId" &> /dev/null; then
    echo -e "${GREEN}Die Cognitive Services Contributor Rolle wurde dem Benutzer zugewiesen${NC}"
else
    echo -e "${RED}Fehler: Zuweisung der Cognitive Services Contributor Rolle fehlgeschlagen${NC}" >&2
    exit 1
fi

# Ausloggen und erneut einloggen
echo -e "\nLogge aus und logge erneut ein..."
if az logout &> /dev/null; then
    echo -e "${GREEN}Erfolgreich ausgeloggt${NC}"
else
    echo -e "${RED}Fehler: Ausloggen fehlgeschlagen${NC}" >&2
    exit 1
fi

echo -e "\nLogge ein..."
if az login &> /dev/null; then
    echo -e "${GREEN}Erfolgreich eingeloggt${NC}"
else
    echo -e "${RED}Fehler: Einloggen fehlgeschlagen${NC}" >&2
    exit 1
fi


# Feature aktivieren
echo -e "\nAktiviere EncryptionAtHost..."
if az feature register --name EncryptionAtHost --namespace Microsoft.Compute &> /dev/null; then
    echo -e "${GREEN}EncryptionAtHost erfolgreich aktiviert${NC}"
else
    echo -e "${RED}Fehler: Aktivierung von EncryptionAtHost fehlgeschlagen${NC}" >&2
    exit 1
fi

# Provider registrieren
echo -e "\nRegistriere den Provider..."
if az provider register --namespace Microsoft.Compute &> /dev/null; then
    echo -e "${GREEN}Provider Microsoft.Compute erfolgreich registriert${NC}"
else
    echo -e "${RED}Fehler: Registrierung des Providers Microsoft.Compute fehlgeschlagen${NC}" >&2
    exit 1
fi

# Provider registrieren
echo -e "\nRegistriere den Provider..."
if az provider register --namespace Microsoft.SqlVirtualMachine &> /dev/null; then
    echo -e "${GREEN}Provider Microsoft.SqlVirtualMachine erfolgreich registriert${NC}"
else
    echo -e "${RED}Fehler: Registrierung des Providers Microsoft.SqlVirtualMachine fehlgeschlagen${NC}" >&2
    exit 1
fi

# Provider registrieren: Microsoft.DesktopVirtualization
echo -e "\nRegistriere den Provider: Microsoft.DesktopVirtualization..."
if az provider register --namespace Microsoft.DesktopVirtualization &> /dev/null; then
    echo -e "${GREEN}Provider Microsoft.DesktopVirtualization erfolgreich registriert${NC}"
else
    echo -e "${RED}Fehler: Registrierung des Providers Microsoft.DesktopVirtualization fehlgeschlagen${NC}" >&2
    exit 1
fi

# Abmelden
echo -e "\nAbmelden aus Azure-CLI..."
if az logout &> /dev/null; then
    echo -e "${GREEN}Erfolgreich ausgeloggt${NC}"
else
    echo -e "${RED}Fehler: Ausloggen fehlgeschlagen${NC}" >&2
    exit 1
fi

echo -e "\n\n${GREEN}Setup erfolgreich abgeschlossen!${NC}"
