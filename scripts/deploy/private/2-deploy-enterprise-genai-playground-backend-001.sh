#!/bin/bash
az account set --subscription f622d6d5-7dd6-4999-9e7a-3401833df0e6

cd ..
./deploy-webapi.sh --subscription f622d6d5-7dd6-4999-9e7a-3401833df0e6 \
--resource-group rg-enterprise-genai-playground-001 \
--deployment-name enterprise-genai-playground-001 \


