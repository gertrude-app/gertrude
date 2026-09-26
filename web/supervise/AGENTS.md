# Supervise UI Package

Presentational React UI for Mac/Windows supervision and removal apps. Components accept
typed props and callbacks; state, API calls, and Tauri/Rust operations live in
`~/gertie/supervise`.

## Structure and Conventions

- `src/frames/index.ts` lists the frames; `src/types.ts` defines props and `src/index.ts`
  exports the public API.
- Use `InstructionLayout` for instructional screens. It provides progress and footer
  placement; omitting image/placeholder props removes the image column.
- All screens must fit the fixed **900×700px** window.
- Shared screens use `unsupervising?: boolean`, defaulting to `false`, for
  action-dependent copy. Currently: `ConfirmDevice`, `GetReady`, `ConfirmSupervision`, and
  `Error`. Keep neutral instructions shared without a mode flag.
- `ConfirmSupervision.onYes` means success in either mode: notice present for supervision,
  absent for removal.
- `DisableFindMy.childName` is optional because removal has no child context.

## Removal Flow

Gertrude Unsupervisor is a separate executable on the private repo's `unsupervise` branch,
with no claim code or API lookup:

`ITunesRequired` (Windows only) → `UnsuperviseConnect` → `ConfirmDevice` → `DisableFindMy`
→ `DisablePrivateRelay` → `GetReady` → `Supervising` → `SwipeToUpgrade` →
`ConfirmSupervision` → `UnsuperviseComplete`.

Connection and completion have dedicated removal screens; the middle screens are shared.
Progress uses eight steps: iTunes 1, connection 2, verification/completion 8.

## Workflow

1. Develop here: `pnpm --filter @storybook/app start` from `web/`.
2. Follow `../storybook/stories/supervise/SuperviseWizard.stories.tsx`; removal stories
   use the `Unsupervise_` prefix.
3. Sync: `cd web/ && just sync-supervise-ui`. Compare first: this overwrites generated UI,
   shared components, and API clients in `~/gertie/supervise/src/generated/`. Preserve
   desktop-only changes.
4. Wire behavior in the desktop repo, then run `just dev` there.
