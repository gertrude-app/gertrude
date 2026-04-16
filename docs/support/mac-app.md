# Mac App

The Gertrude Mac app is the oldest Gertrude product and the most full-featured one. It is
the original flagship product, even though the iOS app now has a larger user base.

## What It Is

- A macOS parental-control app built around a very strict network filter.
- Usually runs mostly in the background as a menu bar utility after setup.
- Parents mainly manage it from the parent dashboard, not from the Mac itself.
- The child usually only interacts with it to:
  - request a filter suspension
  - review blocked requests and submit unlock requests

## Core Model: Allowlist, Not Blocklist

- Gertrude's defining model is **deny by default** internet filtering.
- In practice, this means almost all network requests are blocked unless they are
  specifically allowed.
- This is a safelist/allowlist system, not a traditional blocklist system.
- This is an important support distinction: if something online is not explicitly allowed,
  Gertrude will usually block it.
- A lot of the product experience is built around making this strict model manageable for
  non-technical parents.

## Main Features

- **Network filtering:** blocks internet access unless a rule, keychain, or other allowed
  path permits it.
- **Screenshot monitoring:** can periodically capture background screenshots and upload
  them for parent review in the dashboard.
- **Keylogging:** can record typed text and upload it to the dashboard as reviewable
  keystroke lines.
- **Filter suspensions:** lets a child request a short period of unrestricted internet
  access, subject to parent approval.
- **Blocked request review:** the child can open a live view of blocked requests and send
  unlock requests to the parent.
- **Health check:** an admin-gated diagnostic screen that checks permissions, filter
  health, account state, and common misconfiguration issues.

## Keys And Keychains

- A **key** is a rule that unlocks part of the internet.
- A **keychain** is a grouping of keys.
- This terminology appears throughout the parent dashboard and is core to how Gertrude's
  allowlist model is managed.
- There are two main kinds of keys:
  - **address-based keys:** unlock a specific domain or address; these are most commonly
    used for websites in web browsers
  - **app-based keys:** grant internet access to a specific macOS app; these are mainly
    for non-browser applications
- Many websites and apps need multiple keys to work correctly, not just one. A single site
  may require separate access for its main domain, scripts, stylesheets, APIs, or embedded
  assets.
- One reason keychains exist is to bundle all of those related keys together so parents do
  not have to build them one at a time.
- Gertrude also has **public keychains**, which are prebuilt keychains for common sites
  and apps that Gertrude creates and makes available to all parents.
- Public keychains are meant to speed up the process of unblocking common services and
  reduce the technical burden on parents.

## Always Blocked

- **Always Blocked** is a parallel layer of rules that *always deny* specific traffic,
  inverting the default allowlist model for a narrow set of cases.
- Keys and keychains *allow*; Always Blocked rules *deny*. The two systems coexist and
  deny takes priority: if an Always Blocked rule matches, the traffic is blocked even if
  a key would otherwise allow it.
- Always Blocked rules override **filter suspensions**, **filtering-disabled** state, and
  **allow-keys**. They do not override downtime (downtime already blocks everything).
- Always Blocked rules do **not** apply to exempt macOS users in v1. An exempt user
  remains outside the filter entirely.
- There are two sources of rules:
  - **Gertrude-authored bundles** parents can subscribe to — for example, Messages GIF
    search, a curated adult-content top list, and social-media groups.
  - **Per-child custom rules** parents author themselves in the dashboard.
- Requires Mac app `v2.9.1` or later. Older Mac app versions ignore Always Blocked
  assignments silently.
- The primary motivation is filter suspensions: many parents want certain categories
  (adult content, Messages GIF search, etc.) to stay blocked even during a suspension.

## How Parents Control It

- Parents create and manage children in the dashboard.
- A Mac is connected to a child by generating a one-time six-digit connection code from
  the dashboard and entering it during Mac app setup.
- Monitoring settings are controlled in the dashboard, including:
  - whether screenshots are enabled
  - whether keylogging is enabled
  - screenshot frequency
  - screenshot resolution
- Parents also manage which sites/apps are allowed by assigning keychains and other rules
  in the dashboard.
- Screenshots and keystroke activity are reviewed in the dashboard, where items can be
  flagged for follow-up or deleted/approved.

## Filter Suspensions

- Because the filter is so strict, Gertrude includes a built-in workflow for temporary
  unrestricted access.
