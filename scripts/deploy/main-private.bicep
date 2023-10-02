/*
Copyright (c) Microsoft. All rights reserved.
Licensed under the MIT license. See LICENSE file in the project root for full license information.

Bicep template for deploying CopilotChat Azure resources.
*/

@description('Name for the deployment consisting of alphanumeric characters or dashes (\'-\')')
param name string = 'copichat'

@description('SKU for the Azure App Service plan')
@allowed([ 'B1', 'B3', 'S1', 'S2', 'S3', 'P1V3', 'P2V3', 'I1V2', 'I2V2' ])
param webAppServiceSku string = 'S1'

@description('Location of package to deploy as the web service')
#disable-next-line no-hardcoded-env-urls
param packageUri string = 'https://aka.ms/copilotchat/webapi/latest'

@allowed([ 'private', 'public' ])
@description('Deploy solution as private endpoints')
param deployment string = 'private'

@description('Underlying AI service')
@allowed([
  'AzureOpenAI'
  'OpenAI'
])
param aiService string = 'AzureOpenAI'

@description('Private acs')
param privAcsName string = 'acs'

@description('Model to use for chat completions')
param completionModel string = 'gpt-35-turbo'

@description('Model version')
param modelVersion string = '0301'

@description('Model to use for text embeddings')
param embeddingModel string = 'text-embedding-ada-002'

@description('Completion model the task planner should use')
param plannerModel string = 'gpt-35-turbo'

//@description('Completion model the task planner should use')
//param plannerModel_version string = '0301'

@description('Azure OpenAI endpoint to use (Azure OpenAI only)')
param aiEndpoint string = ''

@secure()
@description('Azure OpenAI or OpenAI API key')
param aiApiKey string = ''

@description('Azure AD client ID for the backend web API')
param webApiClientId string = ''

@description('Azure AD tenant ID for authenticating users')
param azureAdTenantId string = ''

@description('Azure AD cloud instance for authenticating users')
param azureAdInstance string = environment().authentication.loginEndpoint

@description('Whether to deploy a new Azure OpenAI instance')
param deployNewAzureOpenAI bool = false

@description('Whether to deploy Cosmos DB for persistent chat storage')
param deployCosmosDB bool = true

@description('What method to use to persist embeddings')
@allowed([
  'Volatile'
  'AzureCognitiveSearch'
  'Qdrant'
  'Postgres'
])
param memoryStore string = 'Volatile'

@description('Whether to deploy Azure Speech Services to enable input by voice')
param deploySpeechServices bool = true

@description('Whether to deploy the backend Web API package')
param deployWebApiPackage bool = true

@description('Region for the resources')
//param location string = resourceGroup().location
@allowed([
  'northcentralus'
  'eastus'
  'eastus2'
  'southcentralus'
])
param location string = 'eastus'

//@description('Custom dns for vnet')
//param customdns array = [ '172.22.2.8', '172.22.2.9' ]

@description('Region for the webapp frontend')
@allowed([
  'northcentralus'
  'eastus'
  'eastus2'
  'westus2'
  'southcentralus'
])
param webappLocation string = 'westus2'

param vnetCIDR string = '172.22.26.0/24'

// '172.22.26.0/24'

// @description('web subnet')
// param subnet1 object = {
//   name: 'webSubnet'
//   subnet: '172.22.26.0/26'
// }
// @description('qdrant subnet')
// param subnet2 object = {
//   name: 'qdrantSubnet'
//   subnet: '172.22.26.64/26'
// }

// @description('postgres subnet')
// param subnet3 object = {
//   name: 'postgresSubnet'
//   subnet: '172.22.26.128/27'
// }
// @description('privatelinksubnet')
// param subnet4 object = {
//   name: 'websubnet'
//   subnet: '172.22.26.160/27'
// }
// @description('bastion')
// param subnet5 object = {
//   name: 'bastionSubnet'
//   subnet: '172.22.26.224/29'
// }

@description('Hash of the resource group ID')
var rgIdHash = uniqueString(resourceGroup().id)

@description('Deployment name unique to resource group')
var uniqueName = '${name}-${rgIdHash}'

@description('Name of the Azure Storage file share to create')
var storageFileShareName = 'aciqdrantshare'

@description('PostgreSQL admin password')
@secure()
param sqlAdminPassword string = newGuid()

@description('Manditory Tags')
param tags object = {
  APPLICATION: 'Enterprise-GenAI'
  ENVIRONMENT: 'sbx'
  BUSINESS_UNIT: 'KNA'
  OPERATING_HOURS: '24x7'
  NAME: 'Enterprise-GenAI'
  DEPARTMENT: ''
  OWNER: 'brandon.vreuls@kaplan.edu'
  BUSINESS_TIER: 'Low'
  DATA_CLASSIFICATION: ''
  BACKUP: 'False'
  REQUESTER: 'joseph.susai@kaplan.edu'
  COST_CENTER: '302_130077 - Artificial Intelligence Projects'
  GIT_REPO: 'https://github.com/kss-github/enterprise-genai-sandbox.git'
}

@description('Static Web App Tier')
@allowed([ {
    name: 'Standard'
    tier: 'Standard'
  }
  {
    name: 'Free'
    tier: 'Free'
  }

])
param staticWebAppTier object = {
  name: 'Standard'
  tier: 'Standard'

}

