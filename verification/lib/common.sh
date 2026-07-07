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

simulator_os_major() {
  local udid="$1"
  xcrun simctl list devices booted 2>/dev/null | awk -v id="$udid" '
    /^-- / { rt = $0; next }
    index($0, id) {
      if (match(rt, /[0-9]+/)) print substr(rt, RSTART, RLENGTH)
      exit
    }'
}

require_supported_sim_os() {
  local sim="$1" major
  major="$(simulator_os_major "$sim")"
  if [[ -z "$major" ]]; then
    echo "warn    could not determine iOS version for $sim; continuing" >&2
    return 0
  fi
  if (( major < 26 )); then
    if [[ -n "${VERIFY_ALLOW_OLD_SIM:-}" ]]; then
      echo "warn    simulator is iOS $major (<26); VERIFY_ALLOW_OLD_SIM set, continuing" >&2
      return 0
    fi
    echo "simulator is iOS $major; these flows require iOS 26+ (native .searchable hangs on older sims)." >&2
    echo "boot an iOS 26+ simulator, or set VERIFY_ALLOW_OLD_SIM=1 to override." >&2
    return 66
  fi
  return 0
}

report_sim_os() {
  local count sim major
  count="$(booted_simulators | wc -l | tr -d ' ')"
  [[ "$count" == "1" ]] || return 0
  sim="$(booted_simulators | cut -f1)"
  major="$(simulator_os_major "$sim")"
  [[ -n "$major" ]] || return 0
  if (( major >= 26 )); then
    ok "simulator iOS $major (>=26)"
  else
    warn "simulator iOS $major (<26); flows require iOS 26+ (set VERIFY_ALLOW_OLD_SIM=1 to override)"
  fi
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
