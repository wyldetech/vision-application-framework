# Vision Application Framework

This repository currently holds the core planning and architecture documents for the Enterprise Application Framework (EAF) Phase 1 foundation. It is the source-of-truth documentation set for the platform architecture, implementation backlog, review findings, and delivery plan.

The EAF is a cloud-native framework for building multiple independent line-of-business applications with a shared user experience, shared frontend packages, common authentication, API governance, and observability standards. The design is intentionally optimized for AI-assisted development: standalone React applications, strongly typed shared packages, clear scaffolds, and predictable delivery conventions.

## Repository Status

This repository is documentation-first. It does not yet contain the implementation monorepo, scaffold, reference app, or infrastructure code described in the documents.

Phase 1 is planned as a 10-sprint foundation program preceded by a Sprint 0 preparation phase. The documented target state includes:

- Shared packages: `@eaf/ui-components`, `@eaf/shell-layout`, `@eaf/auth`, `@eaf/api-client`, `@eaf/eslint-config`
- A Turborepo-based shared package monorepo with Storybook
- An `eaf-app-template` scaffold for new standalone applications
- A reference application demonstrating CRUD, charts, chat, logging, and error handling
- Azure-hosted infrastructure with APIM, Key Vault, Application Insights, Azure SQL, and Container Apps
- Azure DevOps pipelines and Azure Artifacts for CI/CD and package publishing

## Architecture Summary

The EAF is not a runtime-composed microfrontend platform. Each application is a standalone React app that shares standards through packages at build time, not through a shared runtime.

Core architectural decisions documented in this repo:

- Applications are independently built and deployed, with browser navigation between apps rather than Module Federation.
- Frontend standards are enforced through shared packages and the scaffold template.
- Authentication is handled per app against the same Entra ID tenant, enabling silent SSO across applications.
- All frontend-to-backend communication goes through Azure API Management.
- The platform is optimized for AI development workflows by preferring widely adopted, strongly typed, well-documented technologies.

Planned frontend stack:

- React 18/19-compatible TypeScript applications
- Vite for builds
- Redux Toolkit and RTK Query for state and data fetching
- Fluent UI React v9 for the design system
- Recharts for visualization
- Storybook for component documentation
- Turborepo for shared package development

## Current Document Set

- [Technical design specification](/Users/adam/Documents/GitHub/vision-application-framework/docs/EAF-Technical-Design-Specification-v3.md): the main Phase 1 architecture, goals, principles, and target design.
- [GitHub issues backlog](/Users/adam/Documents/GitHub/vision-application-framework/docs/EAF-GitHub-Issues-v2.md): implementation-ready issue definitions and dependency graph for the Phase 1 deliverables.
- [Architecture review](/Users/adam/Documents/GitHub/vision-application-framework/docs/EAF-Architecture-Review.md): independent review of the design, including critical issues, structural gaps, and recommendations.
- [Critical findings implementation plan](/Users/adam/Documents/GitHub/vision-application-framework/docs/EAF-Critical-Findings-Implementation-Plan.md): decisions made to resolve the review’s critical blockers before implementation.
- [Phase 1 implementation plan](/Users/adam/Documents/GitHub/vision-application-framework/docs/EAF-Phase-1-Implementation-Plan.md): sprint plan, workstreams, milestones, and team structure for delivery.

## Important Resolved Decisions

The latest planning docs already resolve several blockers identified in architecture review:

- `eafBaseQuery` will use a non-React `getToken()` export from `@eaf/auth` via a module-scoped MSAL singleton, avoiding Rules of Hooks violations.
- Local development will use a lightweight Caddy-based mock gateway by default. The APIM self-hosted gateway becomes an opt-in profile instead of the default local path.
- Azure DevOps Pipelines is the selected CI/CD platform.
- Azure Artifacts is the selected internal npm registry.
- Additional backend API issues are required for the reference application and are scheduled into the Phase 1 plan.

## Phase 1 Scope

The documented Phase 1 goals are to establish the shared package foundation, deliver the application scaffold, provide a reference app, deploy Storybook, implement CI/CD, and provision the supporting Azure infrastructure.

Explicit non-goals for Phase 1 include:

- Runtime UI composition
- Event-driven architecture
- Cross-application workflow orchestration
- Multi-region deployment
- Advanced authorization models beyond RBAC
- Cross-application analytics/reporting
- Treating the reference application as production-ready

## How To Use This Repo

- Start with the technical design specification to understand the target architecture and platform principles.
- Read the architecture review and critical findings plan together before implementation work begins.
- Use the GitHub issues document as the implementation backlog and dependency map.
- Use the Phase 1 implementation plan for sprint sequencing, ownership, and milestone planning.

## Expected Future Repositories and Deliverables

Based on the current docs, implementation work will produce or populate repositories and assets such as:

- `eaf-packages` for shared `@eaf/*` packages and Storybook
- `eaf-app-template` for the application scaffold
- A reference application frontend
- A reference application backend API
- Infrastructure-as-code and pipeline definitions

Those assets are planned but are not present in this repository today.

## Audience

This repo is primarily useful for:

- Platform architects defining the operating model and standards
- Engineering leads planning Phase 1 delivery
- Developers onboarding to the EAF architecture before implementation starts
- AI-assisted coding workflows that need stable architectural and backlog context

## Contribution Notes

When updating this repository:

- Keep the README aligned with the latest architecture, review, and implementation-plan documents.
- Prefer documenting decisions explicitly when architectural questions are resolved.
- Avoid describing planned assets as already implemented unless they exist in the repo.
