# EAF Phase 1 Implementation Plan

| Field | Value |
|---|---|
| **Version** | 1.0 |
| **Status** | Final Draft |
| **Author** | Platform Architecture / Project Management |
| **Date** | 2026-03-28 |
| **Inputs** | EAF Technical Design Specification v0.3, GitHub Issues v2, Architecture Review, Critical Findings Resolution |
| **Phase** | Phase 1 — Foundation |
| **Duration** | 10 sprints (20 weeks) |
| **Sprint cadence** | 2-week sprints |

---

## 1. Executive Summary

This plan translates the EAF Technical Design Specification, 24 GitHub issues, architecture review findings, and critical finding resolutions into an executable implementation schedule. Phase 1 delivers the shared package foundation, application scaffold, reference application, CI/CD pipelines, and infrastructure-as-code that enable AI-driven enterprise application development across the organisation.

The work is organised into four parallel workstreams executing across ten two-week sprints. Three critical architectural issues identified in the architecture review have been resolved and their fixes are incorporated into the issue specifications before implementation begins. A two-week pre-implementation sprint (Sprint 0) covers these prerequisite changes, Azure DevOps environment setup, and team onboarding.

The critical path runs through the package foundation: monorepo initialisation → ESLint config → auth + API client → UI components → shell layout → scaffold → reference application. Infrastructure and CI/CD work runs in parallel and converges at Sprint 7 when the reference application is deployed to the dev environment.

---

## 2. Pre-Implementation Prerequisites

Before any implementation sprint begins, the following must be complete. These are assigned to Sprint 0 (weeks 1–2) and owned by the technical lead and DevOps lead jointly.

### 2.1 Resolve Critical Architecture Review Findings

The architecture review identified three critical issues. Decisions have been made and documented in the Critical Findings Implementation Plan. The spec and issue updates below must be applied before issues are assigned.

**Finding 1 — `eafBaseQuery` violates Rules of Hooks.** Decision: MSAL module-scoped singleton in `@eaf/auth`, non-React `getToken()` export. Issues #3, #4, #13, and #24 require modification. The `eafBaseQuery` function now uses a plain `getToken` import instead of the `useToken()` hook, making it safe to call from Redux middleware outside the React tree.

**Finding 2 — APIM self-hosted gateway requires live Azure.** Decision: Caddy reverse proxy as default local gateway; APIM self-hosted gateway as opt-in Docker Compose profile. Issue #19 requires modification. The `db-init` service pattern replaces the invalid `/docker-entrypoint-initdb.d/` mount for SQL Server seed scripts.

**Finding 3 — Unresolved CI/CD and registry decisions block Issues #20–21.** Decision: Azure DevOps Pipelines for CI/CD; Azure Artifacts for npm registry; GitHub for Git hosting only (enabling Copilot Agents). Issues #20 and #21 require full rewrite from GitHub Actions to Azure DevOps YAML. Issue #22 pipeline section updated. Open Questions #1 and #6 in the spec are closed.

### 2.2 Spec and Issue Updates (Sprint 0 Deliverable)

All updates are catalogued in the Critical Findings Implementation Plan. The complete list of affected documents:

| Issue / Doc | Change Type | Summary |
|---|---|---|
| Issue #3 (`@eaf/auth`) | Modify | Add `msalInstance.ts`, `getToken.ts`, `getToken` export. Update `AuthProvider` to use `initialiseMsal()`. |
| Issue #4 (`@eaf/api-client`) | Modify | Replace `useToken()` with `getToken` import. Remove hooks-in-component constraint. |
| Issue #13 (scaffold) | Modify | Replace `.github/workflows/ci.yml` with `azure-pipelines.yml`. Add `.npmrc`. Make APIM env vars optional. |
| Issue #19 (Docker) | Modify | Caddy gateway as default. APIM as opt-in profile. Fix SQL Server seed via `db-init` service with `sqlcmd`. |
| Issue #20 (CI/CD packages) | Full rewrite | GitHub Actions → Azure DevOps YAML. |
| Issue #21 (CI/CD app) | Full rewrite | GitHub Actions → Azure DevOps YAML. Fix bundle size check to measure gzipped size. |
| Issue #22 (Bicep IaC) | Modify | Pipeline section: GitHub Actions → Azure DevOps YAML. |
| Issue #24 (`@eaf/auth-code-app`) | Modify | Add `getToken` export matching `@eaf/auth` contract. |
| Spec Section 6.2 | Update | Add `getToken` to `@eaf/auth` exports list. |
| Spec Section 6.4 | Update | Remove note about `eafBaseQuery` needing component context. |
| Spec Section 11.1 | Update | Caddy proxy as default; APIM self-hosted as opt-in. |
| Spec Section 13.1 | Update | All pipelines run on Azure DevOps Pipelines. |
| Spec Open Questions | Close | #1 → Azure Artifacts. #6 → Azure DevOps Pipelines. |

