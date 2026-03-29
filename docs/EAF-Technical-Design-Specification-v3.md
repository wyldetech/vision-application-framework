# Enterprise Application Framework (EAF)
## Technical Design Specification — Phase 1: Foundation

| Field | Value |
|---|---|
| **Version** | 0.3 |
| **Status** | Draft |
| **Author(s)** | Platform Architecture Team |
| **Reviewers** | Engineering Leadership, Security, DevOps |
| **Last Updated** | 2025-03-27 |
| **Phase** | Phase 1 — Foundation |

---

## Change Log

| Version | Date | Author | Summary of Changes |
|---|---|---|---|
| 0.1 | 2025-03-27 | Platform Architecture Team | Initial draft |
| 0.2 | 2025-03-27 | Platform Architecture Team | Revised frontend architecture: replaced Module Federation with standalone apps and shared packages. Adopted Redux Toolkit + RTK Query for state management. Introduced Turborepo monorepo for shared packages. Replaced Webpack with Vite. Added Storybook. Redesigned shell as portal + layout package. Rewrote risks, ADRs, and testing strategy accordingly. |
| 0.3 | 2025-03-27 | Platform Architecture Team | Added host-agnostic deployment model (Section 13.4). Added Power Apps Code Apps as a supported deployment target with adapter pattern. Added `@eaf/auth-code-app` adapter package. New ADR-006. Updated Future Considerations, Glossary, and Reference Documents. |

---

## 1. Executive Summary

The Enterprise Application Framework (EAF) is a cloud-native, Azure-hosted platform designed to unify multiple independent line-of-business (LOB) applications within a single, consistent user experience. Rather than a single composed application, the EAF is a set of shared standards, packages, and infrastructure that allow independently deployed applications to look, feel, and behave consistently — sharing common authentication, navigation chrome, design language, API governance, and observability infrastructure.

Each application in the EAF is a standalone React application. It is independently developed, built, and deployed. Applications do not share a runtime — they share a set of well-designed packages (`@eaf/ui-components`, `@eaf/shell-layout`, `@eaf/auth`, `@eaf/api-client`) that enforce visual and behavioural consistency at build time rather than at runtime. Navigation between applications is a standard browser navigation. Authentication is handled independently by each application against the same Entra ID tenant, providing seamless SSO via shared session state without any runtime coupling.

This architecture is deliberately chosen to optimise for rapid, AI-driven development across multiple teams and products. The patterns used — standalone React apps, Redux Toolkit, RTK Query, Vite, well-typed shared packages — are among the most thoroughly documented and widely understood in the React ecosystem. AI development tools perform at their best with these patterns, generating reliable, consistent code that requires minimal correction. The platform team's primary investment is in the quality, documentation, and developer experience of the shared packages and the application scaffold template — these are the assets that govern consistency across the portfolio, and they serve as the effective instruction set for AI-assisted development.

---

## 2. Goals and Non-Goals

### 2.1 Goals

Each goal below is verifiable against the delivered Phase 1 system:

- **G1: Shared Package Foundation** — The core shared packages (`@eaf/ui-components`, `@eaf/shell-layout`, `@eaf/auth`, `@eaf/api-client`) are published to the internal package registry, versioned, and fully consumed by the reference application.
- **G2: Application Scaffold** — A `create-eaf-app` scaffold template exists that generates a new standalone application with auth wired up, shared packages installed, APIM integration configured, logging in place, Docker Compose running, and CI/CD pipeline ready. A developer can go from zero to running application in under one hour.
- **G3: Unified Visual Experience** — All applications built on the EAF present identical navigation chrome (header, sidebar, footer) and share the same design tokens. Users cannot visually distinguish which team built which application.
- **G4: Seamless SSO** — A user authenticated in one EAF application is silently authenticated in all others. No visible login prompts when navigating between applications.
- **G5: API Governance** — All application APIs are published through Azure APIM. Consistent authentication, rate limiting, logging, and CORS policies are enforced at the gateway.
- **G6: Reference Application** — A fully functional reference application demonstrates all EAF patterns: CRUD, RTK Query data fetching, data visualisation with Recharts, chat agent integration, structured logging, and error handling. It serves as the canonical example for AI-assisted development.
- **G7: Storybook Component Catalogue** — Every component in `@eaf/ui-components` and `@eaf/shell-layout` is documented in a deployed Storybook instance with usage examples, prop documentation, and accessibility notes.
- **G8: Automated Pipelines** — CI/CD pipelines exist for all shared packages and the reference application, building, testing, security-scanning, and publishing/deploying automatically on merge to main.

### 2.2 Non-Goals

The following are explicitly out of scope for Phase 1:

- **NG1: Runtime UI Composition** — Applications are not composed at runtime. There is no shell application that dynamically loads remote modules. Navigation between applications is a standard browser navigation.
- **NG2: Event-Driven Architecture** — Service Bus, Event Grid, and asynchronous messaging patterns are deferred. Applications requiring event-driven behaviour must implement interim synchronous polling if needed.
- **NG3: Cross-Application Workflows** — Orchestration of business processes spanning multiple application domains is not addressed in Phase 1.
- **NG4: Multi-Region Deployment** — All Phase 1 infrastructure targets a single Azure region.
- **NG5: Advanced / Fine-Grained Authorisation** — ABAC and dynamic permission models are out of scope. Phase 1 supports RBAC only, with roles defined at application level.
- **NG6: Advanced Analytics and Reporting** — A cross-application analytics or reporting layer is not in scope.
- **NG7: Production Readiness of Reference App** — The reference application is a demonstrator for EAF patterns, not a production system.

---

## 3. Architectural Principles

These principles govern all design decisions within the EAF. When facing an ambiguous design choice, a developer should be able to resolve it by reference to one or more of these principles.

| # | Principle | Description | Implication |
|---|---|---|---|
| 1 | Consistency at Build Time, Not Runtime | Shared standards are enforced through packages and tooling consumed at build time. There is no runtime coupling between applications. | Applications share packages, not a runtime. An outage in one application has zero effect on others. |
| 2 | Optimise for AI-Driven Development | Architecture and technology choices prioritise patterns that AI development tools handle reliably — well-documented, widely understood, strongly typed, and opinionated. | Prefer established patterns over clever ones. Complexity that requires deep human expertise to debug is a liability. |
| 3 | Packages Are the Governance Layer | Shared packages (`@eaf/ui-components`, `@eaf/shell-layout`, `@eaf/auth`, `@eaf/api-client`) are the primary mechanism for enforcing consistency. Their quality, documentation, and TypeScript types are first-class engineering concerns. | Package documentation and TypeScript definitions are as important as the implementation. They are the instruction set for AI tooling. |
| 4 | The Scaffold Is the Standard | A new application starts from the scaffold template. The scaffold embeds all EAF conventions — package versions, folder structure, logging setup, auth wiring, pipeline config. Divergence from the scaffold must be deliberate and documented. | Consistency across apps comes from a common starting point, not ongoing policing. |
| 5 | Separation of Concerns | Each application is a self-contained unit with its own domain, data, and API boundary. No shared databases. No direct cross-application API calls from the frontend. | Applications integrate via APIM-published APIs only. |
| 6 | API-First Communication | All communication between frontend and backend, and between services, occurs via published APIs through the central gateway. | No direct frontend-to-backend calls bypassing APIM. API contracts are the only integration surface. |
| 7 | Central Governance, Decentralised Delivery | The platform team defines and maintains standards. Application teams retain full ownership of their implementation and deployment lifecycle. | Governance is embedded in tooling (scaffold, lint rules, pipeline templates), not enforced through manual approval processes wherever avoidable. |
| 8 | Security by Default | Least-privilege access, token-based authentication, encrypted transport, and secrets management are baseline requirements. | No hardcoded credentials. No HTTP. All secrets via Key Vault. Auth is provided by the shared `@eaf/auth` package — never re-implemented per application. |

---

## 4. System Context

### 4.1 Context Diagram (C4 Level 1)

```
┌──────────────────────────────────────────────────────────────────────────┐
│                   Enterprise Application Framework (EAF)                 │
│                                                                          │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────────┐   │
│  │  EAF Portal      │  │  App A           │  │  App B               │   │
│  │  (landing / nav) │  │  (standalone)    │  │  (standalone)        │   │
│  └──────────────────┘  └──────────────────┘  └──────────────────────┘   │
│           │                    │                       │                  │
│           └────────────────────┴───────────────────────┘                 │
│                                │                                          │
│                   [@eaf/shell-layout, @eaf/auth,                         │
│                    @eaf/ui-components, @eaf/api-client]                  │
│                                │                                          │
│                    ┌───────────┴──────────┐                              │
│                    │   Azure APIM Gateway │                              │
│                    └───────────┬──────────┘                              │
│                                │                                          │
│              ┌─────────────────┼─────────────────┐                       │
│              ▼                 ▼                  ▼                       │
│        [App A API]       [App B API]        [Platform APIs]              │
│                                                                          │
│                    ┌──────────────────────┐                              │
│                    │  Microsoft Entra ID  │                              │
│                    └──────────────────────┘                              │
└──────────────────────────────────────────────────────────────────────────┘
        ▲
   [End Users]
   [Admins]
```

