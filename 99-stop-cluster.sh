#!/usr/bin/env bash

source "$(dirname "$(readlink -f "$0")")"/_local_vars.sh

if k3d cluster list "${CLUSTER_NAME}" > /dev/null 2>&1; then
    echo "Refreshing cluster...."
	k3d cluster delete "${CLUSTER_NAME}"
fi

# rm -rdf "${DOT_K3D}"
