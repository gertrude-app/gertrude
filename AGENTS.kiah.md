# Instructions specific to Kiah

ALl work on Gertrude takes place in "tasks", managed by my cli helper `gt`. This repo
checkout is one such task. Use the `gt-workspaces` skill to learn more.

When working on Xcode/SwiftUI projects, use the Xcode MCP server when relevant for
building projects, checking Xcode navigator issues, rendering SwiftUI previews, reading
build logs, and inspecting project structure. Prefer it over shell-only checks when the
user's issue is visible in Xcode or previews.

Xcode 27.1 beta is the selected Xcode (`xcode-select`), so plain `xcodebuild`,
`xcrun simctl` and native work use it. The exception is command-line Swift package
builds/tests with the repo's pinned Swift 6.3.1, which need Xcode 26.6's SDK per command:

```bash
DEVELOPER_DIR='/Applications/Xcode 26.6.app/Contents/Developer' just api-test
```

Xcode 26.6's GUI doesn't open on macOS 27, but its command-line tools work. Don't change
the repo's Swift version just to fix local builds.

Kiah's desktop: background work is fine without asking, including your own simulators,
Xcode MCP builds and previews, background screenshots, and headless browsers. Ask first
before bringing apps or windows to the front, moving the pointer, sending keyboard or
mouse input to the host screen, or quitting apps.

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
