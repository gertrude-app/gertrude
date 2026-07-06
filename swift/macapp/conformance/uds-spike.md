# Unix-domain-socket app ↔ filter channel — spike findings

**Verdict: GO.** Every success criterion from the spike plan (ledger 10) was met,
including all lifecycle witnesses on a real VM with the production filter
extension. The 2024 spike's unsolved half (app→filter reads) turned out to be a
one-line bug, not a platform limitation. UDS gives us the two things XPC
structurally can't: **instant, kernel-truthful dead-peer detection** in both
directions, and **no mach-registration invalidation** across extension
replacement — the exact mechanism behind the 77% filter-alive/channel-dead
field wedge (ledger 10 telemetry).

Branch: `mac-uds-spike` (this task dir). Code is runtime-gated, not merged, and
never activates without the marker file (see Gating below).

## What was built

- `App/Sources/Core/UDSSpike.swift` — shared wire protocol: Codable message
  enum, 4-byte length-prefixed JSON framing, incremental frame parser, socket
  path scheme, marker-file gate.
- `App/Sources/Filter/UDSSpikeServer.swift` — filter-side server, **BSD sockets
  + DispatchSource** (see NW finding below). Creates `/var/run/gertrude/`
  (0755), binds one socket per discovered uid (`/Users` dirs, uid ≥ 500) at
  `spike-<uid>.sock`, chmod 0600 + chown uid, accepts, extracts peer audit
  token, validates, then serves. Push timer proves filter-initiated sends.
- `App/Sources/App/UDSSpikeClient.swift` — app-side client, **Network.framework**
  `NWConnection(to: .unix(path:), using: .tcp)`, receive loop + frame parser,
  2s retry loop on ENOENT/ECONNREFUSED/EOF, periodic pings.
- Hooks: one line each in `FilterDataProvider.init` and
  `AppDelegate.applicationDidFinishLaunching`.
- `App/Tests/MacSimTests/UDSSpikeTests.swift` — 3 local tests (round-trip, peer
  rejection, rebind/reconnect) over temp-dir sockets; run with
  `just macapp-test --filter UDSSpikeTests`.

## Success criteria — all witnessed

VM `gertrude-test-wedge`, macOS 26.3, production-signed VM-scheme builds
(2.9.5/2.9.6), real `[activated enabled]` filter extension. Log evidence via
`[G•] UDS` predicate capture; timestamps below are from the 2026-07-06
22:56–23:04 UTC-4 session.

### 1. Root socket dir + per-uid sockets + ownership ✅

Filter (root) created `/var/run/gertrude/`; bound `spike-501.sock` (admin) and
`spike-502.sock` (franny) — the VM turned out to have TWO ≥500 uids, so the
per-uid design was exercised for real, not vacuously. Post-reboot `ls -la`:

```
srw-------  1 admin   wheel  0 Jul  6 22:59 spike-501.sock
srw-------  1 franny  wheel  0 Jul  6 22:59 spike-502.sock
```

0600 + per-uid owner means user A cannot connect to user B's channel (connect
requires write permission on the socket file). No group-container/TCC exposure.

### 2. Bidirectional Codable round-trip ✅ (both directions, both initiators)

- app→filter→app: `ping n` → `pong n`, continuously, every 20s.
- **filter→app→filter**: `filterPush n` → `pushAck n`, every 30s — the filter
  initiating a send to the app over the same accepted connection, no mach
  lookup, no URL-message side channel.
- JSON-over-length-prefix framing decoded cleanly in both directions; hello
  carries pid/uid/version, ack carries filter pid/version.

**Why the 2024 spike failed on app→filter**: `ServerUDS.readData()` (bak-swift
`bf246b51`) read from the *listening* fd instead of the *accepted* fd. Not a
platform limitation. With the right fd it works trivially.

### 3. Peer auth: LOCAL_PEERTOKEN → audit token → SecCode ✅

`getsockopt(fd, SOL_LOCAL, LOCAL_PEERTOKEN)` (in the macOS SDK, un.h) yields
the peer `audit_token_t`, which drops straight into the existing
`SecurityClient` machinery: `audit_token_to_ruid` must equal the socket's uid,
and `SecCodeCopyGuestWithAttributes(kSecGuestAttributeAudit:)` →
main-executable bundle id must be `com.netrivet.gertrude.app`. Witnessed live
("peer validated, connection accepted for uid 502") against the real
/Applications app on every connection; the reject path is covered by the local
test (rejected peers are closed before any message is processed). This is
strictly stronger than the current XPC listener, which accepts any local
process. Production would add `SecRequirement` validation (team id + signing
requirement, not just bundle id string) — same token, same API family.

### 4. Lifecycle witnesses ✅ (the money test vs XPC)

- **App kill/relaunch** (pid 5090→5153): server saw EOF *instantly* at kill
  time; relaunched app connected + validated ~5s later (helper relaunch
  latency, not channel latency).
- **Filter kill/respawn** (pid 5101→5200): client saw "connection closed by
  server" *immediately* (kernel EOF — XPC gives silence here), retried through
  ECONNREFUSED on the stale socket file, respawned server unlink+rebound,
  client reconnected **600ms after bind**. ~6s total outage, all of it NE
  respawn time.