@description('Kaplan\'s PAT addresses')
param kaplanIps array = [
  '10.0.0.0/8'
  '172.16.0.0/12'
  '192.168.0.0/16'
  '72.166.181.0/24'
  '72.166.187.0/24'
  '208.44.193.0/24'
  '208.91.164.0/22'
  '34.235.102.62/32'
  '34.236.71.163/32'
  '3.85.246.66/32'
  '34.197.205.65/32'
  '34.237.61.87/32'
  '52.86.170.149/32'
  '52.86.170.30/32'
  '54.235.101.69/32'
  '18.116.2.147/32'
  '18.118.80.82/32'
  '18.189.122.247/32'
  '18.218.115.25/32'
  '18.219.242.65/32'
  '18.220.151.8/32'
  '18.224.123.234/32'
  '18.224.195.20/32'
  '3.135.37.193/32'
  '3.14.51.137/32'
  '3.16.117.93/32'
  '3.16.32.68/32'
  '3.16.71.120/32'
  '3.16.96.176/32'
  '3.19.140.27/32'
  '3.19.87.143/32'
  '3.212.64.113/32'
  '3.81.196.144/32'
  '34.198.234.29/32'
  '52.6.88.180/32'
  '52.71.233.89/32'
  '52.86.163.2/32'
  '13.59.54.179/32'
  '18.220.156.155/32'
  '18.223.6.169/32'
  '18.223.94.228/32'
  '3.128.23.137/32'
  '3.13.111.67/32'
  '3.136.75.72/32'
  '3.141.149.110/32'
  '34.199.124.113/32'
  '34.199.124.191/32'
  '34.199.124.52/32'
  '52.202.31.43/32'
  '52.202.43.140/32'
  '52.202.45.82/32'
  '52.202.21.213/32'
  '52.202.22.112/32'
  '52.202.22.132/32'
  '52.202.24.126/32'
  '52.202.25.28/32'
  '52.202.25.94/32'
  '52.22.176.71/32'
  '52.202.137.87/32'
  '52.202.89.144/32'
  '52.44.114.226/32'
  '52.54.54.58/32'
  '52.55.235.57/32'
  '52.55.78.6/32'
  '52.204.236.124/32'
  '52.205.145.18/32'
  '52.205.75.5/32'
  '52.44.160.17/32'
  '52.44.186.254/32'
  '52.54.161.101/32'
  '18.215.225.249/32'
  '3.214.110.158/32'
  '3.214.48.162/32'
  '3.84.175.134/32'
  '34.194.215.117/32'
  '34.200.182.228/32'
  '52.200.200.6/32'
  '52.203.249.240/32'
  '52.21.225.15/32'
  '54.160.35.89/32'
  '54.225.206.185/32'
  '54.243.28.178/32'
  '13.58.12.215/32'
  '18.118.204.249/32'
  '18.119.61.65/32'
  '18.188.98.137/32'
  '18.189.19.83/32'
  '18.216.54.242/32'
  '18.220.102.86/32'
  '18.221.245.189/32'
  '18.224.240.76/32'
  '3.135.132.218/32'
  '3.136.219.142/32'
  '3.142.224.124/32'
  '3.17.51.86/32'
  '3.17.99.255/32'
  '3.18.216.65/32'
  '3.18.248.10/32'
  '3.19.160.250/32'
  '3.20.136.252/32'
  '3.21.74.83/32'
  '3.22.141.48/32'
  '3.23.42.194/32'
  '52.15.35.166/32'
  '52.15.87.70/32'
  '184.72.150.115/32'
  '3.221.81.51/32'
  '3.230.253.13/32'
  '34.235.28.162/32'
  '34.236.126.152/32'
  '35.173.79.146/32'
  '44.205.173.66/32'
  '44.208.134.63/32'
  '44.209.46.85/32'
  '52.54.40.171/32'
  '54.210.15.191/32'
  '54.80.37.238/32'
  '18.119.65.187/32'
  '3.21.61.95/32'
  '107.21.53.227/32'
  '107.23.18.121/32'
  '18.215.49.4/32'
  '54.210.242.95/32'
  '54.236.215.220/32'
  '54.85.147.209/32'
  '107.21.9.54/32'
  '107.23.120.61/32'
  '107.23.120.65/32'
  '107.23.50.79/32'
  '107.23.51.111/32'
  '3.234.172.59/32'
  '34.235.45.187/32'
  '52.1.127.38/32'
  '54.164.142.255/32'
  '54.208.129.148/32'
  '35.169.235.255/32'
  '52.202.203.185/32'
  '52.203.75.102/32'
  '52.55.155.164/32'
  '52.55.55.80/32'
  '52.71.13.109/32'
  '52.71.153.191/32'
  '34.226.231.173/32'
  '35.168.123.194/32'
  '52.205.22.119/32'
  '52.205.61.156/32'
  '50.16.176.183/32'
  '52.200.80.228/32'
  '52.203.120.206/32'
  '52.4.11.202/32'
  '52.202.223.208/32'
  '52.70.125.206/32'
  '3.225.57.247/32'
  '3.82.135.45/32'
  '34.196.185.67/32'
  '34.200.172.156/32'
  '3.219.66.213/32'
  '34.234.182.193/32'
  '34.238.145.41/32'
  '52.71.37.84/32'
  '3.220.55.125/32'
  '3.232.254.171/32'
  '3.233.182.246/32'
  '34.192.219.96/32'
  '35.169.167.106/32'
  '50.16.165.27/32'
  '50.17.179.132/32'
  '52.45.92.123/32'
  '52.71.45.229/32'
  '52.73.208.170/32'
  '54.204.219.197/32'
  '18.205.111.22/32'
  '18.206.43.14/32'
  '18.207.50.183/32'
  '18.209.131.73/32'
  '18.211.153.241/32'
  '18.211.99.35/32'
  '184.72.115.121/32'
  '184.72.115.229/32'
  '3.209.115.147/32'
  '3.212.97.167/32'
  '3.212.99.40/32'
  '3.215.54.177/32'
  '3.215.84.112/32'
  '3.227.138.50/32'
  '3.233.123.111/32'
  '3.88.246.0/32'
  '34.201.176.82/32'
  '34.228.67.174/32'
  '34.230.199.153/32'
  '34.237.196.12/32'
  '35.173.40.254/32'
  '50.17.79.45/32'
  '52.200.108.235/32'
  '52.23.113.232/32'
  '52.3.19.231/32'
  '52.45.48.162/32'
  '52.54.180.200/32'
  '52.73.103.158/32'
  '52.73.179.85/32'
  '52.87.92.108/32'
  '54.158.131.14/32'
  '54.204.56.254/32'
  '54.209.28.49/32'
  '54.82.153.141/32'
  '54.85.185.29/32'
  '54.86.132.110/32'
  '54.86.144.28/32'
  '23.23.107.196/32'
  '3.210.129.82/32'
  '3.218.111.167/32'
  '3.220.156.77/32'
  '34.202.243.206/32'
  '34.230.136.117/32'
  '44.208.233.210/32'
  '44.209.210.178/32'
  '52.202.69.202/32'
  '52.44.20.47/32'
  '52.55.193.116/32'
  '52.7.14.1/32'
  '54.162.10.222/32'
  '54.81.154.214/32'
  '96.60.175.227/32'

]

param azurePortalIps array = [
  '104.42.195.92/32'
  '40.76.54.131/32'
  '52.176.6.30/32'
  '52.169.50.45/32'
  '52.187.184.26/32'
]

var allIps = concat(kaplanIps, azurePortalIps)

param cosmosdbAllowedIps array = [
  {
    ipAddressOrRange: '104.42.195.92/32'
  }
  {
    ipAddressOrRange: '40.76.54.131/32'
  }
  {
    ipAddressOrRange: '52.176.6.30/32'
  }
  {
    ipAddressOrRange: '52.169.50.45/32'
  }
  {
    ipAddressOrRange: '52.187.184.26/32'
  }
  {
    ipAddressOrRange: '0.0.0.0'
  }
]

//
// Azure API management
//
//
@description('deploy API Management')
param deployAPIm string = 'yes'

@description('deploy API Management private or public')
param deployPrivateAPIm string = 'yes'

@description('The name of the API Management service instance')
param apiManagementServiceName string = 'apiservice${uniqueString(resourceGroup().id)}'

@description('The email address of the owner of the service')
@minLength(1)
param publisherEmail string = 'christopher.tatro@kaplan.edu'

@description('The name of the owner of the service')
@minLength(1)
param publisherName string = 'Chris Tatro'

@description('The pricing tier of this API Management service')
@allowed([
  'Developer'
  'Standard'
  'Premium'
])
param sku string = 'Developer'

@description('The instance size of this API Management service.')
@allowed([
  1
  2
])
param skuCount int = 1

// @description('Location for all resources.')
// param location string = resourceGroup().location

// VM configuration
//
//
//

