/// <reference types="vitest" />
import { configDefaults, defineConfig } from 'vitest/config';

process.env.VITE_API_ENDPOINT = `https://not-real-api.com`;
process.env.VITE_TURNSTILE_SITEKEY = ``;
process.env.TZ = `UTC`;

export default defineConfig({
  test: {
    exclude: [...configDefaults.exclude, `storybook/*`, `dash/app/build/*`, `site/*`],
  },
});
