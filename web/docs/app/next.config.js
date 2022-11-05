const withMarkdoc = require(`@markdoc/next.js`);
const transpileModules = require(`next-transpile-modules`);
const withTranspiled = transpileModules([`@shared/components`, `@shared/datetime`]);

/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  pageExtensions: [`ts`, `tsx`, `md`],
  eslint: {
    ignoreDuringBuilds: true,
  },
  swcMinify: true,
  experimental: {
    newNextLinkBehavior: true,
    scrollRestoration: true,
  },
};

module.exports = withMarkdoc()(withTranspiled(nextConfig));
