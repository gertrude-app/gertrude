import { defineConfig } from 'cypress';

export default defineConfig({
  video: true,
  e2e: { baseUrl: `http://localhost:8081` },
  viewportWidth: 1024,
  viewportHeight: 800,
});
