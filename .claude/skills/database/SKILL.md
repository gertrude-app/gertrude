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

You may READ any data, but you may never write data unless EXPLICITLY instructed to.

Important: although this repo has some docker-related files, all local development goes through a local install of postgres and NOT through docker. Never use `docker` commands when dealing with the database.


## Database Structure

The database uses multiple schemas to organize tables:

- **parent**: Parent accounts, children, computers, keychains, keys, notifications, etc.
- **child**: Computer users, blocked apps, iOS devices, tokens, screenshots
- **macapp**: Keystroke lines, releases, unlock requests
- **iosapp**: Block groups, rules, device configurations, suspend requests
- **macos**: App bundle IDs, categories, browsers, identified/unidentified apps
- **system**: Deleted entities, interesting events, security events, Stripe events
- **public**: Fluent migrations, jobs metadata
- **podcasts**: Podcast-related tables

