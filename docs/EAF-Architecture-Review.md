# EAF Technical Design Specification — Architecture Review

| Field | Value |
|---|---|
| **Document Under Review** | EAF Technical Design Specification v0.3 + GitHub Issues v2 (Phase 1) |
| **Reviewer** | Senior Technical Lead / Solutions Architect |
| **Review Date** | 2026-03-28 |

---

## Overall Assessment

The Technical Design Specification and the GitHub Issues backlog are exceptionally well-crafted for a platform initiative of this scope. The architecture is pragmatic, the decisions are well-reasoned, the issues are genuinely implementation-ready, and the AI-first development philosophy is coherently woven throughout rather than bolted on.

**Recommendation:** Resolve the three critical items, add the missing backend API issue, and proceed. The architecture is sound, the backlog is implementation-ready, and the design decisions are well-justified.

---

## Critical Issues

These must be resolved before implementation begins.

### 1. `eafBaseQuery` violates the Rules of Hooks

**Affects:** Issue #4 (`@eaf/api-client`)

Issue #4 specifies that `eafBaseQuery` calls `useToken()` internally via a closure, and documents a constraint that the factory "must be called inside a React component or custom hook." However, `baseQuery` in RTK Query is not a React context — it is a plain function invoked by Redux middleware outside the React tree. You cannot call a hook inside it. The JSDoc note acknowledges this but does not solve it.

**Recommended fix:** Either pass `getToken` as a parameter to `eafBaseQuery` (so the app calls `useToken()` at the component level and passes the function down), or store the MSAL instance in a module-scoped singleton so `eafBaseQuery` can call `acquireTokenSilent` without React context. The second approach is cleaner and is what most MSAL + RTK integrations use. This must be resolved in the spec before Issue #4 is implemented — otherwise it will produce a runtime crash that is confusing to debug.

### 2. The APIM self-hosted gateway in Docker Compose requires a live Azure APIM instance

**Affects:** Issue #19 (Docker dev environment), Goal G2

Issue #19 specifies an `apim-gateway` service using `mcr.microsoft.com/azure-api-management/gateway:latest` with `APIM_GATEWAY_TOKEN` and `APIM_GATEWAY_ENDPOINT`. This is a self-hosted gateway that proxies to a real APIM instance — it requires a provisioned Azure APIM service and a gateway token. A developer who clones the scaffold and runs `docker-compose up` without Azure access will get a connection failure, not a working local environment.

This directly contradicts Goal G2 ("zero to running application in under one hour").

**Recommended fix:** Provide a lightweight mock API gateway as the default local experience (a simple Express or Caddy reverse proxy), or clearly document that the APIM gateway is optional and the scaffold works without it (with the Vite dev server proxying directly to the backend). The current specification will produce a broken first-run experience for most developers.

### 3. Open Questions #1 and #6 block implementation

**Affects:** Issues #20 and #21 (CI/CD pipelines)

The npm registry choice (Azure Artifacts vs GitHub Packages) and the CI/CD platform choice (GitHub Actions vs Azure DevOps) are unresolved, yet Issues #20 and #21 specify GitHub Actions YAML verbatim. If the answer turns out to be Azure DevOps, those issues need to be rewritten.

**Recommended fix:** Resolve these decisions and document them before any CI/CD issues are assigned.

---

## Significant Design Concerns

These should be addressed before v1.0.

### 4. React 18 pinning while the ecosystem moves to React 19

The spec pins `react@^18.0.0` as a peer dependency across all packages. React 19 is now stable. The `^18.0.0` peer dep will produce npm warnings for any team that upgrades to React 19, and Fluent UI v9 is already tracking React 19 compatibility.

**Recommendation:** Use `"react": "^18.0.0 || ^19.0.0"` for peer dependencies now, with testing against React 19 added to the CI matrix. This avoids a painful coordinated upgrade across all consuming applications later.

### 5. MSAL v2 pinning when v3 is the current major

Issue #3 explicitly pins `@azure/msal-browser@^2.38.0` with the note "do not use v3, intentionally pinned." MSAL v2 is in maintenance mode and Microsoft is directing all new development to v3/v4.

**Recommendation:** Document why v2 is pinned. If it is because v3's API changes have not been evaluated, track this as a tech debt item with a target date. Otherwise it will become a security liability.

### 6. `@eaf/auth-code-app` depends on a package that may not exist in its expected form

Issue #24 lists `@microsoft/powerapps-client@latest` as a dependency. The Power Apps Code Apps client SDK is relatively new and the exact npm package name and API surface should be verified. The issue spec includes function signatures like `PowerAppsClient.init()` and `getAccessToken(resource)` — if these do not match the actual SDK API, the issue will need significant rework.

**Recommendation:** Run a spike or proof-of-concept before this issue is sized and scheduled.

### 7. The bundle size check in CI measures the wrong thing

**Affects:** Issue #21 (application pipeline)

Issue #21's bundle size check uses `du -sk dist/assets/*.js` which measures uncompressed size in KB. The performance budget in the spec (Section 6.7) says "< 350 KB gzipped." These are very different numbers — a 350 KB uncompressed bundle is roughly 100 KB gzipped.

**Recommended fix:** Either use `gzip -c dist/assets/*.js | wc -c` to measure actual gzipped size, or adjust the threshold to reflect uncompressed size (probably ~1200 KB). As written, this gate will either be uselessly loose or will block builds that are well within the actual budget.

