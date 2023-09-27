#!/bin/bash

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#cd ..
DEPLOYMENT_NAME=enterprise-genai-playground-001
RESOURCE_GROUP=rg-enterprise-genai-playground-001


DEPLOYMENT_JSON=$(az deployment group show --name $DEPLOYMENT_NAME --resource-group $RESOURCE_GROUP --output json)
# get the webapiUrl from the deployment outputs
eval WEB_APP_URL=$(echo $DEPLOYMENT_JSON | jq -r '.properties.outputs.webappUrl.value')
echo "WEB_APP_URL: $WEB_APP_URL"
eval WEB_APP_NAME=$(echo $DEPLOYMENT_JSON | jq -r '.properties.outputs.webappName.value')
echo "WEB_APP_NAME: $WEB_APP_NAME"
eval WEB_API_URL=$(echo $DEPLOYMENT_JSON | jq -r '.properties.outputs.webapiUrl.value')
echo "WEB_API_URL: $WEB_API_URL"
eval WEB_API_NAME=$(echo $DEPLOYMENT_JSON | jq -r '.properties.outputs.webapiName.value')
echo "WEB_API_NAME: $WEB_API_NAME"

WEB_API_SETTINGS=$(az webapp config appsettings list --name $WEB_API_NAME --resource-group $RESOURCE_GROUP --output json)
eval WEB_API_CLIENT_ID=$(echo $WEB_API_SETTINGS | jq '.[] | select(.name=="Authentication:AzureAd:ClientId").value')
eval WEB_API_TENANT_ID=$(echo $WEB_API_SETTINGS | jq '.[] | select(.name=="Authentication:AzureAd:TenantId").value')
eval WEB_API_INSTANCE=$(echo $WEB_API_SETTINGS | jq '.[] | select(.name=="Authentication:AzureAd:Instance").value')
eval WEB_API_SCOPE=$(echo $WEB_API_SETTINGS | jq '.[] | select(.name=="Authentication:AzureAd:Scopes").value')

ENV_FILE_PATH="$SCRIPT_ROOT/../../webapp/.env"
ls -la $SCRIPT_ROOT/

echo $ENV_FILE_PATH
echo "REACT_APP_BACKEND_URI=https://$WEB_API_URL/" > $ENV_FILE_PATH