@description('Username for the Virtual Machine.')
param adminUsername string = 'kapadmin'

@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param adminPassword string

@description('Unique DNS Name for the Public IP used to access the Virtual Machine.')
param dnsLabelPrefix string = toLower('${vmName}-${uniqueString(resourceGroup().id, vmName)}')

@description('Name for the Public IP used to access the Virtual Machine.')
param publicIpName string = 'myPublicIP'

@description('Allocation method for the Public IP used to access the Virtual Machine.')
@allowed([
  'Dynamic'
  'Static'
])
param publicIPAllocationMethod string = 'Dynamic'

@description('SKU for the Public IP used to access the Virtual Machine.')
@allowed([
  'Basic'
  'Standard'
])
param publicIpSku string = 'Basic'

@description('The Windows version for the VM. This will pick a fully patched image of this given Windows version.')
@allowed([
  '2016-datacenter-gensecond'
  '2016-datacenter-server-core-g2'
  '2016-datacenter-server-core-smalldisk-g2'
  '2016-datacenter-smalldisk-g2'
  '2016-datacenter-with-containers-g2'
  '2016-datacenter-zhcn-g2'
  '2019-datacenter-core-g2'
  '2019-datacenter-core-smalldisk-g2'
  '2019-datacenter-core-with-containers-g2'
  '2019-datacenter-core-with-containers-smalldisk-g2'
  '2019-datacenter-gensecond'
  '2019-datacenter-smalldisk-g2'
  '2019-datacenter-with-containers-g2'
  '2019-datacenter-with-containers-smalldisk-g2'
  '2019-datacenter-zhcn-g2'
  '2022-datacenter-azure-edition'
  '2022-datacenter-azure-edition-core'
  '2022-datacenter-azure-edition-core-smalldisk'
  '2022-datacenter-azure-edition-smalldisk'
  '2022-datacenter-core-g2'
  '2022-datacenter-core-smalldisk-g2'
  '2022-datacenter-g2'
  '2022-datacenter-smalldisk-g2'
])
param OSVersion string = '2022-datacenter-azure-edition'

@description('Size of the virtual machine.')

// vmsize Standard_D2ds_v4 is required if you deploy bastion host and intend to run nested vm (for example wsl2)
param vmSize string = 'Standard_D2ds_v4'

// @description('Location for all resources.')
// param location string = resourceGroup().location

@description('Name of the virtual machine.')
param vmName string = 'simple-vm'

// @description('Security Type of the Virtual Machine.')
// @allowed([
//   'Standard'
//   'TrustedLaunch'
// ])
// param securityType string = 'Standard'

//var storageAccountName = 'bootdiags${uniqueString(resourceGroup().id)}'
var nicName = 'myVMNic'
// var addressPrefix = '10.0.0.0/16'
// var subnetName = 'Subnet'
// var subnetPrefix = '10.0.0.0/24'
// var virtualNetworkName = 'MyVNET'
var networkSecurityGroupName = 'default-NSG'

//var subdomain1 = 'privatelink'
var subdomain = contains(deployment, '.private') ? 'privatelink' : ''
// var securityProfileJson = {
//   uefiSettings: {
//     secureBootEnabled: true
//     vTpmEnabled: true
//   }
//   securityType: securityType
// }
// var extensionName = 'GuestAttestation'
// var extensionPublisher = 'Microsoft.Azure.Security.WindowsAttestation'
// var extensionVersion = '1.0'
// var maaTenantName = 'GuestAttestation'
// var maaEndpoint = substring('emptyString', 0, 0)

// open ai config
@description('enable custom dns servers on vnet')
param customdns bool = true

var dns = customdns ? [ '172.22.2.8', '172.22.2.9' ] : []

//@description('Custom dns for vnet')
//param customdns array = [ '172.22.2.8', '172.22.2.9' ]

resource openAI 'Microsoft.CognitiveServices/accounts@2022-12-01' = if (deployNewAzureOpenAI) {
  name: 'ai-${uniqueName}'
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }

  tags: tags
  properties: {
    customSubDomainName: toLower(uniqueName)
    publicNetworkAccess: contains(deployment, 'private') ? 'Disabled' : 'Enabled'
    //publicNetworkAccess: 'Enabled'

    networkAcls: {
      defaultAction: 'Allow'
    }

  }
}

resource openaiPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = if (deployment == 'private') {
  name: 'openai-${uniqueName}-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: virtualNetwork.properties.subnets[3].id
    }
    privateLinkServiceConnections: [
      {
        name: 'openai'
        properties: {
          privateLinkServiceId: openAI.id
          groupIds: [
            'account'
          ]
        }
      }
    ]
  }
}

param deployPrivateZones string = 'no'
param deployPrivateZoneArecord string = 'no'

param deployPrivateZoneArecordExistingZone string = 'yes'

resource openaiDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if ((deployment == 'private') && (deployPrivateZones == 'yes')) {
  name: 'privatelink.openai.azure.com'
  location: 'global'
  tags: tags
}

resource openaiDNSZoneVirtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if ((deployment == 'private') && (deployPrivateZones == 'yes')) {
  parent: openaiDNSZone
  name: 'openai-${uniqueName}-vnl'
  location: 'global'
  tags: tags
  properties: {
    virtualNetwork: {
      id: virtualNetwork.id
    }
    registrationEnabled: false
  }
}

resource openaiSymbolicname 'Microsoft.Network/privateDnsZones/A@2020-06-01' = if ((deployment == 'private') && (deployPrivateZones == 'yes')) {
  name: openAI.name
  parent: openaiDNSZone

  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: openaiPrivateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
      }
    ]

  }

  dependsOn: []
}

resource openaiSymbolicname2 'Microsoft.Network/privateDnsZones/A@2020-06-01' = if ((deployment == 'private') && (deployPrivateZones == 'yes')) {
  name: toLower(uniqueName)
  parent: openaiDNSZone

  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: openaiPrivateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
      }
    ]

  }

  dependsOn: []
}

// resource openaiCognitiveservicesDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (deployment == 'private') {
//   name: 'privatelink.cognitiveservices.azure.com'
//   location: 'global'
//   tags: tags
// }

// resource openaiCognitiveservicesDNSZoneVirtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (deployment == 'private') {
//   parent: openaiCognitiveservicesDNSZone
//   name: 'openai-cognitiveservices-${uniqueName}-vnl'
//   location: 'global'
//   tags: tags
//   properties: {
//     virtualNetwork: {
//       id: virtualNetwork.id
//     }
//     registrationEnabled: false
//   }
// }

resource openAI_completionModel 'Microsoft.CognitiveServices/accounts/deployments@2022-12-01' = if (deployNewAzureOpenAI) {
  //resource openAI_completionModel 'Microsoft.CognitiveServices/accounts/deployments@2022-12-01' = if (deployNewAzureOpenAI) {
  parent: openAI
  name: completionModel

  properties: {

    model: {
      format: 'OpenAI'
      name: completionModel
      // version: modelVersion
    }
    scaleSettings: {
      //  capacity: 30
      scaleType: 'Standard'
    }
  }
  // sku: {
  //   name: 'S0'
  //   //capacity: 120
  //   tier: 'Standard'
  // }
}

