set dotenv-filename := ".gtask-ports"
set dotenv-required := false

_default:
  @just --choose

# delegate to sub-justfiles

web *args:
  @cd web && just {{args}}

swift *args:
  @cd swift && just {{args}}

podcasts *args:
  @cd swift/podcasts && just {{args}}

# api shortcuts

api:
  @cd swift && just run-api

watch-api:
  @cd swift && just watch-api

# combined commands

check:
  @cd swift && just check
  @cd web && just check

fix:
  @cd swift && just fix
  @cd web && just fix

# codegen

codegen:
  @just codegen-typescript
  @just codegen-swift
  @just codegen-macapp-appviews

codegen-macapp:
  @cd swift/macapp/App && CODEGEN_MACAPP=1 swift test --filter Codegen
  @just swift fix
  @just codegen-macapp-appviews

codegen-swift:
  @cd swift/macapp/App && CODEGEN_SWIFT=1 swift test --filter Codegen
  @cd swift/api && CODEGEN_SWIFT=1 swift test --filter Codegen
  @just swift fix

codegen-api:
  @cd swift/api && CODEGEN_SWIFT=1 swift test --filter Codegen
  @just swift fix

codegen-typescript:
  @cd swift/macapp/App && CODEGEN_TYPESCRIPT=1 swift test --filter Codegen
  @just web format
  @just codegen-pairql-ts-clients

codegen-ts-codable-enums:
  @cd swift/macapp/App && CODEGEN_TS_CODABLE_ENUMS=1 swift test --filter Codegen
  @cd swift/api && CODEGEN_TS_CODABLE_ENUMS=1 swift test --filter Codegen
  @just swift fix

codegen-pairql-ts-clients:
  #!/usr/bin/env bash
  set -euo pipefail
  (cd swift/api && swift run Run ts-codegen /tmp/codegen)
  (cd web/shared/pairql && CODEGEN_INPUT_DIR=/tmp/codegen pnpm codegen)
  printf "\nRunning 'lint-fix' and 'format' after codegen...\n"
  just web fix

codegen-macapp-appviews isolate="":
  @cd web/appviews && pnpm typecheck && node generate.mts {{isolate}}

