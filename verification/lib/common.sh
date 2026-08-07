#!/usr/bin/env bash

verification_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
root="$(cd "$verification_root/.." && pwd)"

ports_file="${VERIFY_PORTS_FILE:-$root/.gtask-ports}"
if [[ -f "$ports_file" ]]; then
  set -a
  source "$ports_file"
  set +a
fi

api_port="${API_PORT:-8080}"
dash_port="${DASH_PORT:-8081}"
api_url="${API_ENDPOINT:-http://127.0.0.1:$api_port}"
dash_url="${DASH_URL:-http://localhost:$dash_port}"
reset_suffix="$(grep -E '^RESET_ROUTE_SUFFIX=' "$root/swift/api/.env" 2>/dev/null | cut -d= -f2- || true)"
reset_url="${reset_suffix:+$api_url/reset-$reset_suffix}"

ok() { printf "ok      %s\n" "$1"; }
warn() { printf "warn    %s\n" "$1"; }
missing() { printf "missing %s\n" "$1"; }

have() {
  command -v "$1" >/dev/null 2>&1
}

http_ready() {
  curl -fsS --max-time 2 "$1" >/dev/null 2>&1
}

env_file_value() {
  local file="$1" key="$2"
  [[ -f "$file" ]] || return 0
  grep -E "^$key=" "$file" 2>/dev/null | head -1 | cut -d= -f2-
}

require_env_value() {
  local file="$1" key="$2" label="$3"
  if [[ -n "$(env_file_value "$file" "$key")" ]]; then
    ok "$label ($key in ${file#$root/})"
  else
    missing "$label — set $key in ${file#$root/}"
  fi
}

check_shared_env() {
  require_env_value "$root/swift/api/.env" RESET_ROUTE_SUFFIX "api reset route (seeds fixtures)"
  require_env_value "$root/web/dash/app/.env.local" VITE_API_ENDPOINT "dashboard -> api endpoint"
}

booted_simulators() {
  xcrun simctl list devices booted 2>/dev/null \
    | sed -nE 's/^[[:space:]]*(.*) \(([0-9A-Fa-f-]{36})\) \(Booted\).*$/\2\t\1/p'
}

simulator_os_version() {
  local udid="$1"
  xcrun simctl list devices booted 2>/dev/null | awk -v id="$udid" '
    /^-- / { rt = $0; next }
    index($0, id) {
      if (match(rt, /[0-9]+(\.[0-9]+)*/)) print substr(rt, RSTART, RLENGTH)
      exit
    }'
}

simulator_os_major() {
  local version
  version="$(simulator_os_version "$1")"
  echo "${version%%.*}"
}

simulator_sdk_version() {
  xcrun --sdk iphonesimulator --show-sdk-version 2>/dev/null || true
}

version_lt() {
  [[ "$1" != "$2" && "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -1)" == "$1" ]]
}

require_supported_sim_os() {
  local sim="$1" version major sdk
  version="$(simulator_os_version "$sim")"
  if [[ -z "$version" ]]; then
    echo "warn    could not determine iOS version for $sim; continuing" >&2
    return 0
  fi
  major="${version%%.*}"
  if (( major < 26 )); then
    if [[ -n "${VERIFY_ALLOW_OLD_SIM:-}" ]]; then
      echo "warn    simulator is iOS $version (<26); VERIFY_ALLOW_OLD_SIM set, continuing" >&2
      return 0
    fi
    echo "simulator is iOS $version; these flows require iOS 26+ (native .searchable hangs on older sims)." >&2
    echo "boot an iOS 26+ simulator, or set VERIFY_ALLOW_OLD_SIM=1 to override." >&2
    return 66
  fi

  sdk="$(simulator_sdk_version)"
  if [[ -n "$sdk" ]] && version_lt "$version" "$sdk"; then
    if [[ -n "${VERIFY_ALLOW_OLD_SIM:-}" ]]; then
      echo "warn    simulator iOS $version is older than the iOS $sdk SDK; VERIFY_ALLOW_OLD_SIM set, continuing" >&2
      return 0
    fi
    echo "simulator is iOS $version but the apps build against the iOS $sdk SDK." >&2
    echo "symbols introduced after iOS $version (e.g. SwiftUI's .glassEffect) link weakly and are" >&2
    echo "missing at runtime, so the app aborts mid-flow with 'a reference to a missing weak symbol'." >&2
    echo "boot an iOS $sdk simulator, or set VERIFY_ALLOW_OLD_SIM=1 to override." >&2
    return 66
  fi
  return 0
}

