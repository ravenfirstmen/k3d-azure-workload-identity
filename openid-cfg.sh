#!/usr/bin/env bash

source "$(dirname "$(readlink -f "$0")")"/_local_vars.sh

azwi jwks --public-keys sa.pub --output-file jwks.json

az storeage blob upload --account-name "oidcdemo1" --container-name "demo" --name "openid/v1/jwks" --file "jwks.json" --overwrite

az storeage blob upload --account-name "oidcdemo1" --container-name "demo" --name ".well-known/openid-configuration" --file "openid-configuration.json" --overwrite

curl -X GET "https://oidcdemo1.blob.core.windows.net/demo/.well-known/openid-configuration"

# https://oidcdemo1.blob.core.windows.net/demo