resource openAI_embeddingModel 'Microsoft.CognitiveServices/accounts/deployments@2022-12-01' = if (deployNewAzureOpenAI) {
  //resource openAI_embeddingModel 'Microsoft.CognitiveServices/accounts/deployments@2022-12-01' = if (deployNewAzureOpenAI) {
  parent: openAI
  name: embeddingModel
  properties: {
    model: {
      format: 'OpenAI'
      name: embeddingModel
      // version: modelVersion
    }

    scaleSettings: {
      //  capacity: 30
      scaleType: 'Standard'
    }
  }

  //   sku: {
  //     name: 'S0'
  //     capacity: 10
  //     tier: 'Standard'
  //   }
  dependsOn: [// This "dependency" is to create models sequentially because the resource
    openAI_completionModel // provider does not support parallel creation of models properly.
  ]
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: 'asp-${uniqueName}-webapi'
  location: location
  kind: 'app'
  tags: tags
  sku: {
    name: webAppServiceSku
    // tier: 'Standard'
  }
}

resource appServiceWeb 'Microsoft.Web/sites@2022-09-01' = {
  name: 'app-${uniqueName}-webapi'
  location: location
  kind: 'app'
  tags: union(tags, {
      skweb: '1'
    })

  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    virtualNetworkSubnetId: virtualNetwork.properties.subnets[0].id
    siteConfig: {
      healthCheckPath: '/healthz'
    }
  }
}

resource appPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = if (deployment == 'private') {
  name: 'app-${uniqueName}-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: virtualNetwork.properties.subnets[3].id
    }
    privateLinkServiceConnections: [
      {
        name: 'app'
        properties: {
          privateLinkServiceId: appServiceWeb.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
}

resource sitesDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if ((deployment == 'private') && (deployPrivateZones == 'yes')) {
  name: 'privatelink.azurewebsites.net'
  location: 'global'
  tags: tags
}

resource appVirtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if ((deployment == 'private') && (deployPrivateZones == 'yes')) {
  parent: sitesDNSZone
  name: 'app-${uniqueName}-vnl'
  location: 'global'
  tags: tags
  properties: {
    virtualNetwork: {
      id: virtualNetwork.id
    }
    registrationEnabled: false
  }
}

resource sitesSymbolicname 'Microsoft.Network/privateDnsZones/A@2020-06-01' = if ((deployment == 'private') && (deployPrivateZones == 'yes')) {
  name: appServiceWeb.name
  parent: sitesDNSZone

  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: appPrivateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
      }
    ]

  }

  dependsOn: []
}

// resource appPrivateEndpointscm 'Microsoft.Network/privateEndpoints@2023-04-01' = if (deployment == 'private') {
//   name: 'app-${uniqueName}-scm-pe'
//   location: location
//   tags: tags
//   properties: {
//     subnet: {
//       id: virtualNetwork.properties.subnets[3].id
//     }
//     privateLinkServiceConnections: [
//       {
//         name: 'app'
//         properties: {
//           privateLinkServiceId: appServiceWeb.id
//           groupIds: [
//             'sites'
//           ]
//         }
//       }
//     ]
//   }
// }

resource sitesDNSZonescm 'Microsoft.Network/privateDnsZones@2020-06-01' = if ((deployment == 'private') && (deployPrivateZones == 'yes')) {
  name: 'scm.privatelink.azurewebsites.net'
  location: 'global'
  tags: tags
}

resource appVirtualNetworkLinkscm 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if ((deployment == 'private') && (deployPrivateZones == 'yes')) {
  parent: sitesDNSZonescm
  name: 'app-${uniqueName}-scm-vnl'
  location: 'global'
  tags: tags
  properties: {
    virtualNetwork: {
      id: virtualNetwork.id
    }
    registrationEnabled: false
  }
}

resource sitesSymbolicnamescm 'Microsoft.Network/privateDnsZones/A@2020-06-01' = if ((deployment == 'private') && (deployPrivateZones == 'yes')) {
  name: appServiceWeb.name
  parent: sitesDNSZonescm

  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: appPrivateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
      }
    ]

  }

  dependsOn: []
}

resource appServiceWebLog 'Microsoft.Web/sites/config@2022-09-01' = {
  name: 'logs'
  parent: appServiceWeb
  properties: {
    applicationLogs: {

      fileSystem: {
        level: 'Error'
      }
    }
    httpLogs: {
      fileSystem: {
        enabled: true
        retentionInDays: 3
        retentionInMb: 50
      }
    }
  }

}

