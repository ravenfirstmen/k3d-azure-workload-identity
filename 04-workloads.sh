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

user_assigned_data=$(az identity show --subscription "${AZURE_SUBSCRIPTION_RD_ID}" --name "${USER_ASSIGNED_IDENTITY_NAME}" --resource-group "${AZURE_RESOURCE_GROUP}" -o json)
user_client_id=$(echo "$user_assigned_data" | jq -r '.clientId')
user_principal_id=$(echo "$user_assigned_data" | jq -r '.principalId')
echo "Client id: $user_client_id"
echo "Principal id: $user_principal_id"

KEYVAULT_URL_RD=$(az keyvault show --subscription "${AZURE_SUBSCRIPTION_RD_ID}" --resource-group "${AZURE_RESOURCE_GROUP}" --name "${KEYVAULT_NAME_RD}" -o json | jq -r '.properties.vaultUri')
KEYVAULT_URL_RD_SDLC=$(az keyvault show --subscription "${AZURE_SUBSCRIPTION_RD_SDLC_ID}" --resource-group "${AZURE_RESOURCE_GROUP}" --name "${KEYVAULT_NAME_RD_SDLC}" -o json | jq -r '.properties.vaultUri')

echo "Key Vault URL Subscription RD: $KEYVAULT_URL_RD"
echo "Key Vault URL Subscription RD SDLC: $KEYVAULT_URL_RD_SDLC"

cat <<EOF > workloads-for-testing.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    azure.workload.identity/client-id: ${user_client_id}
  name: ${K8S_SERVICE_ACCOUNT_NAME}
  namespace: ${K8S_SERVICE_ACCOUNT_NAMESPACE}
---
apiVersion: v1
kind: Pod
metadata:
  name: test-subscription-1
  namespace: ${K8S_SERVICE_ACCOUNT_NAMESPACE}
  labels:
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: ${K8S_SERVICE_ACCOUNT_NAME}
  containers:
    - image: ghcr.io/azure/azure-workload-identity/msal-go
      name: oidc
      env:
      - name: KEYVAULT_URL
        value: ${KEYVAULT_URL_RD}
      - name: SECRET_NAME
        value: ${KEYVAULT_SECRET_NAME}
      resources:
        requests:
          cpu: "100m"
          memory: "128Mi"
        limits:
          cpu: "200m"
          memory: "256Mi"
  nodeSelector:
    kubernetes.io/os: linux
---    
apiVersion: v1
kind: Pod
metadata:
  name: test-subscription-2
  namespace: ${K8S_SERVICE_ACCOUNT_NAMESPACE}
  labels:
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: ${K8S_SERVICE_ACCOUNT_NAME}
  containers:
    - image: ghcr.io/azure/azure-workload-identity/msal-go
      name: oidc
      env:
      - name: KEYVAULT_URL
        value: ${KEYVAULT_URL_RD_SDLC}
      - name: SECRET_NAME
        value: ${KEYVAULT_SECRET_NAME}
      resources:
        requests:
          cpu: "100m"
          memory: "128Mi"
        limits:
          cpu: "200m"
          memory: "256Mi"
  nodeSelector:
    kubernetes.io/os: linux
EOF


