# Gertrude Parental Controls - Swift Monorepo

## Overview

- **Product:** Gertrude - Parental controls and monitoring system for macOS and iOS
- **Repository:** Swift-based monorepo containing macOS app, iOS app, API server, and
  shared libraries

## Important notes

Never run raw `swift build` or `swift test` commands, to ensure toolchain and env
consistency. If there is something you can't do with the `just` commands, ask for
permission to modify and improve the justfile and agent docs.

Never run `xcodebuild` for any reason.

If you need a UUID, use bash to invoke `uuid --llm` to get one, instead of making one
yourself. Many places in this codebase we use partial identifiers (especially for
logging), like `c05ef986`, if you need one of those, invode `sid --llm`.

## Quick Reference

- **Swift Version:** 6.2.1 via Swiftly
- **Build System:** Swift Package Manager + Nx + Just
- **State Management:** The Composable Architecture (TCA)
- **API Pattern:** PairQL (type-safe RPC over HTTP)
- **Backend:** Vapor 4 + PostgreSQL 17 + Custom Duet ORM

## Repository Structure

```
swift/
├── api/               # Vapor 4 API server (PostgreSQL db)
├── macapp/            # macOS app
├── iosapp/            # iOS app
├── gertie/            # Core domain models (shared across platforms)
├── duet/              # Custom lightweight ORM
├── pairql/            # Type-safe RPC core library
├── pairql-macapp/     # macOS API pairql route definitions
├── pairql-iosapp/     # iOS API pairql route definitions
├── pairql-podcasts/   # Podcast app (not in monorepo) pairql API routes
├── ts-interop/        # TypeScript code generation
└── docs/              # Documentation
```

## The Three Main Applications

### 1. macOS App (`macapp/`)

**Structure:**

- `Xcode/Gertrude.xcodeproj` - Xcode project
- `App/` - SPM package with all business logic

**Key Features:**

- System-level network filtering (Network Extension)
- Keystroke logging
- Screenshot monitoring
- App blocking
- Filter suspension with parent approval
- Health check and self-healing system
- WebSocket real-time updates
- XPC communication (app ↔ filter extension)

**Tech Stack:**

- TCA for state management
- Web views for UI, no SwiftUI
- Network Extension Framework for filtering
- XPC for inter-process communication
- Starscream for WebSockets
- Sparkle for auto-updates

**Key Modules:**

- `App` - Main app feature (TCA-based)
- `Filter` - Network filter extension
- `Core` - Shared types
- `ClientInterfaces` - Dependency protocols
- `Live*Client` - Live implementations (API, WebSocket, XPC, etc.)

**VM Testing:**

A macOS VM may be running for manual testing. If `swift/.env.vm` exists, you can run
commands on it non-interactively via:

```bash
source swift/.env.vm && sshpass -p franny ssh -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "franny@$VM_IP" "<command>"
```

### 2. iOS App (`iosapp/`)

**Description**:

An iOS app designed to plug the holes in Screen Time, including blocking #images GIF
searches, and more

**Structure:**

- `Gertrude-iOS.xcodeproj` - Xcode project
- `lib-ios/` - SPM package with core logic
- `app/` - Main app target
- `controller/` - Controller extension target
- `filter/` - Network filter extension target

**Key Features:**

- Content filtering via Network Extension
- Parent-controlled filtering rules

**Context:**

- most commonly authorized via Screen Time, for users < 18
- can also be authorized via Supervision, we support a custom supervision process, if you
  need to know about it read `./docs/ios-supervision.md` from monorepo root.

**Tech Stack:**

- TCA for state management
- SwiftUI for UI
- Network Extension Framework
- PairQL for API communication
- Point-Free Dependencies for DI

**Key Modules (lib-ios):**

- `LibCore` - Core iOS types
- `LibFilter` - Network filtering logic
- `LibController` - Device management
- `LibClients` - API clients
- `LibApp` - Main app UI (TCA-based)

- when working on refining, or adding new iOS block rules, read
  `./docs/ios-block-rule-analysis.md` for a workflow for analyzing filter logs without the
  Console.app
- when investigating a "can we block X in <app>?" question, first read
  `./docs/ios-block-findings.md` to see what's already been tried

### 3. API Server (`api/`)

**Deployment:** api.gertrude.app

**Tech Stack:**

- Vapor 4
- PostgreSQL 17
- Duet + DuetSQL (custom ORM abstraction over Fluent)
- PairQL for type-safe routing

**API PairQL Domains:**

