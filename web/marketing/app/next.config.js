const transpileModules = require(`next-transpile-modules`);
const withTranspiled = transpileModules([
  `@shared/datetime`,
  `@shared/components`,
  `@marketing/components`,
]);

/** @type {import('next').NextConfig} */
const nextConfig = {
  eslint: {
    ignoreDuringBuilds: true,
  },
  reactStrictMode: true,
  swcMinify: true,
  experimental: {
    newNextLinkBehavior: true,
    scrollRestoration: true,
  },
};

module.exports = withTranspiled(nextConfig);
