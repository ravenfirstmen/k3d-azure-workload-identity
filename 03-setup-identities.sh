#!/usr/bin/env bash

source "$(dirname "$(readlink -f "$0")")"/_local_vars.sh
source "$(dirname "$(readlink -f "$0")")"/.env

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

echo "Setting up Azure User Assigned Identity and Key Vaults with demo secrets..."
if ! az identity show --subscription "${AZURE_SUBSCRIPTION_RD_ID}" --name "${USER_ASSIGNED_IDENTITY_NAME}" --resource-group "${AZURE_RESOURCE_GROUP}" >/dev/null 2>&1; then
    echo "The User Assigned Identity ${USER_ASSIGNED_IDENTITY_NAME} does not exist in resource group ${AZURE_RESOURCE_GROUP}. Creating the Identity..."    
    if ! az identity create --subscription "${AZURE_SUBSCRIPTION_RD_ID}" --name "${USER_ASSIGNED_IDENTITY_NAME}" --resource-group "${AZURE_RESOURCE_GROUP}" >/dev/null 2>&1; then
      echo "Failed to create the User Assigned Identity ${USER_ASSIGNED_IDENTITY_NAME}. Please check your access rights."
      exit 1
    fi
fi

if ! az identity federated-credential show --subscription "${AZURE_SUBSCRIPTION_RD_ID}" \
  --name ${FEDERATION_CREDENTIALS_USER_ASSIGNED_IDENTITY_NAME} \
  --identity-name "${USER_ASSIGNED_IDENTITY_NAME}" \
  --resource-group "${AZURE_RESOURCE_GROUP}" >/dev/null 2>&1; then
    echo "The Federated Identity Credential ${FEDERATION_CREDENTIALS_USER_ASSIGNED_IDENTITY_NAME} does not exist for User Assigned Identity ${USER_ASSIGNED_IDENTITY_NAME}. Creating the Federated Identity Credential..."    
    if ! az identity federated-credential create --subscription "${AZURE_SUBSCRIPTION_RD_ID}" \
      --name ${FEDERATION_CREDENTIALS_USER_ASSIGNED_IDENTITY_NAME} \
      --identity-name "${USER_ASSIGNED_IDENTITY_NAME}" \
      --resource-group "${AZURE_RESOURCE_GROUP}" \
      --issuer "${K8S_ISSUER}" \
      --subject "system:serviceaccount:${K8S_SERVICE_ACCOUNT_NAMESPACE}:${K8S_SERVICE_ACCOUNT_NAME}" >/dev/null 2>&1; then
      echo "Failed to create the Federated Identity Credential ${FEDERATION_CREDENTIALS_USER_ASSIGNED_IDENTITY_NAME}. Please check your access rights."
      exit 1
    fi
fi

user_assigned_data=$(az identity show --subscription "${AZURE_SUBSCRIPTION_RD_ID}" --name "${USER_ASSIGNED_IDENTITY_NAME}" --resource-group "${AZURE_RESOURCE_GROUP}" -o json)
user_client_id=$(echo "$user_assigned_data" | jq -r '.clientId')
user_principal_id=$(echo "$user_assigned_data" | jq -r '.principalId')
echo "Client id: $user_client_id"
echo "Principal id: $user_principal_id"


if ! az role assignment create --assignee-object-id ${user_principal_id} --assignee-principal-type ServicePrincipal \
  --role "Key Vault Secrets User" \
  --scope "/subscriptions/${AZURE_SUBSCRIPTION_RD_ID}/resourceGroups/${AZURE_RESOURCE_GROUP}" >/dev/null 2>&1; then
    echo "Failed to assign Reader role to the User Assigned Identity on subscription ${AZURE_SUBSCRIPTION_RD_ID}. Please check your access rights."
    exit 1
fi

if ! az role assignment create --assignee-object-id ${user_principal_id} --assignee-principal-type ServicePrincipal \
  --role "Key Vault Secrets User" \
  --scope "/subscriptions/${AZURE_SUBSCRIPTION_RD_SDLC_ID}/resourceGroups/${AZURE_RESOURCE_GROUP}" >/dev/null 2>&1; then
    echo "Failed to assign Reader role to the User Assigned Identity on subscription ${AZURE_SUBSCRIPTION_RD_SDLC_ID}. Please check your access rights."
    exit 1
fi

echo "List of role assignments for the User Assigned Identity: ${user_principal_id}"

az role assignment list --assignee-object-id ${user_principal_id} --subscription ${AZURE_SUBSCRIPTION_RD_ID} --all
az role assignment list --assignee-object-id ${user_principal_id} --subscription ${AZURE_SUBSCRIPTION_RD_SDLC_ID} --all


echo "User Assigned Identity and role assignments completed successfully."