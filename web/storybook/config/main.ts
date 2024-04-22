import path from 'node:path';
import type { StorybookConfig } from '@storybook/nextjs';

const config: StorybookConfig = {
  stories: [`../stories/**/*.stories.tsx`],
  addons: [`@storybook/addon-essentials`],
  framework: `@storybook/nextjs`,
  staticDirs: [`../../dash/app/public`],
  webpackFinal: async (config) => {
    if (config.resolve) {
      config.resolve.alias = {
        ...config.resolve.alias,
        '@site': path.resolve(__dirname, `../../site`),
      };
    }
    return config;
  },
};
export default config;
