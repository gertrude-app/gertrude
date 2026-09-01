set dotenv-filename := ".gtask-ports"
set dotenv-required := false

swiftly := "${SWIFTLY_HOME_DIR:-$HOME/.swiftly}/bin/swiftly"

_default:
  @just --choose

# delegate to sub-justfiles

web *args:
  @cd web && just {{args}}

swift *args:
  @cd swift && just {{args}}

podcasts *args:
  @cd swift/podcasts && just {{args}}

music *args:
  @cd swift/music && just {{args}}

verify-podcasts *args:
  @./verification/run podcasts {{args}}

verify-blocker *args:
  @./verification/run blocker {{args}}

verify-music *args:
  @./verification/run music {{args}}

verify-all *args:
  @./verification/run all {{args}}

# api shortcuts

api:
  @cd swift && just run-api

watch-api:
  @cd swift && just watch-api

# combined commands

check:
  @cd swift && just check
  @cd web && just check

api-build:
  @cd swift && just api-build

api-test *args:
  @cd swift && just api-test {{args}}

api-test-serial *args:
  @cd swift && just api-test-serial {{args}}

scheduled-marketing-email-dry-run:
  @cd swift && just scheduled-marketing-email-dry-run

fix:
  @cd swift && just fix
  @cd web && just fix

# duplication

dup *args:
  @node .agents/skills/duplication/find-duplication.mjs {{args}}

update-ui-screenshots:
  @cd web && just update-ui-screenshots

# codegen

codegen:
  @just codegen-typescript
  @just codegen-macapp-appviews

codegen-macapp:
  @cd swift/macapp/App && CODEGEN_MACAPP=1 {{swiftly}} run swift test --filter Codegen
  @just swift fix
  @just codegen-macapp-appviews

codegen-typescript:
  @cd swift/macapp/App && CODEGEN_TYPESCRIPT=1 {{swiftly}} run swift test --filter Codegen
  @just web format
  @just codegen-pairql-ts-clients

codegen-pairql-ts-clients:
  #!/usr/bin/env bash
  set -euo pipefail
  (cd swift/api && {{swiftly}} run swift run Run ts-codegen /tmp/codegen)
  (cd web/shared/pairql && CODEGEN_INPUT_DIR=/tmp/codegen pnpm codegen)
  printf "\nRunning 'lint-fix' and 'format' after codegen...\n"
  just web fix

codegen-macapp-appviews isolate="":
  @cd web/appviews && pnpm typecheck && node generate.mts {{isolate}}
