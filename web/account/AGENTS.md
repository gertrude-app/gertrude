# Gertrude Account

`web/account` is a work-in-progress, ground-up rewrite and eventual replacement for
`web/dash`.

Dashboard was originally built only for the Gertrude Mac app. As Gertrude expanded to
Blocker, Podcasts, Music, and many more features, Dashboard became bloated, visually poor,
sprawling, and difficult to reason about or maintain.

Account is a fresh, cohesive experience for a connected Gertrude account across apps.
Build it on the shared UI in `web/ui` and the new Account domain in `swift/api`, rather
than carrying forward Dashboard's architecture or design by default.
