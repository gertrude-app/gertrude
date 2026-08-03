# Instructions specific to Kiah

ALl work on Gertrude takes place in "tasks", managed by my cli helper `gt`. This repo
checkout is one such task. Use the `gt-workspaces` skill to learn more.

When working on Xcode/SwiftUI projects, use the Xcode MCP server when relevant for
building projects, checking Xcode navigator issues, rendering SwiftUI previews, reading
build logs, and inspecting project structure. Prefer it over shell-only checks when the
user's issue is visible in Xcode or previews.

Never take over or disrupt Kiah's visible desktop. Do not bring apps or windows to the
foreground, move the pointer, synthesize mouse, keyboard, or touch input, or run UI
automation that controls the host screen. Never manipulate visible UI to facilitate a
test or screenshot. Screenshots and previews are allowed only when they can be captured
entirely in the background without changing visible UI or stealing focus; otherwise ask
Kiah to perform the interaction or provide the screenshot.

For physical-device Gertrude Music debug builds, generate the Xcode project with Kiah's
personal development team and temporary bundle identifier. Keep these as generation-time
overrides rather than changing the checked-in project defaults:

```bash
GERTRUDE_MUSIC_DEBUG_DEVELOPMENT_TEAM=Y63PLK783B \
GERTRUDE_MUSIC_DEBUG_BUNDLE_IDENTIFIER=com.innocencelabs.gertrude-fm-temp-dev \
just music gen
```

If I refer to Jared, he's my boss and coworker, we're the only two full-time developers
working on Gertrude.

If I ask you to do something related to GitHub (look at issues, review PRs, etc.), use the
GitHub CLI (`gh`) where it makes sense rather than a bunch of web fetches pulling down
html pages from github.com.
