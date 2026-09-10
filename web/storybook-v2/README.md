# Storybook v2 screenshots

## Setup (Apple Silicon Macs)

Screenshots are built and captured in a pinned ARM64 Linux Playwright container, not the
host's browser. This keeps macOS upgrades and differences between developers' machines out
of the tracked PNGs. Colima, Docker CLI, and Buildx are free; Docker Desktop is not
required.

Install once:

```bash
brew install colima docker docker-buildx
mkdir -p ~/.docker/cli-plugins
ln -s "$(brew --prefix docker-buildx)/bin/docker-buildx" ~/.docker/cli-plugins/docker-buildx
colima start --cpu 6 --memory 8 --disk 30
```

If the Buildx symlink already exists, leave it in place. Colima runs in the background
without opening an app. After restarting your Mac, run `colima start` before capturing.
Use `colima stop` when you want to release its resources. An existing Docker installation
with Buildx also works; the runner uses your active Docker context and explicitly selects
`linux/arm64`.

## Capture

Run from the repository root:

```bash
just update-ui-screenshots
```

The first run downloads the Playwright image and dependencies. Later runs reuse Docker's
build cache. Storybook builds and Linux dependencies stay inside Docker; the host's
`node_modules`, local environment files, and existing screenshots are excluded from the
build context. Local source changes, including new untracked stories, are included.

The runner captures opted-in stories from `#storybook-root`, writes PNGs to
`screenshots/<viewport>/`, and writes `screenshots/manifest.json`. Only after a successful
capture are results copied back, removing stale screenshots. A build or capture failure
leaves the existing baselines untouched. Don't run concurrent updates to the same output
directory.

The capture container has no external network access: stories must use bundled assets and
mock data. The image pins Node, Chromium, fonts, and Linux libraries; pnpm follows
`web/package.json` and dependencies follow the frozen lockfile. Capture settings fix
locale (`en-US`), timezone (`UTC`), light mode, pixel density, and reduced motion. The
browser's date is fixed at `2026-07-07T12:00:00Z` (matching the existing calendar
fixtures) without stopping timers, so date-dependent stories stay consistent between days.
Each capture uses a fresh page to keep browser memory from accumulating across hundreds of
stories in the Linux VM. Before capturing, the runner waits for fonts, image elements, and
decoded CSS background images (including `::before` and `::after`). Broken or stalled
background images fail the run instead of silently producing incomplete baselines.

To compare results without replacing tracked screenshots, set `SCREENSHOT_DIR` to an
absolute directory outside `web/`. Relative paths resolve from `web/storybook-v2`.
`SCREENSHOT_CONCURRENCY` controls capture workers (default: 6).

```bash
SCREENSHOT_DIR="$PWD/scratch/ui-capture-a" just update-ui-screenshots
SCREENSHOT_DIR="$PWD/scratch/ui-capture-b" just update-ui-screenshots
diff -rq scratch/ui-capture-a scratch/ui-capture-b
```

Use the same source revision on both Macs and compare PNG hashes before accepting the
initial Linux baseline. Keep the one-time baseline refresh separate from UI changes.

## Stories

Stories opt into screenshots by setting named viewport sizes:

```ts
parameters: {
  screenshotsAt: ['mobile', 'desktop'],
}
```

The named sizes live in `.storybook/preview.tsx` under `parameters.screenshotViewports`.
Set `screenshotsAt: []` on a story to opt out of a meta-level setting.

Known follow-up: keep screenshot coverage declarative. When an interactive state matters,
add a dedicated story/prop for that open or expanded state rather than making the runner
click through the UI.

## Maintenance

When upgrading Playwright in `package.json`, update the matching image tag and its ARM64
manifest digest in `Dockerfile` together. Treat renderer upgrades as intentional baseline
changes, and repeat the unchanged-source comparison. Do not regenerate tracked baselines
by running `screenshot-stories.js` directly on macOS.

The image is tagged `gertrude-ui-screenshots:local`. Docker retains build caches between
runs; these consume disk space and can be removed using Docker's normal cache-management
tools when needed.

Image builds run browser tests against deliberately delayed, broken, and stalled CSS
background images before the image can be used for capture. These use the same pinned
Chromium as screenshots.

Wrapper tests (no Docker daemon required):

```bash
cd web && pnpm exec vitest run storybook-v2/scripts/__tests__/update-screenshots.test.ts
```
