---
name: public-keychain
description:
  Research and prepare a new public keychain for a website or service. Use when asked
  to create or prepare a public keychain for a domain.
---

# Public Keychain Skill

This skill guides you through researching, crawling, and preparing a public keychain for
a given domain. Public keychains are pre-built, admin-owned keychains with `is_public =
true` in the `parent.keychains` table, available to all Gertrude parents. Mac app only.

## Background

Read these for context if you haven't already:
- `./web/site/markdoc/articles/docs/unblocking-guide.md` — how the filter works and why
  multiple domains are often needed
- `./docs/support/mac-app.md` lines 41-60 — public keychain concept

## Key Concepts

**Key types:**
- `anySubdomain` — allows the domain and all subdomains. Used for most domains.
- `domain` (strict) — allows only the exact domain specified. Required for any domain in
  the UNSAFE_DOMAINS list (see below).

**App scope:** Most keychain keys should use `webBrowsers` scope.

**UNSAFE_DOMAINS** (defined in `./web/dash/keys/src/unlock.ts`), read that file, and all
domains listed in the UNSAFE_DOMAINS array must always use strict `domain` type (never `anySubdomain`):

## Research Process

### Step 1: Crawl the site

Use WebFetch to crawl these pages and note every external domain referenced:
1. Root domain (e.g. `https://example.com`)
2. `www` variant
3. 3-5 representative interior pages (article, search results, feature pages)
4. Auth/account pages if they exist (`/login`, `/account`, `/subscribe`)
5. Any audio/media player pages

For each page, look for:
- `<script src="...">` — JS bundles, third-party scripts
- `<link href="...">` — CSS, fonts
- `<img src="...">` — image CDNs
- `<source src="...">` — audio/video CDNs
- `<iframe src="...">` — embeds
- Inline `<script>` blocks loading third-party URLs
- HTTP response headers (`Content-Security-Policy` often reveals all allowed domains)
- 302 redirect destinations (especially for audio/media)

Also fetch 1-2 JS bundle URLs to inspect what third-party services they reference.

### Step 2: Categorize findings

**INCLUDE — Core functionality:**
- The site's own domain(s) and subdomains
- CDN domains serving the site's own CSS, JS, fonts, images
- API domains for the site's own backend calls
- Audio/media CDNs serving the site's own content
- Publisher/parent company CDNs

**EXCLUDE — Always:**
- Google Analytics / Google Tag Manager (`googletagmanager.com`, `google-analytics.com`)
- Facebook Pixel (`connect.facebook.net`, `www.facebook.com`)
- Twitter/X embeds (`platform.twitter.com`, `syndication.twitter.com`)
- Advertising networks
- Sentry / error monitoring (`sentry.io`, `browser.sentry-cdn.com`) — lean toward exclude
- Hotjar, Mixpanel, Segment, Amplitude, Heap — pure tracking

**EXCLUDE — Usually (use judgment):**
- Social sharing links (`twitter.com/intent/tweet`, `facebook.com/sharer`) — hyperlinks
  only, not loaded resources
- App store links (`apps.apple.com`, `play.google.com`) — hyperlinks only
- Background/decorative video (Vimeo, YouTube embeds on landing page only) — exclude
  unless video is core content
- Live chat widgets (Intercom, Salesforce, Zendesk) — only include if support access is
  explicitly needed
- Google Fonts (`fonts.googleapis.com`, `fonts.gstatic.com`): NEVER include these

**CAUTION — Fonts:**
- Self-hosted fonts via the site's own CDN: include the CDN domain

**CAUTION — CDN wildcard domains:**
- If a CDN subdomain is specific to the site (e.g. `dch8lckz6x8ar.cloudfront.net`),
  include as a strict `domain` key (because `cloudfront.net` is in UNSAFE_DOMAINS)
- Note: site-specific CDN subdomains can change when a site rebuilds. Flag this in the
  keychain warning field.

### Step 3: Check for authenticated sections

Note if the site has:
- Login / account pages — may need additional domains post-login
- Subscription features — may require payment processor domains
- If you can't test authenticated sections, note this as a limitation

### Step 4: Build the minimal keychain

**Minimize keys:** Use `anySubdomain` on the root domain wherever possible — this often
covers the main site, API subdomains, and content subdomains in one key.

**Avoid over-including:** Do not add domains just because they appear in the page source.
Social links, app store links, and tracking pixels are not needed for the site to function.

### Step 5: Database insertion (when instructed to actually create)

Read the database skill at `./.claude/skills/database/SKILL.md` for connection info.

Before inserting anything:
- Query existing public keychains to understand the current schema and data shapes
- Look at `parent.keychains` and `parent.keys` to understand the structure
- Examine a few existing public keychain keys to understand the `key` JSONB format in use
- Find the correct admin `parent_id` that owns public keychains by looking at existing ones

Use the Swift models in `./swift/api/Sources/Api/Models/Keychain/` and
`./swift/gertie/Sources/Gertie/Key.swift` as the authoritative source for key types and
shapes — derive the JSONB structure from the types, don't guess.

Save the SQL used in a report file (see step 6) before executing it, so it can be
reviewed and run against production after local testing.

### Step 6: Save a report

Write a report file named `claude.report.<site>-keychain.md` in the project root.
Include: all domains found, categorization decisions, the SQL used, and any caveats
(unstable CDN subdomains, untested auth sections, etc.).

## Output Format

When reporting findings to the user, provide:
1. **Recommended keychain keys** — the minimal set for core functionality
2. **Excluded domains table** — what was found but excluded, and why
3. **Optional additions** — domains that add non-essential features
4. **Authenticated sections** — what couldn't be tested / may need follow-up
5. **Risks or notes** — unstable CDN subdomains, Google dependency, etc.

