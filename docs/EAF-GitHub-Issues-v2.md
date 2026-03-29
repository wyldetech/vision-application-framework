# EAF — GitHub Issues for Phase 1 Implementation

> **Usage note for coding agents:** Each issue is self-contained. Read the full issue before writing any code. All decisions you would ordinarily need to ask about have been made — follow the specification exactly. Where code shapes are shown, treat them as contracts, not suggestions.

---

## Dependency Graph

```
#1 Monorepo setup
  └── #2 @eaf/eslint-config
        ├── #3 @eaf/auth
        │     └── #24 @eaf/auth-code-app (auth adapter for Power Apps Code Apps)
        ├── #4 @eaf/api-client
        │     └── #5 @eaf/ui-components (layout + feedback)
        │           ├── #6 @eaf/ui-components (forms)
        │           ├── #7 @eaf/ui-components (data display)
        │           ├── #8 @eaf/ui-components (charts)
        │           ├── #9 @eaf/ui-components (chat)
        │           └── #10 @eaf/shell-layout
        │                 ├── #11 Storybook
        │                 │     └── #12 components.json manifest
        │                 └── #13 eaf-app-template scaffold
        │                       ├── #14 Reference app — setup
        │                       │     ├── #15 Reference app — CRUD
        │                       │     ├── #16 Reference app — charts
        │                       │     ├── #17 Reference app — chat
        │                       │     └── #18 Reference app — logging & errors
        │                       ├── #19 Docker dev environment
        │                       ├── #20 CI/CD — packages pipeline
        │                       └── #21 CI/CD — application pipeline
#22 Bicep IaC — core infrastructure
#23 APIM configuration as code
```

---

## Issue 1: Initialise Turborepo monorepo for @eaf/* packages

**Labels:** `platform`, `phase-1`, `no-dependencies`

### Context
All shared EAF packages live in a single Turborepo monorepo (`eaf-packages`). This is the first thing that must exist. Nothing else can be built until this repository is initialised correctly.

### Specification

Create a new repository called `eaf-packages` with the following structure:

```
eaf-packages/
├── packages/
│   ├── ui-components/
│   │   └── package.json        (name: "@eaf/ui-components", version: "0.0.1")
│   ├── shell-layout/
│   │   └── package.json        (name: "@eaf/shell-layout", version: "0.0.1")
│   ├── auth/
│   │   └── package.json        (name: "@eaf/auth", version: "0.0.1")
│   ├── api-client/
│   │   └── package.json        (name: "@eaf/api-client", version: "0.0.1")
│   └── eslint-config/
│       └── package.json        (name: "@eaf/eslint-config", version: "0.0.1")
├── apps/
│   └── storybook/
│       └── package.json        (name: "@eaf/storybook", private: true)
├── turbo.json
├── package.json                (private: true, workspaces: ["packages/*", "apps/*"])
├── tsconfig.base.json
├── .nvmrc                      (node version: 20)
└── README.md
```

**`turbo.json`:**
```json
{
  "$schema": "https://turbo.build/schema.json",
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**"]
    },
    "test": {
      "dependsOn": ["^build"]
    },
    "lint": {},
    "typecheck": {
      "dependsOn": ["^build"]
    },
    "dev": {
      "cache": false,
      "persistent": true
    }
  }
}
```

**`tsconfig.base.json`:**
```json
{
  "compilerOptions": {
    "strict": true,
    "target": "ES2020",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "jsx": "react-jsx",
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true
  }
}
```

Each package's `package.json` must include:
- `"main": "./dist/index.js"`
- `"types": "./dist/index.d.ts"`
- `"exports"` field pointing to `./dist/index.js`
- `"scripts": { "build": "tsc", "typecheck": "tsc --noEmit", "lint": "eslint src" }`
- `"peerDependencies": { "react": "^18.0.0", "react-dom": "^18.0.0" }` (where applicable)

Root `package.json` must include `turbo` and `typescript` as dev dependencies.

### Acceptance Criteria
- [ ] `npm install` at the root completes without errors
- [ ] `npx turbo build` runs (and succeeds for the empty stub packages)
- [ ] `npx turbo typecheck` runs without errors
- [ ] All five package stubs export an empty `index.ts` (`export {}`) that compiles cleanly
- [ ] `node --version` output matches `.nvmrc`

---

## Issue 2: Implement @eaf/eslint-config

**Labels:** `package`, `phase-1`
**Depends on:** #1

### Context
Every EAF application and package uses `@eaf/eslint-config` as the base ESLint configuration. It must be implemented before other packages, because all subsequent packages will use it during development.

### Specification

**Location:** `packages/eslint-config/`

**Install these dev dependencies in this package:**
```
eslint, @typescript-eslint/eslint-plugin, @typescript-eslint/parser,
eslint-plugin-react, eslint-plugin-react-hooks, eslint-plugin-jsx-a11y,
eslint-plugin-import
```

**`packages/eslint-config/index.js`** must export a config object with these rules enforced:

```javascript
module.exports = {
  parser: '@typescript-eslint/parser',
  parserOptions: { ecmaVersion: 'latest', sourceType: 'module', ecmaFeatures: { jsx: true } },
  plugins: ['@typescript-eslint', 'react', 'react-hooks', 'jsx-a11y', 'import'],
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:react/recommended',
    'plugin:react-hooks/recommended',
    'plugin:jsx-a11y/recommended',
  ],
  rules: {
    // TypeScript
    '@typescript-eslint/no-explicit-any': 'error',
    '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
    '@typescript-eslint/explicit-module-boundary-types': 'off',

    // React
    'react/react-in-jsx-scope': 'off',
    'react/prop-types': 'off',
    'react-hooks/rules-of-hooks': 'error',
    'react-hooks/exhaustive-deps': 'warn',

    // Import restrictions — prevent cross-app coupling and enforce @eaf/* usage
    'import/no-restricted-paths': ['error', {
      zones: [
        // Applications must not import from other application packages
        { target: './src', from: './src', except: ['./'] }
      ]
    }],

    // Accessibility
    'jsx-a11y/anchor-is-valid': 'error',

    // General
    'no-console': ['warn', { allow: ['warn', 'error'] }],
  },
  settings: {
    react: { version: 'detect' }
  }
};
```

Add a `README.md` explaining how to extend this config in consuming packages:
```json
// .eslintrc in any EAF app or package
{ "extends": ["@eaf/eslint-config"] }
```

### Acceptance Criteria
- [ ] Package builds and exports the config object without errors
- [ ] A test `.tsx` file with an intentional `any` type triggers `@typescript-eslint/no-explicit-any`
- [ ] A test `.tsx` file with a `useEffect` missing a dependency triggers `react-hooks/exhaustive-deps`
- [ ] `console.log` in a `.ts` file triggers a warning
- [ ] README documents usage

---

## Issue 3: Implement @eaf/auth

**Labels:** `package`, `phase-1`, `security`
**Depends on:** #1, #2

### Context
`@eaf/auth` is the authentication package used by every EAF application. It wraps MSAL.js and must be the **only** way applications interact with authentication. Applications never import `@azure/msal-browser` directly.

### Specification

**Location:** `packages/auth/`

**Dependencies:**
```
@azure/msal-browser@^2.38.0   (pin to ^2.38.0 — do not use v3, intentionally pinned)
react@^18.0.0                 (peer)
```

**Public API — `packages/auth/src/index.ts` must export exactly:**
```typescript
export { AuthProvider } from './AuthProvider';
export { useAuth } from './hooks/useAuth';
export { useToken } from './hooks/useToken';
export type { AuthConfig, AuthUser } from './types';
```

**Types — `src/types.ts`:**
```typescript
export interface AuthConfig {
  clientId: string;       // Application's own Entra ID client ID
  tenantId: string;       // Shared EAF tenant ID
  scopes: string[];       // e.g. ['api://eaf-app-a/.default']
  redirectUri?: string;   // Defaults to window.location.origin
}

export interface AuthUser {
  oid: string;            // Entra ID object ID
  name: string;
  email: string;
  roles: string[];
}
```

