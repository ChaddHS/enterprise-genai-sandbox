resource azureCosmosAccountZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.documents.azure.com'

}

param cosmosAccountArecord object = {
  name: ''
  ip: ''
}

param cosmosAccountRegionArecord object = {
  name: ''
  ip: ''
}

resource staticAppsArecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: cosmosAccountArecord.name
  parent: azureCosmosAccountZone

  properties: {
    ttl: 3600

    aRecords: [
      {
        ipv4Address: cosmosAccountArecord.ip
      }
    ]

  }

  dependsOn: []
}

resource cosmosRegionArecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: cosmosAccountRegionArecord.name
  parent: azureCosmosAccountZone

  properties: {
    ttl: 3600

    aRecords: [
      {
        ipv4Address: cosmosAccountRegionArecord.ip
      }
    ]

  }

  dependsOn: []
}
