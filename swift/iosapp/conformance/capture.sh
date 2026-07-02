#!/usr/bin/env bash
set -euo pipefail

# Captures Gertrude conformance witness logs from a physically attached iOS device.
# See docs/ios-conformance.md for the full campaign workflow.
#
# Modes:
#   ./capture.sh stream [udid]              live-stream witnesses to logs/witnesses-<ts>.log
#   ./capture.sh collect [udid] [last]      retroactively collect the device log archive
#                                           (includes events across reboots, within the
#                                           archive rotation window) and extract witnesses
#                                           to logs/witnesses-<ts>.ndjson
#
# stream requires idevicesyslog (libimobiledevice); collect requires sudo + Xcode CLTs.

cd "$(dirname "$0")"
mkdir -p logs
ts=$(date +%Y%m%d-%H%M%S)
mode="${1:-stream}"

resolve_udid() {
  local udid="${1:-}"
  if [ -z "$udid" ]; then
    udid=$(idevice_id -l | head -1)
  fi
  if [ -z "$udid" ]; then
    echo "no USB device found (idevice_id -l)" >&2
    exit 1
  fi
  echo "$udid"
}

case "$mode" in
stream)
  udid=$(resolve_udid "${2:-}")
  out="logs/witnesses-$ts.log"
  echo "streaming witnesses from $udid to $out (ctrl+c to stop)"
  echo "tip: reboot the device mid-stream to capture boot-order evidence"
  idevicesyslog -u "$udid" -q -m "WITNESS" | tee "$out"
  ;;
collect)
  udid=$(resolve_udid "${2:-}")
  last="${3:-2h}"
  archive="logs/device-$ts.logarchive"
  out="logs/witnesses-$ts.ndjson"
  echo "collecting last $last of logs from $udid (requires sudo)..."
  sudo log collect --device-udid "$udid" --last "$last" --output "$archive"
  sudo chown -R "$(whoami)" "$archive"
  log show "$archive" \
    --predicate 'eventMessage CONTAINS "[G•] WITNESS"' \
    --info --style ndjson >"$out"
  count=$(wc -l <"$out" | tr -d ' ')
  echo "extracted $count witness lines to $out"
  echo "next: node check.mjs $out"
  ;;
*)
  echo "usage: ./capture.sh stream|collect [udid] [last]" >&2
  exit 1
  ;;
esac
