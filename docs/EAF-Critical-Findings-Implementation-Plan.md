# EAF — Implementation Plan: Critical Review Findings

| Field | Value |
|---|---|
| **Source** | EAF Architecture Review (2026-03-28) |
| **Scope** | Three critical findings requiring resolution before Phase 1 implementation |
| **Decisions Made** | 1. MSAL module-scoped singleton for `eafBaseQuery`. 2. Lightweight mock API gateway for local dev. 3. Azure DevOps Pipelines for CI/CD; GitHub for Git hosting only (to enable GitHub Copilot Agents). |

---

## 1. MSAL Module-Scoped Singleton for `eafBaseQuery`

### Problem

`eafBaseQuery` (in `@eaf/api-client`) needs to acquire auth tokens to inject into API requests. The current spec says it calls `useToken()` from `@eaf/auth` internally — but `baseQuery` in RTK Query is a plain function executed by Redux middleware outside the React component tree. React hooks cannot be called there. This would crash at runtime.

### Design

Introduce a module-scoped MSAL singleton inside `@eaf/auth` that `@eaf/api-client` can call directly without React context. The `AuthProvider` component already creates the `PublicClientApplication` instance — the change is to expose a non-React token acquisition function alongside the existing hooks.

### Changes to `@eaf/auth` (Issue #3)

Add an internal singleton module and a new public export:

```
packages/auth/src/
├── AuthProvider.tsx          ← existing (no change to component behaviour)
├── hooks/
│   ├── useAuth.ts            ← existing (no change)
│   └── useToken.ts           ← existing (no change — still useful for components)
├── msalInstance.ts            ← NEW: module-scoped singleton
├── getToken.ts                ← NEW: non-React token acquisition function
├── types.ts                   ← existing (no change)
└── index.ts                   ← updated exports
```

**`src/msalInstance.ts`** — The single MSAL instance, created once at module load:

```typescript
import { PublicClientApplication, Configuration } from '@azure/msal-browser';

let msalInstance: PublicClientApplication | null = null;
let configuredScopes: string[] = [];

/**
 * Initialise the module-scoped MSAL instance.
 * Called once by AuthProvider on mount. Subsequent calls are no-ops.
 */
export function initialiseMsal(config: {
  clientId: string;
  tenantId: string;
  scopes: string[];
  redirectUri?: string;
}): PublicClientApplication {
  if (msalInstance) return msalInstance;

  const msalConfig: Configuration = {
    auth: {
      clientId: config.clientId,
      authority: `https://login.microsoftonline.com/${config.tenantId}`,
      redirectUri: config.redirectUri ?? window.location.origin,
    },
    cache: {
      cacheLocation: 'sessionStorage',
    },
  };

  msalInstance = new PublicClientApplication(msalConfig);
  configuredScopes = config.scopes;
  return msalInstance;
}

/**
 * Returns the initialised MSAL instance.
 * Throws if called before AuthProvider has mounted.
 */
export function getMsalInstance(): PublicClientApplication {
  if (!msalInstance) {
    throw new Error(
      '@eaf/auth: MSAL not initialised. Ensure <AuthProvider> has mounted before calling getToken().'
    );
  }
  return msalInstance;
}

export function getConfiguredScopes(): string[] {
  return configuredScopes;
}
```

**`src/getToken.ts`** — Non-React token acquisition, safe to call from `eafBaseQuery`:

```typescript
import { InteractionRequiredAuthError } from '@azure/msal-browser';
import { getMsalInstance, getConfiguredScopes } from './msalInstance';

/**
 * Acquire an access token silently using the module-scoped MSAL instance.
 * Does not require React context — safe for use in RTK Query base queries,
 * Axios interceptors, and other non-component code.
 *
 * Falls back to acquireTokenRedirect on interaction-required errors.
 * Returns null if no active account is available.
 */
