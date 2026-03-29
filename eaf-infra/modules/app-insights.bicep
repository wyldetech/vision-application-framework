param environment string
param location string
param tags object

var uniqueSuffix = toLower(substring(uniqueString(resourceGroup().id, environment), 0, 6))
var workspaceName = 'eaf-${environment}-logs-${uniqueSuffix}'
var appInsightsName = 'eaf-${environment}-appi-${uniqueSuffix}'
var workspaceKeys = listKeys(logAnalytics.name, '2015-11-01-preview')

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  sku: {
    name: 'PerGB2018'
  }
  properties: {
    retentionInDays: 30
  }
  tags: tags
}

resource appInsights 'microsoft.insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  tags: tags
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    IngestionMode: 'ApplicationInsights'
    WorkspaceResourceId: logAnalytics.id
  }
}

output appInsightsId string = appInsights.id
output appInsightsName string = appInsights.name
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
output appInsightsConnectionString string = appInsights.properties.ConnectionString
output logAnalyticsWorkspaceId string = logAnalytics.id
output logAnalyticsCustomerId string = logAnalytics.properties.customerId
output logAnalyticsSharedKey string = workspaceKeys.primarySharedKey
