# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

The **Enterprise Application Framework (EAF)** is a cloud-native, Azure-hosted platform that unifies independent line-of-business (LOB) applications under a consistent user experience. It is **not** a monolith or micro-frontend shell — each application is a standalone React SPA that shares consistency through build-time packages, not runtime composition. Navigation between apps is standard browser navigation; SSO is provided by shared Entra ID sessions.

This repository contains the design specifications and planning documents. The actual implementation will produce:
- A **Turborepo monorepo** (`eaf-packages/`) for shared `@eaf/*` packages
- A **scaffold template** (`eaf-app-template`) for generating new applications
- A **reference application** demonstrating all EAF patterns
- **Infrastructure-as-code** (Bicep) in a separate `eaf-infra` repository

## Architecture

### Core Principle: Consistency at Build Time, Not Runtime

Applications share packages, not a runtime. An outage in one app has zero effect on others. The `@eaf/*` packages are the governance layer — their TypeScript types and documentation serve as the instruction set for AI-assisted development.

### Shared Packages (`@eaf/*`)

| Package | Purpose |
|---|---|
| `@eaf/ui-components` | React component library on Fluent UI v9. Layout, forms, data display, charts (Recharts), feedback, chat components. |
| `@eaf/shell-layout` | Header, collapsible sidebar, footer. Apps render `<ShellLayout navConfig={...}>` as root chrome. |
| `@eaf/auth` | MSAL.js wrapper. Exports `<AuthProvider>`, `useAuth()`, `useToken()`, and `getToken()` (non-React, safe for RTK Query middleware). Uses a module-scoped MSAL singleton. |
| `@eaf/api-client` | Pre-configured HTTP client. Injects Bearer tokens via `getToken()` import (not hooks), appends `x-correlation-id`, sends telemetry to App Insights. Exports `eafBaseQuery` for RTK Query. |
| `@eaf/eslint-config` | Shared ESLint rules: TypeScript strict, React best practices, jsx-a11y, import restrictions. |
| `@eaf/auth-code-app` | Auth adapter for Power Apps Code Apps deployment — same `useAuth()`/`useToken()` API surface, backed by Power Apps SDK instead of MSAL. |

### Frontend Stack

React 18 (peer deps allow ^19) + TypeScript 5 + Vite 5 + Redux Toolkit 2 + RTK Query + Fluent UI v9 + Recharts 2 + Storybook 8. Monorepo managed by Turborepo.

### Backend Stack

.NET 8 + EF Core 8 + Azure SQL + Serilog + Swashbuckle/OpenAPI 3.1. APIs follow RESTful conventions at `/api/v{n}/{resource}` with paginated response envelopes `{ data: [], meta: { total, page, pageSize } }`.

### State Management Pattern

All apps use Redux Toolkit. RTK Query handles server state — no ad-hoc fetch calls. Auth state lives in `@eaf/auth` React context (not Redux). Navigation state is URL-driven via React Router v6.

### Auth Pattern

Each app runs its own MSAL instance against the same Entra ID tenant. `@eaf/auth` handles init, silent token acquisition, redirect login, refresh, and logout. `eafBaseQuery` in `@eaf/api-client` calls `getToken()` (a plain function from the module-scoped MSAL singleton) — never `useToken()`, since RTK Query middleware runs outside the React tree.

### Infrastructure

- **Gateway**: Azure APIM (JWT validation, rate limiting, CORS, logging). Local dev uses Caddy reverse proxy by default; APIM self-hosted gateway is opt-in via Docker Compose profile.
- **CI/CD**: Azure DevOps Pipelines. GitHub for Git hosting (enables Copilot Agents).
- **Registry**: Azure Artifacts for `@eaf/*` npm packages.
- **IaC**: Azure Bicep, parameterised per environment (dev/staging/prod).
- **Secrets**: Azure Key Vault via managed identity. No secrets in env vars or repo files.

### Local Development

`docker-compose up` starts the app, SQL Server 2022 (with seed data via `db-init` service using `sqlcmd`), and Caddy gateway. MSAL authenticates against a dev Entra ID tenant with real tokens — no auth stubs.

### Testing

| Level | Tools |
|---|---|
| Unit | Vitest + React Testing Library (80% coverage gate) |
| Component | Storybook + Storybook Test (Vitest) + axe-core |
| Integration (.NET) | xUnit + TestContainers |
| E2E | Playwright |
| Performance | k6 |

### Performance Budget

- JS bundle: < 350 KB gzipped (measured with `gzip -c`, not uncompressed `du`)
- TTI: < 2.5s on 4G
- LCP: < 2.5s, CLS: < 0.1
- API P95: < 500ms at APIM boundary

## Key Design Decisions

- **Standalone apps over Module Federation** (ADR-001): Simpler security, operational independence, better AI tooling support. Trade-off: full-page navigation between apps.
- **MSAL module-scoped singleton**: Solves the problem of `eafBaseQuery` needing tokens outside React context. `initialiseMsal()` called once by `<AuthProvider>`; `getToken()` is a plain import.
- **Caddy as local gateway**: The APIM self-hosted gateway requires a live Azure APIM instance. Caddy reverse proxy is the default for `docker-compose up` without Azure access.
- **Azure DevOps for CI/CD, GitHub for Git**: Enables both Azure Artifacts integration and GitHub Copilot Agents.
- **Auth adapter pattern** (ADR-006): `@eaf/auth-code-app` provides the same interface as `@eaf/auth` for Power Apps Code Apps targets.

## Documentation Reference

- `docs/EAF-Technical-Design-Specification-v3.md` — Full technical spec (sections on frontend, backend, auth, security, testing, CI/CD, infrastructure)
- `docs/EAF-Architecture-Review.md` — Architecture review with critical findings and recommendations
- `docs/EAF-Critical-Findings-Implementation-Plan.md` — Resolutions for the three critical review findings
- `docs/EAF-Phase-1-Implementation-Plan.md` — Sprint-by-sprint implementation schedule across 4 workstreams
- `docs/EAF-GitHub-Issues-v2.md` — All 24+ GitHub issues with acceptance criteria