- **Reboot**: `/var/run` wiped as expected; boot happened to produce the
  app-before-filter ordering — client retried ENOENT 5× over 10s, filter bound
  at +10s, client connected **77ms later**. Round trips resumed both
  directions. Indeterminate boot order handled by design (dumb retry loop), not
  by luck.
- **6 ext-replacement update cycles** (2.9.5⇄2.9.6, real production update
  path: bundle swap + kill -9 → version mismatch → `replaceFilter`), plus the
  initial 2.9.4→2.9.5 deploy = 7 replacements, **7/7 clean**. Every cycle:
  fresh bind, fresh validated connection, fresh hello/helloAck. No wedge-able
  registration state exists to go stale.
- **Version-skew tolerance witnessed free of charge**: in every update cycle
  the NEW app version connected to and completed handshakes with the OLD
  still-running filter during the replacement window (e.g. app 2.9.6 ↔ filter
  2.9.5), then reconnected to the replaced extension. Codable-with-defaults
  messages over UDS degrade the same way our XPC DTOs do, but the *channel*
  itself has no version coupling at all.

## Findings / gotchas

- **Network.framework can't do peer auth on the listener side**: `NWListener`/
  `NWConnection` never expose the fd or the peer audit token, and
  `getsockopt(LOCAL_PEERTOKEN)` needs the fd. So the server must be BSD
  sockets (DispatchSource makes this ergonomic); the *client* side has no such
  constraint and NW `.unix` endpoints + `.tcp` parameters interoperate
  perfectly with a BSD server. NWProtocolFramer was skipped for the same
  reason — with one BSD end, a shared manual parser both sides is less code
  than framer + parser dual implementations.
- **`#if DEBUG` cannot gate VM-witnessed code**: the VM Xcode configuration
  compiles SPM packages in release (Xcode maps any config not named "Debug" to
  release for packages), so the plan's "DEBUG-gated" instruction was
  implemented as a runtime gate instead: code only activates when
  `/private/etc/gertrude-uds-spike` exists (root-writable marker, absent
  everywhere but the VM; branch unmerged regardless).
- Stale socket files after filter kill produce ECONNREFUSED (not ENOENT) until
  the respawned server's unlink+rebind; the client retry loop treats both the
  same. NW surfaces both as `.waiting` — treat `.waiting` as fatal and drive
  reconnection with your own timer, since for unix endpoints NW's "wait for
  better conditions" never fires.
- `SO_NOSIGPIPE` on every socket or a dying peer kills the filter with SIGPIPE.
- zsh (this harness) doesn't word-split `$SSHOPTS` — inline ssh options.
- VM `/tmp` is wiped on reboot: re-upload tarballs/scripts after any reboot
  witness.

## Production adoption cost (estimate)

The spike is ~500 lines including logging and both test hooks. A production
channel is a different, larger job:

1. **Protocol**: replace the toy messages with the existing app↔filter message
   surface (`XPCInterfaces`/`XPCTypes` already traffic in Codable DTOs — the
   payload types port unchanged; request/response correlation ids + reply
   timeouts needed, ~1-2 days).
2. **Server hardening**: per-uid connection maps (fixes the last-wins
   single-connection XPC bug for free — each uid has its *own socket*),
   backpressure/write-queue instead of usleep retry, connection limits,
   `SecRequirement`-based peer validation. (~2-3 days)
3. **Client integration**: implement `FilterXPCClient` interface over UDS so
   the entire TCA layer is untouched; keep XPC as fallback during migration
   (dual-stack, prefer UDS, health-check both). (~2-4 days)
4. **Rollout safety**: ship dark alongside XPC, compare channel health
   telemetry in the field (we already have `system.security_events` plumbing),
   flip the default once UDS wedge-rate < XPC wedge-rate is demonstrated on
   real fleet data. (calendar time, little code)

No OS-version floor issues: everything used is macOS 11-era API or older
except LOCAL_PEERTOKEN (present in current SDK; verify the floor —
LOCAL_PEERCRED/PEERPID are ancient fallbacks if any supported OS lacks it).

## Open questions for Jared

- Multi-user simultaneous sessions: spike binds per-uid sockets but only one
  GUI user was exercised; fast-user-switching witness is future work.
- `/var/run` vs a persistent root-owned dir: /var/run wipe-on-boot was handled,
  but a dir like `/Library/Application Support/Gertrude/run/` would survive
  boot ordering even if the filter ever bound *before* mount cleanup; probably
  unnecessary.
- Whether production keeps XPC permanently as fallback or fully replaces it
  after field validation.

## Reproduce

- Local: `just macapp-test --filter UDSSpikeTests`
- VM: marker `sudo touch /private/etc/gertrude-uds-spike`, deploy any
  spike-bearing build via the ledger-10 toolchain, then
  `log show --predicate 'eventMessage CONTAINS "UDS"'`.
- Old spike reference: bak-swift `bf246b51`
  (`origin/explore-unix-domain-sockets-SAVE`), issue #223.
