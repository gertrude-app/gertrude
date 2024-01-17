# Gertrude web monorepo

## Apps

- `dash/app` - web admin dashboard (vite SPA)
- `site/app` - main site: marketing and docs (next.js app)
- `docs/app` - docs site (next.js app)
- `storybook` - storybook for all react components

## Packages

- `dash/ambient` - ambient typescript types for dashboard (pkg name `@types/dash-ambient`)
- `dash/components` - react components for dashboard
- `dash/datetime` - date/time fns for dashboard
- `dash/keys` - logic/domain knowledge around _keys_
- `dash/types` - shared types (non-ambient) for dashboard
- `dash/utils` - misc helpers (string, etc.) for dashboard
- `site/components` - react components for site
- `shared/components` - react components used by more than one app
- `shared/datetime` - date/time fns used by more than one app
- `shared/tailwind` - shared tailwind preset
- `shared/ts-utils` - shared typescript utilities

## Environment

- `node` 18
- `pnpm` 8
- `just` 1.9

## Usage

Run `just` for an overview of the most commonly used dev commands. Check out the
`justfile` for even more.

## Tips on adding a new package

- `pnpm` requires that the lib be explicitly listed as a dependency, so in other apps/libs
  that need it, you'll need to run `pnpm --filter @some/pkg install @new/pkg`
- if the lib has react components using tailwind, be sure to updated the `content` section
  of the `tailwind.config.js` for the app consuming it, so that JIT works correctly.
- add the new package to the `justfile` typechecking commands: `ts-check` and `ts-watch`

## Monorepo hacks/issues

- netlify's pnpm+monorepo support isn't quite there yet, had to add
  `NETLIFY_USE_PNPM=true`
  ([see here](https://github.com/netlify/build/issues/4648#issuecomment-1288804297))

## Typescript project references failure

I spent about 6 hours trying to get typescript _project references_ setup to avoid the
huge conglomerate typechecking commands in the `Makefile`, but ultimately failed. There is
no way to typecheck a monorepo in one command (see
[here](https://github.com/microsoft/TypeScript/issues/40431)), so you have to do a
_build_, but then I had to jump through all sorts of hoops to _not get any output_ from
the build. I ultimately solved the output issues, but found that I was getting super
obscure TS errors that I couldn't solve, so gave up. Maybe try again, but I think that
using `nx` to speed up the typecheck command would be good enough.