**`AuthProvider` behaviour:**
- Accepts `config: AuthConfig` and `children: ReactNode`
- Initialises an `msalInstance` (PublicClientApplication) internally — do not expose it
- On mount, calls `msalInstance.handleRedirectPromise()` to complete any in-progress redirect
- If no active account after redirect handling, calls `msalInstance.loginRedirect()`
- While auth is in progress, renders a full-page loading state (a simple centred spinner is sufficient)
- Once authenticated, sets the active account and provides context to children
- Context value must include `user: AuthUser`, `isAuthenticated: boolean`, `logout: () => void`

**`useAuth()` hook:**
```typescript
// Returns the auth context. Throws if used outside AuthProvider.
export function useAuth(): { user: AuthUser; isAuthenticated: boolean; logout: () => void }
```

**`useToken()` hook:**
```typescript
// Acquires an access token silently. Returns the token string or null if unavailable.
// Uses msalInstance.acquireTokenSilent internally.
// On InteractionRequiredAuthError, falls back to acquireTokenRedirect.
export function useToken(): () => Promise<string | null>
```

Write unit tests using Vitest. Mock `@azure/msal-browser` — do not make real auth calls in tests.

### Acceptance Criteria
- [ ] Package builds and all types are exported correctly
- [ ] `useAuth()` throws a descriptive error when called outside `<AuthProvider>`
- [ ] `useToken()` returns a function that resolves to a string in the happy path (mocked)
- [ ] `useToken()` calls `acquireTokenRedirect` when `InteractionRequiredAuthError` is thrown (mocked)
- [ ] Unit test coverage ≥ 80%
- [ ] No direct usage of `@azure/msal-browser` types in the public API surface — all types are EAF-defined

---

## Issue 4: Implement @eaf/api-client

**Labels:** `package`, `phase-1`
**Depends on:** #1, #2, #3

### Context
`@eaf/api-client` provides the pre-configured HTTP client used by all EAF applications. It handles auth token injection, correlation ID generation, and Application Insights telemetry automatically. RTK Query base queries in every application are built on top of this client.

### Specification

**Location:** `packages/api-client/`

**Dependencies:**
```
axios@^1.6.0
uuid@^9.0.0
@microsoft/applicationinsights-web@^3.0.0   (peer — don't bundle it)
react@^18.0.0                                (peer)
```

**Public API — `src/index.ts` must export exactly:**
```typescript
export { createApiClient } from './createApiClient';
export { eafBaseQuery } from './eafBaseQuery';
export type { EafApiClientOptions } from './types';
```

**`createApiClient(baseUrl: string, getToken: () => Promise<string | null>): AxiosInstance`**

The returned Axios instance must:
1. Set `baseURL` to the provided `baseUrl`
2. On every request, call `getToken()` and set `Authorization: Bearer <token>` if a token is returned
3. Generate a UUID v4 and set it as `x-correlation-id` on every request
4. Log every request start and response (status, url, correlationId, duration) to Application Insights if `window.appInsights` is present — do not throw if it is absent
5. On 401 responses, clear the correlation ID and reject with a typed `AuthError`
6. Set a default timeout of 30 seconds
7. Retry on 503 and 504 with exponential backoff, maximum 2 retries, using Axios interceptors

**`eafBaseQuery(baseUrl: string): BaseQueryFn`**

RTK Query base query factory. Returns a function compatible with RTK Query's `baseQuery` contract:
```typescript
export function eafBaseQuery(baseUrl: string): BaseQueryFn<
  { url: string; method?: string; body?: unknown; params?: Record<string, unknown> },
  unknown,
  { status: number; message: string; correlationId?: string }
>
```

Internally, this creates an `AxiosInstance` using `createApiClient`. It must retrieve the auth token by calling `useToken()` from `@eaf/auth`. The RTK Query slice does not need to know about tokens at all.

> Implementation note: `eafBaseQuery` uses `useToken()` internally via a closure. The base query factory must be called inside a React component or custom hook to satisfy React's rules of hooks. Document this constraint in a JSDoc comment.

**`EafApiClientOptions`:**
```typescript
export interface EafApiClientOptions {
  baseUrl: string;
  timeout?: number;    // Default: 30000
  retries?: number;    // Default: 2
}
```

Write unit tests with Vitest. Mock `axios` and `@eaf/auth`.

### Acceptance Criteria
- [ ] `createApiClient` injects a Bearer token on every request (verified in unit test)
- [ ] `createApiClient` sets `x-correlation-id` header on every request (verified in unit test)
- [ ] `createApiClient` retries on 503/504 up to 2 times (verified in unit test)
- [ ] `createApiClient` rejects with `AuthError` on 401 (verified in unit test)
- [ ] `eafBaseQuery` returns an RTK-compatible base query function
- [ ] Package builds with no TypeScript errors
- [ ] Unit test coverage ≥ 80%

---

## Issue 5: Implement @eaf/ui-components — layout and feedback primitives

**Labels:** `package`, `phase-1`, `ui`
**Depends on:** #1, #2

### Context
This issue implements the foundational layout and feedback components of `@eaf/ui-components`. These are needed before form, data display, and chart components, because many of those depend on layout primitives like `PageContainer` and feedback components like `LoadingSkeleton`.

### Specification

**Location:** `packages/ui-components/`

**Dependencies:**
```
@fluentui/react-components@^9.0.0   (peer)
react@^18.0.0                        (peer)
```

Implement the following components. Each must be in its own file under `src/components/`. Each must be fully TypeScript-typed with JSDoc on every prop.

**Layout:**

`PageContainer` — wraps page content with consistent max-width, horizontal padding, and vertical spacing. Props: `children`, `title?: string`, `description?: string`, `actions?: ReactNode`.

`SectionCard` — a card container with a subtle border and shadow. Props: `children`, `title?: string`, `padding?: 'small' | 'medium' | 'large'`.

`ContentGrid` — a responsive CSS grid wrapper. Props: `children`, `columns?: 1 | 2 | 3 | 4`, `gap?: 'small' | 'medium' | 'large'`.

`PageHeader` — page title + optional description + optional action area. Props: `title: string`, `description?: string`, `actions?: ReactNode`.

**Feedback:**

`LoadingSkeleton` — animated placeholder. Props: `lines?: number`, `height?: string`, `width?: string`.

`ErrorDisplay` — standardised error state. Props: `title?: string`, `message: string`, `onRetry?: () => void`. Renders an icon, message, and optional retry button.

`ToastNotification` — wraps Fluent UI's toast system. Export both `ToastNotification` component and a `useToast()` hook that exposes `showToast(message, intent)`. Intents: `'success' | 'error' | 'warning' | 'info'`.

`EmptyState` — zero-data state. Props: `title: string`, `description?: string`, `action?: ReactNode`.

`ConfirmDialog` — modal confirmation. Props: `open: boolean`, `title: string`, `message: string`, `confirmLabel?: string`, `cancelLabel?: string`, `onConfirm: () => void`, `onCancel: () => void`, `intent?: 'default' | 'danger'`.

**`src/index.ts`** must re-export every component and hook.

All components must use Fluent UI v9 primitives (`makeStyles`, `tokens`) for styling — no inline styles, no CSS modules.

### Acceptance Criteria
- [ ] All 9 components compile without TypeScript errors
- [ ] Every prop on every component has a JSDoc comment
- [ ] `PageContainer`, `SectionCard`, `LoadingSkeleton`, and `ErrorDisplay` render without errors in a Vitest + jsdom environment
- [ ] `ConfirmDialog` calls `onConfirm` when the confirm button is clicked (unit test)
- [ ] `useToast()` exposes `showToast` function (unit test)
- [ ] Package builds and `dist/index.js` + `dist/index.d.ts` are produced

---

## Issue 6: Implement @eaf/ui-components — form controls

**Labels:** `package`, `phase-1`, `ui`
**Depends on:** #5

### Context
Form control components. These wrap Fluent UI inputs with consistent styling, accessibility attributes, and integration with React Hook Form's `register` API.

### Specification

All form components must be compatible with React Hook Form's `register()` — they must accept and forward `ref`, `name`, `onChange`, and `onBlur` props. Use `React.forwardRef` where needed.

**Components to implement:**

`TextInput` — Props: all standard HTML input attributes, plus `label: string`, `error?: string`, `hint?: string`, `required?: boolean`. Renders the label, input, hint text, and error message as a controlled unit.

