SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
MANIFESTS_FOLDER="${SCRIPT_DIR}/manifests"

DOT_K3D="${SCRIPT_DIR}/.k3d"
DOT_K3D_MANIFESTS_FOLDER="${DOT_K3D}/manifests"
DOT_K3D_VOLUMES_FOLDER="${DOT_K3D}/volumes"

SA_KEY_FOLDER="${DOT_K3D}/certs"
ISSUER="k3s-issuer"

CLUSTER_NAME="k3s-default"

KUBECTL_CMD=${KUBECTL_CMD:-"kubectl --context k3d-${CLUSTER_NAME}"}
HELM_CMD=${HELM_CMD:-"helm --kube-context k3d-${CLUSTER_NAME}"}
AWS_CMD=${AWS_CMD:-"aws --endpoint-url=http://localhost:4566 --profile localstack"}

REGISTRY=${REGISTRY:-"k3d-registry.localhost:5000"}

# move this to .env file
# export export AZURE_TENANT_ID="««MY TENANT ID»»"
# export export AZURE_SUBSCRIPTION_RD_ID="««MY SUBSCRIPTION ID»»"
# export export AZURE_SUBSCRIPTION_RD_SDLC_ID="««MY OTHER SUBSCRIPTION ID»»"

# the account used to create the Service Principals/app registrations or identities
AZURE_MASTER_APP_REGISTRATION="RD_Crossplane_Upbound_Bootstrap"

AZURE_LOCATION="eastus"
AZURE_RESOURCE_GROUP="rg-k3d-azure-wli"
AZURE_STORAGE_ACCOUNT_NAME="oidcdemostorageacct"
AZURE_STORAGE_CONTAINER_NAME="configuration"
K8S_ISSUER="https://${AZURE_STORAGE_ACCOUNT_NAME}.blob.core.windows.net/${AZURE_STORAGE_CONTAINER_NAME}"

# para demo
KEYVAULT_NAME_RD="vault-sub-rd-id"
KEYVAULT_NAME_RD_SDLC="vault-sub-rd-sdlc"
KEYVAULT_SECRET_NAME="demo-secret"

# identities para demo
USER_ASSIGNED_IDENTITY_NAME="k3d-azure-wli-identity"
FEDERATION_CREDENTIALS_USER_ASSIGNED_IDENTITY_NAME="k3d-azure-wli-federation-credentials"

# kubernetes service account para demo
K8S_SERVICE_ACCOUNT_NAMESPACE="azure-wli-namespace"
K8S_SERVICE_ACCOUNT_NAME="azure-wli-service-account"
