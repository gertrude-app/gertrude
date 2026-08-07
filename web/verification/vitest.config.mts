import { defineConfig } from 'vitest/config';

// Standalone config so the oracle is run explicitly by the verification harness and is NOT
// picked up by the workspace unit run (`just test`, which matches *.test/*.spec only).
// `root` is pinned to this dir so the include glob resolves regardless of invocation cwd.
export default defineConfig({
  root: import.meta.dirname,
  test: {
    include: [`**/*.oracle.ts`],
  },
});
