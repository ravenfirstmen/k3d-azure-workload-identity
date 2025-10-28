#!/usr/bin/env bash

CURRENT_FILE=$(readlink -f "$0")
FOLDER=$(dirname ${CURRENT_FILE})
PARENT_FOLDER=$(dirname ${FOLDER})

echo "Setting up Azure vault for demo..."
source ${PARENT_FOLDER}/_local_vars.sh
source ${PARENT_FOLDER}/.env

if ! az account show >/dev/null 2>&1; then
    echo "You are not logged in to Azure CLI. Attempting to log in..."
    if ! az login --tenant ${AZURE_TENANT_ID} --scope "https://graph.microsoft.com//.default" >/dev/null 2>&1; then
      echo "Azure CLI login failed. Please ensure you have access to the Azure account and try again."
      exit 1
    fi    
fi

if ! az account set --subscription "${AZURE_SUBSCRIPTION_RD_ID}" >/dev/null 2>&1; then
    echo "Failed to set the default Azure subscription to ${AZURE_SUBSCRIPTION_RD_ID}. Please check your access rights."
    exit 1
fi

# subscription 1
if ! az keyvault show --subscription "${AZURE_SUBSCRIPTION_RD_ID}" --resource-group "${AZURE_RESOURCE_GROUP}" --name "${KEYVAULT_NAME_RD}" >/dev/null 2>&1; then
    echo "The Key Vault ${KEYVAULT_NAME_RD} does not exist in resource group ${AZURE_RESOURCE_GROUP}. Creating the Key Vault..."    
    if ! az keyvault create --subscription "${AZURE_SUBSCRIPTION_RD_ID}" --resource-group "${AZURE_RESOURCE_GROUP}" --location "${AZURE_LOCATION}" --name "${KEYVAULT_NAME_RD}" --retention-days 7 --sku standard >/dev/null 2>&1; then
      echo "Failed to create the Key Vault ${KEYVAULT_NAME_RD}. Please check your access rights."
      exit 1
    fi
fi

if ! az keyvault secret set --subscription "${AZURE_SUBSCRIPTION_RD_ID}" --vault-name "${KEYVAULT_NAME_RD}" --name "${KEYVAULT_SECRET_NAME}" --value "From Subscription 1!"  >/dev/null 2>&1; then
    echo "Failed to set secret ${KEYVAULT_SECRET_NAME} in Key Vault ${KEYVAULT_NAME_RD}. Please check your access rights."
    exit 1
fi

# v2
if ! az keyvault show --subscription "${AZURE_SUBSCRIPTION_RD_ID}" --resource-group "${AZURE_RESOURCE_GROUPV2}" --name "${KEYVAULT_NAME_RDV2}" >/dev/null 2>&1; then
    echo "The Key Vault ${KEYVAULT_NAME_RDV2} does not exist in resource group ${AZURE_RESOURCE_GROUPV2}. Creating the Key Vault..."    
    if ! az keyvault create --subscription "${AZURE_SUBSCRIPTION_RD_ID}" --resource-group "${AZURE_RESOURCE_GROUPV2}" --location "${AZURE_LOCATION}" --name "${KEYVAULT_NAME_RDV2}" --retention-days 7 --sku standard >/dev/null 2>&1; then
      echo "Failed to create the Key Vault ${KEYVAULT_NAME_RDV2}. Please check your access rights."
      exit 1
    fi
fi

if ! az keyvault secret set --subscription "${AZURE_SUBSCRIPTION_RD_ID}" --vault-name "${KEYVAULT_NAME_RDV2}" --name "${KEYVAULT_SECRET_NAME}" --value "From Subscription 1!"  >/dev/null 2>&1; then
    echo "Failed to set secret ${KEYVAULT_SECRET_NAME} in Key Vault ${KEYVAULT_NAME_RDV2}. Please check your access rights."
    exit 1
fi


# subscription 2
if ! az keyvault show --subscription "${AZURE_SUBSCRIPTION_RD_SDLC_ID}" --resource-group "${AZURE_RESOURCE_GROUP}" --name "${KEYVAULT_NAME_RD_SDLC}" >/dev/null 2>&1; then
    echo "The Key Vault ${KEYVAULT_NAME_RD_SDLC} does not exist in resource group ${AZURE_RESOURCE_GROUP}. Creating the Key Vault..."
    if ! az keyvault create --subscription "${AZURE_SUBSCRIPTION_RD_SDLC_ID}" --resource-group "${AZURE_RESOURCE_GROUP}" --location "${AZURE_LOCATION}" --name "${KEYVAULT_NAME_RD_SDLC}" --retention-days 7 --sku standard >/dev/null 2>&1; then
      echo "Failed to create the Key Vault ${KEYVAULT_NAME_RD_SDLC}. Please check your access rights."
      exit 1
    fi
fi

if ! az keyvault secret set --subscription "${AZURE_SUBSCRIPTION_RD_SDLC_ID}" --vault-name "${KEYVAULT_NAME_RD_SDLC}" --name "${KEYVAULT_SECRET_NAME}" --value "From Subscription 2!"  >/dev/null 2>&1; then
    echo "Failed to set secret ${KEYVAULT_SECRET_NAME} in Key Vault ${KEYVAULT_NAME_RD_SDLC}. Please check your access rights."
    exit 1
fi

# v2
if ! az keyvault show --subscription "${AZURE_SUBSCRIPTION_RD_SDLC_ID}" --resource-group "${AZURE_RESOURCE_GROUPV2}" --name "${KEYVAULT_NAME_RD_SDLCV2}" >/dev/null 2>&1; then
    echo "The Key Vault ${KEYVAULT_NAME_RD_SDLCV2} does not exist in resource group ${AZURE_RESOURCE_GROUPV2}. Creating the Key Vault..."
    if ! az keyvault create --subscription "${AZURE_SUBSCRIPTION_RD_SDLC_ID}" --resource-group "${AZURE_RESOURCE_GROUPV2}" --location "${AZURE_LOCATION}" --name "${KEYVAULT_NAME_RD_SDLCV2}" --retention-days 7 --sku standard >/dev/null 2>&1; then
      echo "Failed to create the Key Vault ${KEYVAULT_NAME_RD_SDLCV2}. Please check your access rights."
      exit 1
    fi
fi

if ! az keyvault secret set --subscription "${AZURE_SUBSCRIPTION_RD_SDLC_ID}" --vault-name "${KEYVAULT_NAME_RD_SDLCV2}" --name "${KEYVAULT_SECRET_NAME}" --value "From Subscription 2!"  >/dev/null 2>&1; then
    echo "Failed to set secret ${KEYVAULT_SECRET_NAME} in Key Vault ${KEYVAULT_NAME_RD_SDLCV2}. Please check your access rights."
    exit 1
fi


# az keyvault set-policy --subscription "${AZURE_SUBSCRIPTION_RD_SDLC_ID}" --name "${KEYVAULT_NAME_RD_SDLC}" --secret-permissions get --spn "${APPLICATION_CLIENT_ID}"
