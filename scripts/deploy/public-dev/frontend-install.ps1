az account set --subscription f622d6d5-7dd6-4999-9e7a-3401833df0e6 | Out-Null

cd ..

./deploy-webapp-apim.ps1 -Subscription f622d6d5-7dd6-4999-9e7a-3401833df0e6 -ResourceGroupName rg-enterprise-genai-playground-dev -DeploymentName enterprise-genai-playground-dev -FrontendClientId aa2726c4-9fcf-4013-9f5b-8b4249ef3019 -UseApim 'yes'


cd ./public-dev