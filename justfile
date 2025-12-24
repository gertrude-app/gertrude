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

lint-fix:
  @cd swift && just lint-fix
  @cd web && just lint-fix

format:
  @cd swift && just lint-fix
  @cd web && just format
