import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

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
  plugins: [react()],
});
