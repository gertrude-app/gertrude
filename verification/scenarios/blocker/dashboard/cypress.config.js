const dashPort = process.env.DASH_PORT;

if (!dashPort) {
  throw new Error(`DASH_PORT is required`);
}

module.exports = {
  video: false,
  defaultCommandTimeout: 15000,
  pageLoadTimeout: 60000,
  e2e: {
    baseUrl: `http://localhost:${dashPort}`,
    specPattern: `e2e/**/*.cy.js`,
    supportFile: false,
  },
  viewportWidth: 1024,
  viewportHeight: 800,
};