### 4.2 Actors

| Actor | Type | Description |
|---|---|---|
| End User | Human | Enterprise staff who interact with LOB applications. They authenticate once via Entra ID SSO and are silently authenticated across all EAF applications without additional login prompts. |
| Platform Administrator | Human | Responsible for maintaining shared packages, the scaffold template, APIM, and onboarding new application teams. |
| Application Developer | Human | Builds and operates a standalone EAF application. Starts from the scaffold template, consumes shared packages, and owns their domain entirely. |
| External / Downstream Systems | External | Third-party or internal legacy systems called by application backends via their own APIs. Never called directly from the frontend. |

### 4.3 External System Dependencies

| System | Integration Type | Owned By | Notes / Risks |
|---|---|---|---|
| Microsoft Entra ID (Azure AD) | OIDC / OAuth 2.0 | IT / Microsoft | Identity provider for SSO. Each app runs its own MSAL instance against the same tenant. Silent SSO works across apps via shared Entra ID session. |
| Azure API Management | Internal gateway | Platform Team | Central API routing and policy enforcement. Shared across all application APIs. |
| Azure Key Vault | SDK / REST | Platform Team | Secret and certificate storage. Applications access via managed identity. |
| Azure Application Insights | SDK telemetry | Platform Team | Centralised logging and monitoring. The `@eaf/api-client` package includes Application Insights instrumentation by default. |
| Azure Container Registry | Docker pull | Platform Team | Stores built application container images. |
| Internal npm Registry | npm publish/install | Platform Team | Hosts all `@eaf/*` packages. Azure Artifacts or GitHub Packages. Required before any application can consume shared packages. |

---

## 5. High-Level Architecture

### 5.1 Container Diagram (C4 Level 2)

```
  Browser                                       Azure
┌─────────────────────────────────┐  ┌────────────────────────────────────────┐
│                                 │  │                                        │
│  ┌─────────────────────────┐    │  │  ┌───────────┐  ┌──────────────────┐  │
│  │  EAF Portal             │    │  │  │  Azure    │  │  App A API       │  │
│  │  - Landing page         │    │  │  │  APIM     │─►│  (.NET 8 / SQL)  │  │
│  │  - App directory / nav  │    │  │  │  Gateway  │  └──────────────────┘  │
│  │  Uses @eaf/shell-layout │    │  │  │           │  ┌──────────────────┐  │
│  └─────────────────────────┘    │  │  │           │─►│  App B API       │  │
│                                 │  │  └───────────┘  │  (.NET 8 / SQL)  │  │
│  ┌─────────────────────────┐    │  │        │        └──────────────────┘  │
│  │  App A (standalone)     │────┼──┼────────┘                              │
│  │  - Vite + React + Redux │    │  │  ┌──────────────────────────────────┐ │
│  │  - @eaf/shell-layout    │    │  │  │  Shared Package Registry         │ │
│  │  - @eaf/auth            │    │  │  │  @eaf/ui-components              │ │
│  │  - @eaf/ui-components   │    │  │  │  @eaf/shell-layout               │ │
│  │  - @eaf/api-client      │    │  │  │  @eaf/auth                       │ │
│  └─────────────────────────┘    │  │  │  @eaf/api-client                 │ │
│                                 │  │  │  @eaf/eslint-config              │ │
│  ┌─────────────────────────┐    │  │  └──────────────────────────────────┘ │
│  │  App B (standalone)     │────┼──┼───────────────────────────────────────┤
│  │  [same stack as App A]  │    │  │  ┌──────────────────────────────────┐ │
│  └─────────────────────────┘    │  │  │  Microsoft Entra ID              │ │
└─────────────────────────────────┘  │  └──────────────────────────────────┘ │
                                      └────────────────────────────────────────┘
```

### 5.2 Component Summary

| Component | Type | Purpose | Owns Data? |
|---|---|---|---|
| EAF Portal | Standalone React app | Landing page and application directory. Provides navigation links to all EAF applications. Uses `@eaf/shell-layout` for consistent chrome. | No |
| Standalone Application | Standalone React app | Self-contained application for a business domain. Uses all `@eaf/*` packages. Independently deployed to its own URL. | No (UI only) |
| Application API | Backend Service (.NET 8) | Encapsulates domain logic and data access. The only entry point to the application's data store. | Yes |
| Azure APIM | Infrastructure Gateway | Central routing, authentication enforcement, rate limiting, CORS, and observability for all APIs. | No |
| `@eaf/ui-components` | npm package | Shared React component library built on Fluent UI. Layout, forms, data display, charts, feedback components. | No |
| `@eaf/shell-layout` | npm package | Header, sidebar navigation, and footer components. Provides consistent chrome across all applications. | No |
| `@eaf/auth` | npm package | MSAL.js wrapper. Handles authentication initialisation, token acquisition, and token injection into API requests. | No |
| `@eaf/api-client` | npm package | Pre-configured Axios/fetch base client. Injects auth tokens, correlation IDs, and Application Insights telemetry into all API requests. | No |
| `@eaf/eslint-config` | npm package | Shared ESLint configuration enforcing EAF coding standards, import restrictions, and accessibility rules. | No |
| Shared Package Monorepo | Turborepo repository | Co-located source for all `@eaf/*` packages and the Storybook instance. Owned and maintained by the platform team. | No |
| Microsoft Entra ID | Platform / Identity | OAuth 2.0 / OIDC identity provider. Each application runs its own MSAL instance against the same tenant. | No |
| Azure Key Vault | Platform / Security | Stores secrets, connection strings, and certificates. | No |
| Azure Application Insights | Platform / Observability | Centralised structured log aggregation, distributed traces, dashboards, and alerting. | No |

---

## 6. Frontend Architecture

### 6.1 Technology Stack

| Concern | Choice | Version / Constraint | Rationale |
|---|---|---|---|
| Framework | React | 18.x | Industry-standard. Largest presence in AI training data for frontend development. |
| Language | TypeScript | 5.x | Strong typing is critical for shared packages — types serve as machine-readable documentation for AI tools. |
| Build Tool | Vite | 5.x | Fast, simple, minimal configuration. No Module Federation requirement means no reason to use Webpack. AI tools generate correct Vite config reliably. |
| Design System | Fluent UI React | v9.x | Microsoft-native design system, consistent with Azure tooling. Accessible by default. Well-represented in AI training data. |
| State Management | Redux Toolkit (RTK) | 2.x | Industry-standard, heavily documented, opinionated patterns that AI tools replicate accurately. Predictable structure across all applications. |
| Data Fetching / Caching | RTK Query | (bundled with RTK 2.x) | Eliminates loading/error state boilerplate. Consistent data fetching patterns across all apps. Excellent AI-generated code quality. |
| Data Visualisation | Recharts | 2.x | Lightweight, composable, React-native. Specified in EAF requirements. |
| Package Monorepo | Turborepo | Latest stable | Manages shared packages with incremental builds, shared lint/test config, and atomic cross-package changes. Well-supported by AI tooling. |
| Component Dev / Docs | Storybook | 8.x | Primary development, testing, and documentation environment for shared components. Deployed instance serves as the AI developer's component reference. |

### 6.2 Shared Package Architecture

The `@eaf/*` packages are the governance layer of the EAF. They are co-located in a Turborepo monorepo owned by the platform team.

**Repository structure:**
```
eaf-packages/                     ← Turborepo monorepo
├── packages/
│   ├── ui-components/            ← @eaf/ui-components
│   ├── shell-layout/             ← @eaf/shell-layout
│   ├── auth/                     ← @eaf/auth
│   ├── api-client/               ← @eaf/api-client
│   └── eslint-config/            ← @eaf/eslint-config
├── apps/
│   └── storybook/                ← Deployed Storybook instance
├── turbo.json
└── package.json
```

**Package responsibilities:**

`@eaf/ui-components` — The component library. Built on Fluent UI. Covers layout primitives, navigation elements, form controls, data display, chart wrappers, and feedback components. Every component ships with TypeScript types, JSDoc, and a Storybook story. This is the primary reference that AI tools use when generating application UI code.

`@eaf/shell-layout` — Header, collapsible sidebar navigation, and footer. Accepts a navigation config prop that each application provides to populate the sidebar. Handles responsive behaviour. Consuming an application renders `<ShellLayout navConfig={...}>` as its root — this is the entirety of the chrome integration.