resource appServiceWebConfig 'Microsoft.Web/sites/config@2022-09-01' = {
  //resource appServiceWebConfig 'Microsoft.Web/sites/config@2022-09-01' = if (deployment == 'public') {
  parent: appServiceWeb
  name: 'web'
  properties: {
    alwaysOn: false
    cors: {
      allowedOrigins: [
        'http://localhost:3000'
        'https://localhost:3000'
        'https://chatkna.kaplan.com'
        'https://chatkna.int.kaplan.com'
      ]
      supportCredentials: true
    }
    detailedErrorLoggingEnabled: true
    minTlsVersion: '1.2'
    netFrameworkVersion: 'v6.0'
    use32BitWorkerProcess: false
    vnetRouteAllEnabled: true
    webSocketsEnabled: true

    appSettings: [
      {
        name: 'ASPNETCORE_ENVIRONMENT'
        value: 'Development'
      }
      {
        name: 'AIService:Type'
        value: aiService
      }
      {
        name: 'AIService:Endpoint'
        value: deployNewAzureOpenAI ? openAI.properties.endpoint : aiEndpoint
      }
      {
        name: 'AIService:Key'
        value: deployNewAzureOpenAI ? openAI.listKeys().key1 : aiApiKey
      }
      {
        name: 'AIService:Models:Completion'
        value: completionModel
      }
      {
        name: 'AIService:Models:Embedding'
        value: embeddingModel
      }
      {
        name: 'AIService:Models:Planner'
        value: plannerModel
      }
      {
        name: 'Authentication:Type'
        value: 'AzureAd'
      }
      {
        name: 'Authentication:AzureAd:Instance'
        value: azureAdInstance
      }
      {
        name: 'Authentication:AzureAd:TenantId'
        value: azureAdTenantId
      }
      {
        name: 'Authentication:AzureAd:ClientId'
        value: webApiClientId
      }
      {
        name: 'Authentication:AzureAd:Scopes'
        value: 'access_as_user'
      }
      {
        name: 'ChatStore:Type'
        value: deployCosmosDB ? 'cosmos' : 'volatile'
      }
      {
        name: 'ChatStore:Cosmos:Database'
        value: 'CopilotChat'
      }
      {
        name: 'ChatStore:Cosmos:ChatSessionsContainer'
        value: 'chatsessions'
      }
      {
        name: 'ChatStore:Cosmos:ChatMessagesContainer'
        value: 'chatmessages'
      }
      {
        name: 'ChatStore:Cosmos:ChatMemorySourcesContainer'
        value: 'chatmemorysources'
      }
      {
        name: 'ChatStore:Cosmos:ChatParticipantsContainer'
        value: 'chatparticipants'
      }
      {
        name: 'ChatStore:Cosmos:ConnectionString'
        value: deployCosmosDB ? cosmosAccount.listConnectionStrings().connectionStrings[0].connectionString : ''
      }
      {
        name: 'MemoryStore:Type'
        value: memoryStore
      }
      {
        name: 'MemoryStore:Qdrant:Host'
        value: memoryStore == 'Qdrant' ? 'https://${appServiceQdrant.properties.defaultHostName}' : ''
      }
      {
        name: 'MemoryStore:Qdrant:Port'
        value: '443'
      }
      {
        name: 'MemoryStore:AzureCognitiveSearch:UseVectorSearch'
        value: 'true'
      }
      {
        name: 'MemoryStore:AzureCognitiveSearch:Endpoint'
        value: memoryStore == 'AzureCognitiveSearch' ? 'https://${azureCognitiveSearch.name}.search.windows.net' : ''
      }
      {
        name: 'MemoryStore:AzureCognitiveSearch:Key'
        value: memoryStore == 'AzureCognitiveSearch' ? azureCognitiveSearch.listAdminKeys().primaryKey : ''
      }
      {
        name: 'MemoryStore:Postgres:ConnectionString'
        value: memoryStore == 'Postgres' ? 'Host=${postgreServerGroup.properties.serverNames[0].fullyQualifiedDomainName}:5432;Username=citus;Password=${sqlAdminPassword};Database=citus' : ''
      }
      {
        name: 'AzureSpeech:Region'
        value: location
      }
      {
        name: 'AzureSpeech:Key'
        value: deploySpeechServices ? speechAccount.listKeys().key1 : ''
      }
      {
        name: 'AllowedOrigins'
        value: '[*]' // Defer list of allowed origins to the Azure service app's CORS configuration
      }
      {
        name: 'Kestrel:Endpoints:Https:Url'
        value: 'https://localhost:443'
      }
      {
        name: 'Logging:LogLevel:Default'
        value: 'Warning'
      }
      {
        name: 'Logging:LogLevel:CopilotChat.WebApi'
        value: 'Warning'
      }
      {
        name: 'Logging:LogLevel:Microsoft.SemanticKernel'
        value: 'Warning'
      }
      {
        name: 'Logging:LogLevel:Microsoft.AspNetCore.Hosting'
        value: 'Warning'
      }
      {
        name: 'Logging:LogLevel:Microsoft.Hosting.Lifetimel'
        value: 'Warning'
      }
      {
        name: 'ApplicationInsights:ConnectionString'
        value: appInsights.properties.ConnectionString
      }
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: appInsights.properties.ConnectionString
      }
      {
        name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
        value: '~2'
      }
    ]
  }
}

resource appServiceWebDeploy 'Microsoft.Web/sites/extensions@2022-09-01' = if (deployWebApiPackage) {
  name: 'MSDeploy'
  kind: 'string'
  parent: appServiceWeb
  properties: {
    packageUri: packageUri
  }
  dependsOn: [
    appServiceWebConfig
  ]
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appins-${uniqueName}'
  location: location
  kind: 'string'
  tags: union(tags, {
      displayName: 'AppInsight'
    })
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

resource appInsightExtension 'Microsoft.Web/sites/siteextensions@2022-09-01' = {
  parent: appServiceWeb
  name: 'Microsoft.ApplicationInsights.AzureWebSites'
  dependsOn: [ appServiceWebConfig ]
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'la-${uniqueName}'
  location: location
  tags: union(tags, {
      displayName: 'Log Analytics'
    })
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 90
    features: {
      searchVersion: 1
      legacy: 0
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2022-09-01' = if (memoryStore == 'Qdrant') {
  name: 'st${rgIdHash}' // Not using full unique name to avoid hitting 24 char limit
  location: location
  kind: 'StorageV2'
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
  }
  resource fileservices 'fileServices' = {
    name: 'default'
    resource share 'shares' = {
      name: storageFileShareName
    }
  }
}

resource storageaccount 'Microsoft.Storage/storageAccounts@2022-09-01' = if (deployment == 'private') {
  name: 'sta${rgIdHash}' // Not using full unique name to avoid hitting 24 char limit
  location: location
  kind: 'StorageV2'
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
  }
  resource fileservices 'fileServices' = {
    name: 'default'
    resource share 'shares' = {
      name: storageFileShareName
    }
  }
}

