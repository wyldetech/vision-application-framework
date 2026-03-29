param environment string
param location string
param tags object
param logAnalyticsWorkspaceId string

var uniqueSuffix = toLower(substring(uniqueString(resourceGroup().id, environment), 0, 6))
var registryName = toLower('eaf${environment}acr${uniqueSuffix}')
var registrySku = environment == 'dev' ? 'Basic' : 'Standard'

resource registry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: registryName
  location: location
  sku: {
    name: registrySku
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
  }
  tags: tags
}

resource registryDiagnostics 'microsoft.insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'acr-diagnostics'
  scope: registry
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'ContainerRegistryRepositoryEvents'
        enabled: true
      }
      {
        category: 'ContainerRegistryLoginEvents'
        enabled: true
      }
      {
        category: 'ContainerRegistryOperations'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output registryId string = registry.id
output registryName string = registry.name
output registryLoginServer string = registry.properties.loginServer
