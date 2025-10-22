#!/usr/bin/env bash

source "$(dirname "$(readlink -f "$0")")"/_local_vars.sh

mkdir -p "${SA_KEY_FOLDER}"

openssl genrsa -out "${SA_KEY_FOLDER}/sa.key" 4096
openssl rsa -in "${SA_KEY_FOLDER}/sa.key" -pubout -out "${SA_KEY_FOLDER}/sa.pub"

./azwi-linux-amd64 jwks --public-keys "${SA_KEY_FOLDER}/sa.pub" --output-file "${SA_KEY_FOLDER}/jwks.json"

echo "Generated service account keys in ${SA_KEY_FOLDER}"