resource staPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = if (deployment == 'private') {
  name: 'sta-${uniqueName}-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: virtualNetwork.properties.subnets[3].id
    }
    privateLinkServiceConnections: [
      {
        name: 'sta'
        properties: {
          privateLinkServiceId: storageaccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource staDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if ((deployment == 'private') && (deployPrivateZones == 'yes')) {
  name: 'privatelink.blob.core.windows.net'
  location: 'global'
  tags: tags
}

resource staVirtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if ((deployment == 'private') && (deployPrivateZones == 'yes')) {
  parent: staDNSZone
  name: 'sta-${uniqueName}-vnl'
  location: 'global'
  tags: tags
  properties: {
    virtualNetwork: {
      id: virtualNetwork.id
    }
    registrationEnabled: false

  }
}

resource staSymbolicname 'Microsoft.Network/privateDnsZones/A@2020-06-01' = if ((deployment == 'private') && (deployPrivateZones == 'yes')) {
  name: storageaccount.name
  parent: staDNSZone

  properties: {
    ttl: 3600

    aRecords: [
      {
        ipv4Address: staPrivateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
      }
    ]

  }

  dependsOn: []
}

resource appServicePlanQdrant 'Microsoft.Web/serverfarms@2022-03-01' = if (memoryStore == 'Qdrant') {
  name: 'asp-${uniqueName}-qdrant'
  location: location
  tags: tags
  kind: 'linux'
  sku: {
    name: 'P1v3'
  }
  properties: {
    reserved: true
  }
}

resource appServiceQdrant 'Microsoft.Web/sites@2022-09-01' = if (memoryStore == 'Qdrant') {
  name: 'app-${uniqueName}-qdrant'
  location: location
  tags: tags
  kind: 'app,linux,container'
  properties: {
    serverFarmId: appServicePlanQdrant.id
    httpsOnly: true
    reserved: true
    clientCertMode: 'Required'
    virtualNetworkSubnetId: virtualNetwork.properties.subnets[1].id
    siteConfig: {
      numberOfWorkers: 1
      linuxFxVersion: 'DOCKER|qdrant/qdrant:latest'
      alwaysOn: true
      vnetRouteAllEnabled: true
      ipSecurityRestrictions: [
        {
          vnetSubnetResourceId: virtualNetwork.properties.subnets[0].id
          action: 'Allow'
          priority: 300
          name: 'Allow front vnet'
        }
        {
          ipAddress: 'Any'
          action: 'Deny'
          priority: 2147483647
          name: 'Deny all'
        }
      ]
      azureStorageAccounts: {
        aciqdrantshare: {
          type: 'AzureFiles'
          accountName: memoryStore == 'Qdrant' ? storage.name : 'notdeployed'
          shareName: storageFileShareName
          mountPath: '/qdrant/storage'
          accessKey: memoryStore == 'Qdrant' ? storage.listKeys().keys[0].value : ''
        }
      }
    }
  }
}

resource azureCognitiveSearch 'Microsoft.Search/searchServices@2022-09-01' = if (memoryStore == 'AzureCognitiveSearch') {
  name: 'acs-${uniqueName}'
  location: location
  tags: tags
  sku: {
    name: 'basic'
  }
  properties: {
    replicaCount: 1
    partitionCount: 1
  }
}

resource acsPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = if (deployment == 'private') {
  name: 'acs-${uniqueName}-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: virtualNetwork.properties.subnets[3].id
    }
    privateLinkServiceConnections: [
      {
        name: 'acs'
        properties: {
          privateLinkServiceId: azureCognitiveSearch.id
          groupIds: [
            'searchService'
          ]
        }
      }
    ]
  }
}

resource acsDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if ((deployment == 'private') && (deployPrivateZones == 'yes')) {
  name: 'privatelink.search.windows.net'
  location: 'global'
  tags: tags
}

resource acsVirtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if ((deployment == 'private') && (deployPrivateZones == 'yes')) {
  parent: acsDNSZone
  name: 'acs-${uniqueName}-vnl'
  location: 'global'
  tags: tags
  properties: {
    virtualNetwork: {
      id: virtualNetwork.id
    }
    registrationEnabled: false

  }
}

resource acsSymbolicname 'Microsoft.Network/privateDnsZones/A@2020-06-01' = if ((deployment == 'private') && (deployPrivateZones == 'yes')) {
  name: azureCognitiveSearch.name
  parent: acsDNSZone

  properties: {
    ttl: 3600

    aRecords: [
      {
        ipv4Address: acsPrivateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
      }
    ]

  }

  dependsOn: []
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: 'vnet-${uniqueName}'
  location: location
  tags: tags
  properties: {
    dhcpOptions: {
      dnsServers: dns
    }

    addressSpace: {
      addressPrefixes: [
        vnetCIDR
      ]
    }
    subnets: [
      {
        name: 'webSubnet'
        properties: {
          addressPrefix: '172.22.26.0/26'
          networkSecurityGroup: {
            id: webNsg.id
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.Web'
              locations: [
                '*'
              ]
            }
          ]
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'qdrantSubnet'
        properties: {
          addressPrefix: '172.22.26.64/26'
          networkSecurityGroup: {
            id: qdrantNsg.id
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.Web'
              locations: [
                '*'
              ]
            }
          ]
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'postgresSubnet'
        properties: {
          addressPrefix: '172.22.26.128/27'
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }

      }

      {
        name: 'privateEndpointSubnet'
        properties: {
          addressPrefix: '172.22.26.160/27'
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }

      }

      {
        name: 'bastionSubnet'
        properties: {
          addressPrefix: '172.22.26.224/29'
          networkSecurityGroup: {
            id: bastionnsg.id
          }
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }

      }
    ]
  }
}

resource webNsg 'Microsoft.Network/networkSecurityGroups@2022-11-01' = {
  name: 'nsg-${uniqueName}-webapi'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowAnyHTTPSInbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      // {
      //   name: 'AllowAnyHTTPInbound'
      //   properties: {
      //     protocol: 'TCP'
      //     sourcePortRange: '*'
      //     destinationPortRange: '80'
      //     sourceAddressPrefix: '*'
      //     destinationAddressPrefix: '*'
      //     access: 'Allow'
      //     priority: 105
      //     direction: 'Inbound'
      //   }
      // }
      {
        name: 'AllowAnyOutbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource bastionnsg 'Microsoft.Network/networkSecurityGroups@2022-11-01' = if (deployment == 'private') {
  name: 'nsg-${uniqueName}-bastion'
  location: location
  tags: tags
  properties: {
    securityRules: [
      // {
      //   name: 'AllowAnyHTTPSInbound'
      //   properties: {
      //     protocol: 'TCP'
      //     sourcePortRange: '*'
      //     destinationPortRange: '3389'
      //     sourceAddressPrefixes: kaplanIps
      //     destinationAddressPrefix: '*'
      //     access: 'Allow'
      //     priority: 100
      //     direction: 'Inbound'
      //   }
      //}
      {
        name: 'AllowAnyInbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }

    ]
  }
}

resource qdrantNsg 'Microsoft.Network/networkSecurityGroups@2022-11-01' = {
  name: 'nsg-${uniqueName}-qdrant'
  location: location
  tags: tags
  properties: {
    securityRules: []
  }
}

resource webSubnetConnection 'Microsoft.Web/sites/virtualNetworkConnections@2022-09-01' = {
  parent: appServiceWeb
  name: 'webSubnetConnection'

  properties: {
    vnetResourceId: virtualNetwork.properties.subnets[0].id
    isSwift: true
  }
}

resource qdrantSubnetConnection 'Microsoft.Web/sites/virtualNetworkConnections@2022-09-01' = if (memoryStore == 'Qdrant') {
  parent: appServiceQdrant
  name: 'qdrantSubnetConnection'

  properties: {
    vnetResourceId: virtualNetwork.properties.subnets[1].id
    isSwift: true
  }
}

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = if (deployCosmosDB) {
  name: toLower('cosmos-${uniqueName}')
  location: location
  kind: 'GlobalDocumentDB'
  tags: tags
  properties: {
    networkAclBypass: 'AzureServices'
    publicNetworkAccess: 'Enabled'
    ipRules: cosmosdbAllowedIps
    consistencyPolicy: { defaultConsistencyLevel: 'Session' }
    locations: [ {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    databaseAccountOfferType: 'Standard'
  }
}

resource cosmosDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-04-15' = if (deployCosmosDB) {
  parent: cosmosAccount
  name: 'CopilotChat'
  tags: tags
  properties: {
    resource: {
      id: 'CopilotChat'
    }
  }
}

resource messageContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = if (deployCosmosDB) {
  parent: cosmosDatabase
  name: 'chatmessages'
  tags: tags
  properties: {
    resource: {
      id: 'chatmessages'
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/"_etag"/?'
          }
        ]
      }
      partitionKey: {
        paths: [
          '/chatId'
        ]
        kind: 'Hash'
        version: 2
      }
    }
  }
}

resource sessionContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = if (deployCosmosDB) {
  parent: cosmosDatabase
  name: 'chatsessions'
  tags: tags
  properties: {
    resource: {
      id: 'chatsessions'
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/"_etag"/?'
          }
        ]
      }
      partitionKey: {
        paths: [
          '/id'
        ]
        kind: 'Hash'
        version: 2
      }
    }
  }
}

resource participantContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = if (deployCosmosDB) {
  parent: cosmosDatabase
  name: 'chatparticipants'
  tags: tags
  properties: {
    resource: {
      id: 'chatparticipants'
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/"_etag"/?'
          }
        ]
      }
      partitionKey: {
        paths: [
          '/userId'
        ]
        kind: 'Hash'
        version: 2
      }
    }
  }
}

