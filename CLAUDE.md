# Gertrude monorepo

Apps and supporting libraries for Gertrude parental controls.

Depending on the task, read sub CLAUDE.md files as noted below.

## Production Apps:

### Mac App

- `./swift/macapp`
- read `./swift/CLAUDE.md`
- UI is implemented with webviews and embedded react apps from `./web/appviews`

### iOS App

- `./swift/iosapp`
- read `./swift/CLAUDE.md`

### Podcast app (Gertrude AM)

- `./swift/podcasts`
- read `./swift/podcasts/CLAUDE.md`

## Production Websites:

### Dashboard (Gertrude for Parents)

- `./web/dash`
- read `./web/CLAUDE.md`

### Marketing Site

- `./web/site`
- read `./web/CLAUDE.md`

### Admin Site

- `./web/admin`
- read `./web/CLAUDE.md`
- only used by Gertrude staff

## API

Supports all 3 apps, plus dashboard and admin websites

- `./swift/api`
- swift vapor api webapp + postgresskil
- read `./swift/CLAUDE.md`

## Pairql

- typesafe remote procedure call framework used by the apps, websites and api
- implemented in `./swift/api` and `./swift/pairql*` packages
- consumed by 3 production apps, 2 production websites
- generated typesscript clients for websites
- when working on tasks related to pairql, always read `./swift/docs/pairql.md`

## Git operations

- only make git commits when explicity instructed
- only commit after running format, linting, and check scripts
- when making git commits, read last 10 commits to match style
- all lowercase commits, with a short prefix, e.g. `dash: fix bug in xyz`
- when opening PRs, make title match commit style, and create with EMPTY body

## Libraries

- shared libraries for swift apps/api are in `./swift/`
- shared libraries for web apps are in `./web/shared`.

## Comment policy

- never add comments when writing code
- never remove comments when refactoring code
