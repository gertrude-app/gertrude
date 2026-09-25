# iOS pairing in Account

The parent-facing claim pages for Blocker connection, Blocker supervision, Podcasts, and Music live at `/connect/:flow/:code` in Account. Existing iOS apps keep their current short links and API claim-code contracts; the API's short-link redirect decides whether to send parents to Dashboard or Account.

## Deployment order

1. Deploy Account with `VITE_API_ENDPOINT` and `VITE_TURNSTILE_SITEKEY` set at build time. The Turnstile **site key** must correspond to the API's `CLOUDFLARE_SECRET` and allow the Account hostname. Production signup requires a valid Turnstile token. Check the `/signup`, `/verify-signup-email/:token`, and `/login?redirect=/connect/blockerConnect/123456` routes before cutover.
2. Deploy the API with its existing `ACCOUNT_DASHBOARD_URL` pointing to that Account deployment. `ACCOUNT_PAIRING_REDIRECTS_ENABLED` is **off by default**; while off, all public pairing short links continue to land on Dashboard.
3. Run the existing cross-surface smoke scenarios with a booted simulator (see `verification/README.md`): `just verify-blocker e2e`, `just verify-podcasts e2e`, `just verify-music e2e`. **These currently drive Dashboard, not Account**, and are not run by CI. Before cutover, also test each new Account funnel manually against a real app-issued code, including signup/verification, returning login and magic link, assignment, and supervision status.
4. Set `ACCOUNT_PAIRING_REDIRECTS_ENABLED=true` on the API and deploy/restart it. This moves all four pairing short-link types to Account; the app-issued code and claim APIs do not change. Unset the variable and restart to roll back public redirects without migrating data.

An existing claimed code resumes only for its owning account. An unclaimed code still expires; a bound-but-unclaimed code finalizes on lookup, matching the Dashboard recovery behavior. New people are created in the same transaction as their device claim, so a failed claim does not leave an unassigned person behind.
