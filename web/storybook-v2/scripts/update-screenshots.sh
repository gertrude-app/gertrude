#!/usr/bin/env bash
set -euo pipefail

storybook_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
web_dir="$(dirname "$storybook_dir")"
cd "$storybook_dir"

if ! command -v docker >/dev/null 2>&1; then
  printf '%s\n' 'Docker CLI is required. See web/storybook-v2/README.md for setup.' >&2
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  printf '%s\n' 'Docker is not running. Start Colima with: colima start' >&2
  exit 1
fi

if ! docker buildx version >/dev/null 2>&1; then
  printf '%s\n' 'Docker Buildx is required. See web/storybook-v2/README.md for setup.' >&2
  exit 1
fi

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/gertrude-ui-screenshots.XXXXXX")"
container_id=""

cleanup() {
  if [[ -n "$container_id" ]]; then
    docker rm --force "$container_id" >/dev/null 2>&1 || true
  fi
  rm -rf "$tmp_dir"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

docker buildx build --load --platform linux/arm64 \
  --file "$storybook_dir/Dockerfile" \
  --tag gertrude-ui-screenshots:local \
  --iidfile "$tmp_dir/image-id" \
  "$web_dir"

container_id="$(docker create --platform linux/arm64 --init --network none \
  --shm-size 1g \
  --env "SCREENSHOT_CONCURRENCY=${SCREENSHOT_CONCURRENCY:-6}" \
  "$(< "$tmp_dir/image-id")")"
docker start --attach "$container_id"
exit_code="$(docker inspect --format '{{.State.ExitCode}}' "$container_id")"
if [[ "$exit_code" != 0 ]]; then
  printf 'Screenshot capture failed (exit %s); existing screenshots were preserved.\n' "$exit_code" >&2
  exit 1
fi

docker cp "$container_id:/workspace/storybook-v2/screenshots" "$tmp_dir/screenshots"
output_dir="${SCREENSHOT_DIR:-$storybook_dir/screenshots}"
mkdir -p "$output_dir"
rsync -a --delete "$tmp_dir/screenshots/" "$output_dir/"
printf '\nUpdated screenshots in %s\n' "$output_dir"
