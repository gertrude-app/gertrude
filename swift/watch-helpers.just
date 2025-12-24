[private]
watch-swift dir cmd ignore1="•" ignore2="•":
  @watchexec --project-origin . --clear --restart --watch {{dir}} --exts swift,html \
  --ignore '**/.build/*/**' --ignore '**/index.html' --ignore '{{ignore1}}' --ignore '{{ignore2}}' \
  {{cmd}}

watch-build dir:
  @just watch-swift {{dir}} '"cd {{dir}} && swift build"'

watch-test dir isolate="":
  @just watch-swift {{dir}} '"cd {{dir}} && \
  SWIFT_DETERMINISTIC_HASHING=1 swift test \
  {{ if isolate != "" { "--filter " + isolate } else { "" } }} "'
