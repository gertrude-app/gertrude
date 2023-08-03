const withMarkdoc = require(`@markdoc/next.js`);
const transpileModules = require(`next-transpile-modules`);
const withTranspiled = transpileModules([
  `@shared/datetime`,
  `@shared/string`,
  `@shared/components`,
  `@site/components`,
]);

/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  pageExtensions: [`tsx`, `md`],
  swcMinify: true,
  eslint: { ignoreDuringBuilds: true },
  experimental: {
    newNextLinkBehavior: true,
    scrollRestoration: true,
  },
};

module.exports = withMarkdoc()(withTranspiled(nextConfig));
