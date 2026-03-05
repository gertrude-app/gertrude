# Supervise UI Package

React UI for Mac/Windows iOS device supervision app.

## Architecture

This package contains **purely presentational React components** for a Tauri desktop app
that supervises iOS devices. The actual Tauri/Rust code and orchestration logic live in a
separate private repo.

Components accept typed props and fire callbacks — they have no knowledge of state
management, API calls, or Tauri operations. The private repo owns the state machine and
wires these components together.

## Structure

- `src/frames/` — 9 frame components (CodeEntry, PersonalizedConnect, ChooseDirection,
  etc.)
- `src/types.ts` — Prop interfaces for all components
- `src/index.ts` — Public exports
- `src/FrameBackground.tsx` — Shared background wrapper with subtle gradient
- `src/assets/` — Images used by frames

## Workflow

1. Develop UI here with Storybook (`pnpm --filter @storybook/app start`)
2. Sync to private repo: `cd web/ && just sync-supervise-ui` (copies `src/` into
   `~/gertie/supervise/src/generated/supervise/`)
3. Wire up new screens in the supervise repo's state machine (`~/gertie/supervise/src/`)
4. Run Tauri app: `cd ~/gertie/supervise && just dev`

## Storybook

Stories at `../storybook/stories/supervise/`. Each story renders a frame with specific
props to preview different visual states.

## Window Size

The Tauri app window is fixed at **900×700px** (matching macOS onboarding). All frames
must fit this constraint.
