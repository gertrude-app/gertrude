import { mergeConfig } from 'vite';

module.exports = {
  async viteFinal(config, { configType }) {
    return mergeConfig(config, {
      // fix next/link issue with process.env not defined (build only)
      // https://github.com/storybookjs/storybook/issues/18920#issuecomment-1310273755
      // check if still necessary when upgrading to next 13
      define: { 'process.env': {} },
    });
  },
  stories: [`../src/**/*.stories.@(ts|tsx)`],
  addons: [
    `@storybook/addon-links`,
    { name: `@storybook/addon-essentials`, options: { docs: false } },
    `@storybook/addon-interactions`,
  ],
  framework: `@storybook/react-vite`,
  features: {
    buildStoriesJson: true,
  },
};
