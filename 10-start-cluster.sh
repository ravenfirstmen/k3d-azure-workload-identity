#!/usr/bin/env bash

source "$(dirname "$(readlink -f "$0")")"/_local_vars.sh

mkdir -p "${SCRIPT_DIR}/${DOT_K3D}"
mkdir -p "${SCRIPT_DIR}/${SA_KEY_FOLDER}"

# reference/source: https://hub.docker.com/r/rancher/k3s/tags
IMAGE="rancher/k3s:v1.32.9-k3s1-amd64"

export K3D_FIX_MOUNTS=1
export K3D_FIX_DNS=1

if k3d cluster list "${CLUSTER_NAME}" > /dev/null 2>&1; then
    echo "Refreshing cluster...."
	k3d cluster delete "${CLUSTER_NAME}"
fi

# https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/
# https://kubernetes.io/docs/reference/command-line-tools-reference/kube-controller-manager/
# for service account keys
k3d cluster create "${CLUSTER_NAME}" \
    --image "${IMAGE}" \
    --api-port "localhost:6443" \
    --servers 1 \
    --wait \
    --no-lb \
    --k3s-arg '--disable=metrics-server@server:*' \
    --k3s-arg '--disable=traefik@server:*' \
    --k3s-arg "--kube-apiserver-arg=service-account-issuer=${K8S_ISSUER}@server:*" \
    --k3s-arg "--kube-apiserver-arg=service-account-signing-key-file=/etc/ssl/pki/sa/sa.key@server:*" \
    --k3s-arg "--kube-apiserver-arg=service-account-key-file=/etc/ssl/pki/sa/sa.pub@server:*" \
    --k3s-arg "--kube-controller-manager-arg=service-account-private-key-file=/etc/ssl/pki/sa/sa.key@server:*" \
    --volume "${SCRIPT_DIR}/${SA_KEY_FOLDER}:/etc/ssl/pki/sa@server:*" 
