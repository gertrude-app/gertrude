## NB: see bottom of file for VM notes

open:
  @open macapp/Xcode/Gertrude.xcodeproj

bump version:
  @node macapp/bump.mjs {{version}}

xcode-build:
  @pnpm exec nx run macapp:xcode-build

vm-logs ip:
  @sshpass -p admin ssh -o StrictHostKeyChecking=no "admin@{{ip}}" '/usr/bin/log stream --predicate "process == \"Gertrude\" OR process == \"com.netrivet.gertrude.filter-extension\"" --level debug --style compact' | /usr/bin/grep --line-buffered '•\]'

vm-clean:
  #!/usr/bin/env bash
  for vm in $(tart list 2>/dev/null | awk '/^local/ && /gertrude-(test|gui)-/ {print $2}'); do
    tart stop "$vm" 2>/dev/null || true
    tart delete "$vm" 2>/dev/null || true
    echo "deleted $vm"
  done
  echo "✓ clean"

vm-create-tahoe:
  #!/usr/bin/env bash
  set -euo pipefail
  if tart list 2>/dev/null | grep -q "gertrude-tahoe"; then
    echo "✗ gertrude-tahoe already exists — delete it first if you want to recreate"
    exit 1
  fi
  echo "→ pulling tahoe base image (this may take a while)..."
  tart clone ghcr.io/cirruslabs/macos-tahoe-base:latest gertrude-tahoe
  echo "→ baking franny..."
  just macapp vm-bake gertrude-tahoe
  echo "✓ gertrude-tahoe ready"
  echo "  use: just macapp vm tahoe"

vm-bake image="gertrude-base":
  #!/usr/bin/env bash
  set -euo pipefail
  echo "→ booting {{image}} for baking..."
  tart run --no-graphics "{{image}}" >/dev/null 2>&1 &
  IP=$(just macapp vm-wait-for-ip "{{image}}")
  echo "→ baking franny into {{image}} at $IP..."
  cat macapp/vm-bake.sh | just macapp vm-ssh "$IP" 'bash -s'
  echo "→ shutting down..."
  just macapp vm-ssh "$IP" 'sudo shutdown -h now' || true
  sleep 8
  echo "✓ {{image}} baked — franny is ready"

vm os="tahoe":
  #!/usr/bin/env bash
  set -euo pipefail
  if [ "{{os}}" = "sequoia" ]; then IMAGE="gertrude-base"
  elif [ "{{os}}" = "tahoe" ]; then IMAGE="gertrude-tahoe"
  elif [ "{{os}}" = "sonoma" ]; then IMAGE="gertrude-sonoma"
  elif [ "{{os}}" = "ventura" ]; then IMAGE="gertrude-ventura"
  else echo "✗ unknown os: {{os}} (expected sequoia, tahoe, sonoma, or ventura)" >&2; exit 1
  fi
  APP=$(just macapp find-app)
  APP_DIR=$(dirname "$APP")
  TARBALL="$APP_DIR/Gertrude.app.tar.gz"
  echo "→ packaging app..."
  tar czf "$TARBALL" -C "$APP_DIR" Gertrude.app
  just macapp vm-clean
  VM="gertrude-gui-$(date +%s)"
  echo "→ cloning $IMAGE..."
  tart clone "$IMAGE" "$VM"
  echo "→ booting headless to install app..."
  tart run --no-graphics --dir=build:"$APP_DIR" "$VM" >/dev/null 2>&1 &
  IP=$(just macapp vm-wait-for-ip "$VM")
  echo "→ installing app at $IP..."
  cat macapp/vm-setup.sh | just macapp vm-ssh "$IP" 'bash -s'
  echo "→ stopping headless VM..."
  tart stop "$VM" 2>/dev/null || true
  sleep 5
  echo "→ launching {{os}} VM with display..."
  echo "  SSH (admin):  sshpass -p admin ssh admin@<ip>    (pw: admin)"
  echo "  SSH (franny): sshpass -p franny ssh franny@<ip>  (pw: franny)"
  echo "  Logs:         just swift macapp vm-logs <ip>"
  echo "  Cleanup:      tart delete $VM"
  echo ""
  tart run --dir=build:"$APP_DIR" "$VM"

# helpers

[private]
find-app:
  #!/usr/bin/env bash
  APP=$(find ~/Library/Developer/Xcode/DerivedData -path "*/Products/VM/Gertrude.app/Contents/MacOS/Gertrude" -maxdepth 10 2>/dev/null \
    | xargs ls -t 2>/dev/null | head -1 \
    | sed 's|/Contents/MacOS/Gertrude$||')
  if [ -z "$APP" ]; then
    echo "✗ no Gertrude.app found in DerivedData with VM config — build with 'Gertrude VM' scheme (Cmd+B)" >&2
    exit 1
  fi
  DD_DIR=$(echo "$APP" | sed 's|/Build/Products/.*||')
  TASK=$(plutil -extract WorkspacePath raw "$DD_DIR/info.plist" 2>/dev/null \
    | sed 's|.*/tasks/||; s|/swift/.*||')
  MOD=$(stat -f %m "$APP/Contents/MacOS/Gertrude")
  NOW=$(date +%s)
  DIFF=$(( (NOW - MOD) / 60 ))
  if [ "$DIFF" -lt 1 ]; then
    AGE="just now"
  elif [ "$DIFF" -lt 60 ]; then
    AGE="${DIFF}m ago"
  else
    AGE="$(( DIFF / 60 ))h ago"
  fi
  echo -e "→ using VM build from $AGE (task: \033[32m$TASK\033[0m)" >&2
  echo "$APP"

[private]
vm-wait-for-ip vm:
  #!/usr/bin/env bash
  for i in $(seq 1 20); do
    IP=$(tart ip "{{vm}}" 2>/dev/null || true)
    [ -n "$IP" ] && echo "$IP" && exit 0
    sleep 3
  done
  echo "✗ timed out waiting for VM" >&2
  exit 1

[private]
vm-ssh ip +cmd:
  @sshpass -p admin ssh -o StrictHostKeyChecking=no "admin@{{ip}}" {{cmd}}

# VM notes (tart-based macOS VMs for testing Gertrude, created 2026-03)
# - must build Release for VM testing: Debug has TSan dylib crash in filter
#   extension (references host DerivedData), filter allows all traffic for
#   UID < 500 (root = UID 0), and LaunchAtLogin is a no-op
# - always `sync` before `tart stop` — without it, filesystem writes may not
#   flush and the app bundle can be corrupt on next boot
# - tart stdout must be redirected before backgrounding with & — otherwise
#   $() captures hang forever waiting for tart to exit
# - screenresolution (brew) can't set HiDPI/retina modes, only 1x — set
#   display scaling manually in System Settings after VM boots
# - golden images: gertrude-base (Sequoia), gertrude-tahoe (Tahoe),
#   gertrude-sonoma (Sonoma), gertrude-ventura (Ventura), all SIP off,
#   Franny user baked in (UID 502, pw: franny, auto-login)
# - SIP must be off: system extensions require notarization with SIP enabled,
#   and dev builds aren't notarized (production builds are, so customers are fine)
