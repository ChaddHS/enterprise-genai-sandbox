#!/bin/bash

RG="enterprise-genai-playground-001"

unquie_name=copichat-vnfoe6bhgcytw

swa_hostname=$(az staticwebapp show  -n "swa-${unquie_name}" -g "rg-${RG}" --query "defaultHostname" --output tsv)

echo "SWA default hostname: ${swa_hostname}"

az webapp cors add -g  "rg-${RG}" -n "app-${unquie_name}-webapi" --allowed-origins "https://${swa_hostname}" "https://chatkna.int.kaplan.com"




