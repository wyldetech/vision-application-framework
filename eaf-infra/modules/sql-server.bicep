param environment string
param location string
param tags object
param administratorLogin string = 'sqladmin'
@secure()
param administratorPassword string
param logAnalyticsWorkspaceId string

var uniqueSuffix = toLower(substring(uniqueString(resourceGroup().id, environment), 0, 6))
var sqlServerName = toLower('eaf-${environment}-sql-${uniqueSuffix}')

resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  tags: tags
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorPassword
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
}

resource allowAzure 'Microsoft.Sql/servers/firewallRules@2022-05-01-preview' = {
  name: 'AllowAzureServices'
  parent: sqlServer
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource sqlDiagnostics 'microsoft.insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'sql-diagnostics'
  scope: sqlServer
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'SQLSecurityAuditEvents'
        enabled: true
      }
      {
        category: 'DevOpsOperations'
        enabled: true
      }
      {
        category: 'AutomaticTuning'
        enabled: true
      }
      {
        category: 'Errors'
        enabled: true
      }
      {
        category: 'QueryStoreRuntimeStatistics'
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

output sqlServerName string = sqlServer.name
output sqlServerId string = sqlServer.id
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
