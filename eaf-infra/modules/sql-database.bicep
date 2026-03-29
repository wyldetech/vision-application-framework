param environment string
param location string
param tags object
param sqlServerName string
param logAnalyticsWorkspaceId string
param databaseName string = 'referenceapp'

var isDev = toLower(environment) == 'dev'
var sku = isDev ? {
  name: 'Basic'
  tier: 'Basic'
  capacity: 5
} : {
  name: 'GP_Gen5_2'
  tier: 'GeneralPurpose'
  family: 'Gen5'
  capacity: 2
}

resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' existing = {
  name: sqlServerName
}

resource database 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  name: databaseName
  location: location
  parent: sqlServer
  sku: sku
  tags: tags
  properties: {
    zoneRedundant: !isDev
  }
}

resource databaseDiagnostics 'microsoft.insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'sqldb-diagnostics'
  scope: database
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'Errors'
        enabled: true
      }
      {
        category: 'DatabaseWaitStatistics'
        enabled: true
      }
      {
        category: 'QueryStoreRuntimeStatistics'
        enabled: true
      }
      {
        category: 'AutomaticTuning'
        enabled: true
      }
      {
        category: 'Blocks'
        enabled: true
      }
      {
        category: 'Deadlocks'
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

output sqlDatabaseId string = database.id
output sqlDatabaseName string = database.name
