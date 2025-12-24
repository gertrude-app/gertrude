# Code Generation

This project uses code generation of four types:

- Swift Codable enums for better interop with TypeScript + enums w/ payloads
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
| `just codegen-swift`             | Swift Codable enums for macapp and api                        |
| `just codegen-api`               | All API codegen (currently just swift codable enums)          |
| `just codegen-typescript`        | All TypeScript codegen (appview store types + pairql clients) |
| `just codegen-pairql-ts-clients` | PairQL TypeScript clients (requires API running)              |
| `just codegen-macapp-appviews`   | Build React appviews and copy to Xcode project                |

## What Gets Generated

### Swift Codable Enums (`codegen-swift`)

Generates `+Codable.swift` files for swift enums with payloads that need to be accessed
from typescript. By default, swift codable implementation generates json that is not
friendly to typescript, so we generate custom codable implementations for these enums.

- `swift/macapp/App/Sources/App/Generated/*+Codable.swift` - Mac app feature enums
- `swift/api/Sources/Api/Extend/Enums+Codable.swift` - API response types
- `swift/gertie/Sources/GertieIOS/Enums+Codable.swift` - iOS types

### PairQL TypeScript Clients (`codegen-pairql-ts-clients`)

Fetches route specs from running local API and generates type-safe TypeScript clients in
`web/shared/pairql/src/` for Dashboard and Admin web apps.

NB: requires local API to be running

### Macapp TypeScript Store Types (`codegen-typescript`)

Generates TypeScript type definitions in `web/appviews/src/` for React webviews embedded
in the mac app. These mirror the Swift TCA state/action types.

### Macapp Webviews Build (`codegen-macapp-appviews`)

Builds mini React apps (one for each macapp ui window feature: Menu Bar, Blocked Requests,
Request Suspension, Admin, Onboarding) and copies output to
`swift/macapp/Xcode/Gertrude/WebViews/`. These are embedded in the mac app via WKWebView.
