#!/usr/bin/env bash
set -euo pipefail

# Splitting test for the R7 mystery (see agent.report.first-test.md):
# `capture.sh stream` filters with `-m WITNESS`, so an app that emits NO witness
# lines is invisible by construction — "app appears nowhere in the stream log" is
# nearly circular. This script runs an UNFILTERED idevicesyslog capture and reports
# whether the host app process produces ANY log output at all, independent of the
# WITNESS marker. Run it while deliberately provoking app-side work (open the info
# sheet, toggle a block group, trigger a rule refresh) for ~30s.
#
#   ./probe-app-visibility.sh [udid] [seconds]
#
# Output: counts of total lines, filter/controller process lines, and host-app
# process lines, plus any [G•] lines from the host app. Saves the raw capture to
# logs/app-probe-<ts>.log.
#
# Interpretation:
#   - host-app lines > 0  -> idevicesyslog CAN see the app -> R7 gap is a stale
#     build (clean rebuild, redo the one info-sheet tap + rule change).
#   - host-app lines = 0  -> idevicesyslog has a real blind spot for the host app
#     process -> rely on `collect` for all app-side witnesses (R7 and future);
#     R7 then needs one `collect` pass with a deliberate rule change.

cd "$(dirname "$0")"
mkdir -p logs
ts=$(date +%Y%m%d-%H%M%S)
out="logs/app-probe-$ts.log"

udid="${1:-}"
if [ -z "$udid" ]; then
  udid=$(idevice_id -l | head -1)
fi
[ -n "$udid" ] || { echo "no USB device found" >&2; exit 1; }
secs="${2:-30}"

echo "unfiltered capture from $udid for ${secs}s -> $out"
echo "NOW PROVOKE APP-SIDE WORK: open the info sheet, toggle a block group, refresh rules."
( idevicesyslog -u "$udid" -q >"$out" ) &
pid=$!
sleep "$secs"
kill "$pid" 2>/dev/null || true
wait "$pid" 2>/dev/null || true

total=$(wc -l <"$out" | tr -d ' ')
flt=$(grep -ciE '\b(filter)\b' "$out" || true)
ctl=$(grep -ciE '\b(controller)\b' "$out" || true)
# host app bundle id is com.netrivet.gertrude-ios.app; process name may be the
# executable name (e.g. "Gertrude"). Match either, excluding the .app.filter /
# .app.recorder / .app.controller extensions.
app=$(grep -cE 'gertrude-ios\.app\b|gertrude-ios\(' "$out" || true)
appg=$(grep -cE '\[G•\]' "$out" | head -1 || true)

echo
echo "---- probe result ----"
echo "total lines:        $total"
echo "filter process:     $flt"
echo "controller process: $ctl"
echo "host-app (bundle):  $app"
echo "any [G•] lines:     $appg"
echo
echo "sample host-app lines (first 10):"
grep -nE 'gertrude-ios\.app\b|gertrude-ios\(' "$out" | head -10 || echo "(none)"
