import { defineConfig } from 'vite';
import path from 'path';

process.env.SNOWPACK_PUBLIC_GRAPHQL_ENDPOINT = ``;

export default defineConfig({
  resolve: {
    alias: {
      '@shared': path.resolve(__dirname, `./src/components/shared`),
      '@dashboard': path.resolve(__dirname, `./src/components/shared/dashboard`),
    },
  },
});
