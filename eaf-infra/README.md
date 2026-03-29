# EAF Infrastructure (Bicep)

This folder contains the Phase 1 shared infrastructure for the Enterprise Application Framework. It provisions Application Insights (workspace-based), Log Analytics, Azure Container Registry, Key Vault, Azure SQL (server + reference database), a Container Apps environment and reference app, and Azure API Management with platform-wide policies.

## Repository layout

```
eaf-infra/
├── main.bicep
├── modules/
│   ├── app-insights.bicep
│   ├── apim.bicep
│   ├── container-app.bicep
│   ├── container-registry.bicep
│   ├── key-vault.bicep
│   ├── sql-database.bicep
│   └── sql-server.bicep
├── environments/
│   ├── dev.params.json
│   ├── staging.params.json
│   └── prod.params.json
└── .github/workflows/deploy.yml
```

All resources are tagged automatically with `environment`, `project: eaf`, and `managedBy: bicep`.

## Deploying

Prerequisites:
- Azure CLI with Bicep support (`az upgrade` installs the Bicep CLI).
- Permissions to deploy to the target resource group.
- Secrets for `sqlAdminPassword` and container image/OpenAPI URLs for the reference app.

Common deployment command (replace the resource group, parameters file, and secrets):

```bash
az login
az account set --subscription "<subscription-id>"

az deployment group create \
  --resource-group "<rg-name>" \
  --template-file main.bicep \
  --parameters @environments/dev.params.json \
  --parameters sqlAdminPassword="<secret>" \
  --parameters referenceAppImage="<dev-acr-login-server>/reference-app:dev" \
  --parameters referenceAppOpenApiUrl="https://reference-app.example.com/openapi.json"
```

Use the matching parameter file for `staging` and `prod`. Azure DevOps Pipelines remains the source of truth for CI/CD; the GitHub workflow in this folder is an opt-in, manual helper for ad-hoc deployments and should use the same secrets/parameters as the Azure DevOps pipeline.

## CI/CD workflow

- Workflow: `eaf-infra/.github/workflows/deploy.yml`
- Trigger: manual (`workflow_dispatch`) to avoid conflicting with the Azure DevOps pipeline.
- Behavior:
  - Deploys `dev` and `staging` using their parameter files with overrides for secrets (SQL password) and app-specific values (reference app image, OpenAPI URL).
  - `prod` deployment runs only after manual approval via the protected `prod` environment.
- Required GitHub secrets: Azure federated credentials for `azure/login`, `AZURE_SUBSCRIPTION_ID`, `AZURE_RESOURCE_GROUP`, environment-scoped `SQL_ADMIN_PASSWORD_*`, `REFERENCE_APP_IMAGE_*`, and `REFERENCE_APP_OPENAPI_URL_*`.

## Adding a new application API

Add a product and API definition to `main.bicep` using the APIM service output. Replace names and URLs with your application values:

```bicep
resource apimService 'Microsoft.ApiManagement/service@2023-03-01-preview' existing = {
  name: apim.outputs.apimName
}

resource ordersProduct 'Microsoft.ApiManagement/service/products@2021-08-01' = {
  name: 'orders'
  parent: apimService
  properties: {
    displayName: 'orders'
    description: 'Orders API'
    subscriptionRequired: true
    approvalRequired: false
    state: 'published'
  }
}

resource ordersApi 'Microsoft.ApiManagement/service/apis@2023-03-01-preview' = {
  name: 'orders'
  parent: apimService
  properties: {
    displayName: 'orders'
    path: 'orders'
    protocols: [
      'https'
    ]
    subscriptionRequired: true
    apiRevision: '1'
    format: 'openapi-link'
    value: 'https://orders.example.com/openapi.json'
  }
}

resource ordersProductApi 'Microsoft.ApiManagement/service/products/apis@2023-03-01-preview' = {
  name: ordersApi.name
  parent: ordersProduct
  properties: {}
}
```

Keep OpenAPI specs reachable from APIM, and ensure the global JWT validation policy applies by default (no per-API overrides unless approved).
