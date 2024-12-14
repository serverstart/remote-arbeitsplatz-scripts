#!/bin/bash

# Farben definieren
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # Keine Farbe

# Begrüßung
echo -e "${BLUE}serverstart managed IT${NC}"
echo -e "${BLUE}Terraform Service Principal Setup${NC}"
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
echo "Aktuell eingeloggt in Tenant mit der ID $tenantId"

# Bestätigung des Tenants abfragen
read -p "Ist dies der richtige Tenant? (y/n): " confirmTenant
if [[ $confirmTenant != "y" ]]; then
    echo "Abgebrochen. Bitte loggen Sie sich in den richtigen Tenant ein und starten Sie das Skript erneut."
    exit 1
fi

# Subscription ID ermitteln
subscriptionId=$(az account show --query id --output tsv)
echo -e "\nVerwendete Subscription ID: $subscriptionId"

# Scope ermitteln
scope="/subscriptions/$subscriptionId"
echo "Verwendeter Scope: $scope"

# Name generieren
servicePrincipalName="Terraform Client by serverstart managed IT"
echo "Verwendeter Name: $servicePrincipalName"

# Service Principal anlegen
echo -e "\nErstelle Service Principal..."
servicePrincipal=$(az ad sp create-for-rbac --name "$servicePrincipalName")

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Der Service Principal wurde erstellt${NC}"
else
    echo -e "${RED}Fehler: Erstellen des Service Principals fehlgeschlagen${NC}" >&2
    exit 1
fi

# ID ermitteln
servicePrincipalAppId=$(echo "$servicePrincipal" | jq -r .appId)
echo "Service Principal App ID: $servicePrincipalAppId"

# Tenant ermitteln
servicePrincipalTenantId=$(echo "$servicePrincipal" | jq -r .tenant)
echo "Tenant ID: $servicePrincipalTenantId"

# Object ID ermitteln
servicePrincipalObjectId=$(az ad sp show --id "$servicePrincipalAppId" | jq -r .id)
echo "Service Principal Object ID: $servicePrincipalObjectId"

# Contributor zuweisen
echo -e "\nWeise Contributor Role zu..."
role=$(az role assignment create --assignee "$servicePrincipalAppId" --role "Contributor" --scope "$scope")

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Contributor Role zugewiesen${NC}"
else
    echo -e "${RED}Fehler: Zuweisung der Contributor Role fehlgeschlagen${NC}" >&2
    exit 1
fi

# User Access Administrator zuweisen
echo -e "\nWeise User Access Administrator Role zu..."
role=$(az role assignment create --assignee "$servicePrincipalAppId" --role "User Access Administrator" --scope "$scope")

if [ $? -eq 0 ]; then
    echo -e "${GREEN}User Access Administrator Role zugewiesen${NC}"
else
    echo -e "${RED}Fehler: Zuweisung der User Access Administrator Role fehlgeschlagen${NC}" >&2
    exit 1
fi

# Erforderliche Berechtigungen
requiredGraphPermissions=("Application.Read.All" "Group.ReadWrite.All" "User.ReadWrite.All")

# ID der Graph API ermitteln
graphApiId=$(az ad sp list --filter "displayName eq 'Microsoft Graph'" --query "[0].appId" -o tsv)

# Berechtigungen hinzufügen
echo -e "\nFüge erforderliche Berechtigungen hinzu..."
for permission in "${requiredGraphPermissions[@]}"; do
  echo "Füge Berechtigung hinzu: $permission"
  permId=$(az ad sp show --id "$graphApiId" --query "appRoles[?value=='$permission'].id" -o tsv)
  az ad app permission add --id "$servicePrincipalAppId" --api "$graphApiId" --api-permissions "$permId=Role"

  if [ $? -eq 0 ]; then
      echo -e "${GREEN}Berechtigung $permission hinzugefügt${NC}"
  else
      echo -e "${RED}Fehler: Hinzufügen der Berechtigung $permission fehlgeschlagen${NC}" >&2
      exit 1
  fi
done

# Admin Consent erteilen
echo -e "\nErteile Admin Consent..."
echo -e "\nWarten auf Verarbeitung der Zuweisung der Berechtigungen... 60 Sekunden warten."
sleep 60

az ad app permission admin-consent --id "$servicePrincipalAppId"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Admin Consent für die Anwendung erteilt${NC}"
else
    echo -e "${RED}Fehler: Erteilen des Admin Consent fehlgeschlagen${NC}" >&2
    exit 1
fi

# Löschen des automatisch erstellten Schlüssels
echo -e "\nLösche automatisch erstelltes Secret..."
initialSecretId=$(az ad app credential list --id "$servicePrincipalAppId" --query "[0].keyId" -o tsv)
az ad app credential delete --id "$servicePrincipalAppId" --key-id "$initialSecretId"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Automatisch erstelltes Secret gelöscht${NC}"
else
    echo -e "${RED}Fehler: Löschen des automatisch erstellten Secrets fehlgeschlagen${NC}" >&2
    exit 1
fi

# Erstellung von zwei neuen Schlüsseln mit einer Gültigkeit von zwei Jahren
echo -e "\nErstelle neue Secrets..."

# Erster Schlüssel
secretBackupName="serverstart Backup-Key"
secretBackup=$(az ad app credential reset --id "$servicePrincipalAppId" --append --display-name "$secretBackupName" --years 2)
secretBackupPassword=$(echo "$secretBackup" | jq -r .password)
echo -e "${GREEN}Neues Secret '$secretBackupName' erstellt.${NC}"

# Zweiter Schlüssel
secretCloudName="serverstart Terraform Cloud"
secretCloud=$(az ad app credential reset --id "$servicePrincipalAppId" --append --display-name "$secretCloudName" --years 2)
secretCloudPassword=$(echo "$secretCloud" | jq -r .password)
echo -e "${GREEN}Neues Secret '$secretCloudName' erstellt.${NC}"

echo -e "\n${GREEN}Service Principal Setup abgeschlossen${NC}\n"

# Ausgabe für Terraform
echo -e "\n\n${YELLOW}terraform.tfvars - Konfiguration:${NC}"
echo "global_azure_customer_service_principal_app_id=\"$servicePrincipalAppId\""
echo "global_azure_customer_service_principal_object_id=\"$servicePrincipalObjectId\""
echo "global_azure_customer_service_principal_secret=\"$secretCloudPassword\""
echo "global_azure_customer_subscription_id=\"$subscriptionId\""
echo "global_azure_customer_tenant_id=\"$servicePrincipalTenantId\""

# Ausgabe für Luna
echo -e "\n\n${BLUE}Luna-Konfiguration:${NC}"
echo "Tenant-ID: \"$servicePrincipalTenantId\""
echo "Subscription-ID: \"$subscriptionId\""
echo "Client / App-ID: \"$servicePrincipalAppId\""
echo "Client-Secret: \"$secretCloudPassword\""

# Ausgabe für Luna
echo -e "\n\n${RED}Backup-Daten:${NC}"
echo "Client-ID: \"$servicePrincipalAppId\""
echo "Backup-Secret: \"$secretBackupPassword\""

# Warnung
echo -e "\n\n${YELLOW}Bitte prüfen, ob die Administratorzustimmung für die API-Rollen noch ausstehen!${NC}"
