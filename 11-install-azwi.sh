#!/usr/bin/env bash

source "$(dirname "$(readlink -f "$0")")"/_local_vars.sh
source "$(dirname "$(readlink -f "$0")")"/.env

cat <<EOT | ${KUBECTL_CMD} apply --wait=true -f -
---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: cert-manager
  namespace: kube-system
spec:
  repo: https://charts.jetstack.io
  chart: cert-manager
  targetNamespace: cert-manager
  createNamespace: true
  version: "v1.15.3"
  valuesContent: |-
    installCRDs: true
    cert-manager:
      namespace: cert-manager    
    prometheus:
      enabled: true
EOT

cat <<EOT | ${KUBECTL_CMD} apply --wait=true -f -
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ca-issuer
spec:
  ca:
    secretName: ca-key-pair
EOT

helm repo add azure-workload-identity https://azure.github.io/azure-workload-identity/charts
helm repo update
${HELM_CMD} install workload-identity-webhook azure-workload-identity/workload-identity-webhook \
   --namespace ${K8S_SERVICE_ACCOUNT_NAMESPACE} \
   --create-namespace \
   --set azureTenantID="${AZURE_TENANT_ID}"