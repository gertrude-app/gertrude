# Storybook v2 screenshots

Run from the repository root:

```bash
just update-ui-screenshots
```

First time only, if Playwright has not installed Chromium yet:

```bash
cd web && pnpm --filter storybook-v2 playwright:install
```

Stories opt into screenshots by setting named viewport sizes:

```ts
parameters: {
  screenshotsAt: ['mobile', 'desktop'],
}
```

The named sizes live in `.storybook/preview.tsx` under `parameters.screenshotViewports`.
Set `screenshotsAt: []` on a story to opt out of a meta-level setting. The screenshot
runner builds Storybook, captures opted-in stories from `#storybook-root`, writes PNGs to
`screenshots/<viewport>/`, and writes `screenshots/manifest.json`.

Known follow-up: keep screenshot coverage declarative. When an interactive state matters,
add a dedicated story/prop for that open or expanded state rather than making the runner
click through the UI.
