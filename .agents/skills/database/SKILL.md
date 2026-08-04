---
name: database
description:
  Query and analyze the Gertrude PostgreSQL database. Use when answering questions about
  database schema, writing SQL queries, analyzing data, or debugging database-related
  issues.
---

# Database Query Skill

You have access to the Gertrude PostgreSQL database for querying and analysis.

For connection info, read `./swift/api/.env` and use the values there.

You may read from and write to the LOCAL task database because it is a task-specific,
PII-scrubbed snapshot. You must NEVER use tools to SSH into production, retrieve
production credentials, connect to a remote database, or execute remote queries or
mutations.

You may help a user who is operating production themselves by providing shell commands
(including connection commands) and SQL for them to review and run. You may also interpret
non-secret output they choose to share. The user must execute every production command.
Never ask them to disclose credentials or other secrets.

The local snapshot is complete, not a subset of production.

Important: although this repo has some docker-related files, all local development goes
through a local install of postgres and NOT through docker. Never use `docker` commands
when dealing with the database.

## Related skills

- For verifying non-trivial migrations (data backfill, column drop, transforms)
  before merging, see `../migration-verification/SKILL.md`.

## Database Structure

Data is spread across multiple non-`public` Postgres schemas (don't assume `public`). The
map below is orientation for *where to look* — discover the live tables/columns yourself
(`\dn`, `\dt <schema>.*`), since table-level detail drifts.

- **parent** — parent accounts, children, computers, keychains, keys, billing, notifications
- **child** — per-child device data: mac computer users, iOS devices, screenshots, app tokens
- **macapp** — macOS app: keystroke lines, releases, unlock & suspend-filter requests
- **blocker_app** — iOS blocker/filter app: block groups & rules, installs, supervisions, tokens, events
- **podcast_app** — Gertrude Podcasts podcast app: installs, tokens, events
- **music** — Gertrude Music: parent-approved Apple Music albums per child
- **music_app** — Gertrude Music iOS app: installs, tokens
- **macos** — macOS app reference catalog: bundle ids, categories, browsers, identified/unidentified apps
- **appstore** — App Store ratings & reviews data
- **system** — cross-cutting: deleted entities, telemetry, security/interesting events, sms, stripe events, short urls
- **public** — Fluent migration tracking and jobs metadata
