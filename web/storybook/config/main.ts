import path from 'node:path';
import { fileURLToPath } from 'node:url';
import type { StorybookConfig } from '@storybook/nextjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const config: StorybookConfig = {
  stories: [`../stories/**/*.stories.tsx`],
  addons: [],
  framework: `@storybook/nextjs`,
  staticDirs: [`../../dash/app/public`],
  webpackFinal: async (config) => {
    if (config.resolve) {
      config.resolve.alias = {
        ...config.resolve.alias,
        '@site': path.resolve(__dirname, `../../site`),
        '@/public': path.resolve(__dirname, `../../site/public`),
        '@': path.resolve(__dirname, `../../site`),
      };
    }
    return config;
  },
};
export default config;
