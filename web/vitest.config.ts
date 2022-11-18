/// <reference types="vitest" />
import { configDefaults, defineConfig } from 'vitest/config';

process.env.VITE_GRAPHQL_ENDPOINT = ``;

export default defineConfig({
  test: {
    exclude: [...configDefaults.exclude, `storybook/*`, `dash/app/build/*`, `site/*`],
  },
});
