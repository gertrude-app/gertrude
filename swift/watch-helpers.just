[private]
watch_swiftly := "${SWIFTLY_HOME_DIR:-$HOME/.swiftly}/bin/swiftly"

[private]
watch-swift dir cmd:
  @watchexec --project-origin . --clear --restart --watch {{dir}} --exts swift,html \
  --ignore '**/.build/*/**' --ignore '**/index.html' \
  {{cmd}}

watch-build dir:
  @just watch-swift {{dir}} '"cd {{dir}} && {{watch_swiftly}} run swift build"'

watch-test dir isolate="":
  @just watch-swift {{dir}} '"cd {{dir}} && \
  SWIFT_DETERMINISTIC_HASHING=1 {{watch_swiftly}} run swift test \
  {{ if isolate != "" { "--filter " + isolate } else { "" } }} "'
