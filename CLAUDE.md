# EAF Project Context

This is a standalone React application built on the **Enterprise Application Framework (EAF)**. It is one of several independently deployed applications that share a common platform layer.

---

## Stack

| Concern | Tool |
|---|---|
| Framework | React 18 + TypeScript 5 |
| Build | Vite |
| State — server data | RTK Query (Redux Toolkit) |
| State — UI/app | Redux Toolkit slices |
| State — forms | React Hook Form + Zod |
| API client | `@eaf/api-client` |
| Components | `@eaf/ui-components` |
| Layout / chrome | `@eaf/shell-layout` |
| Auth | `@eaf/auth` |
| Styling | Fluent UI v9 design tokens (via `@eaf/ui-components`) |

---

## Hard Rules

These are non-negotiable. Do not deviate from them.

**Data fetching**
- All API calls use RTK Query. No raw `fetch`, `axios`, or `useEffect`-based data fetching.
- Define endpoints in `src/api/`. Use `eafBaseQuery` from `@eaf/api-client` as the base query.
- If generated types exist in `src/api/generated/`, use them. Do not redefine types that already exist.

**State**
- Server data lives in RTK Query cache — never duplicated into Redux slices.
- UI state (modals, filters, selections) lives in Redux Toolkit slices.
- Form state lives in React Hook Form. Form field values do not go in Redux.

**Authentication**
- Use `useAuth()` and `useToken()` from `@eaf/auth` exclusively.
- Never import or configure MSAL directly. Never write a custom auth or token flow.

**Components**
- Check `@eaf/ui-components` before building any new UI element. Use the library component if one exists.
- `<ShellLayout>` from `@eaf/shell-layout` is the application root. Do not build custom layout or navigation chrome.
- Raw Fluent UI components are acceptable only when `@eaf/ui-components` has no equivalent — document the exception.

**API communication**
- All backend calls go through Azure APIM. No direct backend URLs in frontend code.
- The base URL is read from `import.meta.env.VITE_API_BASE_URL`. Never hardcode URLs.

**Code quality**
- TypeScript strict mode is on. No `any`, no `@ts-ignore` without an explanatory comment.
- No `.js` or `.jsx` files. Everything is TypeScript.
- Errors from API calls are handled via RTK Query's `isError` / `error` state. No silent catch blocks.

---

## Patterns to Follow

When adding a new feature, follow this structure:

```
src/
  api/
    featureApi.ts        ← RTK Query slice for this feature
    generated/           ← Auto-generated types from OpenAPI (do not hand-edit)
  features/
    featureName/
      FeaturePage.tsx    ← Route-level component
      FeatureForm.tsx    ← React Hook Form component
      featureSlice.ts    ← Redux slice for local UI state (if needed)
      components/        ← Feature-specific sub-components
```

RTK Query slice pattern:
```typescript
import { createApi } from '@reduxjs/toolkit/query/react';
import { eafBaseQuery } from '@eaf/api-client';

export const featureApi = createApi({
  reducerPath: 'featureApi',
  baseQuery: eafBaseQuery(import.meta.env.VITE_API_BASE_URL),
  endpoints: (builder) => ({
    getItems: builder.query<Item[], void>({ query: () => '/items' }),
    createItem: builder.mutation<Item, CreateItemRequest>({
      query: (body) => ({ url: '/items', method: 'POST', body }),
    }),
  }),
});
```

Form pattern:
```typescript
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';

const schema = z.object({ name: z.string().min(1) });

function FeatureForm({ onSubmit }: Props) {
  const { register, handleSubmit, formState: { errors } } = useForm({
    resolver: zodResolver(schema),
  });
  return <form onSubmit={handleSubmit(onSubmit)}>...</form>;
}
```

---

## What Not to Build

- No custom login pages, token handlers, or session management
- No custom layout, header, sidebar, or footer
- No direct database access or backend-for-frontend patterns
- No cross-application API calls from the frontend — go via the application's own API
- No shared state between this app and other EAF applications

---

## Reference

- Component catalogue: `@eaf/ui-components` — see `components.json` or the deployed Storybook
- Auth API: `@eaf/auth` — `AuthProvider`, `useAuth()`, `useToken()`
- API client: `@eaf/api-client` — `eafBaseQuery`, `createApiClient()`
- Full architecture: `EAF-Technical-Design-Specification-v0.2.md`
