# Gertrude web monorepo

## Apps

- `dash/app` - web admin dashboard (vite SPA)
- `marketing/app` - marketing site (next.js app)
- `docs/app` - docs site (next.js app)
- `storybook` - storybook for all react components

## Packages

- `dash/ambient` - ambient typescript types for dashboard (pkg name `@types/dash-ambient`)
- `dash/components` - react components for dashboard
- `dash/datetime` - date/time fns for dashboard
- `dash/keys` - logic/domain knowledge around _keys_
- `dash/types` - shared types (non-ambient) for dashboard
- `dash/utils` - misc helpers (string, etc.) for dashboard
- `marketing/components` - react components for marketing site
- `shared/components` - react components used by more than one app
- `shared/datetime` - date/time fns used by more than one app
- `shared/tailwind` - shared tailwind preset
- `shared/ts-utils` - shared typescript utilities

## Environment

- `node` 16
- `pnpm` 7

## Usage

Run `make` for an overview of the most commonly used dev commands. Check out the
`Makefile` for even more.

For watching typescript errors, the following monstrosity of a bash command filters out
some of the duplicates/noise:

```sh
script -q /dev/null make ts-watch | grep -P " [^\.][^\.][^ ]+: (- )?error TS\d+|(?<=0 errors)"
```

## Tips on adding a new package

- `pnpm` requires that the lib be explicitly listed as a dependency, so in other apps/libs
  that need it, you'll need to run `pnpm --filter @some/pkg install @new/pkg`
- if the lib has react components using tailwind, be sure to updated the `content` section
  of the `tailwind.comfig.js` for the app consuming it, so that JIT works correctly.
- if a next app is consuming it, edit the `next.config.js` file to transpile the module
  (because we don't _build_ anything for consumption, we just deal with straight
  typescript), and possibly add the path to the `package.json` `start` script (if using
  `next-remote-watch`)
- add the new package to the `Makefile` typechecking commands: `ts-check` and `ts-watch`

## Monorepo hacks/issues

- to get `next dev` to HMR when something in a workspace dependency changes, i had to pull
  in `next-remote-watch` to replace the standard `next-dev`
- for next.js apps to directly consume un-transpiled typescript, we use
  `with-transpiled-modules` in our `next.config.js`
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