export async function getToken(): Promise<string | null> {
  const instance = getMsalInstance();
  const account = instance.getActiveAccount();

  if (!account) return null;

  try {
    const response = await instance.acquireTokenSilent({
      scopes: getConfiguredScopes(),
      account,
    });
    return response.accessToken;
  } catch (error) {
    if (error instanceof InteractionRequiredAuthError) {
      await instance.acquireTokenRedirect({
        scopes: getConfiguredScopes(),
        account,
      });
      return null; // redirect will reload the page
    }
    return null;
  }
}
```

**Updated `src/index.ts`:**

```typescript
export { AuthProvider } from './AuthProvider';
export { useAuth } from './hooks/useAuth';
export { useToken } from './hooks/useToken';
export { getToken } from './getToken';        // NEW — non-React token acquisition
export type { AuthConfig, AuthUser } from './types';
```

**`AuthProvider` changes:** Update `AuthProvider.tsx` to call `initialiseMsal(config)` instead of creating a `PublicClientApplication` directly. The component still owns the lifecycle (redirect handling, setting active account, providing context) — but the instance it uses is the module-scoped singleton. No change to the component's external API or behaviour.

### Changes to `@eaf/api-client` (Issue #4)

Remove all references to `useToken()` from `eafBaseQuery`. Import `getToken` from `@eaf/auth` instead.

**Updated `eafBaseQuery`:**

```typescript
import { getToken } from '@eaf/auth';

export function eafBaseQuery(baseUrl: string): BaseQueryFn<
  { url: string; method?: string; body?: unknown; params?: Record<string, unknown> },
  unknown,
  { status: number; message: string; correlationId?: string }
> {
  const client = createApiClient(baseUrl, getToken);
  // getToken is a plain async function, not a hook — safe to use here

  return async ({ url, method = 'GET', body, params }) => {
    try {
      const result = await client.request({ url, method, data: body, params });
      return { data: result.data };
    } catch (error) {
      // ... error handling unchanged
    }
  };
}
```

**Remove the JSDoc constraint** that `eafBaseQuery` must be called inside a React component. It is now a plain factory function that can be called at module scope — which is how RTK Query's `createApi` expects to use it.

**Updated scaffold `baseApi.ts`** (Issue #13):

```typescript
// This is now valid at module scope — no hooks, no component wrapper needed
import { createApi } from '@reduxjs/toolkit/query/react';
import { eafBaseQuery } from '@eaf/api-client';

export const eafApi = createApi({
  reducerPath: 'eafApi',
  baseQuery: eafBaseQuery(import.meta.env.VITE_API_BASE_URL),
  endpoints: () => ({}),
});
```

### Impact on `@eaf/auth-code-app` (Issue #24)

The adapter must also export a `getToken` function with the same signature. This maintains the host-agnostic contract — `@eaf/api-client` imports `getToken` from whichever auth package is in use.

```typescript
// @eaf/auth-code-app/src/getToken.ts
import { getToken as sdkGetToken } from './utils/powerAppsClient';

