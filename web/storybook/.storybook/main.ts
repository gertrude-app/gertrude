import { StorybookConfig } from '@storybook/nextjs';

module.exports = {
  stories: [`../src/**/*.stories.@(ts|tsx)`],
  addons: [
    `@storybook/addon-links`,
    { name: `@storybook/addon-essentials`, options: { docs: false } },
    `@storybook/addon-interactions`,
    `storybook-tailwind-dark-mode`,
  ],
  framework: `@storybook/nextjs`,
  features: {
    buildStoriesJson: true,
  },
  staticDirs: [`../../dash/app/public`, `../../site/public`],
};
