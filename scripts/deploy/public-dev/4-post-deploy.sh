#!/bin/bash

RG="enterprise-genai-playground-dev"

unquie_name=copichat-wnn2d4dhf3lom

swa_hostname=$(az staticwebapp show  -n "swa-${unquie_name}" -g "rg-${RG}" --query "defaultHostname" --output tsv)

echo "SWA default hostname: ${swa_hostname}"

az webapp cors add -g  "rg-${RG}" -n "app-${unquie_name}-webapi" --allowed-origins "https://${swa_hostname}" "https://chatkna.kaplan.com"

#az webapp cors add -g  "rg-${RG}" -n "app-${unquie_name}-webapi" --allowed-origins "https://chatkna.kaplan.com"

#az staticwebapp enterprise-edge enable -n "swa-${unquie_name}" -g "rg-${RG}"

#https://lively-bay-0a958de1e.3.azurestaticapps.net/