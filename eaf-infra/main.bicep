@allowed([
  'dev'
  'staging'
  'prod'
])
param environment string
param location string = resourceGroup().location
@secure()
param sqlAdminPassword string
param apimPublisherEmail string
param apimPublisherName string
param referenceAppOpenApiUrl string
param referenceAppImage string
param sqlAdminLogin string = 'sqladmin'
param containerAppTargetPort int = 8080

var tags = {
  environment: environment
  project: 'eaf'
  managedBy: 'bicep'
}

module appInsights './modules/app-insights.bicep' = {
  name: 'appInsights'
  params: {
    environment: environment
    location: location
    tags: tags
  }
}

module containerRegistry './modules/container-registry.bicep' = {
  name: 'containerRegistry'
  params: {
    environment: environment
    location: location
    tags: tags
    logAnalyticsWorkspaceId: appInsights.outputs.logAnalyticsWorkspaceId
  }
}

module keyVault './modules/key-vault.bicep' = {
  name: 'keyVault'
  params: {
    environment: environment
    location: location
    tags: tags
    logAnalyticsWorkspaceId: appInsights.outputs.logAnalyticsWorkspaceId
  }
}

module sqlServer './modules/sql-server.bicep' = {
  name: 'sqlServer'
  params: {
    environment: environment
    location: location
    tags: tags
    administratorLogin: sqlAdminLogin
    administratorPassword: sqlAdminPassword
    logAnalyticsWorkspaceId: appInsights.outputs.logAnalyticsWorkspaceId
  }
}

module sqlDatabase './modules/sql-database.bicep' = {
  name: 'sqlDatabase'
  params: {
    environment: environment
    location: location
    tags: tags
    sqlServerName: sqlServer.outputs.sqlServerName
    logAnalyticsWorkspaceId: appInsights.outputs.logAnalyticsWorkspaceId
    databaseName: 'referenceapp'
  }
}

module containerApp './modules/container-app.bicep' = {
  name: 'containerApp'
  params: {
    environment: environment
    location: location
    tags: tags
    logAnalyticsWorkspaceId: appInsights.outputs.logAnalyticsWorkspaceId
    logAnalyticsCustomerId: appInsights.outputs.logAnalyticsCustomerId
    logAnalyticsSharedKey: appInsights.outputs.logAnalyticsSharedKey
    containerRegistryId: containerRegistry.outputs.registryId
    containerRegistryServer: containerRegistry.outputs.registryLoginServer
    containerImage: referenceAppImage
    targetPort: containerAppTargetPort
    containerAppName: 'reference-app'
  }
}

module apim './modules/apim.bicep' = {
  name: 'apim'
  params: {
    environment: environment
    location: location
    tags: tags
    apimPublisherEmail: apimPublisherEmail
    apimPublisherName: apimPublisherName
    appInsightsId: appInsights.outputs.appInsightsId
    referenceAppOpenApiUrl: referenceAppOpenApiUrl
  }
}

output appInsightsId string = appInsights.outputs.appInsightsId
output apimGatewayUrl string = apim.outputs.apimGatewayUrl
output apimName string = apim.outputs.apimName
output containerAppFqdn string = containerApp.outputs.containerAppFqdn
output sqlServerFqdn string = sqlServer.outputs.sqlServerFqdn