`SelectDropdown` — Props: `label: string`, `options: { value: string; label: string }[]`, `placeholder?: string`, `error?: string`, `required?: boolean`, plus RHF-compatible ref/name/onChange/onBlur.

`DatePicker` — wraps Fluent UI's DatePicker. Props: `label: string`, `value?: Date`, `onChange: (date: Date | null) => void`, `error?: string`, `required?: boolean`, `minDate?: Date`, `maxDate?: Date`.

`FormGroup` — layout wrapper for form fields. Props: `children`, `columns?: 1 | 2`. Arranges fields in a consistent grid.

`ValidationMessage` — standalone error/hint text, for use outside of a specific input. Props: `message: string`, `intent: 'error' | 'warning' | 'info'`.

`SubmitButton` — Props: `label: string`, `isLoading?: boolean`, `disabled?: boolean`. Renders a primary button; when `isLoading` is true, shows a spinner and disables interaction.

### Acceptance Criteria
- [ ] All 6 components compile without TypeScript errors
- [ ] All components are exported from `src/index.ts`
- [ ] `TextInput` renders an accessible `<label>` associated with its `<input>` via `htmlFor`/`id` (unit test)
- [ ] `TextInput` renders the `error` string when provided (unit test)
- [ ] `SubmitButton` is disabled and shows loading state when `isLoading={true}` (unit test)
- [ ] All components forward `ref` correctly (verified via `React.forwardRef` usage)

---

## Issue 7: Implement @eaf/ui-components — data display components

**Labels:** `package`, `phase-1`, `ui`
**Depends on:** #5

### Context
Data display components for tables, metrics, and status indicators.

### Specification

`DataTable<T>` — Generic, typed table component. Props:
```typescript
interface DataTableProps<T> {
  data: T[];
  columns: ColumnDef<T>[];
  isLoading?: boolean;        // Renders LoadingSkeleton rows
  totalCount?: number;        // If provided, renders pagination
  page?: number;
  pageSize?: number;
  onPageChange?: (page: number) => void;
  onSortChange?: (sort: SortState) => void;
  emptyMessage?: string;      // Shown when data is empty and not loading
}

interface ColumnDef<T> {
  key: string;
  header: string;
  accessor: (row: T) => ReactNode;
  sortable?: boolean;
  width?: string;
}

interface SortState {
  column: string;
  direction: 'asc' | 'desc';
}
```
When `isLoading` is true, render 5 skeleton rows matching the column count. When `data` is empty and not loading, render `<EmptyState>`.

`StatusBadge` — coloured pill badge. Props: `label: string`, `intent: 'success' | 'warning' | 'error' | 'info' | 'neutral'`.

`MetricCard` — KPI display card. Props: `label: string`, `value: string | number`, `unit?: string`, `trend?: { value: number; direction: 'up' | 'down' }`, `isLoading?: boolean`.

`DefinitionList` — key-value display. Props: `items: { label: string; value: ReactNode }[]`, `columns?: 1 | 2`.

### Acceptance Criteria
- [ ] `DataTable` renders correct number of columns from `columns` prop (unit test)
- [ ] `DataTable` renders `LoadingSkeleton` rows when `isLoading={true}` (unit test)
- [ ] `DataTable` renders `EmptyState` when `data=[]` and `isLoading={false}` (unit test)
- [ ] `DataTable` calls `onSortChange` when a sortable column header is clicked (unit test)
- [ ] `DataTable` calls `onPageChange` when page controls are interacted with (unit test)
- [ ] All components exported from `src/index.ts`
- [ ] No TypeScript errors

---

## Issue 8: Implement @eaf/ui-components — chart wrappers

**Labels:** `package`, `phase-1`, `ui`
**Depends on:** #5

### Context
Thin, typed wrappers around Recharts. These ensure consistent chart styling using EAF design tokens and a consistent API across all applications.

### Specification

**Add dependency:** `recharts@^2.10.0` (peer dependency, not bundled)

Implement three components. Each accepts data and config props and renders the corresponding Recharts chart with EAF default styling (colours from Fluent UI tokens, consistent font, consistent tooltip style, responsive container).

**`LineChartWrapper`:**
```typescript
interface LineChartWrapperProps {
  data: Record<string, unknown>[];
  lines: { dataKey: string; label: string; colour?: string }[];
  xAxisKey: string;
  xAxisLabel?: string;
  yAxisLabel?: string;
  height?: number;               // Default: 300
  isLoading?: boolean;
}
```

**`BarChartWrapper`:**
```typescript
interface BarChartWrapperProps {
  data: Record<string, unknown>[];
  bars: { dataKey: string; label: string; colour?: string }[];
  xAxisKey: string;
  xAxisLabel?: string;
  yAxisLabel?: string;
  layout?: 'vertical' | 'horizontal';  // Default: 'horizontal'
  height?: number;
  isLoading?: boolean;
}
```

**`PieChartWrapper`:**
```typescript
interface PieChartWrapperProps {
  data: { name: string; value: number; colour?: string }[];
  height?: number;
  showLegend?: boolean;           // Default: true
  isLoading?: boolean;
}
```

When `isLoading={true}`, all three components render `<LoadingSkeleton height="300px" />`.

All three must be wrapped in Recharts' `<ResponsiveContainer width="100%">`.

### Acceptance Criteria
- [ ] All three components render without errors when provided with valid data (unit test with mocked Recharts)
- [ ] All three render `LoadingSkeleton` when `isLoading={true}` (unit test)
- [ ] All three are exported from `src/index.ts`
- [ ] `recharts` is listed as a peer dependency, not a direct dependency
- [ ] No TypeScript errors

---

## Issue 9: Implement @eaf/ui-components — chat components

**Labels:** `package`, `phase-1`, `ui`
**Depends on:** #5

### Context
Chat UI components for the optional chat agent integration available in EAF applications.

### Specification

**`ChatPanel`:**
```typescript
interface ChatPanelProps {
  messages: ChatMessageData[];
  onSendMessage: (message: string) => void;
  isLoading?: boolean;       // Agent is responding
  placeholder?: string;
  title?: string;
  onClose?: () => void;      // If provided, renders a close button
}

interface ChatMessageData {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
  actions?: AgentAction[];
}
```
Renders a scrollable message list and a text input with a send button. Auto-scrolls to the latest message. Disables input when `isLoading` is true.

**`ChatMessage`:**
```typescript
interface ChatMessageProps {
  message: ChatMessageData;
}
```
Renders a single message bubble. User messages right-aligned, assistant messages left-aligned. Formats `timestamp` as a relative time string (e.g. "2 minutes ago"). Renders `AgentActionCard` for each item in `actions` if present.

**`AgentActionCard`:**
```typescript
interface AgentAction {
  id: string;
  label: string;
  description?: string;
  onExecute: () => void;
  isExecuting?: boolean;
  isComplete?: boolean;
}

interface AgentActionCardProps {
  action: AgentAction;
}
```
Renders an action card with a label, optional description, and an execute button. When `isExecuting` is true, shows a spinner. When `isComplete` is true, shows a checkmark and disables the button.

### Acceptance Criteria
- [ ] `ChatPanel` renders all messages in `messages` prop (unit test)
- [ ] `ChatPanel` calls `onSendMessage` with the input value when the send button is clicked (unit test)
- [ ] `ChatPanel` disables input when `isLoading={true}` (unit test)
- [ ] `AgentActionCard` calls `onExecute` when the button is clicked (unit test)
- [ ] All three components exported from `src/index.ts`
- [ ] No TypeScript errors

---

## Issue 10: Implement @eaf/shell-layout

**Labels:** `package`, `phase-1`, `ui`
**Depends on:** #5, #6, #7

### Context
`@eaf/shell-layout` provides the application chrome — header, collapsible sidebar navigation, and footer — used by every EAF application. Consuming an application renders `<ShellLayout navConfig={...}>` as its root and gets the chrome for free.

### Specification

**Location:** `packages/shell-layout/`

**Dependencies:** `@fluentui/react-components@^9.0.0` (peer), `react@^18.0.0` (peer), `react-router-dom@^6.0.0` (peer)

**Public API — `src/index.ts` exports:**
```typescript
export { ShellLayout } from './ShellLayout';
export type { NavConfig, NavItem, NavGroup } from './types';
```

