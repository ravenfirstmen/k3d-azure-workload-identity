#!/usr/bin/env bash

source "$(dirname "$(readlink -f "$0")")"/_local_vars.sh
source "$(dirname "$(readlink -f "$0")")"/.env

${KUBECTL_CMD} apply --wait=true -f workloads-for-testing.yaml