### 8. No versioning strategy for `@eaf/*` packages

The spec mentions semver and the issues start at `0.0.1`, but there is no documented strategy for when and how packages move to `1.0.0`, how breaking changes are communicated, or what the minimum supported version window is (Open Question #2). For a platform package consumed by multiple teams, this is a governance gap.

**Recommendation:** Define the policy now. Suggested starting point: packages ship at `1.0.0` at Phase 1 completion, breaking changes require a major bump and a 3-month deprecation window, and the scaffold is updated within one week of any major release.

---

## Structural Gaps in the Issue Backlog

### 9. No issue for the EAF Portal

The spec describes an "EAF Portal" (landing page and application directory) in the context diagram and component summary, but there is no issue for implementing it. Open Question #3 asks whether it should exist, but it appears in the architecture as if it does.

**Recommendation:** Resolve the question and add an issue, or remove it from the diagrams.

### 10. No issue for backend/API implementation

The reference app issues (#14–#18) specify frontend API integration against endpoints like `GET /api/v1/orders`, but no issue covers building the .NET 8 backend API. The spec describes .NET 8 + EF Core + Azure SQL, but the backlog jumps straight to frontend consumption. Either the backend already exists, or there is a missing issue (or set of issues) for the reference app API, database schema, EF Core migrations, and OpenAPI spec. The seed SQL in Issue #19 partially addresses this, but a seed script is not a running API.

**Recommendation:** Add issues for the reference app backend — API project setup, domain model and EF Core migrations, CRUD endpoints, OpenAPI spec generation, and health check endpoints.

### 11. No issue for the `components.json` script's TypeScript AST parsing

Issue #12 specifies a script that reads TypeScript source files, extracts JSDoc comments and prop types, and generates a manifest. This is non-trivial — it requires `ts-morph` or the TypeScript Compiler API. The issue describes the output format but does not specify the tooling or approach for AST parsing.

**Recommendation:** Add a note specifying `ts-morph` as the tool and providing a skeleton of the extraction logic.

### 12. The `generate-manifest` CI freshness check has a race condition

Issues #12 and #20 specify that CI runs `npm run generate:manifest` and then `git diff --exit-code components.json` to detect staleness. The `"generated"` timestamp field in the output will change on every run, causing the diff to always show changes.

**Recommendation:** Exclude the `"generated"` field from the diff check, or remove it from the output entirely and rely on git commit history for provenance.

---

## Minor Items

### 13. `import/no-restricted-paths` rule does not achieve its stated goal

**Affects:** Issue #2 (`@eaf/eslint-config`)

The zone `{ target: './src', from: './src', except: ['./'] }` is meant to "prevent cross-app coupling," but in the context of a shared ESLint config consumed by different repos, `./src` resolves relative to the consuming package's root — it does not prevent cross-application imports. This rule would need to be configured per-application or replaced with a custom rule that blocks imports outside `@eaf/*` and the app's own source.

### 14. `SplitPane` component listed in spec but missing from issues

The spec's component catalogue (Section 6.6) lists `SplitPane` under Layout components. No issue implements it.

### 15. Navigation components listed in spec but missing from issues

The spec lists `AppNav`, `BreadcrumbBar`, and `TabBar` under Navigation in the component catalogue, but none of these appear in any issue. If deferred, the spec should note this.

### 16. Docker Compose `seed.sql` mount path is invalid for SQL Server

Issue #19 mounts `seed.sql` to `/docker-entrypoint-initdb.d/`. The SQL Server container image does not support this convention (that is a PostgreSQL/MySQL pattern). SQL Server requires a custom entrypoint script that waits for the server to start and then runs `sqlcmd`. The `wait-for-db.sh` script mentioned in the issue hints at this, but the `docker-compose.yml` as written will not auto-execute the seed script.

### 17. Consider native `fetch` over `axios`

Issue #4 specifies `axios` but native `fetch` is now widely supported with comparable functionality. Axios adds ~13 KB to the bundle and most of its value (interceptors) can be replicated with a thin wrapper. Not a blocker, but worth a sentence in an ADR explaining the choice.

---

## What's Done Well

The following decisions and qualities are worth explicitly preserving and defending.

**Standalone apps over Module Federation (ADR-001).** The right call. The rationale is honest about the trade-off (full-page navigation between apps) and the benefits (operational independence, simpler security, better AI tooling support) are real.

**"The scaffold is the standard" principle.** The single most impactful governance mechanism in the design. Most platform teams over-invest in runtime enforcement and under-invest in the starting point. This spec gets the balance right.

**Auth adapter pattern (ADR-006).** Forward-thinking and well-executed. The interface contract is small and stable, and the Power Apps Code Apps adapter is a concrete proof that the abstraction works.

**Issue writing quality.** Outstanding for agent consumption. The "all decisions have been made" framing, the exact code shapes, the explicit dependency graph, and the testable acceptance criteria mean these can be handed to a coding agent with minimal iteration. This is rare.

**AI-first framing throughout.** Not superficial — the technology choices, the documentation requirements, the `components.json` manifest, and the `CLAUDE.md` / `copilot-instructions.md` in the scaffold show a team that understands how AI tools consume context, not just that they exist.
