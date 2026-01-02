# Supervise UI Package

React UI for Mac/Windows iOS device supervision app.

## Architecture

This package contains **only the UI** for a Tauri desktop app that supervises iOS devices.
The actual Tauri/Rust code lives in a separate private repo.

## Status

This UI layer is in proof-of-concept mode. The final production code will likely be much
different. It's current state just proves out the sharing of code between two repos, and
slots in a place for this UI in the open source monorepo. The API, structure and UI will
change significantly before production.

## Key Pattern: Abstract API

Components accept a `SuperviseApi` interface instead of calling Tauri directly:

```typescript
interface SuperviseApi {
  getConnectedDevice: () => Promise<DeviceInfo>;
  performOperation: (mode: 'add' | 'remove') => Promise<void>;
  closeWindow: () => void;
}
```

The private Tauri repo provides the glue that maps this to actual `invoke()` calls.

## Structure

- `src/SuperviseWizard.tsx` - Main component, accepts `api` prop
- `src/SuperviseContext.tsx` - React context for shared state
- `src/frames/` - 7 wizard frames (ConnectDevice → Complete)
- `src/types.ts` - DeviceInfo, SuperviseApi, Frame types

## Workflow

1. Develop UI here with Storybook (`pnpm --filter @storybook/app start`)
2. Sync to private repo: `cd {path-to-repo} && just sync-ui`
3. Run Tauri app: `just run`

## Storybook

Stories at `../storybook/stories/supervise/`. Use `initialFrame`, `initialDevice`,
`initialError` props to preview specific states.

## Window Size

The Tauri app window is fixed at **400×350px**. All frames must fit this constraint.
