# @eaf/eslint-config

Shared ESLint configuration for all EAF applications and packages.

## Usage

Install the package and its peer dependencies:

```bash
npm install --save-dev @eaf/eslint-config eslint @typescript-eslint/eslint-plugin @typescript-eslint/parser eslint-plugin-react eslint-plugin-react-hooks eslint-plugin-jsx-a11y eslint-plugin-import
```

Extend the config in your `.eslintrc` file:

```json
{
  "extends": ["@eaf/eslint-config"]
}
```

Or in `.eslintrc.js`:

```js
module.exports = {
  extends: ['@eaf/eslint-config'],
};
```

## Rules Enforced

| Category | Rule | Severity |
|---|---|---|
| TypeScript | `@typescript-eslint/no-explicit-any` | error |
| TypeScript | `@typescript-eslint/no-unused-vars` (ignores `_`-prefixed args) | error |
| React | `react-hooks/rules-of-hooks` | error |
| React | `react-hooks/exhaustive-deps` | warn |
| Accessibility | `jsx-a11y/anchor-is-valid` | error |
| General | `no-console` (allows `warn` and `error`) | warn |
| Imports | `import/no-restricted-paths` (prevents cross-app coupling) | error |

Notable rules that are **turned off**:
- `react/react-in-jsx-scope` — not needed with React 17+ JSX transform
- `react/prop-types` — TypeScript handles prop types
- `@typescript-eslint/explicit-module-boundary-types` — too noisy for internal code

## Overriding Rules

Add a `rules` block in your own `.eslintrc` to override any rule:

```json
{
  "extends": ["@eaf/eslint-config"],
  "rules": {
    "no-console": "off"
  }
}
```