`@eaf/auth` — A thin, opinionated wrapper around MSAL.js. Exports `<AuthProvider>`, `useAuth()`, and `useToken()`. Handles MSAL initialisation, silent token acquisition, and token refresh. Applications never interact with MSAL directly. The package is pre-configured to work with the EAF Entra ID tenant — application teams provide only their application's client ID.

`@eaf/api-client` — A pre-configured Axios instance factory. Automatically injects the Bearer token from `@eaf/auth`, appends a `x-correlation-id` header on every request, and sends telemetry to Application Insights. Applications call `createApiClient(baseUrl)` and get a ready-to-use client. RTK Query base queries are built on top of this client.

`@eaf/eslint-config` — Shared ESLint rules. Enforces TypeScript strictness, React best practices, accessibility rules (jsx-a11y), and import restrictions (prevents cross-application imports, enforces use of `@eaf/*` components over raw Fluent UI where wrappers exist).

### 6.3 Application Scaffold Template

The scaffold is a GitHub template repository (`eaf-app-template`) that generates a complete, runnable EAF application. It is maintained by the platform team and updated whenever shared package versions or conventions change.

**What the scaffold provides out of the box:**
- Vite + React + TypeScript, configured and working
- All `@eaf/*` packages installed at current pinned versions
- `<AuthProvider>` and `<ShellLayout>` wired up in `App.tsx`
- A pre-configured Redux store with RTK Query base query using `@eaf/api-client`
- A sample API slice demonstrating RTK Query usage pattern
- Application Insights initialisation
- Structured logging setup (correlation ID generation)
- Docker Compose file (app + database + APIM self-hosted gateway)
- CI/CD pipeline YAML (Azure DevOps or GitHub Actions)
- `.eslintrc` extending `@eaf/eslint-config`
- A `README.md` with getting-started instructions and links to EAF documentation

**The scaffold is the single most important Phase 1 deliverable.** It encodes all EAF conventions in a form that is immediately useful to AI development tools. When a developer opens the scaffold in Cursor, Copilot, or Claude and says "add a page that lists orders with filtering and pagination," the AI has full context — the store structure, the API client, the component library, the auth pattern — and generates code that fits the application correctly.

### 6.4 State Management

Redux Toolkit is used for all application state. The pattern is consistent across all EAF applications.

**Store structure:**

```typescript
// Standard EAF store structure (generated by scaffold)
import { configureStore } from '@reduxjs/toolkit';
import { eafApi } from './api/eafApi'; // RTK Query base API

export const store = configureStore({
  reducer: {
    [eafApi.reducerPath]: eafApi.reducer,
    // Application slices added here
  },
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware().concat(eafApi.middleware),
});
```

**RTK Query pattern for API integration:**

```typescript
// All API calls use RTK Query slices — no ad-hoc fetch calls
import { createApi } from '@reduxjs/toolkit/query/react';
import { eafBaseQuery } from '@eaf/api-client';

export const ordersApi = createApi({
  reducerPath: 'ordersApi',
  baseQuery: eafBaseQuery('/api/v1'),
  endpoints: (builder) => ({
    getOrders: builder.query<Order[], OrdersFilter>({
      query: (filter) => ({ url: '/orders', params: filter }),
    }),
    createOrder: builder.mutation<Order, CreateOrderRequest>({
      query: (body) => ({ url: '/orders', method: 'POST', body }),
    }),
  }),
});
```

**State ownership:**

| State Type | Owned By | Mechanism | Notes |
|---|---|---|---|
| Server / API data | RTK Query cache | Auto-managed by RTK Query | Loading, error, data states handled automatically |
| Authentication context | `@eaf/auth` package | React Context (internal to package) | Exposed via `useAuth()` hook. Redux does not own auth state. |
| Application UI state | App Redux slice | Redux Toolkit slice | Form state, modal open/closed, active filters, etc. |
| Navigation state | URL | React Router v6 | Source of truth for active route. Deep links must work. |
| Theme preference | `@eaf/shell-layout` | localStorage + React Context | Persists across sessions. Set via shell layout controls. |
| Shared user preferences | Application API | RTK Query + Redux | Fetched on auth completion, stored in Redux, persisted to backend. |

**Navigation and re-mount behaviour:** Each application is a standalone SPA. When a user navigates away (to another EAF application or externally) and returns, the application re-mounts and RTK Query re-fetches data as configured (respecting cache TTL). Applications must not assume in-memory state persists across navigations. RTK Query's `keepUnusedDataFor` and `refetchOnMountOrArgChange` settings should be configured explicitly per endpoint.

### 6.5 Authentication Pattern

Each EAF application runs its own MSAL.js instance, configured against the same Entra ID tenant. This provides seamless SSO — a user who has authenticated in any EAF application has an active Entra ID session, and subsequent applications acquire tokens silently without a visible login prompt.

```typescript
// App.tsx — standard auth setup from scaffold
import { AuthProvider } from '@eaf/auth';

const authConfig = {
  clientId: import.meta.env.VITE_AUTH_CLIENT_ID,  // App-specific
  tenantId: import.meta.env.VITE_AUTH_TENANT_ID,  // Shared EAF tenant
  scopes: ['api://eaf-app-a/.default'],             // App-specific API scope
};

export default function App() {
  return (
    <AuthProvider config={authConfig}>
      <ShellLayout navConfig={navConfig}>
        <AppRouter />
      </ShellLayout>
    </AuthProvider>
  );
}
```

The `@eaf/auth` package handles: MSAL initialisation, silent token acquisition on load, visible redirect login if no session exists, token refresh before expiry, and logout. Application developers never interact with MSAL directly.

### 6.6 Shared Component Library

- **Package:** `@eaf/ui-components`
- **Versioning:** Semantic versioning. Breaking changes increment the major version and are communicated to all application teams with a migration guide.
- **Documentation:** Every component is documented in the deployed Storybook instance. Stories cover default usage, all significant prop variants, and edge cases. Accessibility notes are included.
- **Breaking change policy:** Deprecated components are flagged with a console warning for at least one minor release cycle before removal.

**Phase 1 component catalogue:**

- Layout: `PageContainer`, `SectionCard`, `ContentGrid`, `SplitPane`, `PageHeader`
- Navigation: `AppNav`, `BreadcrumbBar`, `TabBar`
- Forms: `TextInput`, `SelectDropdown`, `DatePicker`, `FormGroup`, `ValidationMessage`, `SubmitButton`
- Data Display: `DataTable` (sorting, pagination, column config), `StatusBadge`, `MetricCard`, `DefinitionList`
- Charts: `LineChartWrapper`, `BarChartWrapper`, `PieChartWrapper` (Recharts-backed)
- Feedback: `LoadingSkeleton`, `ErrorDisplay`, `ToastNotification`, `EmptyState`, `ConfirmDialog`
- Chat: `ChatPanel`, `ChatMessage`, `AgentActionCard`

**Extension rules:** Applications wrap components to add domain-specific behaviour but must not override core styles or accessibility attributes. Components that would be useful across multiple applications should be contributed back to `@eaf/ui-components` rather than maintained in the application.

### 6.7 Performance Budget

| Metric | Target | Measurement Method |
|---|---|---|
| Initial page load (TTI) | < 2.5s on 4G (10 Mbps) | Lighthouse CI in pipeline |
| JavaScript bundle size (initial) | < 350 KB gzipped | Vite build analysis in CI |
| Route transition (within app) | < 300ms | Playwright performance trace |
| Largest Contentful Paint (LCP) | < 2.5s | Lighthouse CI |
| Cumulative Layout Shift (CLS) | < 0.1 | Lighthouse CI |
| API response time (P95) | < 500ms at APIM boundary | APIM analytics dashboard |
| RTK Query cache hit rate | > 60% for read endpoints | Application Insights custom metric |

> Note: Because each application is a standalone bundle, the per-app bundle size limit is larger than it would be in a Module Federation model (where apps load incrementally). The 350 KB limit reflects this. Teams should still code-split aggressively within their app using React.lazy() for route-level chunks.

---

## 7. Backend Architecture

### 7.1 Technology Stack

| Concern | Choice | Version / Constraint | Rationale |
|---|---|---|---|
| Language / Runtime | C# / .NET 8 | .NET 8 LTS | Long-term support, strong Azure ecosystem integration, managed identity support, EF Core maturity. Excellent AI code generation quality. |
| API Style | RESTful (OpenAPI 3.1) | OpenAPI 3.1 | Wide tooling support, easy APIM import, auto-generated TypeScript client types via OpenAPI generator. OpenAPI specs are excellent fuel for AI-assisted frontend development. |
| ORM / Data Access | Entity Framework Core | EF Core 8.x | First-class .NET ORM with strong migration tooling. Enables database-agnostic unit testing via in-memory provider. |
| Database | Azure SQL Database | General Purpose tier | Fully managed, BCDR-capable, familiar SQL semantics. |
| API Documentation | Swashbuckle / Swagger | 6.x | Auto-generated OpenAPI spec from code. Published to APIM on deployment. |
| Logging | Serilog | 3.x | Structured JSON logging, Application Insights sink, correlation ID enrichment. |