- The child requests a suspension from the Mac app UI.
- The parent gets a notification and can approve or deny it from the dashboard.
- If approved, the parent can also change the requested duration.
- While the filter is suspended, monitoring can remain on, and extra monitoring can be
  applied during the suspension.
- When the suspension expires, the filter turns back on automatically.
- If the child has Always Blocked rules assigned, those rules remain enforced during a
  suspension — a suspension does not unblock traffic that matches an Always Blocked rule.
- In the dashboard, activity recorded during a suspension can be visually emphasized so
  parents can review it more carefully.

## Downtime

- **Downtime** is a scheduled daily window when the child has no internet access at all.
- Parents configure downtime in the dashboard for each child.
- A common use case is overnight internet shutoff.
- If needed, a parent can pause downtime from the Mac app menu bar using admin
  authentication.

## Security Events

- Gertrude also records important **security events** that parents can review from the
  dashboard.
- These events are separate from screenshots and keylogging.
- They are meant to highlight noteworthy changes or situations such as suspensions,
  protection changes, and other events that may matter for accountability or
  troubleshooting.
- This is especially useful for parents who want a higher-level audit trail in addition
  to raw activity monitoring.

## Unlock Requests

- The child can open a blocked-requests/network-traffic screen from the menu bar app.
- They can select blocked requests and submit an unlock request to the parent.
- The parent handles that in the dashboard by reviewing the request and, if desired,
  creating or editing a key or assigning a keychain that allows the needed access.
- This workflow is one of the main ways the allowlist model stays usable in daily life.

## Health Check And Local UI

- After onboarding, the Mac app is mostly accessed from the menu bar dropdown.
- The health check/admin area is protected by admin authentication on the Mac.
- Support often directs parents there because it can detect or repair common issues.
- The health check checks things like:
  - filter installation and communication
  - account status
  - screen recording permission
  - keystroke recording permission
  - full disk access
  - notifications permission
  - Screen Time web filter conflicts

## User Exemption

- Gertrude follows a fail-safe approach: if it encounters a macOS user it does not know
  about, it blocks that user's internet access rather than assuming they should be
  allowed.
- This is safer, but it means shared-family computers often need an explicit exemption for
  the parent's own admin account.
- The onboarding flow explains this and offers the exemption step.
- The same exemption controls are also available from the health check/admin area.
- This is a common support issue when a parent installs Gertrude on a shared Mac and then
  finds their own account unexpectedly filtered.
- Exempt users are not subject to Always Blocked rules in v1. Always Blocked only applies
  to non-exempt, filter-enrolled users.

## Onboarding

- First launch uses a long onboarding flow.
- The onboarding guides the parent through macOS permissions and installing the network
  filter system extension.
- This is necessary because macOS requires several unintuitive permissions for filtering
  and monitoring to work correctly.
- Once onboarding is complete, ongoing use is mostly through the menu bar and dashboard.

## Important Limitations And Gotchas

- The Mac app is controlled primarily from the dashboard, not from the Mac itself.
- Because the model is deny-by-default, "why is this blocked?" often has the simple answer
  "it has not been explicitly allowed yet."
- Broken or missing macOS permissions can affect screenshots, keylogging, notifications,
  or filter health.
- Apple's own Screen Time web filter can conflict with Gertrude; the health check now
  explicitly looks for that.
- App blocking is useful, but it is secondary to internet filtering. Many apps are much
  less interesting to children if Gertrude is already denying their network access.

## Significant Recent Changes

- **November 2024:** `v2.5.0` introduced **scheduled keychains** and **downtime**. These
  added time-based controls so parents can allow specific access only on a schedule or
  disable internet during recurring windows such as overnight.
- **December 2024 / January 2025:** app-blocking work landed in the `2.6.x` / `2.7.0` era.
  `v2.6.0` first added app blocking in December 2024, and the January 29, 2025 `2.7.0`
  release positioned it as a headline feature, including scheduled app blocking.
- **January 2025:** newer onboarding/permission work was added around macOS Sequoia and
  full-disk/screen-capture related permission flows.
- **January 2026:** `v2.8.0` added explicit detection and mitigation for conflicts with
  Apple's Screen Time web filter.
- **April 2026:** `v2.9.1` added **Always Blocked** — a parallel deny layer that persists
  through filter suspensions, covering Gertrude-authored bundles (Messages GIF search,
  adult-content top list, social media) and per-child custom rules.
