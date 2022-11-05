/// <reference types="vitest" />
import { configDefaults, defineConfig } from 'vitest/config';

process.env.SNOWPACK_PUBLIC_GRAPHQL_ENDPOINT = ``;

export default defineConfig({
  test: {
    exclude: [
      ...configDefaults.exclude,
      `storybook/*`,
      `dash/app/build/*`,
      `marketing/*`,
    ],
  },
});
