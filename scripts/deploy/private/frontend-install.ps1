az account set --subscription f622d6d5-7dd6-4999-9e7a-3401833df0e6 | Out-Null

cd ..

./deploy-webapp.ps1 -Subscription f622d6d5-7dd6-4999-9e7a-3401833df0e6 -ResourceGroupName rg-enterprise-genai-playground-001 -DeploymentName enterprise-genai-playground-001 -FrontendClientId aa2726c4-9fcf-4013-9f5b-8b4249ef3019