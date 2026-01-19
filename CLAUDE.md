# Gertrude monorepo

Apps and supporting libraries for Gertrude parental controls.

Depending on the task, read relevant sub CLAUDE.md files or other doc files as noted
below.

## Production Apps:

### Mac App

- `./swift/macapp`
- if relevant, read `./swift/CLAUDE.md`
- UI is implemented with webviews and embedded react apps from `./web/appviews`

### iOS App

- `./swift/iosapp`
- if relevant, read `./swift/CLAUDE.md`

### Supervision Tool

- UI only for cross-platform (Windows/Mac) ios device supervision tool
- `./web/supervise/`
- if relevant, read `./web/supervise/CLAUDE.md`

### Podcast app (Gertrude AM)

- `./swift/podcasts`
- if relevant, read `./swift/podcasts/CLAUDE.md`

## Production Websites:

### Dashboard (Gertrude for Parents)

- `./web/dash`
- if relevant, read `./web/CLAUDE.md`

### Marketing Site

- `./web/site`
- if relevant, read `./web/CLAUDE.md`

### Admin Site

- `./web/admin`
- if relevant, read `./web/CLAUDE.md`
- only used by Gertrude staff

## API

Supports all 3 apps, plus dashboard and admin websites

- `./swift/api`
- swift vapor api webapp + postgresskil
- if relevant, read `./swift/CLAUDE.md`
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

## Git operations

- only make git commits when explicity instructed
- only commit after running `just fix` and relevant test scripts
- when making git commits, read last 10 commits to match style
- all lowercase commits, with a short prefix, e.g. `dash: fix bug in xyz`
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

## Database access

- if i ask you to read from the database, or you need to for your task, always read the
  database skill file at `./.claude/skills/database/SKILL.md`
- for local development we use a local postgres, NOT docker

## Dev "task" concept

Local dev for this monorepo takes place in individual "task" branches with separate
directories, similar in concept to **git worktrees.** If I refer to another "task", it
means another directory. You can list out other tasks by `ls`-ing the directory above your
cwd. You may read data from any other task, but you may not modify code outside your
current task unless explicity instructed.

## Task-specific instructions (may not be present)

- @./claude.task.md
