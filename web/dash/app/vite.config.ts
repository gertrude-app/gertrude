import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';

// https://vitejs.dev/config/
export default defineConfig({
  server: {
    host: `localhost`,
    port: 8081,
    strictPort: true,
    open: false,
  },
  build: {
    outDir: `build`,
  },
  preview: {
    port: 8081,
  },
  define: {
    'process.env.STORYBOOK_SCREENSHOT_TESTING': `false`,
  },
  plugins: [react()],
});