diagnose_missing_claim_code() {
  local scenario="$1"
  if find "$HOME/Library/Logs/DiagnosticReports" -name 'SpringBoard-*.ips' -mmin -3 2>/dev/null | grep -q .; then
    echo "SpringBoard crashed during this run (XCTAutomationSupport respring — see verification/README.md gotchas); the app was killed with it." >&2
    echo "rerun: just verify-$scenario flow, then: just verify-$scenario claim" >&2
  else
    echo "claim code not found in simulator hierarchy; run: just verify-$scenario flow" >&2
  fi
}

report_one_sim_os() {
  local sim="$1" sdk="$2" version major label
  version="$(simulator_os_version "$sim")"
  [[ -n "$version" ]] || return 0
  label="$(selected_simulator_name "$sim")"
  label="${label:-$sim}"
  major="${version%%.*}"
  if (( major < 26 )); then
    warn "$label: iOS $version (<26); flows require iOS 26+ (set VERIFY_ALLOW_OLD_SIM=1 to override)"
  elif [[ -n "$sdk" ]] && version_lt "$version" "$sdk"; then
    warn "$label: iOS $version is older than the iOS $sdk SDK; expect missing-weak-symbol crashes"
  else
    ok "$label: iOS $version (matches iOS ${sdk:-?} SDK)"
  fi
}

report_sim_os() {
  local sim sdk
  sdk="$(simulator_sdk_version)"
  if [[ -n "${SIMULATOR_UDID:-}" ]]; then
    report_one_sim_os "$SIMULATOR_UDID" "$sdk"
    return 0
  fi
  while IFS=$'\t' read -r sim _; do
    [[ -n "$sim" ]] && report_one_sim_os "$sim" "$sdk"
  done < <(booted_simulators)
}

selected_simulator() {
  local sim=""
  if [[ -n "${SIMULATOR_UDID:-}" ]]; then
    if xcrun simctl list devices booted 2>/dev/null | grep -q "$SIMULATOR_UDID"; then
      sim="$SIMULATOR_UDID"
    else
      echo "SIMULATOR_UDID is not booted: $SIMULATOR_UDID" >&2
      return 66
    fi
  else
    count="$(booted_simulators | wc -l | tr -d ' ')"
    if [[ "$count" == "1" ]]; then
      sim="$(booted_simulators | cut -f1)"
    elif [[ "$count" == "0" ]]; then
      echo "no booted simulator found" >&2
      return 66
    else
      echo "multiple booted simulators found; set SIMULATOR_UDID to choose one:" >&2
      booted_simulators | sed 's/^/  /' >&2
      return 66
    fi
  fi

  require_supported_sim_os "$sim" || return $?
  echo "$sim"
}

selected_simulator_name() {
  local simulator="$1"

  booted_simulators | awk -F '\t' -v id="$simulator" '$1 == id { print $2 }'
}

reset_server_state() {
  if [[ -z "$reset_url" ]]; then
    warn "reset route not configured (RESET_ROUTE_SUFFIX in swift/api/.env); skipping API reset"
    return 0
  fi

  if curl -fsS "$reset_url" >/dev/null; then
    ok "API reset via maintained route (known fixtures reseeded)"
  else
    echo "API reset route failed: $reset_url" >&2
    return 70
  fi
}
