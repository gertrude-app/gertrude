/** @type {import('next').NextConfig} */

const nextConfig = {
  output: `export`,
  reactStrictMode: true,
  pageExtensions: [`tsx`, `md`],
  eslint: { ignoreDuringBuilds: true },
  transpilePackages: [
    `@shared/datetime`,
    `@shared/string`,
    `@shared/components`,
    `@shared/tailwind`,
  ],
  experimental: {
    scrollRestoration: true,
  },
};

module.exports = nextConfig;
