# Code Generation

This project uses code generation of three types:

- Typesafe TypeScript pairql clients generated from swift pairql types
- Mac app communicates via js bridge to react webviews, types are generated for
  state/actions
- Mac app webviews for each UI window are built as standalne mini React apps

Run all codegen: `just codegen`

## Commands

| Command                          | Description                                                   |
| -------------------------------- | ------------------------------------------------------------- |
| `just codegen`                   | Run all codegen tasks                                         |
| `just codegen-macapp`            | All mac app codegen (Swift + TypeScript + appviews build)     |
| `just codegen-typescript`        | All TypeScript codegen (appview store types + pairql clients) |
| `just codegen-pairql-ts-clients` | PairQL TypeScript clients (requires API running)              |
| `just codegen-macapp-appviews`   | Build React appviews and copy to Xcode project                |

## What Gets Generated

### PairQL TypeScript Clients (`codegen-pairql-ts-clients`)

Fetches route specs from running local API and generates type-safe TypeScript clients in
`web/shared/pairql/src/` for Dashboard, Admin, and Account web apps.

NB: requires local API to be running

### Macapp TypeScript Store Types (`codegen-typescript`)

Generates TypeScript type definitions in `web/appviews/src/` for React webviews embedded
in the mac app. These mirror the Swift TCA state/action types.

### Macapp Webviews Build (`codegen-macapp-appviews`)

Builds mini React apps (one for each macapp ui window feature: Menu Bar, Blocked Requests,
Request Suspension, Admin, Onboarding) and copies output to
`swift/macapp/Xcode/Gertrude/WebViews/`. These are embedded in the mac app via WKWebView.
