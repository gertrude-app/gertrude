/** @type {import('next').NextConfig} */

const nextConfig = {
  reactStrictMode: true,
  pageExtensions: [`tsx`, `md`],
  eslint: { ignoreDuringBuilds: true },
  transpilePackages: [
    `@shared/datetime`,
    `@shared/string`,
    `@shared/components`,
    `@shared/tailwind`,
  ],
  async headers() {
    return [
      {
        source: `/(.*)`,
        headers: [
          { key: `X-Frame-Options`, value: `DENY` },
          { key: `Content-Security-Policy`, value: `frame-ancestors 'none'` },
        ],
      },
    ];
  },
  async redirects() {
    return [
      redir(`/support`, `/contact`, 301),
      redir(`/docs/keeping-users-safe`, `/docs/keeping-children-safe`, 301), // parent rename
      redir(`/docs`, `/docs/getting-started`, 302),
      // macos app
      redir(`/app-redir/connect/more-info`, `/docs/getting-started`, 301),
      redir(`/app-redir/connect/contact-support`, `/contact`, 301),
      // onboarding
      redir(`/start`, `https://parents.gertrude.app/signup`, 302),
      redir(`/cu-v`, `https://youtu.be/Z_kC6ZfXZDU`, 302), // create macos user, ventura or later
      redir(`/cu-b`, `https://youtu.be/FFFOF3BmSos`, 302), // create macos user, big sur or monterey
      redir(`/cu-c`, `https://youtu.be/FFFOF3BmSos`, 302), // create macos user, catalina
      redir(`/du-v`, `https://youtu.be/Sq0baQ4Ze6o`, 302), // demote admin user, ventura or later
      redir(`/du-b`, `https://youtu.be/tT3wowZ3BZ8`, 302), // demote admin user, big sur or monterey
      redir(`/du-c`, `https://youtu.be/tT3wowZ3BZ8`, 302), // demote admin user, catalina
      redir(`/su-v`, `https://youtu.be/lAoeKEFy9Zw`, 302), // switch to non-admin, ventura or later
      redir(`/su-b`, `https://youtu.be/jhufHnF6nEI`, 302), // switch to non-admin, big sur or monterey
      redir(`/su-c`, `https://youtu.be/jhufHnF6nEI`, 302), // switch to non-admin, catalina
      redir(`/a-c`, `https://parents.gertrude.app/children`, 302),
    ];
  },
};

function redir(source, destination, statusCode) {
  return { source, destination, statusCode };
}

module.exports = nextConfig;
