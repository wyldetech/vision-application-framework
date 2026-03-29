# GitHub Copilot Instructions for Vision Application Framework

## Purpose

This repository is the documentation source of truth for the Enterprise Application Framework (EAF) Phase 1 foundation. It currently contains architecture, backlog, review, and implementation-planning documents. It does not yet contain the implementation monorepo, scaffold, reference application, or infrastructure code described in the docs.

When working in this repository, prioritise accuracy, consistency with the documented decisions, and explicit documentation of changes. Do not imply that planned assets already exist.

## Current Repository Reality

- Treat this as a documentation-first repository unless the file structure clearly shows implementation assets have been added.
- Do not invent missing packages, apps, pipelines, or infrastructure as if they already exist.
- When asked to update the architecture or delivery plan, keep README and related documents aligned.
- Prefer editing existing documents over creating speculative new files unless the request explicitly asks for them.

## Source of Truth

Use these documents in this order when there is ambiguity:

1. `README.md`
2. `docs/EAF-Technical-Design-Specification-v3.md`
3. `docs/EAF-Critical-Findings-Implementation-Plan.md`
4. `docs/EAF-GitHub-Issues-v2.md`
5. `docs/EAF-Phase-1-Implementation-Plan.md`
6. `docs/EAF-Architecture-Review.md`

If two documents appear to conflict, prefer the more recent decision-oriented document, especially the critical findings implementation plan for resolved blockers.

## Non-Negotiable Architecture Rules

- EAF applications are standalone React applications, not runtime-composed microfrontends.
- Shared standards are enforced through packages at build time, not through a shared runtime shell.
- Frontend stack is TypeScript, React, Vite, Redux Toolkit, RTK Query, Fluent UI React v9, Recharts, Storybook, and Turborepo for shared packages.
- Frontend applications authenticate independently against the same Entra ID tenant to enable silent SSO.
- Frontend-to-backend traffic goes through Azure API Management.
- Shared packages are the governance layer: `@eaf/ui-components`, `@eaf/shell-layout`, `@eaf/auth`, `@eaf/api-client`, `@eaf/eslint-config`.
- CI/CD runs on Azure DevOps Pipelines. GitHub is used for source control, pull requests, and Copilot instructions.
- Local development should assume the lightweight mock gateway approach described in the critical findings plan, not APIM self-hosted gateway as the default.
- `@eaf/api-client` must use the non-React `getToken()` pattern from `@eaf/auth`, not React hooks inside RTK Query base query code.

## How To Write Changes

- Keep terminology consistent across documents: EAF, standalone applications, shared packages, scaffold, reference application, Azure API Management, Entra ID, Azure DevOps Pipelines, Azure Artifacts.
- Prefer precise, implementation-ready language over aspirational or marketing language.
- When documenting future work, mark it as planned, proposed, required, or out of scope.
- When resolving an architectural question, record the decision explicitly and update all affected documents that restate the old assumption.
- Preserve numbered goals, non-goals, ADRs, issue numbering, and dependency relationships unless the change explicitly requires restructuring.
- Keep issue specifications self-contained and agent-friendly. If code shapes are shown, present them as contracts.

## If Code Is Added Later

If this repository begins to include implementation assets, generate code that follows these conventions unless a file proves otherwise:

- Use strict TypeScript and explicit types on public APIs.
- Prefer predictable, widely adopted patterns over clever abstractions.
- Use Redux Toolkit and RTK Query for application state and server data.
- Use Fluent UI React v9 for UI primitives and accessibility-friendly components.
- Keep applications independently deployable and avoid runtime coupling between apps.
- Do not bypass shared packages with app-local reimplementations of auth, shell layout, or API plumbing.
- Do not add direct frontend calls that bypass APIM.
- Do not introduce Module Federation or cross-app frontend imports.
- Keep package documentation, Storybook stories, JSDoc, and types in sync because they are part of the AI instruction surface.

## Documentation Update Expectations

When making a meaningful architectural or planning change, check whether these also need updates:

- `README.md`
- issue backlog references in `docs/EAF-GitHub-Issues-v2.md`
- implementation sequencing in `docs/EAF-Phase-1-Implementation-Plan.md`
- resolved decision notes in `docs/EAF-Critical-Findings-Implementation-Plan.md`

Avoid leaving the README or planning docs behind after changing core assumptions.

## What To Avoid

- Do not describe the repository as a completed implementation.
- Do not generate GitHub Actions workflows as the default CI/CD answer for EAF Phase 1; use Azure DevOps pipeline language instead.
- Do not reintroduce outdated assumptions already resolved in review follow-up documents.
- Do not call React hooks from non-React execution paths.
- Do not add architecture that conflicts with the documented non-goals, especially runtime UI composition, event-driven architecture in Phase 1, or fine-grained authorisation models beyond RBAC.

## Preferred Response Style For This Repo

- Be concrete and decision-oriented.
- Surface assumptions explicitly.
- When summarising changes, mention affected documents.
- When drafting specs or backlog items, include acceptance criteria that are testable.
- Optimise for maintainability and AI-assisted implementation quality, not novelty.
