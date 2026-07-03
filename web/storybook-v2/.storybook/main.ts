import tailwindcss from '@tailwindcss/vite';
import { mergeConfig } from 'vite';
import type { StorybookConfig } from '@storybook/tanstack-react';

const config: StorybookConfig = {
  stories: [`../../ui/src/**/*.stories.@(ts|tsx)`],
  staticDirs: [`../../account/public`],
  addons: [],
  framework: `@storybook/tanstack-react`,
  viteFinal: (baseConfig) =>
    mergeConfig(baseConfig, {
      plugins: [tailwindcss()],
    }),
};

export default config;