### 7.2 API Design Standards

- **URL conventions:** `/api/v{n}/{resource}` — e.g. `/api/v1/orders/{id}`
- **HTTP method usage:** GET (read), POST (create), PUT (full update), PATCH (partial update), DELETE (remove)
- **Pagination:** Offset-based using `?page=1&pageSize=25` with total count in response envelope
- **Response envelope:** All list responses wrapped in `{ data: [], meta: { total, page, pageSize } }`
- **Versioning strategy:** URL path versioning (v1, v2). Maintain previous version for a minimum of 6 months after deprecation notice.

> **AI development note:** A complete, accurate OpenAPI spec for each application API is a high-priority deliverable. AI tools use the spec to generate RTK Query endpoint definitions, TypeScript types, and test fixtures. An incomplete or inaccurate spec directly degrades AI-generated code quality.

**Standard error response:**
```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "The requested order does not exist.",
    "traceId": "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"
  }
}
```

Error codes are application-defined string constants (e.g. `VALIDATION_FAILED`, `UNAUTHORISED`, `CONFLICT`). Stack traces are never returned in production responses.

### 7.3 API Gateway (Azure APIM)

| Concern | Detail |
|---|---|
| Product | Azure API Management (Developer tier for Dev; Standard v2 for Staging/Prod) |
| Configuration approach | Bicep — APIM configuration is infrastructure-as-code. Application teams self-service via pull request against the infra repository. |
| Ownership model | Platform team owns the APIM instance. Application teams own their product and API definitions within it. |
| Auth enforcement | JWT validation policy on all inbound requests. Token issued by Entra ID, audience claim validated against the registered API app registration. |
| Rate limiting | Default: 100 calls per 60 seconds per subscription key. Adjustable via infra PR. |
| CORS | Allowed origins explicitly configured per API — no wildcard in production. |
| Logging | All requests logged to Application Insights via APIM diagnostic settings. Body logging limited to 8 KB. |
| OpenAPI import | Application OpenAPI specs are imported into APIM automatically as part of the deployment pipeline. |
| Environments | Separate APIM instances for Dev, Staging, and Production. URL pattern: `api.{env}.eaf.internal/{app-name}` |

### 7.4 Data Ownership

| Application | Data Store | Type | Access Boundary |
|---|---|---|---|
| EAF Portal | None — stateless | N/A | No persistent state. |
| Reference App (Sample) | eaf-sample-db | Azure SQL | Only the Sample App's API may read or write. |
| [Future App A] | [app-a-db] | Azure SQL / Cosmos (TBD) | Only App A's API. |

**Rules:** No shared databases between applications. Cross-application data access must occur via published APIs through APIM. Direct database access from outside the owning application's Azure identity boundary is prohibited and enforced via managed identity scoping and Azure network rules.

### 7.5 Inter-Application Communication

| Pattern | When to Use | Approval Required? |
|---|---|---|
| API call via APIM | Standard cross-app data reads from backend services. | No — standard pattern |
| Shared read-only reference API | Common reference data (user profile, tenant config) exposed as a platform-level API. | No — provided by platform team |
| Direct service-to-service | High-throughput internal calls where APIM overhead is unacceptable. Must be justified. | Yes — platform architecture review |
| Event-based messaging | Asynchronous workflows spanning multiple apps. | Not in Phase 1 — deferred |

---

## 8. Authentication and Authorisation

### 8.1 Authentication

| Concern | Detail |
|---|---|
| Provider | Microsoft Identity Platform (Entra ID / Azure AD) |
| Protocol | OAuth 2.0 + OpenID Connect (OIDC) |
| Library | MSAL.js 2.x via `@eaf/auth` package — applications never use MSAL directly |
| Backend library | Microsoft.Identity.Web 2.x — integrated into each application API |
| Token type | JWT access token + refresh token |
| Token lifetime | Access token: 1 hour. Refresh token: 24 hours. |
| Token storage | MSAL in-memory cache (sessionStorage fallback). Never localStorage. |
| SSO mechanism | Each application runs an independent MSAL instance against the same Entra ID tenant. If the user has an active Entra ID session cookie, all applications acquire tokens silently. No visible login prompt when navigating between EAF applications. |
| Login flow | Redirect flow (PKCE). Each application handles its own redirect. The `@eaf/auth` `<AuthProvider>` component manages this transparently. |

**SSO behaviour note:** This is not the same as the shell-composition SSO model where a single MSAL instance serves all apps. In the standalone model, the SSO experience relies on the browser's Entra ID session cookie. This is functionally equivalent for users — they do not see repeated login prompts. The difference is implementation: if a user clears cookies, they must log in again in each app they visit. This is acceptable behaviour for an internal enterprise platform.

### 8.2 Authorisation

| Concern | Detail |
|---|---|
| Model | Role-Based Access Control (RBAC). Roles stored as claims in Entra ID app registrations. |
| Role definitions | Platform roles: `Platform.Admin`, `Platform.User`. Application roles: `{AppName}.Reader`, `{AppName}.Admin` etc. |
| Roles stored in | Entra ID application role assignments. Propagated as `roles` claim in access token. |
| Enforcement | API middleware validates token signature, audience, issuer, and role claims on every request. APIM validates presence; claims validation is at the API layer. |
| Per-app flexibility | Applications define their own roles within their app registration. Convention: `{AppName}.{Permission}`. |
| Admin experience | Role assignments managed by IT Admins in Entra ID portal. |

**Token claims example:**
```json
{
  "sub": "user-guid-abc123",
  "name": "Jane Smith",
  "preferred_username": "jane.smith@company.com",
  "roles": ["SampleApp.Reader", "Platform.User"],
  "oid": "entra-object-id",
  "tid": "tenant-guid",
  "aud": "api://eaf-sample-app",
  "exp": 1712000000
}
```

---

## 9. Cross-Cutting Concerns

### 9.1 Observability

#### Logging

| Concern | Detail |
|---|---|
| Framework (.NET) | Serilog 3.x with Application Insights sink |
| Framework (React) | Application Insights JS SDK via `@eaf/api-client` — telemetry initialised automatically when using the package |
| Format | Structured JSON. Human-readable format in local development only. |
| Correlation | `x-correlation-id` header generated client-side in `@eaf/api-client`, propagated through APIM to all downstream services. Logged as `CorrelationId` on every entry. |
| PII policy | Email addresses, names, and user identifiers must not appear in log messages. Use `User[oid-hash]` references. Secrets and tokens are never logged. |
| Log levels | Error (unhandled exceptions), Warning (handled errors, degraded paths), Information (key business events), Debug (local only). |

#### Monitoring and Alerting

| Concern | Detail |
|---|---|
| Platform | Azure Monitor + Application Insights. APIM analytics for API-level metrics. |
| Phase 1 Dashboards | Per-app availability and error rates, APIM request volume and error rates, API P95 latency per endpoint. |
| Alerting rules | 5xx error rate > 1% over 5 minutes; API P95 latency > 2 seconds; APIM availability < 99.5%. |
| On-call | Phase 1: platform team handles all infrastructure alerts. Application-specific alerts routed to respective teams post-onboarding. |

#### Health Checks

- Every application API must expose `GET /health` (liveness) and `GET /health/ready` (readiness).
- Liveness: returns 200 if the process is running.
- Readiness: returns 200 only when database connection and Key Vault access are confirmed.
- Frontend applications expose a static `/health.json` served from their hosting infrastructure for uptime monitoring.

### 9.2 Error Handling

| Layer | Strategy |
|---|---|
| Frontend (per application) | React error boundary at the application root. Renders `<ErrorDisplay>` from `@eaf/ui-components` with a user-friendly message. Error reported to Application Insights. |
| API | Global exception handler middleware returns standardised error envelope. Stack traces stripped in non-Development environments. |
| Gateway (APIM) | Custom error responses for 401, 403, 429 (with `Retry-After`), and 500 (with correlation ID). |
| RTK Query | Errors surfaced via RTK Query's `isError` / `error` state. `@eaf/ui-components` provides standard error display components. No ad-hoc `try/catch` for API calls. |

### 9.3 Resilience