**Types:**
```typescript
export interface NavConfig {
  groups: NavGroup[];
  footerItems?: NavItem[];     // Items rendered at the bottom of the sidebar
}

export interface NavGroup {
  label?: string;              // Optional group label
  items: NavItem[];
}

export interface NavItem {
  label: string;
  path: string;                // href for navigation
  icon?: ReactNode;
  external?: boolean;          // If true, opens in new tab and shows external icon
  badge?: string | number;     // Optional badge (e.g. notification count)
}
```

**`ShellLayout` component:**
```typescript
interface ShellLayoutProps {
  navConfig: NavConfig;
  children: ReactNode;
  appName?: string;            // Shown in header alongside EAF branding
  onThemeToggle?: () => void;  // If provided, renders a theme toggle button in the header
}
```

Structure:
```
┌──────────────────────────────────────────────────────┐
│  Header: EAF logo | appName               user menu  │
├────────────────┬─────────────────────────────────────┤
│  Sidebar       │  Content area                       │
│  (collapsible) │  {children}                         │
│                │                                     │
├────────────────┴─────────────────────────────────────┤
│  Footer: © EAF Platform                    version   │
└──────────────────────────────────────────────────────┘
```

The sidebar must be collapsible (icon-only mode when collapsed). Collapse state persists in `localStorage` under the key `eaf-sidebar-collapsed`.

The active nav item is determined by comparing `item.path` against `window.location.pathname` using a prefix match.

Navigation items with `external: true` render an `<a href>` tag. All other items render using React Router's `<Link>` or `<NavLink>`.

**Inter-app navigation loading state:** When the user clicks any navigation link (including external EAF app links), the content area must immediately render a `<LoadingSkeleton lines={6} />` until the next route renders. This handles the blank-screen gap during cross-app navigation.

### Acceptance Criteria
- [ ] `ShellLayout` renders children in the content area (unit test)
- [ ] Sidebar collapses when the toggle button is clicked (unit test)
- [ ] Collapsed state persists to `localStorage` (unit test)
- [ ] Active nav item is highlighted based on current path (unit test)
- [ ] External nav items render as `<a>` tags with `target="_blank"` (unit test)
- [ ] Package builds with no TypeScript errors
- [ ] All exported types are correct and documented

---

## Issue 11: Set up Storybook and write stories for all @eaf/* components

**Labels:** `platform`, `phase-1`, `docs`
**Depends on:** #5, #6, #7, #8, #9, #10

### Context
The deployed Storybook instance is the canonical visual reference for all shared components. Every component must have at least one story before v1.0 can be declared. Storybook also runs accessibility audits via axe-core.

### Specification

**Location:** `apps/storybook/`

**Setup:**
- Vite-based Storybook 8: `@storybook/react-vite`
- Addon: `@storybook/addon-essentials` (controls, actions, docs)
- Addon: `@storybook/addon-a11y` (accessibility auditing via axe-core)
- Configure Storybook to resolve `@eaf/*` packages from the local workspace

**Story requirements for each component:**

