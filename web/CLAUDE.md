# Gertrude Web Monorepo

Parental controls apps web monorepo. **Tech:** pnpm workspaces, nx, TypeScript, React,
Next.js, Vite, Tailwind.

## Notes

- Never leave comments in code, unless something is extremely non-obvious.

## Main Apps

- **`site/`** — Marketing site + docs (Next.js, port varies)
- **`dash/app/`** — Parent admin dashboard (Vite SPA, http://localhost:8081)
- **`appviews/`** — Web views embedded in macOS app via webviews (Vite)
- **`admin/`** — Internal reporting/admin backend (Next.js, port 4242)
- **`storybook/`** — Component library/documentation

## Key Packages

- **`dash/*`** — Dashboard-specific libs (components, types, datetime, keys, utils,
  ambient types, block-rules)
- **`shared/*`** — Cross-app libs (components, datetime, tailwind preset, ts-utils,
  string)

## Quick Commands

```bash
# Testing & QA
just test              # Run unit tests (vitest)
just cy-run            # Dashboard e2e tests
just smoke-run         # Smoke tests
just check             # Lint + format-check + typecheck + test
just fix               # Format + lint-fix
just typecheck         # Type check all packages (nx)

# Build
just build-dash        # Build dashboard
just build-site        # Build marketing site
just appviews          # Build & generate appviews code
```
