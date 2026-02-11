import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';

// https://vitejs.dev/config/
const port = parseInt(process.env.PORT ?? `8081`);

export default defineConfig({
  server: {
    host: `localhost`,
    port,
    strictPort: true,
    open: false,
  },
  build: {
    outDir: `build`,
  },
  preview: {
    port,
  },
  define: {
    'process.env.STORYBOOK_SCREENSHOT_TESTING': `false`,
  },
  plugins: [react()],
});