- **API timeouts:** All HTTP clients (`@eaf/api-client`) configured with a 30-second request timeout. APIM enforces a 60-second backend timeout.
- **API retries:** Transient failures (503, 504) retried up to 2 times with exponential backoff. Implemented in `@eaf/api-client` so all applications benefit automatically.
- **Application independence:** Each EAF application is fully independent at runtime. An outage or deployment in one application has zero effect on others. This is a fundamental improvement over the Module Federation model.
- **RTK Query caching:** Configured cache TTLs mean applications can continue displaying stale data gracefully when APIs are temporarily unavailable, with appropriate UI indicators.

---

## 10. Security

### 10.1 Security Requirements

| Requirement | Implementation |
|---|---|
| API authentication | JWT validation at APIM (presence) and API middleware (signature, audience, issuer, claims). |
| Secrets management | Azure Key Vault. Applications access via managed identity. No secrets in environment variables or repository files. |
| Transport security | HTTPS everywhere. TLS 1.2 minimum, TLS 1.3 preferred. HSTS enabled. |
| Credential handling | No hardcoded credentials. Managed identity for service-to-service auth. |
| Access model | Least privilege. Managed identities scoped to minimum required RBAC roles. |
| Dependency scanning | Dependabot on all repositories. OWASP Dependency-Check and `npm audit` in CI. Builds fail on High/Critical findings. |
| OWASP coverage | A01 (Access Control): per-app role enforcement at API. A02 (Crypto): TLS everywhere. A03 (Injection): EF Core parameterised queries. A07 (Auth): MSAL + Entra ID via `@eaf/auth`. A09 (Logging): structured logging, no sensitive data. |
| Data at rest | Azure SQL TDE enabled. Key Vault encrypted at rest. |
| Data in transit | TLS 1.2+ for all communication. |
| Content Security Policy | CSP headers on all application frontends. Simpler to configure than in a Module Federation model — no remote script origins required. |

> **Security note:** The standalone architecture significantly reduces the frontend security attack surface compared to Module Federation. There are no remote script origins to manage in CSP, no shared JavaScript execution context between applications, and no runtime composition vectors. Each application is fully isolated at the browser level.

### 10.2 Threat Model Summary

| Threat | Risk | Mitigation |
|---|---|---|
| Token theft via XSS | High | CSP headers; MSAL in-memory token storage via `@eaf/auth`; Fluent UI safe HTML output; user-generated content sanitised before rendering. |
| Broken access control between applications | High | Each API validates token audience against its own app registration. Applications are fully isolated — there is no shared runtime through which cross-app data leakage could occur. |
| Supply chain attack via `@eaf/*` packages | High | Internal package registry (not public npm). Dependabot on the monorepo. CI security scan on every PR to the packages monorepo. Platform team reviews all changes. |
| Stale package versions in applications | Medium | Dependabot on all application repositories. Minimum supported version policy for `@eaf/*` packages enforced via peer dependency constraints. |
| APIM misconfiguration exposing unauthenticated endpoints | Medium | JWT validation policy required by default. New API products reviewed by platform team. CI/CD runs APIM policy linting. |

---

## 11. Development Environment

### 11.1 Local Setup

| Concern | Detail |
|---|---|
| Container runtime | Docker Compose. `docker-compose up` starts the application, database, and APIM self-hosted gateway. |
| Local auth | MSAL.js against a dedicated development Entra ID tenant. Test accounts with documented role assignments. Real token flow — no auth stubs. |
| Database | SQL Server 2022 container with seed data. Migrations applied automatically on startup. |
| APIM emulator | Azure API Management self-hosted gateway container. Mirrors production APIM policies locally. |
| Mock services | No mocking of external dependencies. Feature flags disable non-critical integrations (e.g. email notifications) locally. |
| Package development | Shared packages are developed in the Turborepo monorepo. Applications can use `npm link` or Turborepo's workspace protocol to develop against local package versions before publishing. |
| Documentation | Getting-started guide in scaffold README. Storybook for component exploration. Test accounts documented in team wiki. |

### 11.2 Developer Experience Requirements

- New applications start from the scaffold template — zero manual configuration of auth, logging, linting, or CI/CD.
- Applications run in isolation without any other EAF service running (except database and APIM gateway).
- Hot module replacement (HMR) works in local development via Vite.
- The full local stack (app + DB + APIM gateway) starts within 2 minutes.
- Storybook is runnable locally from the packages monorepo for component development.
- `@eaf/*` packages are updated in the scaffold template within one week of a new published version.

---

## 12. Testing Strategy

### 12.1 Test Levels

| Level | Scope | Tooling | Owned By |
|---|---|---|---|
| Unit | Component logic, Redux slice reducers, RTK Query endpoint definitions. | Vitest + React Testing Library | Application teams |
| Integration | API ↔ database. Service layer ↔ repositories. | xUnit + TestContainers | Application teams |
| Component | `@eaf/*` package components in isolation with all prop variants and accessibility checks. | Storybook + Storybook Test (Vitest) + axe-core | Platform team |
| End-to-End | Full user journey through the application — login, navigate, CRUD, error states. | Playwright | Platform + App teams |
| Performance | Load and stress testing of APIM and application APIs. | k6 | Platform team |

> **Note:** Contract testing (as specified in v0.1) is no longer required. The removal of Module Federation eliminates the runtime composition contract. Shared package compatibility is enforced through TypeScript peer dependencies and Storybook visual regression.

### 12.2 Key Testing Scenarios for Phase 1

- User authenticates via MSAL and is redirected back to the application without errors
- Silent token acquisition succeeds for a user with an active Entra ID session (SSO scenario)
- RTK Query fetches data correctly and renders in the UI with loading and error states covered
- Application API rejects requests with missing tokens (401) and insufficient role claims (403)
- Reference application CRUD operations complete end-to-end via APIM
- Error boundary renders correctly when the application throws an unhandled error
- All `@eaf/ui-components` components pass axe-core accessibility audit with zero critical violations
- Application bundle size remains under 350 KB gzipped after adding a representative page

---

## 13. CI/CD and Infrastructure

### 13.1 Pipeline Design

**Shared packages monorepo pipeline:**

| Stage | Actions |
|---|---|
| Build | TypeScript compile for all packages. Turborepo incremental builds — only changed packages rebuild. |
| Test | Vitest unit tests. Storybook component tests including axe-core accessibility. |
| Security Scan | `npm audit`. OWASP Dependency-Check. Fail on High/Critical. |
| Publish | Publish changed packages to internal registry with new semantic version. Tag release in git. |

**Application pipeline:**

| Stage | Actions |
|---|---|
| Build | `vite build`. TypeScript type-check. ESLint with `@eaf/eslint-config`. Bundle size check. |
| Test | Vitest unit + integration tests. 80% coverage gate. |
| Security Scan | `npm audit`. SAST scan. Fail on High/Critical. |
| Package | Build Docker image. Tag with git SHA. Push to Azure Container Registry. |
| Deploy (Dev) | Auto-deploy on merge to main. Smoke test post-deploy. |
| Deploy (Stg) | Manual trigger or daily schedule. Full Playwright E2E suite. k6 performance test. |
| Deploy (Prod) | Manual approval. Blue/green deployment. Automated rollback on health check failure. |

### 13.2 Infrastructure as Code

| Concern | Detail |
|---|---|
| Tool | Azure Bicep. Declarative, no manual portal provisioning. |
| Repository | Separate `eaf-infra` repository. Application teams submit PRs to provision their resources. |
| Environment parity | Parameterised Bicep modules with `dev.params.json`, `staging.params.json`, `prod.params.json`. |
| Secrets provisioning | Secrets provisioned to Key Vault via Bicep. Applications read via managed identity at runtime. |

### 13.3 Environments

| Environment | Purpose | Deployment Trigger | Data | APIM Tier |
|---|---|---|---|---|
| Dev | Active development and integration testing. | Auto — merge to main | Synthetic seed data | Developer |
| Staging | Pre-production validation. E2E and performance testing. | Manual or daily schedule | Anonymised copy | Standard v2 |
| Production | Live users. | Manual approval | Real data | Standard v2 |

### 13.4 Deployment Targets and Host Requirements

Because EAF enforces consistency at build time through shared packages rather than at runtime through a composed shell, EAF applications are host-agnostic. By the time an application is deployed it is a standard bundle of HTML, JavaScript, and CSS with no runtime dependency on any other EAF application or on a specific hosting platform.

**Minimum host requirements** for any deployment target:

| Requirement | Detail |
|---|---|
| Serve static files | Must serve `index.html` and associated JS/CSS assets over HTTPS |
| SPA routing | Must return `index.html` for all URL paths (not 404 on deep links) |
| Outbound HTTPS to APIM | Application must be able to reach the APIM gateway URL |
| Outbound HTTPS to Entra ID | Application must be able to reach `login.microsoftonline.com` for auth |
| Configurable CSP headers | Host must allow Content Security Policy headers to be set |
| Redirect URI registration | The deployment URL must be registered as an allowed redirect URI in the Entra ID app registration |

