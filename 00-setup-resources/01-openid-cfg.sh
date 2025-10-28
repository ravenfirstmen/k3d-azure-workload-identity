#!/usr/bin/env bash

CURRENT_FILE=$(readlink -f "$0")
FOLDER=$(dirname ${CURRENT_FILE})
PARENT_FOLDER=$(dirname ${FOLDER})

echo "Setting up Azure resources for OpenID configuration..."
source ${PARENT_FOLDER}/_local_vars.sh
source ${PARENT_FOLDER}/.env

CERTS_FOLDER="${PARENT_FOLDER}/${SA_KEY_FOLDER}"

mkdir -p "${CERTS_FOLDER}"

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


echo "Default Azure account details:"

az account show -o json | jq -r '.'

# subscription 1
if ! az group show --subscription "${AZURE_SUBSCRIPTION_RD_ID}" --name "${AZURE_RESOURCE_GROUP}" >/dev/null 2>&1; then
    echo "The current Azure resource group does not match ${AZURE_RESOURCE_GROUP} on subscription ${AZURE_SUBSCRIPTION_RD_ID}. Creating the resource group..."
    if ! az group create --subscription "${AZURE_SUBSCRIPTION_RD_ID}" --name "${AZURE_RESOURCE_GROUP}" --location "${AZURE_LOCATION}" >/dev/null 2>&1; then
      echo "Failed to create or access the Azure resource group ${AZURE_RESOURCE_GROUP} on subscription ${AZURE_SUBSCRIPTION_RD_ID}. Please check your access rights."
      exit 1
    fi
fi

if ! az group show --subscription "${AZURE_SUBSCRIPTION_RD_ID}" --name "${AZURE_RESOURCE_GROUPV2}" >/dev/null 2>&1; then
    echo "The current Azure resource group does not match ${AZURE_RESOURCE_GROUPV2} on subscription ${AZURE_SUBSCRIPTION_RD_ID}. Creating the resource group..."
    if ! az group create --subscription "${AZURE_SUBSCRIPTION_RD_ID}" --name "${AZURE_RESOURCE_GROUPV2}" --location "${AZURE_LOCATION}" >/dev/null 2>&1; then
      echo "Failed to create or access the Azure resource group ${AZURE_RESOURCE_GROUPV2} on subscription ${AZURE_SUBSCRIPTION_RD_ID}. Please check your access rights."
      exit 1
    fi
fi

# subscription 2
if ! az group show --subscription "${AZURE_SUBSCRIPTION_RD_SDLC_ID}" --name "${AZURE_RESOURCE_GROUP}" >/dev/null 2>&1; then
    echo "The current Azure resource group does not match ${AZURE_RESOURCE_GROUP} on subscription ${AZURE_SUBSCRIPTION_RD_SDLC_ID}. Creating the resource group..."
    if ! az group create --subscription "${AZURE_SUBSCRIPTION_RD_SDLC_ID}" --name "${AZURE_RESOURCE_GROUP}" --location "${AZURE_LOCATION}" >/dev/null 2>&1; then
      echo "Failed to create or access the Azure resource group ${AZURE_RESOURCE_GROUP} on subscription ${AZURE_SUBSCRIPTION_RD_SDLC_ID}. Please check your access rights."
      exit 1
    fi
fi

if ! az group show --subscription "${AZURE_SUBSCRIPTION_RD_SDLC_ID}" --name "${AZURE_RESOURCE_GROUPV2}" >/dev/null 2>&1; then
    echo "The current Azure resource group does not match ${AZURE_RESOURCE_GROUPV2} on subscription ${AZURE_SUBSCRIPTION_RD_SDLC_ID}. Creating the resource group..."
    if ! az group create --subscription "${AZURE_SUBSCRIPTION_RD_SDLC_ID}" --name "${AZURE_RESOURCE_GROUPV2}" --location "${AZURE_LOCATION}" >/dev/null 2>&1; then
      echo "Failed to create or access the Azure resource group ${AZURE_RESOURCE_GROUPV2} on subscription ${AZURE_SUBSCRIPTION_RD_SDLC_ID}. Please check your access rights."
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

if [ ! -f "${CERTS_FOLDER}/sa.pub" ]; then
  openssl genrsa -out "${CERTS_FOLDER}/sa.key" 4096
  openssl rsa -in "${CERTS_FOLDER}/sa.key" -pubout -out "${CERTS_FOLDER}/sa.pub"
  ./azwi-linux-amd64 jwks --public-keys "${CERTS_FOLDER}/sa.pub" --output-file "${CERTS_FOLDER}/jwks.json"
fi

az storage blob upload --subscription "${AZURE_SUBSCRIPTION_RD_ID}" --account-name ${AZURE_STORAGE_ACCOUNT_NAME} --container-name ${AZURE_STORAGE_CONTAINER_NAME} --name "openid/v1/jwks" --file "${CERTS_FOLDER}/jwks.json" --overwrite  >/dev/null 2>&1
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
