#!/usr/bin/env bash

CURRENT_FILE=$(readlink -f "$0")
FOLDER=$(dirname ${CURRENT_FILE})

source "${FOLDER}/_local_vars.sh"
source "${FOLDER}/.env"
source "${FOLDER}/_app-login.sh"

app_login

user_assigned_data=$(az identity show --subscription "${AZURE_SUBSCRIPTION_RD_ID}" --name "${USER_ASSIGNED_IDENTITY_NAMEV2}" --resource-group "${AZURE_RESOURCE_GROUPV2}" -o json)
user_client_id=$(echo "$user_assigned_data" | jq -r '.clientId')
user_principal_id=$(echo "$user_assigned_data" | jq -r '.principalId')
echo "Client id: $user_client_id"
echo "Principal id: $user_principal_id"

KEYVAULT_URL_RD=$(az keyvault show --subscription "${AZURE_SUBSCRIPTION_RD_ID}" --resource-group "${AZURE_RESOURCE_GROUPV2}" --name "${KEYVAULT_NAME_RDV2}" -o json | jq -r '.properties.vaultUri')
KEYVAULT_URL_RD_SDLC=$(az keyvault show --subscription "${AZURE_SUBSCRIPTION_RD_SDLC_ID}" --resource-group "${AZURE_RESOURCE_GROUPV2}" --name "${KEYVAULT_NAME_RD_SDLCV2}" -o json | jq -r '.properties.vaultUri')

echo "Key Vault URL Subscription RD: $KEYVAULT_NAME_RDV2"
echo "Key Vault URL Subscription RD SDLC: $KEYVAULT_NAME_RD_SDLCV2"

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