**Supported and tested deployment targets:**

| Target | Notes |
|---|---|
| Azure Container Apps | Default target. Containerised, behind APIM, full CI/CD via pipeline template. |
| Azure Static Web Apps | Preferred for pure SPAs — cheaper, CDN-backed, native SPA routing, built-in GitHub Actions. |
| Azure App Service | Supported. Use nginx or the built-in static file server. |
| On-premises / corporate nginx or IIS | Supported where APIM is reachable from the internal network. Configure nginx for SPA routing (`try_files $uri /index.html`). |
| Microsoft Teams (tab app) | Supported with standard MSAL redirect URI configuration. Teams tabs are iframed web apps — no architectural changes needed. |
| Power Apps Code Apps | Supported with adapter — see Section 13.5. |

### 13.5 Power Apps Code Apps Deployment Target

Power Apps Code Apps are a generally available application type in the Microsoft Power Platform that allows developers to build standalone single-page applications using React, TypeScript, and Vite — the same stack as EAF applications — and deploy them into the Power Platform via the `pac code push` CLI command. They run natively within Power Apps, subject to the platform's governance policies (DLP, Conditional Access, app sharing controls).

**What carries across unchanged:**

- `@eaf/ui-components` — works as-is. Fluent UI v9, the same design system used natively in Power Platform.
- `@eaf/shell-layout` — the layout chrome components work, though `<ShellLayout>` may need to render in a "chromeless" mode (no header/sidebar) if the Power Apps container provides its own navigation. This is a configuration option, not a rebuild.
- Redux Toolkit + RTK Query — works as-is.
- `@eaf/eslint-config` — works as-is.
- The Vite build and TypeScript stack — Code Apps use Vite + React + TypeScript by default, an exact match.

**What requires adaptation:**

| Concern | Standard EAF | Code App Adaptation |
|---|---|---|
| Authentication | `@eaf/auth` wraps MSAL.js, manages OAuth redirect flow | Power Apps SDK handles auth automatically — no MSAL, no token management, no redirect URIs. Use `@eaf/auth-code-app` adapter (see below). |
| API access | `@eaf/api-client` injects Bearer tokens from `@eaf/auth` | Token injection replaced by Power Apps SDK session context. APIM calls still work if the Code App is permitted outbound HTTPS. Alternatively, use Power Platform connectors for Dataverse and other platform-native sources. |
| Deployment | Docker image → Azure Container Registry → Container Apps | `npm run build` → `pac code push` to Dataverse environment. No Docker, no Azure infra. |
| Health checks | `/health` and `/health/ready` endpoints on the backend API | Not applicable to the frontend — health monitoring is provided by the Power Platform. |

**`@eaf/auth-code-app` adapter package:**

To maintain a consistent application-level auth interface (`useAuth()`, `useToken()`) regardless of host, a lightweight adapter package wraps the Power Apps SDK's identity context and exposes the same API surface as `@eaf/auth`.

```typescript
// @eaf/auth-code-app exposes an identical public API to @eaf/auth
// Application code does not change between deployment targets

import { AuthProvider } from '@eaf/auth-code-app'; // swap the import; nothing else changes

export interface AuthConfig {
  // No clientId, tenantId, or scopes needed — Power Apps SDK provides identity
  appName?: string;  // Optional — used for telemetry labelling only
}
```

Internally, `@eaf/auth-code-app` initialises the Power Apps client library, retrieves the current user's identity from the SDK context, and provides a `useToken()` implementation that returns a token suitable for calling APIM (using the Power Apps SDK's connector auth, or a configured custom connector).

**Decision on API access in Code Apps:**

Two patterns are supported. The choice depends on whether the Code App needs to call EAF's APIM gateway or only Power Platform-native data sources.

| Pattern | When to Use |
|---|---|
| Direct APIM calls via `@eaf/api-client` | The Code App is a full EAF application that happens to be deployed in Power Platform. All existing APIs are in APIM. Token is obtained from the Power Apps SDK and injected by `@eaf/api-client`. CORS and network egress must be permitted by the Power Platform environment's DLP policies. |
| Power Platform connectors | The Code App primarily accesses Dataverse or other Power Platform data sources. Uses the Power Apps SDK connector interface rather than `@eaf/api-client`. `@eaf/ui-components` and Redux patterns still apply; only the data access layer differs. |

Both patterns can coexist in a single Code App.

**Code App onboarding checklist additions:**

In addition to the standard onboarding checklist (Section 14.2), Code App deployments must also satisfy:

- [ ] `@eaf/auth-code-app` used in place of `@eaf/auth` — no MSAL configuration present
- [ ] Power Apps SDK initialised before any connector or auth calls
- [ ] DLP policy reviewed — outbound HTTPS to APIM URL explicitly permitted if using direct APIM calls
- [ ] App registered in Dataverse environment and sharing permissions configured
- [ ] `pac code push` deployment tested to Dev environment via CI pipeline

---

## 14. Governance and Onboarding

### 14.1 Platform Team Responsibilities

- Own and maintain all `@eaf/*` packages and the Turborepo monorepo
- Own and maintain the `eaf-app-template` scaffold, keeping it current with latest package versions and conventions
- Own and maintain the deployed Storybook instance
- Own shared infrastructure: APIM, Entra ID app registrations, Key Vault, Application Insights, internal package registry
- Review and approve new application onboarding
- Publish CI/CD pipeline templates for application teams
- Operate the dependency upgrade cadence for shared packages

### 14.2 Application Onboarding Checklist

A new application must satisfy all of the following before integration into the production EAF:

- [ ] Application generated from (or verified against) the current `eaf-app-template` scaffold
- [ ] All `@eaf/*` packages at the current minimum supported version
- [ ] `@eaf/auth` `<AuthProvider>` used for authentication — no custom MSAL implementation
- [ ] `@eaf/shell-layout` `<ShellLayout>` used for application chrome
- [ ] `@eaf/api-client` used as the base for all RTK Query base queries — no undecorated fetch/axios calls
- [ ] All APIs published through APIM with JWT validation policy applied
- [ ] OpenAPI spec published and imported into APIM
- [ ] Structured logging with correlation ID support implemented
- [ ] Health check endpoints (liveness + readiness) implemented and passing
- [ ] Performance budget met: initial bundle < 350 KB gzipped
- [ ] CI/CD pipeline using approved templates
- [ ] Security scan passing — no Critical or High findings
- [ ] Documentation submitted: OpenAPI spec, runbook, data model, roles matrix
- [ ] Architecture review completed and approved by platform team
- [ ] At least one successful staging deployment with E2E tests passing

### 14.3 Enforcement Mechanisms

| Mechanism | What It Enforces |
|---|---|
| `@eaf/eslint-config` | TypeScript strictness, React best practices, accessibility, use of `@eaf/` components, no direct cross-app imports |
| CI pipeline gates | Type-check, lint, test coverage (≥80%), bundle size, security scan, OpenAPI spec validity |
| APIM inbound policies | JWT validation on all requests |
| Package peer dependencies | Minimum supported versions of `@eaf/*` packages declared as peer dependencies — npm warns on incompatible versions |
| Scaffold template | New applications inherit all conventions — divergence is visible and deliberate |
| Architecture review | Human review before production go-live |

---

## 15. Phase 1 Deliverables

| # | Deliverable | Acceptance Criteria |
|---|---|---|
| 1 | `@eaf/ui-components` v1.0 | Published to internal registry. All Phase 1 components implemented, TypeScript-typed, and documented in Storybook. Passes axe-core accessibility audit. |
| 2 | `@eaf/shell-layout` v1.0 | Published. Header, sidebar nav, and footer components implemented. Accepts `navConfig` prop. Storybook stories for all layout variants. |
| 3 | `@eaf/auth` v1.0 | Published. `<AuthProvider>`, `useAuth()`, `useToken()` implemented and working against EAF dev Entra ID tenant. |
| 4 | `@eaf/api-client` v1.0 | Published. Axios-based client factory with auto auth injection, correlation ID, and Application Insights telemetry. RTK Query base query exported. |
| 5 | `@eaf/eslint-config` v1.0 | Published. Enforces EAF coding standards. Used in scaffold and all `@eaf/*` package development. |
| 5a | `@eaf/auth-code-app` v1.0 | Published. Exposes identical API surface to `@eaf/auth`. Wraps Power Apps SDK identity context. Enables Code App deployment without MSAL or Entra ID redirect configuration. |
| 6 | Storybook (deployed) | All Phase 1 components documented with usage examples, prop tables, and accessibility notes. Publicly accessible within the organisation. |
| 7 | `eaf-app-template` scaffold | GitHub template repository. Generates a complete, runnable EAF application. New app running locally in < 1 hour from scaffold. |
| 8 | Reference Application | Fully functional CRUD application using all EAF packages. RTK Query data fetching, Recharts visualisation, chat agent integration, structured logging, error handling. Deployed to Dev. |
| 9 | CI/CD Pipelines | Pipelines for packages monorepo and reference application. Auto-publish/deploy on merge to main. All gates (test, security, bundle size) active. |
| 10 | Infrastructure as Code | All Azure resources provisioned via Bicep. Dev, Staging, Prod environments. Runbook documented. |
| 11 | Docker Dev Environment | `docker-compose up` starts full stack in < 2 minutes. Test accounts documented. |
| 12 | Documentation Pack | This specification. Onboarding guide. Storybook. Scaffold README. At least 3 ADRs. Operational runbook. |

