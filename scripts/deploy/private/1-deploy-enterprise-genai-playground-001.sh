#chmod +x ./deploy-azure.sh


az account set --subscription f622d6d5-7dd6-4999-9e7a-3401833df0e6

cd ..
./deploy-azure-private.sh --subscription f622d6d5-7dd6-4999-9e7a-3401833df0e6 \
--deployment-name enterprise-genai-playground-001 \
--ai-service AzureOpenAI \
--client-id 252015cb-4c81-4794-a22a-edae1852e5ab \
--tenant-id f895a74b-e96c-4af4-be16-fe5308979167 \
--app-service-sku S2 \
--region eastus



./private/4-post-deploy-001.sh

cd ..

