#!/usr/bin/env bash

source "$(dirname "$(readlink -f "$0")")"/_local_vars.sh
source "$(dirname "$(readlink -f "$0")")"/.env
mkdir -p "${SA_KEY_FOLDER}"


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

master_app_registration=$(az ad sp list --display-name ${AZURE_MASTER_APP_REGISTRATION} -o json)
master_app_registration_sp_id=$(echo $master_app_registration | jq -r '.[0].appId')

if [ -z "${master_app_registration_sp_id}" ] || [ "${master_app_registration_sp_id}" == "null" ]; then
  echo "Service principal ${AZURE_MASTER_APP_REGISTRATION} not found. Please create it before proceeding."
  exit 1f
fi

if [ -z "${AZURE_AZURE_MASTER_APP_REGISTRATION_PWD}" ]; then
  echo "AZURE_AZURE_MASTER_APP_REGISTRATION_PWD variable is not set. Please ensure AZURE_AZURE_MASTER_APP_REGISTRATION_PWD is set in .env file"  
  exit 1
fi

if ! az login --allow-no-subscriptions --service-principal --username "${master_app_registration_sp_id}" --password "${AZURE_AZURE_MASTER_APP_REGISTRATION_PWD}" --tenant "${AZURE_TENANT_ID}" >/dev/null 2>&1; then
  echo "Failed to login to Azure as service principal. Please check your credentials."
  exit 1
fi

az account show -o json | jq -r '.'

# subscription 1
if ! az group show --subscription "${AZURE_SUBSCRIPTION_RD_ID}" --name "${AZURE_RESOURCE_GROUP}" >/dev/null 2>&1; then
    echo "The current Azure resource group does not match ${AZURE_RESOURCE_GROUP} on subscription ${AZURE_SUBSCRIPTION_RD_ID}. Creating the resource group..."
    if ! az group create --subscription "${AZURE_SUBSCRIPTION_RD_ID}" --name "${AZURE_RESOURCE_GROUP}" --location "${AZURE_LOCATION}" --managed-by "${master_app_registration_sp_id}" >/dev/null 2>&1; then
      echo "Failed to create or access the Azure resource group ${AZURE_RESOURCE_GROUP} on subscription ${AZURE_SUBSCRIPTION_RD_ID}. Please check your access rights."
      exit 1
    fi
fi

# subscription 2
if ! az group show --subscription "${AZURE_SUBSCRIPTION_RD_SDLC_ID}" --name "${AZURE_RESOURCE_GROUP}" >/dev/null 2>&1; then
    echo "The current Azure resource group does not match ${AZURE_RESOURCE_GROUP} on subscription ${AZURE_SUBSCRIPTION_RD_SDLC_ID}. Creating the resource group..."
    if ! az group create --subscription "${AZURE_SUBSCRIPTION_RD_SDLC_ID}" --name "${AZURE_RESOURCE_GROUP}" --location "${AZURE_LOCATION}" --managed-by "${master_app_registration_sp_id}" >/dev/null 2>&1; then
      echo "Failed to create or access the Azure resource group ${AZURE_RESOURCE_GROUP} on subscription ${AZURE_SUBSCRIPTION_RD_SDLC_ID}. Please check your access rights."
      exit 1
    fi
fi

if ! az storage account show --subscription "${AZURE_SUBSCRIPTION_RD_ID}" -n "${AZURE_STORAGE_ACCOUNT_NAME}" -g ${AZURE_RESOURCE_GROUP} >/dev/null 2>&1; then
    echo "The storage account ${AZURE_STORAGE_ACCOUNT_NAME} does not exist in resource group ${AZURE_RESOURCE_GROUP}. Creating the storage account..."
    if ! az storage account create --subscription "${AZURE_SUBSCRIPTION_RD_ID}" -n "${AZURE_STORAGE_ACCOUNT_NAME}" -g ${AZURE_RESOURCE_GROUP} --location "${AZURE_LOCATION}" --sku Standard_LRS --allow-blob-public-access >/dev/null 2>&1; then
      echo "Failed to create the Azure storage account ${AZURE_STORAGE_ACCOUNT_NAME}. Please check your access rights."
      exit 1
    fi    
fi

if ! az storage container show --subscription "${AZURE_SUBSCRIPTION_RD_ID}" --account-name "${AZURE_STORAGE_ACCOUNT_NAME}" --name "${AZURE_STORAGE_CONTAINER_NAME}" >/dev/null 2>&1; then
    echo "The storage container ${AZURE_STORAGE_CONTAINER_NAME} does not exist in storage account ${AZURE_STORAGE_ACCOUNT_NAME}. Creating the storage container..."
    if ! az storage container create --subscription "${AZURE_SUBSCRIPTION_RD_ID}" --account-name "${AZURE_STORAGE_ACCOUNT_NAME}" --name "${AZURE_STORAGE_CONTAINER_NAME}" --public-access blob >/dev/null 2>&1; then
      echo "The storage container ${AZURE_STORAGE_CONTAINER_NAME} could not be created in storage account ${AZURE_STORAGE_ACCOUNT_NAME}. Please check your access rights."
      exit 1
    fi
fi


if [ ! -f "${SA_KEY_FOLDER}/sa.pub" ]; then
  openssl genrsa -out "${SA_KEY_FOLDER}/sa.key" 4096
  openssl rsa -in "${SA_KEY_FOLDER}/sa.key" -pubout -out "${SA_KEY_FOLDER}/sa.pub"
  ./azwi-linux-amd64 jwks --public-keys "${SA_KEY_FOLDER}/sa.pub" --output-file "${SA_KEY_FOLDER}/jwks.json"
fi

az storage blob upload --subscription "${AZURE_SUBSCRIPTION_RD_ID}" --account-name ${AZURE_STORAGE_ACCOUNT_NAME} --container-name ${AZURE_STORAGE_CONTAINER_NAME} --name "openid/v1/jwks" --file "${SA_KEY_FOLDER}/jwks.json" --overwrite  >/dev/null 2>&1
cat << EOT > openid-configuration.json 
{
    "issuer": "${K8S_ISSUER}",
    "jwks_uri": "${K8S_ISSUER}/openid/v1/jwks",
    "response_types_supported": [
        "id_token"
    ],
    "subject_types_supported": [
        "public"
    ],
    "id_token_signing_alg_values_supported": [
        "RS256"
    ]
}
EOT
az storage blob upload --subscription "${AZURE_SUBSCRIPTION_RD_ID}" --account-name ${AZURE_STORAGE_ACCOUNT_NAME} --container-name ${AZURE_STORAGE_CONTAINER_NAME} --name ".well-known/openid-configuration" --file "openid-configuration.json" --overwrite  >/dev/null 2>&1

curl -s  -X GET "${K8S_ISSUER}/.well-known/openid-configuration"
curl -s  -X GET "${K8S_ISSUER}/openid/v1/jwks"