resource memorySourcesContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = if (deployCosmosDB) {
  parent: cosmosDatabase
  name: 'chatmemorysources'
  tags: tags
  properties: {
    resource: {
      id: 'chatmemorysources'
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/"_etag"/?'
          }
        ]
      }
      partitionKey: {
        paths: [
          '/chatId'
        ]
        kind: 'Hash'
        version: 2
      }
    }
  }
}

resource cosmosPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = if (deployment == 'private') {
  name: 'cosmos-${uniqueName}-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: virtualNetwork.properties.subnets[3].id
    }
    privateLinkServiceConnections: [
      {
        name: 'cosmos'
        properties: {
          privateLinkServiceId: cosmosAccount.id
          groupIds: [
            'Sql'
          ]
        }
      }
    ]
  }
}

resource cosmosDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if ((deployment == 'private') && (deployPrivateZones == 'yes')) {
  name: 'privatelink.documents.azure.com'
  location: 'global'
  tags: tags
}

resource cosmosVirtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if ((deployment == 'private') && (deployPrivateZones == 'yes')) {
  parent: cosmosDNSZone
  name: 'cosmos-${uniqueName}-vnl'
  location: 'global'
  tags: tags
  properties: {
    virtualNetwork: {
      id: virtualNetwork.id
    }
    registrationEnabled: false

  }
}

resource cosmosSymbolicname 'Microsoft.Network/privateDnsZones/A@2020-06-01' = if ((deployment == 'private') && (deployPrivateZones == 'yes')) {
  name: cosmosAccount.name
  parent: cosmosDNSZone

  properties: {
    ttl: 3600

    aRecords: [
      {
        ipv4Address: cosmosPrivateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
      }
    ]

  }

  dependsOn: []
}

// Postgres persistent store

resource postgreServerGroup 'Microsoft.DBforPostgreSQL/serverGroupsv2@2022-11-08' = if (memoryStore == 'Postgres') {
  name: 'pg-${uniqueName}'
  location: location
  tags: tags
  properties: {
    postgresqlVersion: '15'
    administratorLoginPassword: sqlAdminPassword
    enableHa: false
    coordinatorVCores: 1
    coordinatorServerEdition: 'BurstableMemoryOptimized'
    coordinatorStorageQuotaInMb: 32768
    nodeVCores: 4
    nodeCount: 0
    nodeStorageQuotaInMb: 524288
    nodeEnablePublicIpAccess: false
  }
}

resource postgresDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (memoryStore == 'Postgres') {
  name: 'privatelink.postgres.cosmos.azure.com'
  location: 'global'
  tags: tags
}

resource postgresPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = if (memoryStore == 'Postgres') {
  name: 'pg-${uniqueName}-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: virtualNetwork.properties.subnets[2].id
    }
    privateLinkServiceConnections: [
      {
        name: 'postgres'
        properties: {
          privateLinkServiceId: postgreServerGroup.id
          groupIds: [
            'coordinator'
          ]
        }
      }
    ]
  }
}

resource postgresVirtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (memoryStore == 'Postgres') {
  parent: postgresDNSZone
  name: 'pg-${uniqueName}-vnl'
  location: 'global'
  tags: tags
  properties: {
    virtualNetwork: {
      id: virtualNetwork.id
    }
    registrationEnabled: true
  }
}

resource postgresPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-04-01' = if (memoryStore == 'Postgres') {
  #disable-next-line use-parent-property
  name: '${postgresPrivateEndpoint.name}/default'

  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'postgres'
        properties: {
          privateDnsZoneId: postgresDNSZone.id
        }
      }
    ]
  }
}

resource speechAccount 'Microsoft.CognitiveServices/accounts@2022-12-01' = if (deploySpeechServices) {
  name: 'cog-${uniqueName}'
  location: location
  tags: tags
  sku: {
    name: 'S0'
  }
  kind: 'SpeechServices'
  identity: {
    type: 'None'
  }
  properties: {
    customSubDomainName: 'cog-${uniqueName}'
    networkAcls: {
      defaultAction: 'Allow'
    }
    publicNetworkAccess: 'Enabled'
  }
}

resource staticWebApp 'Microsoft.Web/staticSites@2022-09-01' = {
  name: 'swa-${uniqueName}'
  location: webappLocation
  tags: tags
  properties: {
    provider: 'None'
  }
  sku: {
    name: staticWebAppTier.name
    tier: staticWebAppTier.tier
  }

  //staticWebAppTier

  //{
  //  name: 'Free'
  //  tier: 'Free'
  // }
}

resource swaPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = if (deployment == 'private') {
  name: 'swa-${uniqueName}-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: virtualNetwork.properties.subnets[3].id
    }
    privateLinkServiceConnections: [
      {
        name: 'swa'
        properties: {
          privateLinkServiceId: staticWebApp.id
          groupIds: [
            'staticSites'
          ]
        }
      }
    ]
  }
}

resource staticWebAppDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if ((deployment == 'private') && (deployPrivateZones == 'yes')) {
  name: 'privatelink.3.azurestaticapps.net'
  location: 'global'
  tags: tags
}

resource staticWebAppVirtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if ((deployment == 'private') && (deployPrivateZones == 'yes')) {
  parent: staticWebAppDNSZone
  name: 'swa-${uniqueName}-vnl'
  location: 'global'
  tags: tags
  properties: {
    virtualNetwork: {
      id: virtualNetwork.id
    }
    registrationEnabled: false
  }
}

//var swaHostname = split(staticWebApp.properties.defaultHostname, '.')[0]

resource swaSymbolicname 'Microsoft.Network/privateDnsZones/A@2020-06-01' = if ((deployment == 'private') && (deployPrivateZones == 'yes')) {
  name: staticWebApp.name
  //name: swaHostname
  //name: staticWebApp
  parent: staticWebAppDNSZone

  properties: {
    ttl: 3600

    aRecords: [
      {
        //  ipv4Address: '192.168.1.1'

        ipv4Address: swaPrivateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
      }
    ]

  }

  dependsOn: []
}

// Deploy VM

@description('Deploy Public Ip on bastion vm')
param deployVmPublicIp string = 'no'

resource publicIp 'Microsoft.Network/publicIPAddresses@2022-05-01' = if (deployVmPublicIp == 'yes') {
  name: publicIpName
  location: location
  sku: {
    name: publicIpSku
  }
  properties: {
    publicIPAllocationMethod: publicIPAllocationMethod
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-05-01' = if (deployment == 'private') {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-3389'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2022-05-01' = if (deployment == 'private') {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          // publicIPAddress: {
          //   id: contains(deployVmPublicIp, 'yes') ? publicIp.id : ''
          // }
          subnet: {
            id: virtualNetwork.properties.subnets[4].id
            //id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.id, virtualNetwork.properties.subnets[4].id)
          }
        }
      }
    ]
  }
  dependsOn: []
}

