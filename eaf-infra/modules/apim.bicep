param environment string
param location string
param tags object
param apimPublisherEmail string
param apimPublisherName string
param appInsightsId string
param referenceAppOpenApiUrl string

var uniqueSuffix = toLower(substring(uniqueString(resourceGroup().id, environment), 0, 6))
var apimName = 'eaf-${environment}-apim-${uniqueSuffix}'
var apimSku = toLower(environment) == 'dev' ? 'Developer' : 'Standard_v2'
var openIdConfigUrl = 'https://login.microsoftonline.com/${subscription().tenantId}/v2.0/.well-known/openid-configuration'
var policyContent = format('''<policies>
  <inbound>
    <base />
    <validate-jwt header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Unauthorized">
      <openid-config url="{0}" />
      <audiences><audience>api://eaf-platform</audience></audiences>
    </validate-jwt>
    <set-variable name="correlationId" value="@(context.Request.Headers.GetValueOrDefault('x-correlation-id', Guid.NewGuid().ToString()))" />
    <set-header name="x-correlation-id" exists-action="skip">
      <value>@(context.Variables.GetValueOrDefault<string>('correlationId', Guid.NewGuid().ToString()))</value>
    </set-header>
    <rate-limit calls="100" renewal-period="60" />
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
  </outbound>
  <on-error>
    <base />
    <return-response>
      <set-status code="@(context.Response.StatusCode)" reason="@(context.Response.StatusReasonPhrase)" />
      <set-header name="x-correlation-id" exists-action="override">
        <value>@(context.Variables.GetValueOrDefault<string>('correlationId', 'unknown'))</value>
      </set-header>
    </return-response>
  </on-error>
</policies>
''', openIdConfigUrl)

resource appInsights 'microsoft.insights/components@2020-02-02' existing = {
  name: last(split(appInsightsId, '/'))
}

resource apim 'Microsoft.ApiManagement/service@2023-03-01-preview' = {
  name: apimName
  location: location
  sku: {
    name: apimSku
    capacity: 1
  }
  identity: {
    type: 'SystemAssigned'
  }
  tags: tags
  properties: {
    publisherEmail: apimPublisherEmail
    publisherName: apimPublisherName
    publicNetworkAccess: 'Enabled'
  }
}

resource globalPolicy 'Microsoft.ApiManagement/service/policies@2021-08-01' = {
  name: 'policy'
  parent: apim
  properties: {
    value: policyContent
    format: 'rawxml'
  }
}

resource appInsightsLogger 'Microsoft.ApiManagement/service/loggers@2021-08-01' = {
  name: 'appInsights'
  parent: apim
  properties: {
    loggerType: 'applicationInsights'
    credentials: {
      instrumentationKey: appInsights.properties.InstrumentationKey
    }
  }
}

resource apimDiagnostics 'Microsoft.ApiManagement/service/diagnostics@2021-08-01' = {
  name: 'apim-applicationinsights'
  parent: apim
  properties: {
    alwaysLog: 'allErrors'
    loggerId: appInsightsLogger.id
    sampling: {
      samplingType: 'fixed'
      percentage: 100
    }
    frontend: {
      request: {
        body: {
          bytes: 8192
        }
      }
      response: {
        body: {
          bytes: 8192
        }
      }
    }
    backend: {
      request: {
        body: {
          bytes: 8192
        }
      }
      response: {
        body: {
          bytes: 8192
        }
      }
    }
    httpCorrelationProtocol: 'W3C'
  }
}

resource referenceProduct 'Microsoft.ApiManagement/service/products@2021-08-01' = {
  name: 'reference-app'
  parent: apim
  properties: {
    displayName: 'reference-app'
    description: 'Reference application API product'
    subscriptionRequired: true
    approvalRequired: false
    subscriptionsLimit: 1000
    state: 'published'
  }
}

resource referenceApi 'Microsoft.ApiManagement/service/apis@2023-03-01-preview' = {
  name: 'reference-app'
  parent: apim
  properties: {
    displayName: 'reference-app'
    path: 'reference-app'
    protocols: [
      'https'
    ]
    apiRevision: '1'
    subscriptionRequired: true
    format: 'openapi-link'
    value: referenceAppOpenApiUrl
  }
}

resource referenceProductApi 'Microsoft.ApiManagement/service/products/apis@2023-03-01-preview' = {
  name: referenceApi.name
  parent: referenceProduct
}

output apimId string = apim.id
output apimName string = apim.name
output apimGatewayUrl string = apim.properties.gatewayUrl
