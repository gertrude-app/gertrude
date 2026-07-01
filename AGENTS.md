# Gertrude monorepo

Apps and supporting libraries for Gertrude parental controls.

Depending on the task, read relevant sub AGENTS.md files or other doc files as noted
below.

## Production Apps:

### Mac App

- `./swift/macapp`
- if relevant, read `./swift/AGENTS.md`
- UI is implemented with webviews and embedded react apps from `./web/appviews`

### iOS Blocker app

- `./swift/iosapp`
- if relevant, read `./swift/AGENTS.md`

#### Supervision Tool

- UI only for cross-platform (Windows/Mac) ios device supervision tool. Supervision is
  required for the Blocker app's content-filter on devices owned by people over 18
- `./web/supervise/`
- if relevant, read `./web/supervise/AGENTS.md`

### iOS Podcast app (Gertrude Podcasts)

- `./swift/podcasts`
- if relevant, read `./swift/podcasts/AGENTS.md`

### iOS Music app (Gertrude Music)

> **Private beta (not yet released):** Gertrude Music, a parent-curated music-playing iOS
> app, now lives in `./swift/music`. It's in App Store review for a private beta while we
> validate the business model with Apple — hopefully coming soon. Don't present it as a
> shipped or public product (e.g. in marketing copy or `llms.txt`).

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

#### "Account" Site

- WIP replacement for Dashboard, being stood up in `./web/account`. Not yet used in
  production, but will eventually replace Dashboard.

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

- `./docs/notes/` holds lightweight ADR-style notes capturing the _why_ behind a decision
  **already made and implemented**, when that _why_ can't be reconstructed from the code
  itself. Don't load these by default.
- Don't write one unless instructed. Only _suggest_ one when **all** hold: (1) a real
  choice was made among genuine alternatives, (2) the _why_ is non-obvious enough that a
  future reader would wonder "why is it like this?" or assume a mistake, (3) that _why_
  has no durable home in the code, comments, commit, or PR, and (4) it's settled, not
  proposed. Never suggest one for an idea, TODO, future task, or routine choice — those
  are tasks, not notes. When unsure, don't: a missed borderline note costs little; notes
  for non-decisions erode the ones that matter.
- When researching _why_ a past decision was made, start with
  [`./docs/notes/index.md`](./docs/notes/index.md) — one-line summary of every note, to
  find the right one to load.

## Git operations

- only make git commits when explicity instructed
- only commit after running `just fix` and relevant test scripts
- when making git commits, read last 10 commits to match style
- all lowercase commits, with a short prefix, e.g. `dash: fix bug in xyz`
- keep commit subjects tight: target ~50 chars, hard cap 72 (github elides past that);
  subject line only — no body or extended description
- before opening a PR, ensure `just fix` and targeted tests pass, then reserve
  `just ci-local` for the final pre-PR verification run; prefer the human to run it unless
  explicitly asked otherwise
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
- in test files, DO sometimes add small (usually line-end) comments to help separate
  critical, load-bearing setup and assertion details from the rest of test

## Continuous Improvement

If during the task you overcame something non-obvious that took time and tokens to figure
out, propose to the user to make the minimal updates to documentation/scripting to prevent
the same failure mode for future agents.

## Database access

- if I ask you to read from the database, or you need to for your task, always read the
  database skill file at `./.agents/skills/database/SKILL.md`
- for local development we use a local postgres, NOT docker

## Proactively copy relevant values to clipboard

Proactively copy complex URLs and other likely copy-paste values (email text, SQL, or
commands) to my macOS clipboard when I will use them in a browser, another app, or another
terminal. Mark the rendered value with 📋 only; don't mention it in prose. I use clipboard
history, so copying multiple values is fine.

## Further user-specific instructions

Use `whoami` to determine what additional user-specific instructions to read, as each user
has their own different prefences and ways of doing things:

- `miciah` -> `./AGENTS.kiah.md`
- `jared` -> `./AGENTS.jared.md` Completely ignore and don't even read the other user's
  instruction file, only the one corresponding to the result you get from running
  `whoami`.
