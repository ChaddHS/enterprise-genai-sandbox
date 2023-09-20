resource azureStaticAppsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.3.azurestaticapps.net'

}
resource azureAPIMZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.azure-api.net'

}
resource azureWebsitesZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.azurewebsites.net'

}
resource azureBlobZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.blob.core.windows.net'

}

resource azureOpenAiZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.openai.azure.com'

}
resource azureWebsitesScmZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'scm.privatelink.azurewebsites.net'

}
resource azureCognitiveSearchZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.search.windows.net'
}

param azureStaticAppsArecord object = {
  name: ''
  ip: ''
}
param azureAPIMArecord object = {
  name: ''
  ip: ''

}
param azureWebsitesArecord object = {
  name: ''
  ip: ''

}
param azureBlobArecord object = {
  name: ''
  ip: ''

}

param azureOpenAiArecord object = {
  name: ''
  ip: ''

}
param azureWebsitesScmArecord object = {
  name: ''
  ip: ''

}
param azureCognitiveSearchArecord object = {
  name: ''
  ip: ''

}

resource staticAppsArecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: azureStaticAppsArecord.name
  parent: azureStaticAppsZone

  properties: {
    ttl: 3600

    aRecords: [
      {
        ipv4Address: azureStaticAppsArecord.ip
      }
    ]

  }

  dependsOn: []
}

resource APIMArecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: azureAPIMArecord.name
  parent: azureAPIMZone

  properties: {
    ttl: 3600

    aRecords: [
      {
        ipv4Address: azureAPIMArecord.ip
      }
    ]

  }

  dependsOn: []
}

resource websitesArecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: azureWebsitesArecord.name
  parent: azureWebsitesZone

  properties: {
    ttl: 3600

    aRecords: [
      {
        ipv4Address: azureWebsitesArecord.ip
      }
    ]

  }

  dependsOn: []
}

resource blobArecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: azureBlobArecord.name
  parent: azureBlobZone

  properties: {
    ttl: 3600

    aRecords: [
      {
        ipv4Address: azureBlobArecord.ip
      }
    ]

  }

  dependsOn: []
}

resource openAiArecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: azureOpenAiArecord.name
  parent: azureOpenAiZone

  properties: {
    ttl: 3600

    aRecords: [
      {
        ipv4Address: azureOpenAiArecord.ip
      }
    ]

  }

  dependsOn: []
}

resource WebsitesScmArecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: azureWebsitesScmArecord.name
  parent: azureWebsitesScmZone

  properties: {
    ttl: 3600

    aRecords: [
      {
        ipv4Address: azureWebsitesScmArecord.ip
      }
    ]

  }

  dependsOn: []
}

resource cognitiveSearchArecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: azureCognitiveSearchArecord.name
  parent: azureCognitiveSearchZone

  properties: {
    ttl: 3600

    aRecords: [
      {
        ipv4Address: azureCognitiveSearchArecord.ip
      }
    ]

  }

  dependsOn: []
}