---

## 16. Risks and Mitigations

| # | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| 1 | Shared package quality is poor — inconsistent types, missing stories, undocumented edge cases — degrading AI-generated code quality across all applications | High | High | Platform team treats package documentation as a first-class deliverable. Storybook stories and TypeScript types are required for every component before merge. Dedicated quality review before v1.0 release. |
| 2 | Application teams diverge from the scaffold, accumulating inconsistencies that undermine AI tooling benefits over time | Medium | High | Scaffold is the enforced starting point. ESLint config and pipeline template enforce conventions automatically. Periodic audit of live apps against scaffold conventions. |
| 3 | `@eaf/*` packages become a bottleneck — teams waiting for platform team to add components | Medium | High | Contribution guidelines allow application teams to submit PRs to the packages monorepo. Platform team reviews and merges rather than owning all authorship. Emergency path: teams may implement locally and contribute back within one sprint. |
| 4 | SSO user experience degrades if Entra ID session expires between app navigations | Low | Medium | Entra ID session cookies are long-lived (configurable by tenant admin, default 1-14 days). MSAL handles silent re-auth gracefully. Edge case: incognito/private browsing — document expected behaviour. |
| 5 | Redux Toolkit / RTK Query pattern is unfamiliar to some developers, leading to anti-patterns | Medium | Medium | Scaffold includes opinionated examples. AI tools handle RTK well when given clear examples. Reference application serves as the canonical pattern. Optional platform-team-run onboarding session. |
| 6 | APIM availability causes complete API failure across all applications | Low | Critical | APIM Standard v2 provides built-in redundancy. Client-side retry in `@eaf/api-client`. Incident response runbook. Unlike the MF model, frontend apps continue to load and display cached data during APIM issues. |
| 7 | Security vulnerability in a shared `@eaf/*` package affects all consuming applications simultaneously | Low | High | Dependabot on packages monorepo. CI security scan on every PR. Platform team owns expedited patch release for security fixes. All consuming apps updated via coordinated Dependabot PRs. |
| 8 | Internal npm registry becomes unavailable, blocking builds and deployments | Low | High | Package registry (Azure Artifacts / GitHub Packages) is a managed service with high availability SLA. CI pipelines cache packages. Mirror strategy for critical packages. |

---

## 17. Open Questions

| # | Question | Owner | Target Date | Resolution |
|---|---|---|---|---|
| 1 | Which internal npm registry will host `@eaf/*` packages — Azure Artifacts or GitHub Packages? | DevOps Lead | TBD | |
| 2 | What is the minimum supported version policy for `@eaf/*` packages? How long must applications be able to remain on an older major version? | Platform Team Lead | TBD | |
| 3 | Should the EAF Portal be a distinct deployed application, or should it be a page within each application's nav? | Product Owner | TBD | |
| 4 | Are there applications requiring offline or low-connectivity support? This would affect RTK Query cache configuration and bundle strategy. | Engineering Leadership | TBD | |
| 5 | What is the data residency requirement for Application Insights telemetry? | Security / Legal | TBD | |
| 6 | Should the scaffold use GitHub Actions or Azure DevOps pipelines? Or support both? | DevOps Lead | TBD | |
| 7 | What SLA is required for the APIM gateway in production? Determines tier selection and failover configuration. | Engineering Leadership | TBD | |

---

## 18. Architectural Decision Records

### ADR-001: Standalone applications over Module Federation

- **Status:** Accepted
- **Context:** The EAF requires multiple independently developed LOB applications to share a consistent user experience. Two approaches were evaluated: Webpack Module Federation (runtime composition) and standalone applications consuming shared packages (build-time consistency).
- **Decision:** Standalone applications consuming `@eaf/*` shared packages. No Module Federation. No runtime shell compositor.
- **Alternatives considered:** Module Federation: enables seamless client-side navigation and a single runtime shell, but introduces significant operational complexity — shared dependency version alignment, cryptic runtime errors, complex webpack configuration, and a shell that is a single point of failure for all applications. This complexity is particularly costly in an AI-driven development model, where AI tools are less reliable with Module Federation than with standard package consumption patterns.
- **Consequences:** Navigation between applications is a full page navigation. SSO relies on Entra ID session cookies rather than a shared MSAL instance. Each application is fully operationally independent — no blast radius between applications. Consistency is maintained through shared packages and the scaffold rather than runtime enforcement.

---

### ADR-002: Redux Toolkit + RTK Query as the standard state management solution

- **Status:** Accepted
- **Context:** EAF applications need a consistent, well-understood state management approach that works well with AI-driven development and handles both UI state and server data fetching.
- **Decision:** Redux Toolkit for all application state management. RTK Query for all API data fetching and caching. This is the mandated pattern — applications do not choose their own state management library.
- **Alternatives considered:** Zustand: lighter weight, simpler API, but less opinionated — teams would implement data fetching patterns inconsistently. React Query (TanStack Query): excellent for server state, but introduces a second library alongside a separate UI state solution. RTK Query handles both in one package with excellent AI tool support. Context API alone: insufficient for complex application state at scale. Redux Toolkit consolidates all of these concerns with well-established, well-documented patterns.
- **Consequences:** All EAF applications have an identical, predictable store structure. AI tools generate highly consistent Redux/RTK Query code. Developers familiar with RTK in any EAF application are immediately productive in others. The trade-off is that RTK may feel like overhead for very simple applications — this is accepted in favour of portfolio-level consistency.

---

### ADR-003: Turborepo monorepo for shared packages

- **Status:** Accepted
- **Context:** The EAF requires multiple shared packages (`@eaf/ui-components`, `@eaf/shell-layout`, `@eaf/auth`, `@eaf/api-client`, `@eaf/eslint-config`) that are developed and released together. Co-location simplifies cross-package changes, shared configuration, and atomic versioning.
- **Decision:** All `@eaf/*` packages are co-located in a single Turborepo monorepo. Storybook is also hosted in this monorepo. The monorepo is owned and maintained by the platform team.
- **Alternatives considered:** Separate repositories per package: maximum isolation, but cross-package changes require coordinated PRs and releases. High overhead for a small platform team. Nx: more feature-rich than Turborepo but significantly more complex. Turborepo's minimal configuration and excellent performance are well-suited to this use case.
- **Consequences:** Cross-package changes are atomic and easy to review. Shared build, test, and lint configuration is defined once. Turborepo's incremental build cache means only changed packages rebuild in CI. The platform team must coordinate all changes to shared packages — application teams contribute via PR.

---

### ADR-004: Azure API Management as the sole API integration surface

- **Status:** Accepted
- **Context:** Applications need a governed, observable, and secure way to expose their APIs both to the EAF frontend applications and potentially to other services. Direct API calls from frontends to backends would bypass governance.
- **Decision:** All application APIs published through Azure APIM. Frontends call APIM endpoints only via `@eaf/api-client`. Direct frontend-to-backend calls are prohibited.
- **Alternatives considered:** No gateway: simpler initially but no centralised auth enforcement, no rate limiting, no unified observability. Custom reverse proxy: more operational overhead, less feature-rich. APIM is the natural choice for an Azure-hosted platform.
- **Consequences:** APIM is a critical infrastructure dependency. All API traffic is observable in one place. Enables future capabilities (developer portal, API versioning, monetisation) without architectural changes.

---

### ADR-005: MSAL.js per-application with shared Entra ID tenant for SSO

- **Status:** Accepted
- **Context:** Each standalone EAF application must authenticate users via Entra ID. The SSO experience across applications needs to be seamless — users should not be prompted to log in repeatedly as they navigate between applications.
- **Decision:** Each application runs its own MSAL.js instance (via `@eaf/auth`) configured against the same Entra ID tenant. SSO is achieved via the shared Entra ID browser session cookie — applications acquire tokens silently when a session exists.
- **Alternatives considered:** Shared MSAL instance via shell (Module Federation): provides more seamless auth state sharing but requires runtime composition which has been rejected (ADR-001). Central auth service with token relay: additional infrastructure complexity with no meaningful benefit over the native Entra ID session model.
- **Consequences:** SSO works transparently for users in all standard scenarios. Edge case: private browsing / cookie-cleared sessions require re-authentication per application. This is acceptable for an internal enterprise platform. The `@eaf/auth` package abstracts all MSAL complexity — application developers never interact with MSAL directly.

