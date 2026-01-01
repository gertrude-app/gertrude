# Gertrude monorepo

## Current Task: iOS Account Onboarding & Supervision

This directory is for high-level planning of the iOS supervision onboarding feature. This
is a large multi-phase feature spanning iOS app, API, dashboard, and supervision tool.
Implementation tasks will be spun out to separate branches/PRs.

Planning docs:

- `tasks.md` - initial context and goals
- `next.md` - brainstorming prompt and constraints
- `ios-onboarding-flow.md` - current iOS onboarding state machine reference
- `supervision-onboarding-recommendations.md` - detailed recommendations and analysis

---

Apps and supporting libraries for Gertrude parental controls.

Depending on the task, read relevant sub CLAUDE.md files or other doc files as noted
below.

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

## Templated Emails

- Postmark-based email system for transactional emails
- templates stored in `./swift/api/Sources/Api/Email/Templates/`
- when working on email templates, read `./docs/templated-emails.md`

## Git operations

- only make git commits when explicity instructed
- only commit after running `just fix` and relevant test scripts
- when making git commits, read last 10 commits to match style
- all lowercase commits, with a short prefix, e.g. `dash: fix bug in xyz`
- when opening PRs, make title match commit style, and create with EMPTY body

## Libraries

- shared libraries for swift apps/api are in `./swift/`
- shared libraries for web apps are in `./web/shared`.

## Code generation

- project uses code generation for swift/typescript interop, pairql typescript clients,
  macapp webviews
- read `./docs/codegen.md`

## Comment policy

- never add comments when writing code
- never remove comments when refactoring code
