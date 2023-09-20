// resource coreVNET 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
//   name: 'usnc-vnet-core01'
//   scope: resourceGroup('11b1e7dd-d35d-435f-9c04-274e5e673671', 'usnc-core01')
// }
resource core 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: 'usnc-vnet-core01'
  // scope: resourceGroup('usnc-core01')
}

param uniqueName string = ''
param spokeVnetId string = ''
param out string = ''
resource peerToAIvnet 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = {
  name: 'usnc-vnet-core01-To-vnet-${uniqueName}'
  parent: core
  properties: {
    allowGatewayTransit: true
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    remoteVirtualNetwork: {
      id: spokeVnetId
    }
  }
}