### 2.3 Azure DevOps Environment Setup (Sprint 0 Deliverable)

The DevOps lead must provision the following before Sprint 1 begins:

- [ ] Azure DevOps project created with GitHub service connection (Azure Pipelines GitHub App)
- [ ] Azure Artifacts npm feed created; feed URL documented; `.npmrc` template prepared
- [ ] Service connections configured: Azure subscriptions, Azure Container Registry
- [ ] Environments created: `dev`, `staging`, `production` with appropriate approval gates
- [ ] Pipeline variable groups created with placeholder values for `ACR_SERVICE_CONNECTION`, `AZURE_SERVICE_CONNECTION`, `APIM_GATEWAY_TOKEN`, etc.
- [ ] Dev Entra ID tenant configured with test app registrations and test user accounts
- [ ] Test accounts documented in team wiki with role assignments

### 2.4 Additional Review Items to Address During Implementation

The architecture review identified 14 non-critical findings. The following are incorporated into the implementation schedule rather than blocking Sprint 1:

| # | Finding | Resolution | When |
|---|---|---|---|
| 4 | React 18 pinning | Update peer deps to `"^18.0.0 \|\| ^19.0.0"` | Sprint 1 (Issue #1) |
| 5 | MSAL v2 pinning | Document rationale in ADR; track v3 evaluation as tech debt | Sprint 2 (Issue #3) |
| 6 | `@microsoft/powerapps-client` SDK verification | Spike before Issue #24 is sized | Sprint 4 (before #24 starts) |
| 7 | Bundle size check measures wrong thing | Fixed in Azure DevOps pipeline rewrite (gzipped measurement) | Sprint 0 (Issue #21 rewrite) |
| 8 | No versioning strategy | Define policy; packages ship `1.0.0` at Phase 1 completion | Sprint 1 (governance doc) |
| 9 | No EAF Portal issue | Defer; remove from diagrams until Open Question #3 resolved | Sprint 0 (spec update) |
| 10 | No backend API issues | Add new issues for reference app backend | Sprint 0 (new issues) |
| 11 | `components.json` AST parsing tooling | Specify `ts-morph` in Issue #12 | Sprint 0 (issue update) |
| 12 | `generate-manifest` timestamp race condition | Exclude `"generated"` field from CI diff | Sprint 0 (Issue #12 update) |
| 13 | ESLint `import/no-restricted-paths` | Document limitation; replace with per-app config guidance | Sprint 1 (Issue #2) |
| 14 | `SplitPane` missing from issues | Defer to Phase 1.1 or add issue if time permits | Backlog |
| 15 | Navigation components missing | Defer to Phase 1.1 or add issue if time permits | Backlog |
| 16 | Docker SQL Server seed path | Fixed in Caddy gateway redesign (db-init service) | Sprint 0 (Issue #19 update) |
| 17 | Axios vs native fetch | Document choice in ADR; not a blocking change | Sprint 2 (Issue #4 ADR note) |

### 2.5 New Issues Required

The architecture review identified a structural gap: no issues exist for the reference application backend API. The following issues must be created during Sprint 0 and scheduled into the infrastructure workstream:

| New Issue | Summary | Dependencies | Sprint |
|---|---|---|---|
| #25 | Reference app backend — .NET 8 API project setup, health endpoints, OpenAPI/Swagger | #22 (infra provisioned) | Sprint 4 |
| #26 | Reference app backend — domain model, EF Core migrations, Azure SQL schema | #25 | Sprint 5 |
| #27 | Reference app backend — CRUD endpoints for orders, analytics, chat | #26 | Sprint 5–6 |
| #28 | Reference app backend — OpenAPI spec generation, APIM import | #27, #23 | Sprint 6 |

---

## 3. Team Structure and Roles

### 3.1 Workstream Ownership

| Workstream | Owner | Team Size | Focus |
|---|---|---|---|
| **Packages** | Platform Engineer A | 2 developers | `@eaf/*` shared packages, Storybook, `components.json` |
| **Scaffold & Reference App** | Platform Engineer B | 2 developers | App template, reference app frontend, Docker environment |
| **Infrastructure & Backend** | DevOps Lead + Backend Engineer | 2 people | Bicep IaC, APIM, .NET API, Azure DevOps pipelines |
| **Quality & Integration** | Technical Lead | 1 person (part-time across all streams) | Architecture decisions, code review, cross-stream integration, risk management |

Total team: 6–7 people (including the technical lead who spans all workstreams).

### 3.2 RACI for Key Decisions

| Decision | Responsible | Accountable | Consulted | Informed |
|---|---|---|---|---|
| Package API surface changes | Packages team | Technical Lead | All developers | Product Owner |
| Infrastructure provisioning | DevOps Lead | Technical Lead | Security | Engineering Leadership |
| Scaffold conventions | Scaffold team | Technical Lead | Packages team | Application teams |
| Version bumps / breaking changes | Packages team | Technical Lead | All consumers | Product Owner |
| Production deployment approval | DevOps Lead | Engineering Leadership | Technical Lead | All |

---

## 4. Workstream Breakdown and Sprint Schedule

### 4.1 Visual Timeline

```
Sprint:     S0    S1    S2    S3    S4    S5    S6    S7    S8    S9

PACKAGES    ─── ┬─#1──┬─#3──┬─#5──┬─#6,7,8,9─┬──#10─┬─#11─┬─#12─┬─────┬─────┐
                │     │ #2  │ #4  │           │      │     │ #24 │     │v1.0 │
                │     │     │     │           │      │     │     │     │     │

SCAFFOLD    ─── ┼─────┼─────┼─────┼──────────┼──#13─┼─────┼─#19─┼─────┼─────┤
& REF APP       │     │     │     │          │      │ #14 │#15  │#16  │#17  │
                │     │     │     │          │      │     │#18  │     │     │

INFRA &     ─── ┼─ADO─┼─#22─┼─#22─┼──#23────┼──#25─┼─#26─┼─#27─┼─#28─┼─────┤
BACKEND         │setup│     │     │          │      │     │     │     │     │

CI/CD       ─── ┼─────┼─────┼─────┼──────────┼──────┼──#20┼─#21─┼─────┼─────┤
                │     │     │     │          │      │     │     │     │     │

MILESTONES  ────M0────────────M1──────────────M2────────────M3───────────M4──
```

### 4.2 Sprint-by-Sprint Plan

---

#### Sprint 0 — Pre-Implementation (Weeks 1–2)

**Goal:** Resolve all blockers. Every team member can start coding on Sprint 1 Day 1.

| Task | Owner | Deliverable |
|---|---|---|
| Apply spec updates from Critical Findings Plan | Technical Lead | Updated spec v0.4 |
| Rewrite Issues #20, #21 for Azure DevOps | DevOps Lead | Updated issue specs |
| Update Issues #3, #4, #13, #19, #22, #24 | Technical Lead | Updated issue specs |
| Create new backend Issues #25–28 | Technical Lead | New issues in backlog |
| Update Issue #12 (ts-morph, timestamp fix) | Technical Lead | Updated issue spec |
| Provision Azure DevOps environment | DevOps Lead | Working ADO project with feeds, connections, environments |
| Configure dev Entra ID tenant | DevOps Lead | Test app registrations, test users documented |
| Define versioning policy document | Technical Lead | Versioning policy (packages ship 1.0.0 at Phase 1 end) |
| Team onboarding: EAF architecture walkthrough | Technical Lead | All developers understand the design |
| Spike: verify `@microsoft/powerapps-client` SDK | Platform Engineer A | Confirmed package name, API surface, viability |

**Milestone M0: Implementation-ready.** All issues are updated, Azure DevOps is provisioned, and the team is onboarded.

---

#### Sprint 1 — Monorepo Foundation (Weeks 3–4)

| Issue | Workstream | Summary |
|---|---|---|
| **#1** | Packages | Initialise Turborepo monorepo with all package stubs, `tsconfig.base.json`, `turbo.json` |
| **#2** | Packages | Implement `@eaf/eslint-config` with TypeScript, React, a11y, and import rules |
| **#22** (start) | Infrastructure | Begin Bicep IaC — container registry, App Insights, Key Vault, SQL modules |

**Notes:**
- Issue #1 peer dependencies updated to `"^18.0.0 || ^19.0.0"` per review finding #4.
- Issue #2 includes documentation of the `import/no-restricted-paths` limitation per review finding #13.
- Issue #22 is a large issue; it spans Sprints 1–2.

**Sprint 1 Definition of Done:**
- `npm install` and `npx turbo build` succeed in the monorepo
- ESLint config catches intentional violations in test files
- Bicep modules compile for container registry and App Insights

---

#### Sprint 2 — Auth and API Client (Weeks 5–6)

| Issue | Workstream | Summary |
|---|---|---|
| **#3** | Packages | Implement `@eaf/auth` — MSAL wrapper with `AuthProvider`, `useAuth`, `useToken`, module-scoped singleton, `getToken` |
| **#4** | Packages | Implement `@eaf/api-client` — Axios client factory, `eafBaseQuery` using `getToken` |
| **#22** (complete) | Infrastructure | Complete Bicep IaC — SQL server/database, container app module, environment params |

**Notes:**
- Issue #3 implements the Critical Finding #1 fix: `msalInstance.ts` singleton, `getToken.ts` non-React export, `AuthProvider` calling `initialiseMsal()`.
- Issue #4 implements the corrected `eafBaseQuery` using `getToken` import (not `useToken` hook).
- MSAL v2 pinning rationale documented in package README and tracked as tech debt per review finding #5.
- Axios choice documented in ADR note per review finding #17.

**Sprint 2 Definition of Done:**
- `@eaf/auth` unit tests pass with mocked MSAL (≥80% coverage)
- `@eaf/api-client` unit tests confirm token injection, correlation ID, retry logic
- `getToken()` works outside React context (verified in unit test)
- `az bicep build main.bicep` compiles without errors for all environments

---

#### Sprint 3 — UI Components Foundation (Weeks 7–8)

| Issue | Workstream | Summary |
|---|---|---|
| **#5** | Packages | Implement `@eaf/ui-components` — layout and feedback primitives (9 components) |
| **#23** | Infrastructure | APIM configuration as code — Bicep module, global JWT policy, rate limiting, diagnostics |

**Notes:**
- Issue #5 delivers `PageContainer`, `SectionCard`, `ContentGrid`, `PageHeader`, `LoadingSkeleton`, `ErrorDisplay`, `ToastNotification`, `EmptyState`, `ConfirmDialog`.
- These layout/feedback components are prerequisites for Issues #6, #7, #8, #9, and #10.

**Sprint 3 Definition of Done:**
- All 9 layout/feedback components compile, render, and have JSDoc on every prop
- `ConfirmDialog` and `useToast()` pass unit tests
- APIM Bicep module compiles; JWT validation and rate limiting policies present

---

#### Sprint 4 — UI Components Expansion (Weeks 9–10)

Issues #6, #7, #8, and #9 can all run in parallel since they depend only on #5 (completed in Sprint 3).

| Issue | Workstream | Summary |
|---|---|---|
| **#6** | Packages (Dev 1) | `@eaf/ui-components` — form controls (6 components) |
| **#7** | Packages (Dev 1) | `@eaf/ui-components` — data display (4 components) |
| **#8** | Packages (Dev 2) | `@eaf/ui-components` — chart wrappers (3 components) |
| **#9** | Packages (Dev 2) | `@eaf/ui-components` — chat components (3 components) |
| **#25** | Infrastructure | Reference app backend — .NET 8 API project setup, health endpoints |

**Notes:**
- Two developers split the four UI issues: Dev 1 takes #6 + #7 (forms and data display share patterns), Dev 2 takes #8 + #9 (charts and chat are self-contained).
- All form components use `React.forwardRef` for React Hook Form compatibility.
- `DataTable<T>` is the most complex component — generic typing, pagination, sorting, loading skeleton, empty state.
- Backend Issue #25 begins in parallel on the infrastructure workstream.

**Sprint 4 Definition of Done:**
- All 16 new components compile and export from `src/index.ts`
- `DataTable` renders pagination, loading, and empty states (unit tests)
- All form components forward `ref` correctly
- .NET 8 API project runs locally with health endpoints returning 200

---

#### Sprint 5 — Shell Layout and Backend Domain (Weeks 11–12)

| Issue | Workstream | Summary |
|---|---|---|
| **#10** | Packages | Implement `@eaf/shell-layout` — header, collapsible sidebar, footer |
| **#26** | Infrastructure | Reference app backend — domain model, EF Core migrations, Azure SQL schema |

**Notes:**
- Issue #10 depends on #5, #6, #7 (uses layout primitives, LoadingSkeleton for inter-app navigation).
- Shell layout sidebar collapse state persists in localStorage.
- Active nav item determined by pathname prefix match.
- Backend domain model matches the `Order` type from Issue #15 and the analytics endpoints from Issue #16.

**Sprint 5 Definition of Done:**
- `ShellLayout` renders children with header, sidebar, and footer
- Sidebar collapses and persists state (unit tests)
- External nav items render as `<a>` with `target="_blank"`
- EF Core migrations run; Orders table seeded with test data

---

#### Sprint 6 — Storybook, Scaffold, and Pipelines (Weeks 13–14)

This is the convergence sprint where the packages workstream delivers the component catalogue, the scaffold is assembled, and CI/CD pipelines are created.

| Issue | Workstream | Summary |
|---|---|---|
| **#11** | Packages | Storybook setup with stories for all components, axe-core accessibility |
| **#12** | Packages | `components.json` manifest generation script using `ts-morph` |
| **#13** | Scaffold | Create `eaf-app-template` scaffold — Vite + React + Redux + all `@eaf/*` packages wired |
| **#20** | CI/CD | Azure DevOps pipeline for packages monorepo |
| **#27** | Infrastructure | Reference app backend — CRUD endpoints for orders, analytics, chat |

**Notes:**
- Issue #12 uses `ts-morph` for TypeScript AST parsing (per review finding #11). The CI freshness check excludes the `"generated"` timestamp from the diff (per review finding #12).
- Issue #13 scaffold includes `azure-pipelines.yml` (not GitHub Actions), `.npmrc` for Azure Artifacts, and `CLAUDE.md` + `copilot-instructions.md`.
- Issue #20 pipeline uses Azure DevOps YAML syntax with `npmAuthenticate@0` for Azure Artifacts.

**Milestone M2: Packages complete and publishable.** All `@eaf/*` packages are built, tested, documented in Storybook, and have a working CI pipeline. The scaffold template is ready.

**Sprint 6 Definition of Done:**
- Storybook starts and displays all components with zero critical axe-core violations
- `components.json` contains entries for every exported component
- `eaf-app-template` generates a project where `npm install`, `npm run dev`, `npm run build`, and `npm run lint` all pass
- Packages pipeline validates, builds, and publishes on merge to main
- Backend CRUD endpoints return correct responses against seeded data

---

#### Sprint 7 — Reference App Setup and Docker (Weeks 15–16)

| Issue | Workstream | Summary |
|---|---|---|
| **#14** | Reference App | Reference app project setup — generated from scaffold, routes configured, auth working |
| **#19** | Reference App | Docker Compose dev environment — Caddy gateway, SQL Server with db-init, APIM opt-in profile |
| **#21** | CI/CD | Azure DevOps pipeline for application template |
| **#24** | Packages | `@eaf/auth-code-app` Power Apps Code Apps auth adapter |
| **#28** | Infrastructure | Reference app backend — OpenAPI spec generation, APIM import |

**Notes:**
- Issue #19 implements the Critical Finding #2 fix: Caddy as default gateway, APIM self-hosted as opt-in `--profile apim`, `db-init` service for SQL Server seeding.
- Issue #24 depends on the Power Apps SDK spike from Sprint 0 and the `getToken` pattern from Critical Finding #1.
- Issue #21 uses gzipped bundle size measurement per review finding #7.
- The reference app authenticates against the dev Entra ID tenant — this is the first end-to-end integration test.

**Milestone M3: Reference app running end-to-end.** A developer can clone the reference app, run `docker compose up` and `npm run dev`, authenticate, and see the shell with sidebar navigation.

**Sprint 7 Definition of Done:**
- Reference app authenticates via Entra ID and renders shell layout
- `docker compose up` starts Caddy + SQL Server without Azure credentials
- Application pipeline validates, builds Docker image, and deploys to dev
- `@eaf/auth-code-app` passes all unit tests; `getToken` export matches `@eaf/auth` signature
- OpenAPI spec imported into APIM; reference app API product defined

---

#### Sprint 8 — Reference App Features Part 1 (Weeks 17–18)

| Issue | Workstream | Summary |
|---|---|---|
| **#15** | Reference App (Dev 1) | Orders CRUD — list with DataTable, detail with DefinitionList, form with React Hook Form + Zod |
| **#18** | Reference App (Dev 2) | Logging, error boundaries, health check — App Insights init, AppErrorBoundary, structured logger |

**Notes:**
- Issues #15, #16, #17, and #18 all depend on #14 and can run in any order. They are split across Sprints 8–9 to manage scope.
- Issue #15 is the largest reference app feature — CRUD with pagination, filtering, debounced search, delete confirmation dialog.
- Issue #18 sets up observability infrastructure that benefits all subsequent features.

**Sprint 8 Definition of Done:**
- Orders list renders with pagination and loading states
- Create/edit form validates with Zod; submissions call RTK Query mutations
- Delete triggers ConfirmDialog
- AppErrorBoundary catches errors and reports to Application Insights
- Health check page shows API connectivity and auth status

---

#### Sprint 9 — Reference App Features Part 2 (Weeks 19–20)

| Issue | Workstream | Summary |
|---|---|---|
| **#16** | Reference App (Dev 1) | Analytics dashboard — MetricCards, LineChart, BarChart, PieChart with date range filter |
| **#17** | Reference App (Dev 2) | Chat agent integration — ChatPanel, Redux slice, agent action cards |

**Sprint 9 Definition of Done:**
- Dashboard renders 4 metric cards, 3 charts, with loading and error states
- Date range filter updates all chart data
- Chat sends messages and displays assistant responses
- Agent action cards execute API calls with loading/complete states

---

#### Sprint 10 — Integration, Hardening, and Release (Weeks 21–22)

This sprint has no new issues. It is dedicated to integration testing, bug fixes, documentation completion, and the v1.0 release.

| Activity | Owner | Deliverable |
|---|---|---|
| End-to-end Playwright tests across reference app | Scaffold team | Passing E2E test suite |
| Performance testing: bundle size audit, Lighthouse CI, k6 API load test | DevOps Lead | Performance report; all budgets met |
| Security audit: `npm audit`, dependency check, OWASP review | DevOps Lead | Clean security scan |
| Storybook deployment to organisational URL | Packages team | Live Storybook instance |
| Documentation pack completion | Technical Lead | Onboarding guide, operational runbook, ADRs complete |
| Bump all `@eaf/*` packages to v1.0.0 | Packages team | Published v1.0.0 packages |
| Scaffold updated to reference v1.0.0 packages | Scaffold team | Updated `eaf-app-template` |
| Reference app deployed to staging | DevOps Lead | Staging deployment with E2E tests passing |
| Architecture review sign-off | Technical Lead | Formal sign-off document |

**Milestone M4: Phase 1 complete.** All deliverables from Section 15 of the spec are met. The platform is ready for application team onboarding.

---

## 5. Critical Path

The critical path determines the minimum time to completion. Any delay on these items delays the entire project.

```
#1 Monorepo setup (S1)
 └── #2 ESLint config (S1)
      └── #3 @eaf/auth (S2)
           └── #4 @eaf/api-client (S2)
                └── #5 UI components — layout/feedback (S3)
                     └── #10 Shell layout (S5)
                          └── #13 Scaffold (S6)
                               └── #14 Reference app setup (S7)
                                    └── #15 Reference app CRUD (S8)
```

The critical path spans 8 sprints of implementation work (Sprints 1–8), plus Sprint 0 for prerequisites and Sprint 9–10 for remaining features and hardening. Total: 10 sprints (20 weeks).

**Key risk on the critical path:** Issues #3 and #4 (auth and API client) are architecturally complex and include the Critical Finding #1 fix. If these slip, everything downstream shifts. Mitigation: assign the strongest developer, have the technical lead available for daily review during Sprint 2.

---

## 6. Dependency Map with Sprint Assignments

| Issue | Title | Depends On | Sprint | Workstream |
|---|---|---|---|---|
| — | Spec + issue updates, ADO setup, SDK spike | — | S0 | All |
| #1 | Monorepo initialisation | — | S1 | Packages |
| #2 | `@eaf/eslint-config` | #1 | S1 | Packages |
| #22 | Bicep IaC — core infrastructure | — | S1–2 | Infrastructure |
| #3 | `@eaf/auth` (with singleton + `getToken`) | #1, #2 | S2 | Packages |
| #4 | `@eaf/api-client` (with corrected `eafBaseQuery`) | #1, #2, #3 | S2 | Packages |
| #5 | UI components — layout/feedback | #1, #2 | S3 | Packages |
| #23 | APIM configuration as code | #22 | S3 | Infrastructure |
| #6 | UI components — forms | #5 | S4 | Packages |
| #7 | UI components — data display | #5 | S4 | Packages |
| #8 | UI components — charts | #5 | S4 | Packages |
| #9 | UI components — chat | #5 | S4 | Packages |
| #25 | Backend — API project setup | #22 | S4 | Infrastructure |
| #10 | `@eaf/shell-layout` | #5, #6, #7 | S5 | Packages |
| #26 | Backend — domain model + migrations | #25 | S5 | Infrastructure |
| #11 | Storybook | #5–10 | S6 | Packages |
| #12 | `components.json` manifest | #11 | S6 | Packages |
| #13 | `eaf-app-template` scaffold | #3, #4, #10, #12 | S6 | Scaffold |
| #20 | CI/CD — packages pipeline | #11, #12 | S6 | CI/CD |
| #27 | Backend — CRUD endpoints | #26 | S6 | Infrastructure |
| #14 | Reference app — setup | #13 | S7 | Reference App |
| #19 | Docker dev environment | #13 | S7 | Reference App |
| #21 | CI/CD — application pipeline | #13 | S7 | CI/CD |
| #24 | `@eaf/auth-code-app` | #3 | S7 | Packages |
| #28 | Backend — OpenAPI spec + APIM import | #27, #23 | S7 | Infrastructure |
| #15 | Reference app — CRUD | #14 | S8 | Reference App |
| #18 | Reference app — logging/errors | #14 | S8 | Reference App |
| #16 | Reference app — dashboard | #14 | S9 | Reference App |
| #17 | Reference app — chat agent | #14 | S9 | Reference App |

---

## 7. Milestones and Go/No-Go Gates

| Milestone | Sprint | Criteria | Decision |
|---|---|---|---|
| **M0: Implementation-ready** | End of S0 | All issues updated. Azure DevOps provisioned. Team onboarded. SDK spike complete. | Go/No-Go: Technical Lead approves issue readiness. |
| **M1: Packages foundation** | End of S2 | `@eaf/auth` and `@eaf/api-client` pass unit tests. `getToken` works outside React. Bicep IaC compiles. | Progress check. No gate. |
| **M2: Packages complete** | End of S6 | All `@eaf/*` packages built. Storybook runs. CI pipeline publishes. Scaffold generates a working app. | Go/No-Go: Technical Lead signs off on package API surfaces. This is the last opportunity to make breaking API changes cheaply. |
| **M3: End-to-end integration** | End of S7 | Reference app authenticates, renders shell, connects to API via local Docker. Pipeline deploys to dev. | Go/No-Go: DevOps Lead confirms deployment pipeline is functional. |
| **M4: Phase 1 complete** | End of S10 | All deliverables from spec Section 15 met. v1.0.0 packages published. Reference app deployed to staging. Documentation pack complete. | Go/No-Go: Engineering Leadership approves for application team onboarding. |

---

## 8. Risk Register

| # | Risk | Likelihood | Impact | Mitigation | Owner |
|---|---|---|---|---|---|
| 1 | Auth + API client (Sprint 2) slips due to MSAL singleton complexity | Medium | High (delays entire critical path) | Assign strongest developer. Technical Lead provides daily review. Timebox MSAL investigation to 3 days; escalate if blocked. | Technical Lead |
| 2 | Power Apps SDK (`@microsoft/powerapps-client`) API doesn't match Issue #24 spec | Medium | Medium (rework required) | Sprint 0 spike validates SDK. If API differs significantly, Issue #24 is reshaped before Sprint 7. | Platform Engineer A |
| 3 | Azure DevOps pipeline setup takes longer than Sprint 0 allows | Low | High (blocks CI/CD and deployment) | DevOps Lead starts provisioning immediately. Pipeline YAML is pre-written in Critical Findings doc. Manual package publishing is the fallback. | DevOps Lead |
| 4 | Storybook axe-core audit surfaces many accessibility violations | Medium | Medium (Sprint 6 scope increase) | Build components with accessibility from Sprint 3 onward. Run axe-core locally during development, not just at Storybook time. | Packages team |
| 5 | Reference app backend (.NET) is underspecified (new Issues #25–28) | Medium | Medium (frontend blocked on API) | Backend issues created in Sprint 0 with full specs. MSW (Mock Service Worker) provides frontend mock APIs if backend is delayed. | Technical Lead |
| 6 | Bundle size exceeds 350 KB gzipped after reference app features | Low | Low (requires optimisation) | Code-split routes with `React.lazy()`. Monitor bundle size in every PR via CI gate. Tree-shake Fluent UI imports. | Scaffold team |
| 7 | Team unfamiliar with RTK Query patterns | Medium | Medium (slow velocity in Sprints 7–9) | Reference app examples are the training material. Technical Lead runs a 1-hour RTK Query workshop in Sprint 0. | Technical Lead |

---

## 9. Definition of Done — Phase 1

Phase 1 is complete when all of the following are true:

**Packages:**
- [ ] `@eaf/ui-components` v1.0.0 published to Azure Artifacts with all Phase 1 components
- [ ] `@eaf/shell-layout` v1.0.0 published with header, sidebar, footer
- [ ] `@eaf/auth` v1.0.0 published with `AuthProvider`, `useAuth`, `useToken`, `getToken`
- [ ] `@eaf/api-client` v1.0.0 published with `createApiClient`, `eafBaseQuery`
- [ ] `@eaf/eslint-config` v1.0.0 published
- [ ] `@eaf/auth-code-app` v1.0.0 published with identical API surface to `@eaf/auth`
- [ ] All packages have ≥80% unit test coverage
- [ ] All components pass axe-core accessibility audit (zero critical/serious violations)
- [ ] `components.json` manifest is complete and current

**Storybook:**
- [ ] Deployed and accessible within the organisation
- [ ] Every component has a Default story plus required variant stories
- [ ] Accessibility panel shows green for all stories

**Scaffold:**
- [ ] `eaf-app-template` is a GitHub template repository
- [ ] `npm install && npm run dev` starts a working authenticated app
- [ ] `CLAUDE.md` and `copilot-instructions.md` are present and accurate
- [ ] Azure DevOps pipeline template included and functional

**Reference Application:**
- [ ] Deployed to dev and staging environments
- [ ] Orders CRUD, analytics dashboard, and chat agent features all functional
- [ ] End-to-end Playwright tests pass
- [ ] Performance budgets met (bundle < 350 KB gzipped, TTI < 2.5s)

**Infrastructure:**
- [ ] All Azure resources provisioned via Bicep for dev, staging, and production
- [ ] APIM configured with global JWT validation, rate limiting, and diagnostic logging
- [ ] Reference app API published through APIM with OpenAPI spec imported

**CI/CD:**
- [ ] Packages monorepo pipeline: validates, tests, builds, publishes on merge
- [ ] Application pipeline: validates, tests, builds Docker image, deploys to dev on merge
- [ ] All pipeline gates active (typecheck, lint, coverage, security scan, bundle size)

**Documentation:**
- [ ] Technical Design Specification updated to v1.0
- [ ] Application onboarding guide complete
- [ ] Operational runbook documented
- [ ] At least 6 ADRs (001–006) documented
- [ ] Versioning and deprecation policy published

---

## 10. Post-Phase 1 Backlog

Items deferred from Phase 1 that should be prioritised for Phase 1.1:

| Item | Source | Priority |
|---|---|---|
| `SplitPane` component | Review finding #14 | Medium |
| `AppNav`, `BreadcrumbBar`, `TabBar` navigation components | Review finding #15 | Medium |
| EAF Portal (application directory) | Spec Open Question #3 | High — resolve decision first |
| MSAL v3 evaluation and migration plan | Review finding #5 | High (security) |
| React 19 testing in CI matrix | Review finding #4 | Medium |
| TypeScript client generation from OpenAPI (orval) | Spec Section 19 | Medium |
| Minimum supported version policy enforcement | Review finding #8 | High (governance) |
| Staging E2E test suite (Playwright) | Spec Section 12 | High |
| k6 performance test suite | Spec Section 12 | Medium |

---

## Appendix A: Sprint Capacity Assumptions

- Each developer delivers approximately 20 story points per sprint (2-week sprint).
- Issue complexity estimates (used for scheduling, not formal story points):
  - Small (S): 5–8 points — e.g., Issue #2 (ESLint config), Issue #9 (chat components)
  - Medium (M): 8–13 points — e.g., Issue #3 (auth), Issue #10 (shell layout), Issue #13 (scaffold)
  - Large (L): 13–20 points — e.g., Issue #7 (DataTable), Issue #15 (CRUD feature), Issue #22 (Bicep IaC)
- Technical Lead capacity is split across code review, architecture decisions, and risk management — not counted as a full developer.

## Appendix B: Communication Cadence

| Ceremony | Frequency | Participants | Purpose |
|---|---|---|---|
| Daily standup | Daily, 15 min | All team | Blockers, progress, cross-stream dependencies |
| Sprint planning | Bi-weekly, 1 hour | All team | Commit to sprint scope, assign issues |
| Sprint review | Bi-weekly, 1 hour | Team + stakeholders | Demo deliverables, gather feedback |
| Sprint retro | Bi-weekly, 30 min | All team | Process improvements |
| Architecture sync | Weekly, 30 min | Technical Lead + workstream leads | Cross-cutting decisions, API surface reviews |
| Milestone review | At M0, M2, M3, M4 | Team + Engineering Leadership | Go/No-Go decisions |
