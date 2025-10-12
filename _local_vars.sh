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

