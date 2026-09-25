# Gertrude Account

`web/account` is a work-in-progress, ground-up rewrite and eventual replacement for
`web/dash`.

Dashboard was originally built only for the Gertrude Mac app. As Gertrude expanded to
Blocker, Podcasts, Music, and many more features, Dashboard became bloated, visually poor,
sprawling, and difficult to reason about or maintain.

Account is a fresh, cohesive experience for a connected Gertrude account across apps.
Build it on the shared UI in `web/ui` and the new Account domain in `swift/api`, rather
than carrying forward Dashboard's architecture or design by default.

## Signup

- Signup and email verification use the Account PairQL domain, delegating to the existing
  signup resolvers. Verification signs in and lands on `/people`; onboarding and device
  claims are not part of this flow yet.
- Production builds require `VITE_TURNSTILE_SITEKEY`, with the Account hostname allowed in
  Cloudflare and the matching API secret configured. Missing configuration disables
  signup. Vite development mode skips the widget; the local API also skips verification.
- Verification and existing-account emails use the API's `ACCOUNT_DASHBOARD_URL`, not a
  URL supplied by the browser. Keep it pointed at this task's Account server locally.
