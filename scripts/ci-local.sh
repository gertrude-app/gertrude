#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ -f .gtask-ports ]]; then
  # shellcheck disable=SC1091
  source .gtask-ports
fi

API_PORT="${API_PORT:-8080}"
DASH_PORT="${DASH_PORT:-8081}"
CI_API_PORT="${CI_API_PORT:-$((API_PORT + 100))}"
CI_DASH_PORT="${CI_DASH_PORT:-$((DASH_PORT + 100))}"

if [[ ! -f swift/api/.env ]]; then
  echo "Missing swift/api/.env" >&2
  exit 1
fi

TEST_DATABASE_NAME="$(
  awk -F= '$1 == "TEST_DATABASE_NAME" { print $2 }' swift/api/.env | tail -n 1
)"
RESET_ROUTE_SUFFIX="$(
  awk -F= '$1 == "RESET_ROUTE_SUFFIX" { print $2 }' swift/api/.env | tail -n 1
)"

if [[ -z "$TEST_DATABASE_NAME" || -z "$RESET_ROUTE_SUFFIX" ]]; then
  echo "Missing TEST_DATABASE_NAME or RESET_ROUTE_SUFFIX in swift/api/.env" >&2
  exit 1
fi

RESET_URL="http://127.0.0.1:${CI_API_PORT}/reset-${RESET_ROUTE_SUFFIX}"
API_LOG="$(mktemp -t ci-local-api.XXXXXX.log)"
DASH_LOG="$(mktemp -t ci-local-dash.XXXXXX.log)"
API_PID=""
DASH_PID=""

cleanup() {
  local exit_code=$?
  if [[ -n "$DASH_PID" ]] && kill -0 "$DASH_PID" 2>/dev/null; then
    kill "$DASH_PID" 2>/dev/null || true
    wait "$DASH_PID" 2>/dev/null || true
  fi
  if [[ -n "$API_PID" ]] && kill -0 "$API_PID" 2>/dev/null; then
    kill "$API_PID" 2>/dev/null || true
    wait "$API_PID" 2>/dev/null || true
  fi
  if [[ $exit_code -ne 0 ]]; then
    printf '\nAPI log: %s\n' "$API_LOG" >&2
    tail -n 80 "$API_LOG" >&2 || true
    printf '\nDashboard log: %s\n' "$DASH_LOG" >&2
    tail -n 80 "$DASH_LOG" >&2 || true
  else
    rm -f "$API_LOG" "$DASH_LOG"
  fi
}
trap cleanup EXIT

require_clean_paths() {
  if ! git diff --quiet -- "$@"; then
    echo "Refusing to run with existing changes in: $*" >&2
    exit 1
  fi
}

verify_codegen() {
  require_clean_paths swift web/appviews/src web/shared/pairql
  just codegen-typescript
  if ! git diff --exit-code -- swift web/appviews/src web/shared/pairql web/dash/app/cypress/support/intercept.ts; then
    echo "Codegen output changed. Run the relevant codegen command(s) and commit the results." >&2
    exit 1
  fi
}

wait_for_http() {
  local url="$1"
  local attempts="${2:-120}"
  local delay="${3:-1}"
  local i
  for ((i = 1; i <= attempts; i++)); do
    if curl --silent --fail "$url" >/dev/null 2>&1; then
      return 0
    fi
    sleep "$delay"
  done
  echo "Timed out waiting for $url" >&2
  return 1
}

wait_for_port() {
  local port="$1"
  local attempts="${2:-120}"
  local delay="${3:-1}"
  local i
  for ((i = 1; i <= attempts; i++)); do
    if nc -z 127.0.0.1 "$port" >/dev/null 2>&1; then
      return 0
    fi
    sleep "$delay"
  done
  echo "Timed out waiting for port $port" >&2
  return 1
}

DATABASE_NAME="$TEST_DATABASE_NAME" just check
verify_codegen

(
  cd swift
  just nuke-test-db
  DATABASE_NAME="$TEST_DATABASE_NAME" just migrate-up
) >/dev/null

(
  cd swift
  DATABASE_NAME="$TEST_DATABASE_NAME" API_PORT="$CI_API_PORT" just run-api
) >"$API_LOG" 2>&1 &
API_PID=$!

wait_for_port "$CI_API_PORT"
curl --silent --fail "$RESET_URL" >/dev/null

(
  cd web
  VITE_API_ENDPOINT="http://127.0.0.1:${CI_API_PORT}" \
  VITE_TURNSTILE_SITEKEY="not-real" \
  VITE_GTM_ID="not-real" \
  PORT="$CI_DASH_PORT" \
  just build-dash
)

(
  cd web
  VITE_API_ENDPOINT="http://127.0.0.1:${CI_API_PORT}" \
  VITE_TURNSTILE_SITEKEY="not-real" \
  VITE_GTM_ID="not-real" \
  PORT="$CI_DASH_PORT" \
  pnpm --filter @dash/app preview
) >"$DASH_LOG" 2>&1 &
DASH_PID=$!

wait_for_http "http://localhost:${CI_DASH_PORT}"

(
  cd web
  DASH_PORT="$CI_DASH_PORT" just cy-run
)
