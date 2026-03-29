import { ESLint } from 'eslint';
import { describe, it, expect, beforeAll } from 'vitest';
import path from 'path';

const pkgRoot = path.resolve(__dirname, '..');

let eslint: ESLint;

beforeAll(() => {
  eslint = new ESLint({
    useEslintrc: false,
    overrideConfigFile: path.join(pkgRoot, 'index.js'),
    resolvePluginsRelativeTo: pkgRoot,
  });
});

describe('@eaf/eslint-config rules', () => {
  it('no-explicit-any fires on explicit any type', async () => {
    const results = await eslint.lintFiles([
      path.join(pkgRoot, 'test/fixtures/no-explicit-any.tsx'),
    ]);
    const ruleIds = results[0].messages.map((m) => m.ruleId);
    expect(ruleIds).toContain('@typescript-eslint/no-explicit-any');
  });

  it('exhaustive-deps warns on missing useEffect dependency', async () => {
    const results = await eslint.lintFiles([
      path.join(pkgRoot, 'test/fixtures/exhaustive-deps.tsx'),
    ]);
    const ruleIds = results[0].messages.map((m) => m.ruleId);
    expect(ruleIds).toContain('react-hooks/exhaustive-deps');
  });

  it('no-console warns on console.log', async () => {
    const results = await eslint.lintFiles([
      path.join(pkgRoot, 'test/fixtures/console-log.ts'),
    ]);
    const ruleIds = results[0].messages.map((m) => m.ruleId);
    expect(ruleIds).toContain('no-console');
  });
});
