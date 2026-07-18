# Gertrude Web Monorepo

Parental controls apps web monorepo. **Tech:** pnpm workspaces, nx, TypeScript, React,
Next.js, Vite, Tailwind.

## Notes

- Never leave comments in code, unless something is extremely non-obvious.
- Use `const ComponentName: React.FC<Props> = () => ...` pattern for React components.

## Main Apps

- **`site/`** — Marketing site + docs (Next.js, port varies)
- **`dash/app/`** — Parent admin dashboard (Vite SPA)
- **`account/`** — WIP replacement for the parent dashboard (Vite SPA)
- **`appviews/`** — Web views embedded in macOS app via webviews (Vite)
- **`supervise/`** — Web UI only for external Tauri iOS device supervision tool
- **`admin/`** — Internal reporting/admin backend (Next.js)
- **`storybook/`** — Legacy component and app documentation
- **`storybook-v2/`** — Storybook for Account and the shared UI package

## Marketing Site

- When working on design-related tasks, read `./site/docs/design.md`.
- When asked to run or design a usability/UX eval of the site, read
  `./site/docs/usability-personas.md` (the marketing persona set; it uses the shared
  method in `../.agents/skills/usability-eval/SKILL.md`).

## Key Packages

- **`ui/`** — Shared components and UI primitives used by Account and Storybook v2
- **`dash/*`** — Dashboard-specific libs (components, types, datetime, keys, utils,
  ambient types, block-rules)
- **`shared/*`** — Cross-app libs (components, datetime, tailwind preset, ts-utils,
  string)

## Quick Commands

```bash
# Local development
just account              # Run Account
just storybook-v2         # Run Storybook v2

# Testing & QA
just test                 # Run unit tests (vitest)
just cy-run               # Dashboard e2e tests
just smoke-run            # Smoke tests
just check                # Lint, format-check, typecheck, test, and app builds
just fix                  # Format + lint-fix
just typecheck            # Type check all packages (nx)
just update-ui-screenshots

# Build
just build-account
just build-storybook-v2
just build-dash
just build-site
```
