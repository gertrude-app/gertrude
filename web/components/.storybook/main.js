module.exports = {
  stories: [`../src/**/*.stories.@(ts|tsx)`],
  addons: [
    `@storybook/addon-links`,
    `@storybook/addon-interactions`,
    { name: `@storybook/addon-essentials`, options: { docs: false } },
  ],
  framework: `@storybook/react`,
  core: {
    builder: `@storybook/builder-vite`,
  },
};
