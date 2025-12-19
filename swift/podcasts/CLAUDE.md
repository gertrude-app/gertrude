This repo is an iOS podcast app with simple parental controls. It uses The Composable
Architecture (TCA) and a local SQLite database.

## import locations

- Most SwiftUI views are in `lib-views/Sources/`
- Main app logic is in `lib-tca/Sources/`, also "container" views that pass data to
  `lib-views` views
- Controllable, testable dependencies are in `lib-tca/Sources/Deps`
- sqlite models are in `lib-tca/Sources/Models`
- a shared core library is in `lib-core/Sources/`, currently for Platform stubs, since I
  compile for testing on macOS in neovim, and swift doesn't understand that the target is
  iOS only.

## commands

- run `just test` to run tests
- run `just build-views` to build/compile swiftui views after any changes
- run `just build-tca` to build/compile main logic after any changes
- run `just build` to build all 3 main modules

## misc

- unless it's a SwiftUI view, NEVER LEAVE COMMENTS
- if i ask you do do anything with the database or custom queries, read the schema from
  `lib-tca/Deps/Database+Migrations.swift`
- for questions about localization (LocalizedStringKey enums, lstr() function, .xcstrings
  files), read `./docs/localization.md`
