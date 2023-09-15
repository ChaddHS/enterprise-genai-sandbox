#!/bin/bash
az account set --subscription f622d6d5-7dd6-4999-9e7a-3401833df0e6

./deploy-webapp.sh --subscription f622d6d5-7dd6-4999-9e7a-3401833df0e6 \
--resource-group rg-enterprise-genai-playground-v2 \
--deployment-name enterprise-genai-playground-v2 \
--client-id aa2726c4-9fcf-4013-9f5b-8b4249ef3019