resource vm 'Microsoft.Compute/virtualMachines@2022-03-01' = if (deployment == 'private') {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: OSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      dataDisks: [
        {
          diskSizeGB: 1023
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    // diagnosticsProfile: {
    //   bootDiagnostics: {
    //     enabled: true
    //     storageUri: storageAccount.properties.primaryEndpoints.blob
    //   }
    // }
    //securityProfile: ((securityType == 'TrustedLaunch') ? securityProfileJson : null)
  }
}

// Deploy Azure API Management

resource apiManagementService 'Microsoft.ApiManagement/service@2021-08-01' = {
  name: apiManagementServiceName
  location: location
  sku: {
    name: sku
    capacity: skuCount
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}

resource apimPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = if ((deployAPIm == 'yes') && (deployment == 'private')) {
  name: 'apim-${uniqueName}-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: virtualNetwork.properties.subnets[3].id
    }
    privateLinkServiceConnections: [
      {
        name: 'apim'
        properties: {
          privateLinkServiceId: apiManagementService.id
          groupIds: [
            'Gateway'
          ]
        }
      }
    ]
  }
}

resource apimDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if ((deployAPIm == 'yes') && (deployPrivateZones == 'yes')) {
  name: 'privatelink.azure-api.net'
  location: 'global'
  tags: tags
}

resource apimVirtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if ((deployAPIm == 'yes') && (deployPrivateZones == 'yes')) {
  parent: apimDNSZone
  name: 'apim-${uniqueName}-vnl'
  location: 'global'
  tags: tags
  properties: {
    virtualNetwork: {
      id: virtualNetwork.id
    }
    registrationEnabled: false
  }
}

//var swaHostname = split(staticWebApp.properties.defaultHostname, '.')[0]

resource apimSymbolicname 'Microsoft.Network/privateDnsZones/A@2020-06-01' = if ((deployAPIm == 'yes') && (deployPrivateZones == 'yes')) {
  name: apiManagementService.name
  //name: swaHostname
  //name: staticWebApp
  parent: apimDNSZone

  properties: {
    ttl: 3600

    aRecords: [
      {
        //  ipv4Address: '192.168.1.1'

        ipv4Address: apimPrivateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
      }
    ]

  }

  dependsOn: []
}

@description('Remote Vnet')
param remoteVirtualNetworkId string = '/subscriptions/11b1e7dd-d35d-435f-9c04-274e5e673671/resourceGroups/usnc-core01/providers/Microsoft.Network/virtualNetworks/usnc-vnet-core01'

@allowed([ 'yes', 'no' ])
@description('Deploy VNet peering')
param deployVnetPeering string = 'yes'

resource coreVNET 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: 'usnc-vnet-core01'
  scope: resourceGroup('11b1e7dd-d35d-435f-9c04-274e5e673671', 'usnc-core01')
}

resource peerToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = if (deployVnetPeering == 'yes') {
  name: 'vnet-${uniqueName}-To-usnc-vnet-core01'
  parent: virtualNetwork
  properties: {

    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: true
    remoteVirtualNetwork: {
      id: remoteVirtualNetworkId
    }

  }
}

// deploy to different scope
//module peering 'vnetPeering.bicep' = if (deployVnetPeering == 'yes') {
module peering 'vnetPeering.bicep' = {
  name: 'deployVnetPeering'
  scope: resourceGroup('11b1e7dd-d35d-435f-9c04-274e5e673671', 'usnc-core01')
  params: {
    uniqueName: contains(deployVnetPeering, 'yes') ? uniqueName : ''
    spokeVnetId: contains(deployVnetPeering, 'yes') ? virtualNetwork.id : ''

  }
}

param deployPrivateZoneArecords string = 'yes'

var azureStaticAppsArecord = {
  name: split(staticWebApp.properties.defaultHostname, '.')[0]
  //name: staticWebApp.name
  ip: swaPrivateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
}
var azureAPIMArecord = {
  name: apiManagementService.name
  ip: apimPrivateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
}
var azureWebsitesArecord = {
  name: appServiceWeb.name
  ip: appPrivateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
}
var azureBlobArecord = {
  name: storageaccount.name
  ip: staPrivateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
}
var azureOpenAiArecord = {
  name: toLower(uniqueName)
  ip: openaiPrivateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
}
var azureWebsitesScmArecord = {
  name: appServiceWeb.name
  ip: appPrivateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
}

var cosmosAccountArecord = {
  name: cosmosAccount.name
  ip: cosmosPrivateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
}

var cosmosAccountRegionArecord = {
  name: '${cosmosAccount.name}-${location}'
  ip: cosmosPrivateEndpoint.properties.customDnsConfigs[1].ipAddresses[0]
}

var azureCognitiveSearchArecord = {
  name: azureCognitiveSearch.name
  ip: acsPrivateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
}

var nothing = {
  name: ''
  ip: ''
}

// Create A records in existing Private Zones

module privateZoneArecords 'privatezones-s01core.bicep' = {
  name: 'deployPrivateZoneARecords'
  scope: resourceGroup('11b1e7dd-d35d-435f-9c04-274e5e673671', 'usnc-rg-privatedns-core01')
  params: {
    azureStaticAppsArecord: contains(deployPrivateZoneArecords, 'yes') ? azureStaticAppsArecord : nothing
    azureAPIMArecord: contains(deployPrivateZoneArecords, 'yes') ? azureAPIMArecord : nothing
    azureWebsitesArecord: contains(deployPrivateZoneArecords, 'yes') ? azureWebsitesArecord : nothing
    azureBlobArecord: contains(deployPrivateZoneArecords, 'yes') ? azureBlobArecord : nothing
    azureOpenAiArecord: contains(deployPrivateZoneArecords, 'yes') ? azureOpenAiArecord : nothing
    azureWebsitesScmArecord: contains(deployPrivateZoneArecords, 'yes') ? azureWebsitesScmArecord : nothing
    azureCognitiveSearchArecord: contains(deployPrivateZoneArecords, 'yes') ? azureCognitiveSearchArecord : nothing
  }
}

module privateZoneArecordsS02 'privatezones-S02.bicep' = {
  name: 'deployPrivateZoneARecords-S02'
  scope: resourceGroup('8701016c-7d8e-4940-993c-fda1a8417f46', 'usnc-rg-s02-vnet-prd2')
  params: {
    cosmosAccountArecord: contains(deployPrivateZoneArecords, 'yes') ? cosmosAccountArecord : nothing
    cosmosAccountRegionArecord: contains(deployPrivateZoneArecords, 'yes') ? cosmosAccountRegionArecord : nothing
  }
}

output webappUrl string = staticWebApp.properties.defaultHostname
output webappName string = staticWebApp.name
output webapiUrl string = appServiceWeb.properties.defaultHostName
output webapiName string = appServiceWeb.name
//output pip object = publicIp
output vmfqdn string = publicIp.properties.dnsSettings.fqdn
//output swape object = swaPrivateEndpoint

//output privip object = swaPrivateEndpoint.properties.customDnsConfigs[0]

output privip2 string = swaPrivateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]

output staticWebAppHostName string = split(staticWebApp.properties.defaultHostname, '.')[0]

output staticWebAppHostNamefqdn string = staticWebApp.properties.defaultHostname

output cosmosPrivateIps object = cosmosPrivateEndpoint.properties.customDnsConfigs[0]

output apiManagementEndpoint string = apiManagementService.properties.gatewayUrl

output apiManagementName string = apiManagementService.name
