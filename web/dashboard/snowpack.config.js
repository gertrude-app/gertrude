// @see: https://www.snowpack.dev/reference/configuration
/** @type {import("snowpack").SnowpackUserConfig } */
module.exports = {
  mount: {
    src: `/`,
  },
  plugins: [
    `@snowpack/plugin-postcss`,
    `@snowpack/plugin-dotenv`,
    `@snowpack/plugin-react-refresh`,
  ],
  packageOptions: {
    types: true,
  },
  devOptions: {
    port: 8081,
    open: `none`,
    tailwindConfig: `./tailwind.config.js`,
  },
  buildOptions: {},
};