Every story file must:
1. Have a `Default` story showing the component with representative data
2. Have stories for each significant variant or state
3. Include `argTypes` so controls work in the Storybook UI
4. Include a `parameters.docs.description.component` string (the component's JSDoc summary)

Minimum required stories per component group:

| Component | Required stories |
|---|---|
| `PageContainer` | Default, with title and actions |
| `SectionCard` | Default, small/medium/large padding |
| `DataTable` | Default with data, loading state, empty state, with pagination |
| `StatusBadge` | All 5 intents |
| `TextInput` | Default, with error, with hint, required |
| `SelectDropdown` | Default, with placeholder, with error |
| `SubmitButton` | Default, loading, disabled |
| `ErrorDisplay` | With retry, without retry |
| `LoadingSkeleton` | Default, multiple lines |
| `ConfirmDialog` | Default (open), danger intent |
| `LineChartWrapper` | Default with data, loading |
| `BarChartWrapper` | Horizontal, vertical, loading |
| `PieChartWrapper` | With legend, without legend, loading |
| `ChatPanel` | With messages, loading (agent responding), empty |
| `AgentActionCard` | Default, executing, complete |
| `ShellLayout` | Full layout with nav, collapsed sidebar |

**Accessibility:** All stories must pass axe-core checks with zero critical or serious violations. The `@storybook/addon-a11y` panel must show green for all stories.

Add an npm script to `apps/storybook/package.json`: `"build-storybook": "storybook build -o dist"`.

### Acceptance Criteria
- [ ] `npm run storybook` starts Storybook and all components are visible
- [ ] Every component listed above has at minimum a `Default` story
- [ ] All required variant stories are present
- [ ] `npm run build-storybook` completes without errors
- [ ] Zero critical or serious axe-core violations across all stories
- [ ] Storybook controls (args) work for all configurable props

---

## Issue 12: Generate components.json manifest

**Labels:** `platform`, `phase-1`, `tooling`
**Depends on:** #11

### Context
`components.json` is a machine-readable index of every component in `@eaf/ui-components` and `@eaf/shell-layout`. It exists primarily for AI coding tools, which use it to discover available components and their props without browsing source files. It is generated automatically and committed to the monorepo root.

### Specification

Create a Node.js script at `scripts/generate-manifest.ts` in the monorepo root.

The script must:
1. Use the TypeScript compiler API (`ts-morph` library recommended) to parse the `src/index.ts` of `@eaf/ui-components` and `@eaf/shell-layout`
2. For each exported component, extract: component name, import path, a description (from the JSDoc `@description` tag or the first JSDoc line), and each prop (name, type string, whether required, description from JSDoc)
3. Write the output to `components.json` in the monorepo root

**Output format:**
```json
{
  "generated": "2025-03-27T00:00:00Z",
  "packages": {
    "@eaf/ui-components": {
      "components": [
        {
          "name": "DataTable",
          "importPath": "@eaf/ui-components",
          "description": "Generic typed table with sorting, pagination, and loading states.",
          "props": [
            { "name": "data", "type": "T[]", "required": true, "description": "The data rows to display" },
            { "name": "columns", "type": "ColumnDef<T>[]", "required": true, "description": "Column definitions" },
            { "name": "isLoading", "type": "boolean", "required": false, "description": "Renders skeleton rows when true" }
          ]
        }
      ]
    },
    "@eaf/shell-layout": {
      "components": [ ]
    }
  }
}
```

Add to the root `package.json` scripts: `"generate:manifest": "tsx scripts/generate-manifest.ts"`.

Add to `turbo.json` tasks so that `generate:manifest` runs after `build`.

The `components.json` file must be committed to the repository and kept current. Add a CI check that runs `generate:manifest` and fails if the output differs from the committed file (i.e. a developer forgot to regenerate after changing a component's props).

### Acceptance Criteria
- [ ] `npm run generate:manifest` runs without errors
- [ ] Output `components.json` contains an entry for every exported component in `@eaf/ui-components` and `@eaf/shell-layout`
- [ ] Each component entry includes at least 3 props with descriptions
- [ ] CI check fails when `components.json` is out of date
- [ ] `components.json` is valid JSON (verify with `JSON.parse`)

---

## Issue 13: Create eaf-app-template scaffold

**Labels:** `platform`, `phase-1`, `scaffold`
**Depends on:** #3, #4, #10, #12

### Context
The scaffold is a GitHub template repository (`eaf-app-template`) that every new EAF application is generated from. It must be fully runnable out of the box. A developer who clones it, runs `npm install` and `npm run dev`, must see a working authenticated application. This is the single most important Phase 1 deliverable.

### Specification

**Create a new repository** configured as a GitHub template (Settings → check "Template repository").

**Complete file structure:**
```
eaf-app-template/
├── src/
│   ├── api/
│   │   ├── baseApi.ts          ← RTK Query base API using eafBaseQuery
│   │   └── generated/          ← Empty dir with .gitkeep + README explaining orval
│   ├── features/
│   │   └── example/
│   │       ├── ExamplePage.tsx ← Working example CRUD page
│   │       └── exampleApi.ts   ← Example RTK Query slice
│   ├── store/
│   │   └── store.ts            ← Configured Redux store
│   ├── app/
│   │   ├── App.tsx             ← AuthProvider + ShellLayout root
│   │   ├── router.tsx          ← React Router routes
│   │   └── navConfig.ts        ← ShellLayout navConfig
│   ├── main.tsx
│   └── vite-env.d.ts
├── .github/
│   ├── copilot-instructions.md ← EAF Copilot instructions
│   └── workflows/
│       └── ci.yml              ← CI pipeline (see Issue #21)
├── CLAUDE.md                   ← EAF Claude instructions
├── .env.example                ← All required env vars with placeholder values
├── .env.local                  ← Git-ignored, populated from .env.example
├── .eslintrc.json
├── .nvmrc                      ← Node 20
├── docker-compose.yml          ← See Issue #19
├── index.html
├── orval.config.ts             ← Pre-configured for EAF APIM OpenAPI endpoint
├── package.json
├── tsconfig.json
├── tsconfig.node.json
├── vite.config.ts
└── README.md
```

**`src/app/App.tsx`:**
```typescript
import { AuthProvider, AuthConfig } from '@eaf/auth';
import { ShellLayout } from '@eaf/shell-layout';
import { Provider } from 'react-redux';
import { BrowserRouter } from 'react-router-dom';
import { store } from '../store/store';
import { navConfig } from './navConfig';
import { AppRouter } from './router';

const authConfig: AuthConfig = {
  clientId: import.meta.env.VITE_AUTH_CLIENT_ID,
  tenantId: import.meta.env.VITE_AUTH_TENANT_ID,
  scopes: [import.meta.env.VITE_AUTH_SCOPE],
};

export default function App() {
  return (
    <Provider store={store}>
      <BrowserRouter>
        <AuthProvider config={authConfig}>
          <ShellLayout navConfig={navConfig} appName={import.meta.env.VITE_APP_NAME}>
            <AppRouter />
          </ShellLayout>
        </AuthProvider>
      </BrowserRouter>
    </Provider>
  );
}
```

**`.env.example`** must include:
```
VITE_APP_NAME=My EAF App
VITE_AUTH_CLIENT_ID=
VITE_AUTH_TENANT_ID=
VITE_AUTH_SCOPE=
VITE_API_BASE_URL=http://localhost:4000
```

**`orval.config.ts`** pre-configured to read from `VITE_API_BASE_URL` and output to `src/api/generated/`.

**`README.md`** must include step-by-step getting started instructions: clone, configure `.env.local`, `npm install`, `npm run dev`.

**`CLAUDE.md` and `.github/copilot-instructions.md`** must be copied verbatim from the files produced in the Architecture Review recommendations (the EAF AI instructions).

### Acceptance Criteria
- [ ] Repository is marked as a GitHub template
- [ ] `npm install` completes without errors with all `@eaf/*` packages resolved
- [ ] `npm run dev` starts the Vite dev server on port 5173
- [ ] `npm run build` produces a `dist/` folder without TypeScript errors
- [ ] `npm run lint` passes with zero errors on the scaffold source
- [ ] `npm run typecheck` passes with zero errors
- [ ] `CLAUDE.md` and `copilot-instructions.md` are present and non-empty
- [ ] `.env.example` documents all required environment variables

---

## Issue 14: Reference application — project setup and authentication

**Labels:** `reference-app`, `phase-1`
**Depends on:** #13

### Context
The reference application (`eaf-reference-app`) is a fully functional EAF application that demonstrates all platform patterns. It is created from the `eaf-app-template` scaffold. This issue covers initial setup, auth wiring, and a working shell.

### Specification

Generate a new repository `eaf-reference-app` from `eaf-app-template`.

The application domain is an **order management system** — a simple domain with enough richness to demonstrate CRUD, data visualisation, chat agent, and error handling.

**Configure the following routes:**
```
/                   → redirect to /orders
/orders             → Orders list page (Issue #15)
/orders/:id         → Order detail page (Issue #15)
/orders/new         → Create order form (Issue #15)
/dashboard          → Analytics dashboard (Issue #16)
/chat               → Chat agent page (Issue #17)
```

**Configure `navConfig.ts`** with appropriate icons (use Fluent UI icons) for each route.

**Implement `GET /health` check** — a simple page at `/health-check` that calls the API health endpoint using RTK Query and displays the result. This confirms auth + API connectivity is working end to end.

**Environment:** configure `.env.local` to point to the local Docker Compose APIM gateway (`http://localhost:4000`) and the dev Entra ID tenant.

The application must authenticate successfully against the dev Entra ID tenant before any other issues in this application are worked.

### Acceptance Criteria
- [ ] `npm run dev` starts and redirects unauthenticated users to Entra ID login
- [ ] After login, the shell renders correctly with the sidebar navigation
- [ ] All defined routes render without a white screen or console errors
- [ ] `/health-check` page renders an API connectivity status
- [ ] `npm run build` and `npm run typecheck` pass with zero errors

---

## Issue 15: Reference application — orders CRUD feature

**Labels:** `reference-app`, `phase-1`
**Depends on:** #14

### Context
Implements the orders CRUD feature — the primary demonstration of RTK Query, form handling, `DataTable`, and the EAF error handling pattern.

### Specification

**API endpoints to integrate (via APIM):**
```
GET    /api/v1/orders?page=&pageSize=&status=&search=   → paginated list
GET    /api/v1/orders/:id                                → single order
POST   /api/v1/orders                                    → create order
PUT    /api/v1/orders/:id                                → update order
DELETE /api/v1/orders/:id                                → delete order
```

**Define the Order type:**
```typescript
interface Order {
  id: string;
  reference: string;
  customerName: string;
  status: 'pending' | 'processing' | 'completed' | 'cancelled';
  totalAmount: number;
  currency: string;
  createdAt: string;
  updatedAt: string;
}
```

**`src/api/ordersApi.ts`** — RTK Query slice with endpoints for all 5 operations. Use `providesTags` and `invalidatesTags` for cache invalidation on mutations.

**`OrdersPage`** — list view using `DataTable` with:
- Columns: reference, customer, status (`StatusBadge`), amount, created date, actions
- Server-side pagination via `onPageChange` → RTK Query arg
- Status filter (SelectDropdown)
- Search input (debounced, 300ms)
- Delete action with `ConfirmDialog`
- Loading state via `isLoading` from RTK Query

**`OrderDetailPage`** — detail view using `DefinitionList` for order fields. Edit button navigates to a pre-populated form.

**`OrderFormPage`** — create/edit form using React Hook Form + Zod. Fields: customerName (required, min 2 chars), status (required), totalAmount (required, positive number), currency (required, 3-char code). On submit, calls the create or update RTK Query mutation. On success, navigates back to `/orders`.

**Error handling:** all three pages must handle API errors via RTK Query's `isError` state, rendering `<ErrorDisplay>` with an appropriate message and a retry action.

### Acceptance Criteria
- [ ] Orders list renders with pagination and loading state
- [ ] Status filter and search filter the results (API params updated)
- [ ] Create form validates all fields with Zod and displays errors inline
- [ ] Create form submits and navigates back to list on success
- [ ] Edit form pre-populates with existing order data
- [ ] Delete triggers `ConfirmDialog` and removes the row on confirmation
- [ ] API errors render `<ErrorDisplay>` (not a blank screen or unhandled exception)
- [ ] All pages pass `npm run typecheck` and `npm run lint`

---

## Issue 16: Reference application — analytics dashboard

**Labels:** `reference-app`, `phase-1`
**Depends on:** #14

### Context
Implements the analytics dashboard demonstrating the Recharts chart wrappers.

### Specification

**API endpoints:**
```
GET /api/v1/analytics/orders-over-time    → { date: string; count: number }[]
GET /api/v1/analytics/revenue-by-month    → { month: string; revenue: number }[]
GET /api/v1/analytics/orders-by-status   → { status: string; count: number }[]
GET /api/v1/analytics/summary            → { totalOrders: number; totalRevenue: number; avgOrderValue: number; pendingOrders: number }
```

**`DashboardPage`** layout:

Top row — 4 × `MetricCard` (total orders, total revenue, average order value, pending orders). Show loading skeleton while `summary` is fetching.

Middle row — `LineChartWrapper` (orders over time, last 30 days) and `BarChartWrapper` (revenue by month, last 6 months), side by side in a `ContentGrid columns={2}`.

Bottom row — `PieChartWrapper` (orders by status) at half width.

All charts must handle `isLoading` and error states. On API error, show `<ErrorDisplay>` in place of the chart.

Date range filter (last 7 / 30 / 90 days) above the charts — changing it updates the API query parameters.

### Acceptance Criteria
- [ ] Dashboard renders all 4 metric cards with loading states
- [ ] All 3 charts render with representative data
- [ ] Date range filter updates the data displayed
- [ ] Loading and error states are handled for every chart and metric
- [ ] Page is responsive — charts reflow on smaller viewport widths

---

## Issue 17: Reference application — chat agent integration

**Labels:** `reference-app`, `phase-1`
**Depends on:** #14

### Context
Implements the chat agent feature using the `ChatPanel` and related components.

### Specification

**API endpoints:**
```
POST /api/v1/chat/messages    → Send a message; returns assistant response
GET  /api/v1/chat/history     → Retrieve message history for the session
```

**`ChatPage`** using `ChatPanel`. Messages persisted in Redux slice (not RTK Query cache — chat history is session-specific and append-only).

**Redux slice `src/features/chat/chatSlice.ts`:**
```typescript
interface ChatState {
  messages: ChatMessageData[];
  isAgentResponding: boolean;
  error: string | null;
}
```

Sending a message must:
1. Immediately append the user message to `messages` in the slice
2. Set `isAgentResponding: true`
3. Call `POST /api/v1/chat/messages` via RTK Query mutation
4. On success, append the assistant response to `messages`, set `isAgentResponding: false`
5. On error, set `error` in the slice and render an error toast via `useToast()`

**Agent actions:** the assistant response may include `actions`. When an `AgentActionCard` is executed, call `POST /api/v1/orders` (create order) with the action's data payload. Show `isExecuting` state during the API call. On success, set `isComplete: true` and show a success toast.

On `ChatPage` mount, call `GET /api/v1/chat/history` and populate initial messages from the response.

### Acceptance Criteria
- [ ] User can type and send a message
- [ ] Assistant response appears after the API call resolves
- [ ] `ChatPanel` shows loading state while agent is responding
- [ ] Agent action cards execute the associated API call
- [ ] Error toast appears on API failure
- [ ] Chat history is loaded on page mount
- [ ] Page passes typecheck and lint

---

## Issue 18: Reference application — logging, error boundaries, and health check

**Labels:** `reference-app`, `phase-1`
**Depends on:** #14

### Context
Implements the cross-cutting observability and resilience requirements: Application Insights telemetry, correlation ID logging, error boundaries, and the health check endpoint.

### Specification

**Application Insights initialisation** in `src/main.tsx`:
```typescript
import { ApplicationInsights } from '@microsoft/applicationinsights-web';

const appInsights = new ApplicationInsights({
  config: { connectionString: import.meta.env.VITE_APPINSIGHTS_CONNECTION_STRING }
});
appInsights.loadAppInsights();
appInsights.trackPageView();

// Attach to window so @eaf/api-client can access it
window.appInsights = appInsights;
```

Add `VITE_APPINSIGHTS_CONNECTION_STRING` to `.env.example` with a blank value (not required locally).

**Error boundary** — create `src/components/AppErrorBoundary.tsx` wrapping the route content area inside `ShellLayout`. On error:
- Report to Application Insights via `appInsights.trackException()`
- Render `<ErrorDisplay title="Something went wrong" message="..." onRetry={() => window.location.reload()} />`

**Structured logging utility** — `src/utils/logger.ts`:
```typescript
export const logger = {
  info: (message: string, properties?: Record<string, unknown>) => void,
  warn: (message: string, properties?: Record<string, unknown>) => void,
  error: (message: string, error?: Error, properties?: Record<string, unknown>) => void,
};
```
Logs to console in development. Sends to Application Insights in production (if `window.appInsights` is present).

**Health check page** at `/health-check` calls `GET /api/v1/health` and `GET /api/v1/health/ready` via RTK Query. Displays: API reachable (boolean), auth token acquired (boolean), readiness status, and the correlation ID from the last request header.

Add `VITE_APPINSIGHTS_CONNECTION_STRING` to `.env.example`.

### Acceptance Criteria
- [ ] Application Insights initialises in `main.tsx` without errors (even when connection string is blank)
- [ ] `AppErrorBoundary` renders `ErrorDisplay` when a child component throws (unit test using a test component that throws)
- [ ] `logger.error` calls `appInsights.trackException` when `window.appInsights` is present (unit test)
- [ ] `/health-check` page renders API and auth status without errors
- [ ] Correlation IDs appear in `x-correlation-id` request headers (verified in browser DevTools — documented in README)

---

## Issue 19: Docker Compose development environment

**Labels:** `platform`, `phase-1`, `infrastructure`
**Depends on:** #13

### Context
The Docker Compose file provides a complete local development environment. Running `docker-compose up` must start everything a developer needs to run an EAF application locally.

### Specification

**Add to the `eaf-app-template` scaffold** (and update `eaf-reference-app` accordingly).

**`docker-compose.yml`** must define the following services:

`db` — SQL Server 2022:
```yaml
db:
  image: mcr.microsoft.com/mssql/server:2022-latest
  environment:
    SA_PASSWORD: "EafDev_Password1"
    ACCEPT_EULA: "Y"
  ports:
    - "1433:1433"
  volumes:
    - db-data:/var/opt/mssql
    - ./docker/db/seed.sql:/docker-entrypoint-initdb.d/seed.sql
```

`apim-gateway` — Azure API Management self-hosted gateway:
```yaml
apim-gateway:
  image: mcr.microsoft.com/azure-api-management/gateway:latest
  environment:
    config.service.auth: "${APIM_GATEWAY_TOKEN}"
    config.service.endpoint: "${APIM_GATEWAY_ENDPOINT}"
  ports:
    - "4000:8080"
  depends_on:
    - db
```

Create `docker/db/seed.sql` with `CREATE DATABASE EafSample` and 10–20 sample orders matching the Order type defined in Issue #15.

Create `docker/db/wait-for-db.sh` — a health check script that polls SQL Server until it accepts connections.

**Update `.env.example`** with:
```
APIM_GATEWAY_TOKEN=
APIM_GATEWAY_ENDPOINT=
```

Add a `README-docker.md` documenting: prerequisites (Docker Desktop), how to obtain the APIM gateway token, how to start and stop the environment, and how to reset the database.

### Acceptance Criteria
- [ ] `docker-compose up` starts both services without errors
- [ ] SQL Server is reachable on `localhost:1433` after startup
- [ ] APIM gateway is reachable on `localhost:4000/health` after startup
- [ ] Seed SQL script runs on first start and creates the sample database and orders
- [ ] `docker-compose down -v` removes volumes cleanly
- [ ] `README-docker.md` covers all setup steps

---

## Issue 20: CI/CD pipeline — packages monorepo

**Labels:** `platform`, `phase-1`, `ci-cd`
**Depends on:** #11, #12

### Context
Automated pipeline for the `eaf-packages` monorepo. Runs on every PR and on merge to `main`. On merge to `main`, publishes changed packages to the internal npm registry.

### Specification

Create `.github/workflows/ci.yml` in the `eaf-packages` repository.

**Trigger:** `pull_request` (all branches) and `push` to `main`.

**Jobs:**

`validate`:
```yaml
- uses: actions/checkout@v4
- uses: actions/setup-node@v4
  with: { node-version-file: '.nvmrc', cache: 'npm' }
- run: npm ci
- run: npx turbo typecheck
- run: npx turbo lint
- run: npx turbo test -- --coverage
- name: Check coverage threshold
  run: npx vitest run --coverage --coverage.thresholds.lines=80
- run: npx turbo build
- name: Verify components.json is current
  run: |
    npm run generate:manifest
    git diff --exit-code components.json || (echo "components.json is out of date. Run npm run generate:manifest." && exit 1)
```

`security`:
```yaml
- run: npm audit --audit-level=high
  continue-on-error: false
```

`publish` (only on push to `main`):
```yaml
- name: Publish changed packages
  run: npx turbo publish --filter='[HEAD^1]'
  env:
    NODE_AUTH_TOKEN: ${{ secrets.NPM_REGISTRY_TOKEN }}
```

Use Turborepo's `--filter='[HEAD^1]'` to publish only packages changed since the last commit.

`storybook`:
```yaml
- run: npx turbo run build-storybook
- uses: actions/upload-artifact@v4
  with:
    name: storybook-dist
    path: apps/storybook/dist
```

### Acceptance Criteria
- [ ] Pipeline runs on pull request creation
- [ ] Pipeline fails if TypeScript errors are present
- [ ] Pipeline fails if lint errors are present
- [ ] Pipeline fails if test coverage drops below 80%
- [ ] Pipeline fails if `components.json` is out of date
- [ ] Pipeline fails if `npm audit` finds High or Critical vulnerabilities
- [ ] Storybook build artifact is uploaded on successful runs
- [ ] Publish job runs only on merge to `main`

---

## Issue 21: CI/CD pipeline — application template

**Labels:** `platform`, `phase-1`, `ci-cd`
**Depends on:** #13

### Context
The application pipeline template is included in `eaf-app-template` and therefore in every application generated from it. It must work for any EAF application with no modification beyond adding environment-specific secrets.

### Specification

**`.github/workflows/ci.yml`** in `eaf-app-template`:

**Trigger:** `pull_request` and `push` to `main`.

**Jobs:**

`validate`:
```yaml
- uses: actions/checkout@v4
- uses: actions/setup-node@v4
  with: { node-version: '20', cache: 'npm' }
- run: npm ci
- run: npm run typecheck
- run: npm run lint
- run: npm run test -- --coverage
- name: Enforce coverage
  run: npx vitest run --coverage --coverage.thresholds.lines=80
- name: Build
  run: npm run build
- name: Bundle size check
  run: |
    BUNDLE_SIZE=$(du -sk dist/assets/*.js | awk '{sum += $1} END {print sum}')
    echo "Bundle size: ${BUNDLE_SIZE}KB"
    [ "$BUNDLE_SIZE" -lt 358 ] || (echo "Bundle exceeds 350KB gzipped limit" && exit 1)
```

`security`:
```yaml
- run: npm audit --audit-level=high
```

`deploy-dev` (only on push to `main`):
```yaml
needs: [validate, security]
environment: dev
steps:
  - uses: actions/checkout@v4
  - uses: azure/login@v1
    with: { creds: '${{ secrets.AZURE_CREDENTIALS }}' }
  - name: Build Docker image
    run: |
      docker build -t ${{ secrets.ACR_REGISTRY }}/app:${{ github.sha }} .
      docker push ${{ secrets.ACR_REGISTRY }}/app:${{ github.sha }}
  - name: Deploy to Dev
    run: az containerapp update --name ${{ secrets.APP_NAME }} --resource-group ${{ secrets.RESOURCE_GROUP }} --image ${{ secrets.ACR_REGISTRY }}/app:${{ github.sha }}
  - name: Smoke test
    run: curl -f https://${{ secrets.APP_HOSTNAME }}/health.json
```

`deploy-prod` (manual trigger only):
```yaml
needs: deploy-dev
environment: production  # Requires manual approval in GitHub environment settings
```

Add a `Dockerfile` to the template:
```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
```

Add `nginx.conf` configured for SPA routing (all paths → `index.html`).

### Acceptance Criteria
- [ ] Pipeline runs on PR creation for a project generated from the template
- [ ] All `validate` steps run and the build produces a `dist/` folder
- [ ] Bundle size check fails when a file is added that inflates the bundle past 350 KB (test by adding a large dummy file)
- [ ] `deploy-dev` job exists and is gated on `validate` and `security`
- [ ] `deploy-prod` job requires manual approval (GitHub environment protection rule documented in README)
- [ ] `Dockerfile` builds successfully
- [ ] `nginx.conf` serves `index.html` for unknown routes (SPA routing)

---

## Issue 22: Bicep IaC — core platform infrastructure

**Labels:** `infrastructure`, `phase-1`
**Depends on:** #1 (repo structure only)

### Context
All Azure infrastructure for the EAF platform is provisioned via Bicep. This issue covers the core shared infrastructure: Container Registry, Application Insights, Key Vault, and the SQL server shared by the reference application. Application-specific resources follow the same pattern.

### Specification

Create a new repository `eaf-infra` with this structure:
```
eaf-infra/
├── modules/
│   ├── container-registry.bicep
│   ├── app-insights.bicep
│   ├── key-vault.bicep
│   ├── sql-server.bicep
│   ├── sql-database.bicep
│   ├── container-app.bicep
│   └── apim.bicep              (see Issue #23)
├── environments/
│   ├── dev.params.json
│   ├── staging.params.json
│   └── prod.params.json
├── main.bicep                   ← Orchestrates all modules
├── README.md
└── .github/workflows/deploy.yml
```

**`main.bicep`** must accept these parameters:
```bicep
param environment string  // 'dev' | 'staging' | 'prod'
param location string = resourceGroup().location
param sqlAdminPassword string  // @secure()
```

**Each module must:**
- Use the environment parameter to apply appropriate SKUs (dev = cheaper, prod = resilient)
- Enable diagnostic settings sending logs to Application Insights
- Use managed identities where applicable (no connection strings with passwords in app config)
- Tag all resources with `{ environment: environment, project: 'eaf', managedBy: 'bicep' }`

**SKU rules:**
| Resource | Dev | Staging/Prod |
|---|---|---|
| Container Registry | Basic | Standard |
| Application Insights | Pay-as-you-go | Pay-as-you-go |
| Key Vault | Standard | Standard |
| SQL Server | n/a (shared) | n/a (shared) |
| SQL Database | Basic (5 DTU) | General Purpose |

**`.github/workflows/deploy.yml`** must:
- Trigger on push to `main`
- Use `az deployment group create` with the appropriate params file
- Require manual approval for production deployments

### Acceptance Criteria
- [ ] `az bicep build main.bicep` compiles without errors
- [ ] All modules are referenced from `main.bicep`
- [ ] `dev.params.json`, `staging.params.json`, and `prod.params.json` exist with all required parameter values (using placeholder secrets)
- [ ] All resources include environment and project tags
- [ ] `README.md` documents how to deploy to each environment and how to add a new application's resources

---

## Issue 23: APIM configuration as code

**Labels:** `infrastructure`, `phase-1`
**Depends on:** #22

### Context
Azure API Management configuration is managed as Bicep in `eaf-infra`. This issue provisions the APIM instance and configures the global policies that enforce JWT validation and logging for all APIs. Application teams add their own API definitions via PR to this repository.

### Specification

**`modules/apim.bicep`** must provision:

1. An APIM instance (Developer tier for dev, Standard v2 for staging/prod)

2. A global inbound policy applied to all APIs:
```xml
<policies>
  <inbound>
    <base />
    <validate-jwt header-name="Authorization" failed-validation-httpcode="401"
                  failed-validation-error-message="Unauthorized">
      <openid-config url="https://login.microsoftonline.com/{tenantId}/v2.0/.well-known/openid-configuration" />
      <audiences><audience>api://eaf-platform</audience></audiences>
    </validate-jwt>
    <set-header name="x-correlation-id" exists-action="skip">
      <value>@(Guid.NewGuid().ToString())</value>
    </set-header>
  </inbound>
  <backend><base /></backend>
  <outbound><base /></outbound>
  <on-error>
    <base />
    <return-response>
      <set-status code="@(context.Response.StatusCode)" reason="@(context.Response.StatusReasonPhrase)" />
      <set-header name="x-correlation-id" exists-action="override">
        <value>@(context.Variables.GetValueOrDefault<string>("correlationId", "unknown"))</value>
      </set-header>
    </return-response>
  </on-error>
</policies>
```

3. A rate limiting policy (100 calls/60 seconds) applied by default to all products

4. Diagnostic settings logging to Application Insights (body logging limited to 8192 bytes)

5. A `reference-app` API product and API definition, importing from the reference application's OpenAPI spec URL

**Parameter:** `apimPublisherEmail` and `apimPublisherName` must be parameters in `main.bicep`.

**`README.md`** must include a section "Adding a new application API" with the exact Bicep snippet an application team must add to `main.bicep` to register their API.

### Acceptance Criteria
- [ ] `az bicep build modules/apim.bicep` compiles without errors
- [ ] Global JWT validation policy is present in the Bicep output
- [ ] Global rate limiting policy is present
- [ ] Diagnostic settings reference the Application Insights instance from `modules/app-insights.bicep`
- [ ] The reference application API product is defined
- [ ] "Adding a new application API" section exists in `README.md` with a working Bicep snippet

---

## Issue 24: Implement @eaf/auth-code-app — Power Apps Code Apps auth adapter

**Labels:** `package`, `phase-1`, `security`, `power-platform`
**Depends on:** #3

### Context

`@eaf/auth-code-app` is an auth adapter package that implements the same public interface as `@eaf/auth` but wraps the Power Apps SDK's identity context instead of MSAL.js. It exists so that an EAF application can be deployed as a Power Apps Code App — or to any other host where MSAL-based auth is unavailable or unnecessary — with a single import change and no modifications to application logic.

This issue implements the adapter pattern established in ADR-006. The public interface must be **identical** to `@eaf/auth`. Any deviation from the interface breaks the host-agnostic contract.

### Background: Power Apps Code Apps

Power Apps Code Apps are a generally available Power Platform application type. They use Vite + React + TypeScript — the same EAF stack — and are deployed via `pac code push` to a Dataverse environment. The Power Apps SDK handles authentication transparently; the application developer does not configure OAuth, manage tokens, or register redirect URIs. Identity is provided by the platform at runtime via the SDK.

Reference: https://learn.microsoft.com/en-us/power-apps/developer/code-apps/overview

### Specification

**Location:** `packages/auth-code-app/` in the `eaf-packages` Turborepo monorepo.

**Dependencies:**
```
@microsoft/powerapps-client@latest   (Power Apps client library for code apps)
react@^18.0.0                        (peer)
```

**Public API — `src/index.ts` must export exactly:**
```typescript
export { AuthProvider } from './AuthProvider';
export { useAuth } from './hooks/useAuth';
export { useToken } from './hooks/useToken';
export type { AuthConfig, AuthUser } from './types';
```

This is **identical** to the exports from `@eaf/auth`. Any application that imports from `@eaf/auth` can switch to `@eaf/auth-code-app` by changing the import path only. No other code changes are required.

**Types — `src/types.ts`:**

The `AuthUser` type must be identical to `@eaf/auth`:
```typescript
export interface AuthUser {
  oid: string;       // Mapped from Power Apps SDK user context — use sub or userId
  name: string;      // Display name from SDK context
  email: string;     // Email from SDK context
  roles: string[];   // Empty array — Power Apps Code Apps do not use Entra ID role claims
                     // Role-based access for Code Apps is enforced at the API (APIM) level
}
```

The `AuthConfig` type is simplified for the Code App context:
```typescript
export interface AuthConfig {
  appName?: string;  // Optional — used for telemetry labelling only
                     // No clientId, tenantId, or scopes — SDK handles all of this
}
```

> **Note:** `AuthConfig` has a different shape from `@eaf/auth` because Code Apps have no configurable auth parameters. This is the only intentional API difference. Applications targeting Code Apps will have a simpler config — this is a feature, not an oversight.

**`AuthProvider` behaviour:**

```typescript
interface AuthProviderProps {
  config?: AuthConfig;
  children: ReactNode;
}
```

- On mount, initialise the Power Apps client library: `await PowerAppsClient.init()`
- Once initialised, retrieve the current user from the SDK context and map to `AuthUser`
- While initialising, render a full-page loading state (identical visual to `@eaf/auth`)
- Provide context value: `{ user: AuthUser, isAuthenticated: boolean, logout: () => void }`
- `logout()` in a Code App context calls the SDK's sign-out method if available, or navigates to the Power Apps home page

**`useAuth()` hook:**
```typescript
// Returns the auth context. Throws if used outside AuthProvider.
// Identical signature to @eaf/auth.
export function useAuth(): { user: AuthUser; isAuthenticated: boolean; logout: () => void }
```

**`useToken()` hook:**
```typescript
// Returns a function that resolves to a token string suitable for calling APIM.
// In the Code Apps context, this obtains an access token via the Power Apps SDK's
// getAccessToken() method for the configured APIM audience.
// If the SDK does not provide a usable token (e.g. connector-only auth), returns null.
export function useToken(): () => Promise<string | null>
```

The `useToken()` implementation must handle two scenarios:

1. **Direct APIM calls:** The Code App is calling EAF's APIM gateway. Use the SDK's `getAccessToken(resource)` where `resource` is the APIM audience. Returns a Bearer token that APIM can validate.

2. **No external token needed:** The Code App uses only Power Platform connectors and does not call APIM directly. `useToken()` returns a function that resolves to `null`. `@eaf/api-client` will omit the Authorization header when the token is null — this is existing behaviour, no change needed in `@eaf/api-client`.

The scenario is determined by whether `VITE_API_BASE_URL` is set in the environment. If it is, attempt token acquisition. If not, return null.

**`src/utils/powerAppsClient.ts`** — encapsulates all direct Power Apps SDK calls. This file is the only place in the package that imports from `@microsoft/powerapps-client`. If the SDK API changes, only this file needs updating.

```typescript
// Internal utility — not exported from index.ts
export async function initializeSdk(): Promise<void>
export function getCurrentUser(): PowerAppsUser | null
export async function getToken(resource?: string): Promise<string | null>
export function signOut(): void
```

**What this package must NOT do:**

- Must not import from `@azure/msal-browser`
- Must not configure OAuth redirect URIs
- Must not manage token storage (the SDK handles this)
- Must not expose any Power Apps SDK types in its public API surface — all public types are EAF-defined

**Testing approach:**

Mock `@microsoft/powerapps-client` entirely in all unit tests. Do not attempt real SDK calls in the test environment. The SDK is only available at runtime inside the Power Apps platform.

```typescript
// vitest.config.ts
export default {
  test: {
    alias: {
      '@microsoft/powerapps-client': './src/__mocks__/powerAppsClient.ts'
    }
  }
}
```

Provide a `src/__mocks__/powerAppsClient.ts` that exports a realistic stub of the SDK with configurable test user data.

**Local development note:**

The Power Apps SDK is only functional when the app is running inside the Power Apps runtime. For local development outside Power Apps, `@eaf/auth-code-app` must detect that the SDK is unavailable and fall back to a mock identity (from `VITE_DEV_USER_*` environment variables) rather than throwing. Document this behaviour clearly in the package README.

```
# .env.local for Code App development outside Power Apps runtime
VITE_DEV_USER_NAME="Dev User"
VITE_DEV_USER_EMAIL="dev@example.com"
VITE_DEV_USER_OID="dev-user-oid-local"
```

### Acceptance Criteria
- [ ] Package is in `packages/auth-code-app/` in the Turborepo monorepo and builds cleanly with `npx turbo build`
- [ ] Public API surface (`AuthProvider`, `useAuth`, `useToken`, `AuthConfig`, `AuthUser`) is identical in shape to `@eaf/auth` except for `AuthConfig` which is simplified — difference is documented in README
- [ ] `useAuth()` throws a descriptive error when called outside `<AuthProvider>` (unit test)
- [ ] `useToken()` returns `null` when `VITE_API_BASE_URL` is not set (unit test with mock SDK)
- [ ] `useToken()` returns a token string when `VITE_API_BASE_URL` is set and the mock SDK returns a token (unit test)
- [ ] `AuthProvider` renders the loading state before SDK initialisation completes (unit test)
- [ ] `AuthProvider` renders children after SDK initialisation completes with a valid user (unit test)
- [ ] `AuthProvider` renders an error state if SDK initialisation fails (unit test)
- [ ] Local development fallback renders correctly when `VITE_DEV_USER_NAME` is set and SDK is unavailable (unit test)
- [ ] No imports of `@azure/msal-browser` anywhere in the package
- [ ] No Power Apps SDK types in the exported public API (verified by TypeScript type exports)
- [ ] Unit test coverage ≥ 80%
- [ ] README documents: package purpose, usage, AuthConfig difference from `@eaf/auth`, local development setup, and Power Platform DLP requirements for APIM calls
- [ ] Package added to Turborepo monorepo with correct `package.json` including `peerDependencies` for React
