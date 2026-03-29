# GitHub Copilot Instructions — EAF Application

This repository is a standalone React application built on the Enterprise Application Framework (EAF). The instructions below define the patterns and constraints Copilot should follow when generating code in this codebase.

---

## Technology Stack

- **React 18 + TypeScript 5** — strict mode enabled, no `any`
- **Vite** — do not suggest Webpack or CRA patterns
- **Redux Toolkit + RTK Query** — all state and data fetching
- **React Hook Form + Zod** — all form state and validation
- **`@eaf/ui-components`** — all UI components
- **`@eaf/shell-layout`** — application layout root
- **`@eaf/auth`** — authentication, always via hooks
- **`@eaf/api-client`** — base query for all RTK Query slices

---

## Code Generation Rules

### Data fetching
- Use RTK Query for **all** API calls. Never suggest `fetch`, `axios` directly, or `useEffect` to load data.
- Base all RTK Query API slices on `eafBaseQuery` from `@eaf/api-client`.
- If types exist in `src/api/generated/`, import them — do not regenerate or redefine them.

### State management
- RTK Query cache = server data. Redux slices = local UI state. React Hook Form = form state.
- These three categories do not overlap. Do not put form values or API response data in Redux slices.

### Forms
- All forms use `react-hook-form` with `zodResolver`.
- Define a Zod schema for every form. Keep schemas co-located with their form component.
- Submit actions call RTK Query mutations via `handleSubmit`.

### Authentication
- Always use `useAuth()` or `useToken()` from `@eaf/auth`.
- Never import `@azure/msal-browser` or any MSAL package directly.
- Never suggest a redirect handler, token storage, or login page — these are handled by `<AuthProvider>`.

### Components and layout
- Before generating a custom component, check whether `@eaf/ui-components` has an equivalent.
- The application root must use `<ShellLayout>` from `@eaf/shell-layout`. Never suggest a custom layout wrapper.
- Do not generate custom header, sidebar, footer, or navigation chrome.

### API and environment
- API base URL comes from `import.meta.env.VITE_API_BASE_URL`. Never hardcode URLs or ports.
- All API traffic routes through Azure APIM. Do not suggest direct service URLs.

### Error handling
- Surface API errors via RTK Query's `isError` and `error` fields — render `<ErrorDisplay>` from `@eaf/ui-components`.
- Do not suggest empty `catch` blocks or `console.error`-only error handling in production code.

---

## File and Folder Conventions

```
src/
  api/              ← RTK Query slices and generated types
  features/         ← One folder per domain feature
    featureName/
      FeaturePage.tsx
      FeatureForm.tsx
      featureSlice.ts   (only if local UI state is needed)
      components/
  store.ts          ← Redux store configuration
  App.tsx           ← AuthProvider + ShellLayout root
```

New features go in `src/features/`. New API endpoints go in `src/api/`. Do not suggest alternative structures.

---

## Do Not Suggest

- Custom authentication or session management code
- `localStorage` or `sessionStorage` for storing tokens or sensitive data
- Direct imports of Fluent UI components where an `@eaf/ui-components` wrapper exists
- `useEffect` for data fetching or synchronising server state
- Inline styles or CSS modules — use Fluent UI design tokens and `@eaf/ui-components` props
- Cross-application API calls from the frontend
- Any pattern that bypasses `@eaf/auth`, `@eaf/api-client`, or `@eaf/shell-layout`