---

### ADR-006: Host-agnostic deployment model with per-host auth adapters

- **Status:** Accepted
- **Context:** EAF applications may need to be deployed to targets other than Azure Container Apps — including Power Apps Code Apps, Teams tabs, on-premises hosts, and Azure Static Web Apps. Each target has different constraints, particularly around authentication. A single `@eaf/auth` package that hardcodes MSAL is insufficient for all targets.
- **Decision:** The EAF auth abstraction (`useAuth()`, `useToken()`) is defined as a stable interface contract, not tied to a specific implementation. `@eaf/auth` implements it for MSAL/Entra ID. `@eaf/auth-code-app` implements it for the Power Apps SDK. Future adapters may implement it for other hosts. Application code imports `AuthProvider` and uses `useAuth()` / `useToken()` — it never references the underlying auth mechanism directly. Swapping deployment target requires only changing the auth package import, not the application code.
- **Alternatives considered:** A single universal auth package that detects its host at runtime and branches internally: more transparent to application developers, but complex to maintain, harder to tree-shake, and fragile when host detection fails. Requiring application developers to handle auth per-host: breaks the EAF principle that auth is provided by the platform, not re-implemented per application.
- **Consequences:** Adding a new deployment target requires building and publishing a new `@eaf/auth-{target}` adapter package conforming to the interface. Application teams choosing a non-standard deployment target must explicitly select the correct auth package — this is a one-line import change. The auth interface contract (`AuthProvider`, `useAuth`, `useToken`, `AuthConfig`, `AuthUser`) must be treated as stable and versioned independently of its implementations.

---

## 19. Future Considerations (Out of Scope)

| Item | Description | Phase 1 Compatibility |
|---|---|---|
| Runtime UI Composition | If future requirements genuinely demand seamless client-side navigation between applications, Module Federation or an alternative micro-frontend composition layer could be adopted. | Compatible — the standalone architecture does not preclude this. The `@eaf/shell-layout` package and `@eaf/auth` patterns would carry forward. Migration would be a shell-layer addition, not a rebuild of applications. |
| Event-Driven Architecture | Azure Service Bus or Event Grid for asynchronous cross-application messaging. | Compatible. Would be implemented in application backends, calling published APIM APIs. |
| Cross-Application Workflows | Orchestrated business processes spanning multiple application domains. | Compatible. Durable Functions or Logic Apps would call APIM APIs. |
| Multi-Region Deployment | Geo-redundant deployment for BCDR and low-latency access. | Compatible. APIM Premium supports multi-region. Bicep modules would need regional extensions. |
| Fine-Grained Authorisation (ABAC) | Row-level or attribute-based access control. | Compatible. Token claim structure is extensible. Application teams should not hardcode RBAC assumptions. |
| Advanced Analytics / Reporting | Cross-application reporting aggregating data from multiple domains. | Compatible. Would be a standalone EAF application consuming other apps' APIs via APIM. |
| Developer Portal | Self-service API discovery powered by APIM's built-in developer portal. | Compatible. Enableable without architectural changes. |
| TypeScript Client Generation | Auto-generate typed RTK Query clients from OpenAPI specs. | Highly compatible — OpenAPI specs are published to APIM as part of the deployment pipeline. Tools like `orval` or `openapi-typescript` can be added to application pipelines to auto-generate typed API clients. |
| Additional Auth Adapters | As new deployment targets emerge (e.g. SharePoint Framework, Teams Toolkit), new `@eaf/auth-{target}` adapter packages can be built following the pattern established by `@eaf/auth-code-app`. | Explicitly designed for in ADR-006. The auth interface contract is stable; new adapters require no changes to application code or other packages. |

---

## 20. Appendices

### A. Glossary

| Term | Definition |
|---|---|
| EAF | Enterprise Application Framework. The platform described in this document. |
| Standalone Application | A self-contained React application representing a single business domain. Independently developed, built, deployed, and hosted. Shares conventions and packages with other EAF applications but shares no runtime. |
| `@eaf/*` Packages | The shared npm packages published by the platform team. They are the primary mechanism through which EAF standards are distributed and enforced across applications. |
| Scaffold / `eaf-app-template` | The GitHub template repository that generates a new EAF-compliant application. Starting from the scaffold is mandatory for new applications. |
| APIM | Azure API Management. The platform's central API gateway. |
| MSAL | Microsoft Authentication Library. Used internally by `@eaf/auth`. Application developers do not use MSAL directly. |
| Entra ID | Microsoft Entra ID (formerly Azure Active Directory). The organisation's identity provider. |
| RTK Query | Redux Toolkit Query. The data fetching and caching layer built into Redux Toolkit. Used for all API calls in EAF applications. |
| Turborepo | A build system optimiser for JavaScript/TypeScript monorepos. Used to manage the `@eaf/*` packages monorepo. |
| Storybook | A development, testing, and documentation tool for UI components. The deployed EAF Storybook instance is the canonical reference for all shared components. |
| IaC | Infrastructure as Code. All Azure resources defined in Bicep and provisioned declaratively. |
| Managed Identity | An Azure-managed service identity allowing Azure resources to authenticate to other Azure services without credentials. |
| TDE | Transparent Data Encryption. Azure SQL encryption at rest. |
| Power Apps Code App | A generally available Power Platform application type that allows developers to build standalone SPAs using React, TypeScript, and Vite, deployed via the Power Platform CLI (`pac code push`). A supported EAF deployment target via the `@eaf/auth-code-app` adapter. |
| Auth Adapter | An `@eaf/auth-{target}` package that implements the EAF auth interface contract (`AuthProvider`, `useAuth`, `useToken`) for a specific deployment host. Allows application code to remain host-agnostic. `@eaf/auth` is the MSAL/Entra ID adapter; `@eaf/auth-code-app` is the Power Apps SDK adapter. |
| Power Apps SDK | The client library provided by Microsoft for Power Apps Code Apps. Handles authentication, connector access, and platform integration transparently. Wrapped by `@eaf/auth-code-app`. |

### B. Reference Documents

| Document | Location / Link |
|---|---|
| EAF Project Concept (eaf.txt) | Internal repository — `/docs/concept/eaf.txt` |
| Redux Toolkit Documentation | https://redux-toolkit.js.org/ |
| RTK Query Documentation | https://redux-toolkit.js.org/rtk-query/overview |
| MSAL.js Documentation | https://docs.microsoft.com/azure/active-directory/develop/msal-overview |
| Azure APIM Documentation | https://docs.microsoft.com/azure/api-management/ |
| Fluent UI React v9 | https://react.fluentui.dev/ |
| Recharts Documentation | https://recharts.org/ |
| Turborepo Documentation | https://turbo.build/repo/docs |
| Storybook Documentation | https://storybook.js.org/docs |
| Vite Documentation | https://vitejs.dev/ |
| OpenAPI 3.1 Specification | https://spec.openapis.org/oas/v3.1.0 |
| OWASP Top 10 (2021) | https://owasp.org/Top10/ |
| Azure Well-Architected Framework | https://docs.microsoft.com/azure/architecture/framework/ |
| Bicep Language Reference | https://docs.microsoft.com/azure/azure-resource-manager/bicep/ |
| Application Onboarding Guide | Internal — `/docs/onboarding/README.md` *(Phase 1 deliverable)* |
| Power Apps Code Apps Documentation | https://learn.microsoft.com/en-us/power-apps/developer/code-apps/overview |
| Power Apps Code Apps GitHub Templates | https://github.com/microsoft/PowerAppsCodeApps |
| Power Platform CLI Reference | https://learn.microsoft.com/en-us/power-platform/developer/cli/reference/code |

### C. Diagrams Index

- **C1** — C4 Level 1 Context Diagram (Section 4.1)
- **C2** — C4 Level 2 Container Diagram (Section 5.1)
- **C3** — `@eaf/*` packages dependency diagram — which packages each application consumes
- **C4** — APIM API topology — application API routing and policy layer
- **C5** — Authentication flow — MSAL per-app SSO via shared Entra ID session
- **C6** — CI/CD pipeline — packages monorepo and application pipelines
- **C7** — Local development Docker Compose topology
- **C8** — Turborepo monorepo structure — packages, apps, and build graph
- **C9** — Deployment targets diagram — Azure Container Apps, Static Web Apps, Power Apps Code Apps, showing auth adapter selection per target