export async function getToken(): Promise<string | null> {
  if (!import.meta.env.VITE_API_BASE_URL) return null;
  return sdkGetToken(import.meta.env.VITE_API_BASE_URL);
}
```

Updated `@eaf/auth-code-app` exports:

```typescript
export { AuthProvider } from './AuthProvider';
export { useAuth } from './hooks/useAuth';
export { useToken } from './hooks/useToken';
export { getToken } from './getToken';          // NEW — matches @eaf/auth
export type { AuthConfig, AuthUser } from './types';
```

### Testing

All existing unit tests for `useAuth()` and `useToken()` remain valid. Add:

- `getToken()` returns a token string when the MSAL singleton is initialised and has an active account (mock MSAL).
- `getToken()` returns `null` when no active account exists.
- `getToken()` calls `acquireTokenRedirect` on `InteractionRequiredAuthError`.
- `getToken()` throws a descriptive error when called before `AuthProvider` has mounted.
- `eafBaseQuery` calls `getToken()` (not `useToken()`) and injects the token into requests.

### Spec and Issue Updates Required

| Document | Section / Issue | Change |
|---|---|---|
| Spec | Section 6.2 (`@eaf/auth` description) | Add `getToken` to the list of exports. Note that it is the non-React equivalent of `useToken()`, intended for use in RTK Query base queries and other non-component code. |
| Spec | Section 6.4 (RTK Query pattern) | Remove the note about `eafBaseQuery` needing to be called inside a component. |
| Issue #3 | Public API / Specification | Add `msalInstance.ts`, `getToken.ts`, and the `getToken` export. Update `AuthProvider` to use `initialiseMsal()`. |
| Issue #4 | `eafBaseQuery` specification | Replace `useToken()` with `getToken` import. Remove the JSDoc constraint about calling inside a component. |
| Issue #13 | `baseApi.ts` in scaffold | Confirm the `eafBaseQuery` call is at module scope (no component wrapper). |
| Issue #24 | Public API | Add `getToken` export to `@eaf/auth-code-app`. |

---

## 2. Lightweight Mock API Gateway for Local Development

### Problem

The Docker Compose spec (Issue #19) uses the Azure APIM self-hosted gateway container, which requires a live Azure APIM instance and a gateway provisioning token. A developer who clones the scaffold and runs `docker-compose up` without Azure access gets a connection failure. This breaks Goal G2 ("zero to running application in under one hour").

### Design

Replace the APIM self-hosted gateway in the default Docker Compose with a lightweight reverse proxy that mimics APIM's routing and header behaviour. Provide the real APIM self-hosted gateway as an opt-in profile for developers who need policy-accurate local testing.

The mock gateway must reproduce the three behaviours that application code depends on:

1. Route requests from `localhost:4000/api/*` to the backend API.
2. Pass through the `Authorization` header (no JWT validation locally — the dev Entra ID tenant handles real tokens).
3. Set `x-correlation-id` on requests that don't already have one.

Caddy is the recommended choice: single static binary, zero-dependency Docker image (~40 MB), native reverse proxy with header manipulation, and a Caddyfile that is human-readable.

### Implementation

**`docker/gateway/Caddyfile`:**

```caddyfile
# EAF Local API Gateway
# Mimics APIM routing and correlation ID behaviour for local development.
# Does NOT enforce JWT validation — use the APIM self-hosted gateway profile
# for policy-accurate testing.

:8080 {
    # Correlation ID: set if not already present
    @no-correlation-id {
        not header x-correlation-id *
    }
    header @no-correlation-id x-correlation-id "{http.request.uuid}"

    # Reverse proxy to backend API
    reverse_proxy /api/* backend:5000 {
        header_up Host {upstream_hostport}
    }

    # Health endpoint for Docker health checks and smoke tests
    respond /health 200 {
        body "OK"
    }
}
```

**Updated `docker-compose.yml`** (default profile):

```yaml
services:
  db:
    image: mcr.microsoft.com/mssql/server:2022-latest
    environment:
      SA_PASSWORD: "EafDev_Password1"
      ACCEPT_EULA: "Y"
    ports:
      - "1433:1433"
    volumes:
      - db-data:/var/opt/mssql
    healthcheck:
      test: /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$$SA_PASSWORD" -C -Q "SELECT 1" || exit 1
      interval: 10s
      timeout: 5s
      retries: 5

  db-init:
    image: mcr.microsoft.com/mssql-tools:latest
    depends_on:
      db:
        condition: service_healthy
    volumes:
      - ./docker/db/seed.sql:/seed.sql
    entrypoint: >
      bash -c "/opt/mssql-tools18/bin/sqlcmd -S db -U sa -P 'EafDev_Password1' -C -i /seed.sql"

  gateway:
    image: caddy:2-alpine
    ports:
      - "4000:8080"
    volumes:
      - ./docker/gateway/Caddyfile:/etc/caddy/Caddyfile
    depends_on:
      - db

  # --- Opt-in: Real APIM self-hosted gateway ---
  # Activate with: docker compose --profile apim up
  apim-gateway:
    image: mcr.microsoft.com/azure-api-management/gateway:latest
    profiles:
      - apim
    environment:
      config.service.auth: "${APIM_GATEWAY_TOKEN}"
      config.service.endpoint: "${APIM_GATEWAY_ENDPOINT}"
    ports:
      - "4001:8080"
    depends_on:
      - db

volumes:
  db-data:
```

This also fixes review item #16 (the SQL Server seed script). The `db-init` service uses `sqlcmd` to execute the seed script after the database is healthy, rather than relying on the PostgreSQL-style `/docker-entrypoint-initdb.d/` convention.

### `.env.example` Update

```bash
# Required
VITE_APP_NAME=My EAF App
VITE_AUTH_CLIENT_ID=
VITE_AUTH_TENANT_ID=
VITE_AUTH_SCOPE=
VITE_API_BASE_URL=http://localhost:4000

# Optional — only needed if using the APIM self-hosted gateway profile
# Activate with: docker compose --profile apim up
# APIM_GATEWAY_TOKEN=
# APIM_GATEWAY_ENDPOINT=
```

### README Documentation

Add a section to the scaffold README and `README-docker.md`:

```markdown
## Local API Gateway

By default, `docker compose up` starts a lightweight Caddy reverse proxy on
port 4000 that routes API requests to the backend and sets correlation ID
headers. This does not require any Azure resources.

### Using the real APIM gateway (optional)

If you need to test against actual APIM policies (JWT validation, rate
limiting, CORS), activate the APIM profile:

    docker compose --profile apim up

This requires a provisioned Azure APIM instance. Set `APIM_GATEWAY_TOKEN` and
`APIM_GATEWAY_ENDPOINT` in `.env.local`. The APIM gateway runs on port 4001.
Update `VITE_API_BASE_URL` to `http://localhost:4001` to route through it.
```

### Spec and Issue Updates Required

| Document | Section / Issue | Change |
|---|---|---|
| Spec | Section 11.1 (Local Setup) | Change "APIM self-hosted gateway container" to "Lightweight Caddy reverse proxy (default) or APIM self-hosted gateway (opt-in profile)". |
| Spec | Section 11.2 (DX Requirements) | Add: "The default local stack requires no Azure resources beyond the dev Entra ID tenant." |
| Issue #19 | Docker Compose specification | Replace the `apim-gateway` service with the Caddy `gateway` service as default. Move APIM to an opt-in Docker Compose profile. Replace the `seed.sql` mount with the `db-init` service pattern. Update `.env.example`. Add README section. |
| Issue #19 | Acceptance criteria | Update: "`docker-compose up` starts all services without requiring Azure credentials." Add: "`docker compose --profile apim up` starts the APIM self-hosted gateway when credentials are provided." |
| Issue #13 | `.env.example` in scaffold | Make APIM variables optional with comments explaining the profile. |

---

## 3. Azure DevOps Pipelines (GitHub for Git Only)

### Decision

Azure DevOps is the CI/CD platform. GitHub is used exclusively for Git repository hosting to enable GitHub Copilot Agents. All pipelines, artifact publishing, environment approvals, and deployment orchestration run in Azure DevOps Pipelines.

### Implications

Issues #20 and #21 are currently written as GitHub Actions workflows (`.github/workflows/ci.yml`). These must be rewritten as Azure DevOps YAML pipeline definitions (`azure-pipelines.yml`). The pipeline logic is identical — only the syntax, runner references, and service connection patterns change.

### Packages Monorepo Pipeline (Issue #20)

**File:** `azure-pipelines.yml` in the `eaf-packages` repository.

```yaml
trigger:
  branches:
    include:
      - main

pr:
  branches:
    include:
      - '*'

pool:
  vmImage: 'ubuntu-latest'

variables:
  nodeVersion: '20.x'
  npmRegistry: '$(NPM_REGISTRY_URL)'    # Azure Artifacts feed URL

stages:
  - stage: Validate
    jobs:
      - job: BuildAndTest
        steps:
          - task: NodeTool@0
            inputs:
              versionSpec: '$(nodeVersion)'

          - script: npm ci
            displayName: 'Install dependencies'

          - script: npx turbo typecheck
            displayName: 'Type check'

          - script: npx turbo lint
            displayName: 'Lint'

          - script: npx turbo test -- --coverage
            displayName: 'Run tests'

          - script: npx vitest run --coverage --coverage.thresholds.lines=80
            displayName: 'Enforce 80% coverage threshold'

          - script: npx turbo build
            displayName: 'Build all packages'

          - script: |
              npm run generate:manifest
              git diff --exit-code -- ':!*"generated"*' components.json || \
                (echo "##vso[task.logissue type=error]components.json is out of date. Run npm run generate:manifest." && exit 1)
            displayName: 'Verify components.json is current'

      - job: Security
        steps:
          - task: NodeTool@0
            inputs:
              versionSpec: '$(nodeVersion)'

          - script: npm ci
            displayName: 'Install dependencies'

          - script: npm audit --audit-level=high
            displayName: 'Security audit'

      - job: Storybook
        steps:
          - task: NodeTool@0
            inputs:
              versionSpec: '$(nodeVersion)'

          - script: npm ci
            displayName: 'Install dependencies'

          - script: npx turbo run build-storybook
            displayName: 'Build Storybook'

          - task: PublishBuildArtifacts@1
            inputs:
              pathToPublish: 'apps/storybook/dist'
              artifactName: 'storybook-dist'
            displayName: 'Publish Storybook artifact'

  - stage: Publish
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    dependsOn: Validate
    jobs:
      - job: PublishPackages
        steps:
          - task: NodeTool@0
            inputs:
              versionSpec: '$(nodeVersion)'

          - script: npm ci
            displayName: 'Install dependencies'

          - script: npx turbo build
            displayName: 'Build all packages'

          - task: npmAuthenticate@0
            inputs:
              workingFile: '.npmrc'
            displayName: 'Authenticate to Azure Artifacts'

          - script: npx turbo publish --filter='[HEAD^1]'
            displayName: 'Publish changed packages'
```

### Application Pipeline (Issue #21)

**File:** `azure-pipelines.yml` in `eaf-app-template` (and therefore in every application generated from it).

```yaml
trigger:
  branches:
    include:
      - main

pr:
  branches:
    include:
      - '*'

pool:
  vmImage: 'ubuntu-latest'

variables:
  nodeVersion: '20.x'

stages:
  - stage: Validate
    jobs:
      - job: BuildAndTest
        steps:
          - task: NodeTool@0
            inputs:
              versionSpec: '$(nodeVersion)'

          - script: npm ci
            displayName: 'Install dependencies'

          - script: npm run typecheck
            displayName: 'Type check'

          - script: npm run lint
            displayName: 'Lint'

          - script: npm run test -- --coverage
            displayName: 'Run tests'

          - script: npx vitest run --coverage --coverage.thresholds.lines=80
            displayName: 'Enforce 80% coverage threshold'

          - script: npm run build
            displayName: 'Build'

          - script: |
              BUNDLE_SIZE=$(gzip -c dist/assets/*.js | wc -c)
              BUNDLE_KB=$((BUNDLE_SIZE / 1024))
              echo "Bundle size: ${BUNDLE_KB}KB gzipped"
              [ "$BUNDLE_KB" -lt 350 ] || \
                (echo "##vso[task.logissue type=error]Bundle exceeds 350KB gzipped limit (${BUNDLE_KB}KB)" && exit 1)
            displayName: 'Bundle size check (gzipped)'

      - job: Security
        steps:
          - task: NodeTool@0
            inputs:
              versionSpec: '$(nodeVersion)'

          - script: npm ci
            displayName: 'Install dependencies'

          - script: npm audit --audit-level=high
            displayName: 'Security audit'

  - stage: DeployDev
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    dependsOn: Validate
    jobs:
      - deployment: DeployToDev
        environment: 'dev'
        strategy:
          runOnce:
            deploy:
              steps:
                - checkout: self

                - task: Docker@2
                  inputs:
                    containerRegistry: '$(ACR_SERVICE_CONNECTION)'
                    repository: '$(APP_NAME)'
                    command: 'buildAndPush'
                    Dockerfile: 'Dockerfile'
                    tags: '$(Build.SourceVersion)'
                  displayName: 'Build and push Docker image'

                - task: AzureCLI@2
                  inputs:
                    azureSubscription: '$(AZURE_SERVICE_CONNECTION)'
                    scriptType: 'bash'
                    scriptLocation: 'inlineScript'
                    inlineScript: |
                      az containerapp update \
                        --name $(APP_NAME) \
                        --resource-group $(RESOURCE_GROUP) \
                        --image $(ACR_REGISTRY)/$(APP_NAME):$(Build.SourceVersion)
                  displayName: 'Deploy to Dev'

                - script: curl -f https://$(APP_HOSTNAME)/health.json
                  displayName: 'Smoke test'

  - stage: DeployProd
    dependsOn: DeployDev
    jobs:
      - deployment: DeployToProduction
        environment: 'production'    # Azure DevOps environment with approval gate
        strategy:
          runOnce:
            deploy:
              steps:
                - checkout: self

                - task: Docker@2
                  inputs:
                    containerRegistry: '$(ACR_SERVICE_CONNECTION)'
                    repository: '$(APP_NAME)'
                    command: 'buildAndPush'
                    Dockerfile: 'Dockerfile'
                    tags: '$(Build.SourceVersion)'
                  displayName: 'Build and push Docker image'

                - task: AzureCLI@2
                  inputs:
                    azureSubscription: '$(AZURE_SERVICE_CONNECTION)'
                    scriptType: 'bash'
                    scriptLocation: 'inlineScript'
                    inlineScript: |
                      az containerapp update \
                        --name $(APP_NAME) \
                        --resource-group $(RESOURCE_GROUP) \
                        --image $(ACR_REGISTRY)/$(APP_NAME):$(Build.SourceVersion)
                  displayName: 'Deploy to Production'
```

Note: the bundle size check now uses `gzip -c dist/assets/*.js | wc -c` to measure actual gzipped size, fixing review item #7.

### Infrastructure Pipeline (Issue #22)

**File:** `azure-pipelines.yml` in the `eaf-infra` repository.

```yaml
trigger:
  branches:
    include:
      - main

pool:
  vmImage: 'ubuntu-latest'

stages:
  - stage: Validate
    jobs:
      - job: BicepBuild
        steps:
          - task: AzureCLI@2
            inputs:
              azureSubscription: '$(AZURE_SERVICE_CONNECTION)'
              scriptType: 'bash'
              scriptLocation: 'inlineScript'
              inlineScript: az bicep build --file main.bicep
            displayName: 'Validate Bicep'

  - stage: DeployDev
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    dependsOn: Validate
    jobs:
      - deployment: DeployInfraDev
        environment: 'dev'
        strategy:
          runOnce:
            deploy:
              steps:
                - checkout: self
                - task: AzureCLI@2
                  inputs:
                    azureSubscription: '$(AZURE_SERVICE_CONNECTION)'
                    scriptType: 'bash'
                    scriptLocation: 'inlineScript'
                    inlineScript: |
                      az deployment group create \
                        --resource-group $(RESOURCE_GROUP) \
                        --template-file main.bicep \
                        --parameters @environments/dev.params.json
                  displayName: 'Deploy to Dev'

  - stage: DeployProd
    dependsOn: DeployDev
    jobs:
      - deployment: DeployInfraProd
        environment: 'production'    # Approval gate
        strategy:
          runOnce:
            deploy:
              steps:
                - checkout: self
                - task: AzureCLI@2
                  inputs:
                    azureSubscription: '$(AZURE_SERVICE_CONNECTION)'
                    scriptType: 'bash'
                    scriptLocation: 'inlineScript'
                    inlineScript: |
                      az deployment group create \
                        --resource-group $(RESOURCE_GROUP) \
                        --template-file main.bicep \
                        --parameters @environments/prod.params.json
                  displayName: 'Deploy to Production'
```

### Package Registry

Azure Artifacts is the internal npm registry. This resolves Open Question #1.

Each repository requires an `.npmrc` file pointing to the Azure Artifacts feed:

```ini
registry=https://pkgs.dev.azure.com/{org}/{project}/_packaging/{feed}/npm/registry/
always-auth=true
```

The `npmAuthenticate@0` task in the pipeline handles token injection at build time. Developers authenticate locally via `az artifacts universal connect` or `vsts-npm-auth`.

### Repository and Pipeline Mapping

| Repository | Hosted On | Pipeline Runs On | Pipeline File |
|---|---|---|---|
| `eaf-packages` | GitHub | Azure DevOps Pipelines | `azure-pipelines.yml` |
| `eaf-app-template` | GitHub | Azure DevOps Pipelines | `azure-pipelines.yml` |
| `eaf-reference-app` | GitHub | Azure DevOps Pipelines | `azure-pipelines.yml` (inherited from template) |
| `eaf-infra` | GitHub | Azure DevOps Pipelines | `azure-pipelines.yml` |

Azure DevOps connects to GitHub repos via the **Azure Pipelines GitHub App** or a GitHub service connection. This is a one-time setup per repository.

### What Stays in GitHub

| Concern | Location | Purpose |
|---|---|---|
| Git repository hosting | GitHub | Source of truth for all code. |
| Pull requests and code review | GitHub | Standard PR workflow. |
| `CLAUDE.md` | Repo root | Claude Code / Claude instructions. |
| `.github/copilot-instructions.md` | `.github/` | GitHub Copilot Agents instructions. |
| GitHub template repository flag | `eaf-app-template` settings | Enables "Use this template" for new apps. |

### What Moves to / Lives in Azure DevOps

| Concern | Location | Purpose |
|---|---|---|
| CI/CD pipelines | `azure-pipelines.yml` in each repo | Build, test, security scan, deploy. |
| Package registry | Azure Artifacts | Hosts all `@eaf/*` npm packages. |
| Environment approvals | Azure DevOps Environments | Manual approval gates for staging and production deployments. |
| Pipeline variables and secrets | Azure DevOps Pipeline Variables / Variable Groups | `ACR_SERVICE_CONNECTION`, `AZURE_SERVICE_CONNECTION`, `APIM_GATEWAY_TOKEN`, etc. |
| Service connections | Azure DevOps Project Settings | Connections to Azure subscriptions, ACR, and GitHub. |

### Spec and Issue Updates Required

| Document | Section / Issue | Change |
|---|---|---|
| Spec | Section 6.3 (Scaffold) | Change "CI/CD pipeline YAML (Azure DevOps or GitHub Actions)" to "Azure DevOps Pipeline YAML (`azure-pipelines.yml`)". |
| Spec | Section 13.1 (Pipeline Design) | Add a note: "All pipelines run on Azure DevOps Pipelines. GitHub is used for repository hosting only." |
| Spec | Section 4.3 (External Dependencies) | Add Azure DevOps to the external systems table. |
| Spec | Open Questions | Close #1 (Azure Artifacts) and #6 (Azure DevOps Pipelines). |
| Issue #13 | Scaffold file structure | Replace `.github/workflows/ci.yml` with `azure-pipelines.yml`. Keep `.github/copilot-instructions.md`. |
| Issue #20 | Full rewrite | Replace GitHub Actions YAML with Azure DevOps YAML (packages monorepo pipeline, as above). Replace `actions/upload-artifact` with `PublishBuildArtifacts@1`. Replace `secrets.*` references with Azure DevOps variable group references. |
| Issue #21 | Full rewrite | Replace GitHub Actions YAML with Azure DevOps YAML (application pipeline, as above). Replace GitHub environment protection rules with Azure DevOps environment approval gates. Fix the bundle size measurement to use gzipped size. |
| Issue #22 | Pipeline section | Replace `.github/workflows/deploy.yml` with `azure-pipelines.yml` (infra pipeline, as above). |

---

## Summary of All Affected Issues

| Issue | Change Type | Description |
|---|---|---|
| #3 (`@eaf/auth`) | Modify | Add `msalInstance.ts` singleton module, add `getToken.ts`, update `AuthProvider` to use `initialiseMsal()`, add `getToken` to public exports. |
| #4 (`@eaf/api-client`) | Modify | Replace `useToken()` with `getToken` import in `eafBaseQuery`. Remove the hooks-in-component constraint. |
| #13 (`eaf-app-template`) | Modify | Replace `.github/workflows/ci.yml` with `azure-pipelines.yml`. Add `.npmrc` for Azure Artifacts. Update `.env.example` to make APIM vars optional. |
| #19 (Docker dev env) | Modify | Replace APIM gateway with Caddy as default. Move APIM to opt-in profile. Fix SQL Server seed script to use `db-init` service with `sqlcmd`. |
| #20 (CI/CD packages) | Full rewrite | GitHub Actions → Azure DevOps YAML. |
| #21 (CI/CD application) | Full rewrite | GitHub Actions → Azure DevOps YAML. Fix bundle size check to measure gzipped. |
| #22 (Bicep IaC) | Modify | Replace `.github/workflows/deploy.yml` with `azure-pipelines.yml`. |
| #24 (`@eaf/auth-code-app`) | Modify | Add `getToken` export matching `@eaf/auth` contract. |

---

## Pre-Implementation Checklist

Before assigning any Phase 1 issues, confirm the following are done:

- [ ] Spec updated with all changes from the three tables above
- [ ] Issues #3, #4, #13, #19, #24 updated with modifications
- [ ] Issues #20 and #21 fully rewritten for Azure DevOps
- [ ] Issue #22 pipeline section updated for Azure DevOps
- [ ] Azure DevOps project created with: GitHub service connection, Azure Artifacts npm feed, service connections to Azure subscriptions and ACR, environments (`dev`, `staging`, `production`) with appropriate approval gates
- [ ] Azure Artifacts feed URL documented and `.npmrc` template prepared
- [ ] Open Questions #1 and #6 closed in the spec with recorded decisions
