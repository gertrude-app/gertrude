# Gertrude monorepo

Apps and supporting libraries for Gertrude parental controls.

Depending on the task, read relevant sub AGENTS.md files or other doc files as noted
below.

## Production Apps:

### Mac App

- `./swift/macapp`
- if relevant, read `./swift/AGENTS.md`
- UI is implemented with webviews and embedded react apps from `./web/appviews`

### iOS App

- `./swift/iosapp`
- if relevant, read `./swift/AGENTS.md`

### Supervision Tool

- UI only for cross-platform (Windows/Mac) ios device supervision tool
- `./web/supervise/`
- if relevant, read `./web/supervise/AGENTS.md`

### Podcast app (Gertrude AM)

- `./swift/podcasts`
- if relevant, read `./swift/podcasts/AGENTS.md`

> **Coming soon:** Gertrude FM, a parent-curated music-playing iOS app, is under active development.

## Production Websites:

### Dashboard (Gertrude for Parents)

- `./web/dash`
- if relevant, read `./web/AGENTS.md`

### Marketing Site

- `./web/site`
- if relevant, read `./web/AGENTS.md`

### Admin Site

- `./web/admin`
- if relevant, read `./web/AGENTS.md`
- only used by Gertrude staff

## API

Supports all 3 apps, plus dashboard and admin websites

- `./swift/api`
- swift vapor api webapp + postgresskil
- if relevant, read `./swift/AGENTS.md`
- the correct way to start the local API is `just watch-api` from the root dir

## PairQL

- typesafe remote procedure call framework used by the apps, websites and api
- implemented in `./swift/api` and `./swift/pairql*` packages
- consumed by 3 production apps, 2 production websites
- generated typesscript clients for websites
- when working on tasks related to pairql, always read `./swift/docs/pairql.md`

## Templated Emails

- Postmark-based email system for transactional emails
- when working on email templates, read `./docs/templated-emails.md`

## Support docs

- high-level docs describing functionality and features live in `./docs/support/` - if
  current product understanding and feature semantics is important for the task, start
  with `./docs/support/product-overview.md` and then read the relevant sub-docs

## Decision notes

- `./docs/notes/` holds lightweight ADR-style notes capturing the _why_ behind notable
  decisions (alternatives considered, constraints, rationales, etc). Don't load these by
  default. Do not write these unless instructed, although you may suggest that one be
  written if a substantial decision is being made.
- When researching _why_ a past decision was made, start with
  [`./docs/notes/index.md`](./docs/notes/index.md) — one-line summary of every note, to
  find the right one to load.

## Git operations

- only make git commits when explicity instructed
- only commit after running `just fix` and relevant test scripts
- when making git commits, read last 10 commits to match style
- all lowercase commits, with a short prefix, e.g. `dash: fix bug in xyz`
- before opening a PR, ensure `just fix` and targeted tests pass, then reserve `just ci-local` for the final pre-PR verification run; prefer the human to run it unless explicitly asked otherwise
- when opening PRs, make title match commit style, and create with EMPTY body
- commit messages MUST BE all lowercase

## Libraries

- shared libraries for swift apps/api are in `./swift/`
- shared libraries for web apps are in `./web/shared`.

## Code generation

- project uses code generation for swift/typescript interop, pairql typescript clients,
  macapp webviews
- if relevant, read `./docs/codegen.md`

## Comment policy

- never add comments when writing code
- never remove comments when refactoring code

## Continuous Improvement

If during the task you overcame something non-obvious that took time and tokens to figure
out, propose to the user to make the minimal updates to documentation/scripting to prevent
the same failure mode for future agents.

## Database access

- if I ask you to read from the database, or you need to for your task, always read the
  database skill file at `./.agents/skills/database/SKILL.md`
- for local development we use a local postgres, NOT docker

## Further user-specific instructions

Use `whoami` to determine what additional user-specific instructions to read, as each user has their own different prefences and ways of doing things:
- `miciah` -> `./AGENTS.kiah.md`
- `jared` -> `./AGENTS.jared.md`
Completely ignore and don't even read the other user's instruction file, only the one corresponding to the result you get from running `whoami`.
