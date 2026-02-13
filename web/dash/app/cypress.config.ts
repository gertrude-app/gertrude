import { defineConfig } from 'cypress';

export default defineConfig({
  video: true,
  e2e: { baseUrl: `http://localhost:${process.env.DASH_PORT || 8081}` },
  viewportWidth: 1024,
  viewportHeight: 800,
});