- `macos-app` - Mac app routes
- `ios-app` - iOS app routes
- `dashboard` - Web dashboard routes
- `gertrude-am` - Podcast app routes
- `super-admin` - Admin tools

**External Integrations:**

- Stripe (payments)
- Postmark (email)
- Slack (notifications)
- AWS S3 (storage)

**Deployment:**

- GitHub Actions CI/CD builds binary with ssh/scp deployment
- Separate production/staging builds
- see `./docs/api-build.md` for details on ci build

## Core Shared Libraries

### `gertie/` - Domain Models

- **Purpose:** Core domain types shared across macOS, iOS, and API
- **Products:** `Gertie`, `GertieBlocker`

### `duet/` - Custom ORM

**Purpose:** Type-safe database abstraction over Fluent/PostgreSQL

### `pairql/` - Type-Safe RPC Core

**Purpose:** Foundation for all client-server communication

**Key Concepts:**

- `Pair<Input, Output>` - Request/response pair
- `PairInput` - Request data
- `PairOutput` - Response data
- `ClientAuth` - Authentication types
- `PqlError` - Standardized error handling
- Uses URLRouting for bidirectional parser/printer
- Custom fork of swift-url-routing (avoids swift-syntax dependency)

**Architecture:** See `./docs/pairql.md` for comprehensive documentation

### `pairql-macapp/` & `pairql-iosapp/`

**Purpose:** Platform-specific API route definitions **Shared Between:** API server and
client apps

### Utility Libraries (`x-*` packages)

All `x-*` libraries:

- Follow Point-Free dependency injection patterns
- Zero or minimal dependencies
- MIT licensed
- Platform support: macOS (.v12+) or cross-platform (.v10_15+)

**`x-kit/`** - Core utilities (XCore, XBase64) **`x-http/`** - Zero-dependency HTTP client
(async/await, JSON/form support) **`x-expect/`** - Testing assertions with better diffs
**`x-aws/`** - AWS S3 client with swift-crypto signing **`x-slack/`** - Slack messaging
(text + blocks) **`x-stripe/`** - Stripe payment client (USD only, intentional)
**`x-postmark/`** - Postmark email delivery

## Key Architectural Patterns

### The Composable Architecture (TCA)

**Used By:** macOS app, iOS app

**Benefits:**

- Unidirectional data flow
- Effect system for side effects
- Testable by default (reducer composition)
- Dependencies library for DI

## Development Workflow

### Build Commands (Just)

```bash
just build         # Build all packages
just test          # Run all tests
just api-build     # Build the API
just api-test      # Run API tests
just api-test --filter SomeTestName
just macapp-test   # Run the macOS app package tests
just iosapp-test   # Run the iOS library package tests
just lint-fix      # Fix formatting
```

### Testing

**Framework:** XCTest + x-expect **CI:** GitHub Actions (Linux + macOS + iOS)

**Test Commands:**

```bash
just test                           # All tests
just api-test                       # API tests only
just api-test --filter SomeTestName # API tests filtered by substring
just macapp-test                    # macOS app package tests
just iosapp-test                    # iOS library package tests
```

### Package Manager

- **SPM** - Primary package manager
- **pnpm** (v10.12.1) - For npm dependencies (Nx, TypeScript)
- **Nx** - Monorepo task caching

## Notable Files

### Documentation

- `/docs/pairql.md` - PairQL architecture (comprehensive, 281 lines)
- `macapp/readme.md` - macOS release notes and procedures
- `iosapp/readme.md` - iOS release notes and config
- `api/readme.md` - Docker setup instructions
- Individual library READMEs for public packages

## Common Tasks & Locations

### Adding a New API Endpoint

- see `./docs/pairql.md`

### Duet ORM

If you are doing anything non-trivial in the API with the Duet database layer, read
`../.agents/skills/duet/SKILL.md` before writing/editing queries.

### Adding a Database Migration

- read several examples in `api/Sources/Api/Database/Migrations/` to see pattern
- for any non-trivial migration (data backfill, column drop, transforms, etc.), follow
  `./.agents/skills/migration-verification/SKILL.md` to capture a pre/post baseline
  before merging

### Adding/Removing a Model Field

Adding/removing a field/column to a model requires changes in three files:

- The model struct (e.g. `api/Sources/Api/Models/IOS/IOSDevice.swift`) — add the property
- `api/Sources/Api/Models/Models+Duet.swift` — add to the `CodingKeys` enum
- `api/Sources/Api/Models/Models+DuetSQL.swift` — add to `postgresData` and `insertValues`

### Other database tasks

- see `./.agents/skills/database/SKILL.md`
