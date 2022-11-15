module.exports = {
  stories: [`../src/**/*.stories.@(ts|tsx)`],
  addons: [
    `@storybook/addon-links`,
    { name: `@storybook/addon-essentials`, options: { docs: false } },
    `@storybook/addon-interactions`,
  ],
  framework: `@storybook/react`,
  core: {
    builder: `@storybook/builder-vite`,
  },
  features: {
    buildStoriesJson: true,
  },
};
