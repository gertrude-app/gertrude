# MacSim VM witness-capture — feasibility findings

## UPDATE 2026-07-06: capability PROVEN + first witnesses captured

The one-time GUI-gated setup (onboarding + sysext approval) is done via Jared's
own `just macapp vm` flow — it produces a properly **signed** (teamID
`WFN83LM943`), `[activated enabled]` filter extension, connected app, live XPC.
The adhoc-signed build I tried on 2026-07-05 was the whole reason activation
failed (needs developer mode); the signed golden path sidesteps it.

**Snapshot round-trip works** (the linchpin): `tart stop` → `tart clone
gertrude-approved` → `tart run --no-graphics` → the onboarded+approved filter
comes back. So destructive witness runs can reset headlessly without redoing
onboarding. `gertrude-approved` is the durable reset point (name avoids
`vm-clean`'s `gertrude-(test|gui)-*` deletion pattern).

**Everything below was captured by me, headless, over SSH** — no GUI clicks.

### Witnessed OS behaviors (candidates to promote P1/P2/P3 → OS RULES)

- **Reboot persistence (P1)**: after full reboot, extension `[activated
  enabled]` and `nesessionmanager` submits the launchd job for
  `com.netrivet.gertrude.filter-extension` on its own — provider process back
  without any app action. The app also auto-relaunches (launch-at-login).
- **Provider crash-recovery (P1)**: `kill -9` the provider → `nesessionmanager`
  logs `Restarting` → `Starting with control unit 1073741825` → `Plugin …
  started with pid N` → `running`, **~2.5s** later. The respawn gets a NEW
  control unit; all in-flight flow owners (Gertrude, apsd, cloudd, nsurlsessiond,
  …) log `Got an error on the Filter XPC connection to unit 1` when the old one
  dies.
- **App crash-recovery (P2/relauncher)**: `kill -9` the macapp → the
  `GertrudeHelper … --crash-watch` sidecar relaunches it (pid 523 → 826) within
  seconds; app re-establishes its NE/XPC connection.
- **App-death → app relaunch, and AWOL fail-closed (NOT cleanly isolated —
  honesty note)**: killing the app, the still-running provider logged a stream
  of `Dropping flow …`. I first read this as the `Decision+Flow` `macappAWOL`
  path (app-dead ⇒ drop protected traffic). On reflection that's an OVERCLAIM:
  the child config is *default-block*, so those drops are indistinguishable from
  normal rule-blocking. The AWOL behavior IS real, unit-tested filter code, and
  it's exercised for free when the sim runs the real reducer with app-liveness
  threaded (`recordAppActivity` sets `macappsAliveUntil = now+150s`; it expires
  → AWOL). But to *device-witness* it distinctly I'd need an **allowlisted** host
  that flips allow→block when the app dies (kill app, wait past the 150s
  liveness window, curl an allowed host). Deferred as a targeted witness; not
  claimed as evidence. What IS cleanly witnessed: the crash-watch relauncher
  brings the app back (pid 523→826) and it reconnects.

- **Provider-not-running FAILS OPEN, with a bounded verdict-finality leak
  (P3)** — the full characterization, witnessed on the pristine clone
  (child config is default-block; every host blocked at baseline, curl gets TCP
  connect ~0.09s then `Recv failure: Socket is not connected` on the SNI drop):
  - **Dead window**: `kill -9` provider → for ~2.5-5s the provider is DEAD and
    **all traffic flows** — example.com (blocked at baseline) returns HTTP 200
    continuously. NEFilterDataProvider fails OPEN when the provider process is
    absent (matches `NEFilterSettings.defaultAction = .allow` + no provider to
    consult).
  - **Respawn re-enforces correctly**: once the OS respawns the provider it
    reloads rules from disk (`extensionStarted` → `loadedPersistentState(…
    userKeychains[502]=[education.minecraft.net, …])`) and the app re-sends
    `receiveAlive(for: 502)`. Six FRESH hosts never touched during the dead
    window (reddit, wikipedia, github, cloudflare, nytimes, bbc) are all
    **blocked (000)** afterward — enforcement for new destinations is fully
    restored.
  - **Bounded leak**: only destinations *contacted during the dead window*
    (example.com, google.com) keep working after respawn — a flow-verdict /
    connection-verdict finality that persists past the crash. This is the **Mac
    analogue of iOS OS RULE R13** (leaked-socket survival). A reboot clears it
    (post-reboot: example/google/reddit all blocked 000 again).
  - Net: a filter crash is a *bounded, self-healing* enforcement hole — total
    fail-open for a few seconds, then a residual leak limited to whatever the
    kid was actively loading during those seconds. Not an indefinite gap.

- **Respawned-provider startup sequence (FilterExtensionState-adjacent)**:
  captured our own os_log — `received action: extensionStarted` → NE
  `Calling startFilterWithCompletionHandler` → `received action:
  loadedPersistentState(Optional(…))` → app's `receiveAlive(for: 502)` →
  `received action: xpc(…macappAlive(userId: 502))`. This is the real ordering
  the sim's boot/respawn model should reproduce.

### Reusable witness harness

`/tmp/witness.sh <label> <action>` on the VM: starts `log stream` on the
sysextd/NE/nesessionmanager/gertrude predicate, runs the action, tails the
filtered capture. Pattern works well; gotcha — kill the `sudo log stream` with
`sudo kill` and expect a "Terminated: 15" line to clobber the next echo.

### Still to capture

- **P2 XPC single-retained-connection / last-connect-wins** (deferred): needs
  two live app contexts (fast-user-switch or a 2nd onboarded macOS user). The
  single-connection re-establish path IS witnessed (app killed → relaunched →
  reconnects; provider killed → app reconnects). The "second connect steals the
  slot" case needs a 2nd user set up — lowest-priority, revisit if the sim's
  multi-user modeling needs device grounding.
- Exact `FilterExtensionState` transition strings across an app-driven
  stop/start/replace (vs the crash path already captured) — needs the app's
  admin control, which is GUI/passcode-gated. The crash/reboot startup ordering
  is captured; the admin stop/replace strings can wait until we model that path.

### Snapshot / reset workflow (validated)

- `gertrude-approved` = pristine onboarded clone (durable reset point).
- Reset for a clean run: `tart stop <vm>` → `tart clone gertrude-approved
  gertrude-gui-fresh` → `tart run gertrude-gui-fresh --no-graphics &` → poll
  `tart ip`. ~40s to a pristine, filter-running, connected state. Proven this
  session (the muddy first fail-open read was a perturbed VM; the clone gave a
  clean reproduction).
- Reboot-in-place (`tart stop` + `tart run` same VM) also restores clean process
  state from disk — used to confirm the verdict-finality leak clears.

---

# (original 2026-07-05 feasibility findings below)

# MacSim VM witness-capture — feasibility findings (session 2026-07-05)

Goal: establish how much of the macapp cross-extension behavior (the sim's
`PROVISIONAL RULE P1/P2/P3`) can be **witnessed on a real macOS host** to
promote provisional rules to evidenced `OS RULE`s, per the honesty clause
inherited from the iOS harness.

Environment: `tart` VM `gertrude-tahoe`, macOS 26.3 (build 25D125), SIP
**disabled**, auto-login user `franny` (uid 502), booted headless
(`tart run --no-graphics`).

## TL;DR

Headless **observation** and **log capture** work great. Headless
**GUI automation** does not. The system-extension install/approval is
GUI-gated and blocks a fully-agent-driven witness run. The unblock is a
one-time human (or GUI-window) approval, ideally baked into a reusable
snapshot — after which all the lifecycle/XPC probing is fully agent-drivable
over SSH.

## What works (agent-drivable, headless, over SSH)

- **Boot + reach**: `tart run --no-graphics` → `tart ip` → `sshpass ssh`.
  VM up and SSH-reachable in ~30-60s. `sw_vers`, `csrutil status` (SIP off),
  `systemextensionsctl list`, `ps`, `defaults read`, `sudo` (NOPASSWD) all
  fine.
- **File transfer**: `scp` of a 30MB `Gertrude.app.tar.gz`, unpack into
  `/Applications` as root — works. (Mirrors the existing `vm-setup.sh`
  "shared files" flow, but plain scp is simpler for our purposes.)
- **Live GUI screenshot**: `screencapture -x /tmp/screen.png` run *directly as
  franny* (who owns the console session) succeeds — a full 1728px aqua
  desktop, readable. So we CAN visually observe the running app headlessly.
  (NB: must run as franny directly; `launchctl asuser 502 …` fails with
  "Could not switch to audit session … Operation not permitted".)
- **Unified log capture**: `log show --last Nm --predicate '…' --style compact`
  over SSH works and returns real subsystem events (verified pulling
  `nesessionmanager` / `com.apple.networkextension` filter-session logs). This
  is the exact witness-capture mechanism the honesty loop needs — and unlike
  iOS 26 (where `idevicesyslog` live streaming is dead), here both `log show`
  (historical) and presumably `log stream` (live) are available.
- **The VM is pre-baked for automation**: system TCC.db already grants
  `kTCCServiceAccessibility` (auth_value=2) to `/usr/libexec/sshd-keygen-wrapper`
  and `/usr/bin/osascript`. Someone set this image up for SSH-driven GUI
  scripting.

## What does NOT work (the walls)

- **`systemextensionsctl developer on`** → `AuthorizationCreate failed: the
  authorization was denied since no user interaction was possible`, even under
  `sudo`. It uses Authorization Services, which demands a GUI prompt. So we
  **cannot CLI-sideload** the filter extension; the only install path is the
  app running `OSSystemExtensionRequest` + a user approving in System Settings.
- **AppleEvents to GUI apps hang from the SSH session**. Plain osascript works
  (`osascript -e "6*7"` → 42), but any app-directed event
  (`tell application "Finder" …`, `tell application "System Events" …`) times
  out (-1712) or hangs, *despite* the pre-granted Accessibility TCC entries.
  This is the blocker for blind GUI automation: we can't reliably click through
  onboarding or the sysext "Allow" button via System Events from ssh.
- **No pre-approved Gertrude extension in the image**: `systemextensionsctl
  list` = 0 extensions, `/Library/SystemExtensions/.staging` empty, the only
  `NEContentFilter` in `com.apple.networkextension.plist` is Apple's own
  `com.apple.preferences.application-firewall`. Copying the .app into
  `/Applications` registers nothing — the sysext only activates when the app
  runs and the user approves.
- **The onboarding path is heavy even with GUI**: it's a WKWebView flow (HTML
  buttons, not natively AX-targetable), needs a live Gertrude child-account
  connection code, plus separate System Settings grants (Full Disk Access,
  Screenshots, Notifications) before the sysext step. Automating this blind is
  impractical and brittle.

## Recommended path: human-in-the-loop, then snapshot

Mirror the iOS spike division of labor (Jared drove the phone for the manual
bits; the agent did capture + analysis):

1. **One-time manual approval** (human drives the VM GUI window, or clicks the
   single System Settings "Allow" for the sysext after a scripted app launch):
   get the filter extension installed, approved, and connected to a real child
   account with rules.
2. **Snapshot that state** (`tart clone gertrude-tahoe gertrude-approved` or a
   suspended snapshot) so the approved+connected filter is reusable and the
   manual step is paid once.
3. **Agent-driven witness runs** against the approved snapshot, all over SSH:
   - **P1 (sysext lifecycle)**: `kill -9` the provider process → does the OS
     relaunch it? (`log stream` on sysextd/NE while watching `ps`). Reboot the
     VM → does the provider come back without the app? Observe the exact
     `FilterExtensionState` transitions.
   - **P3 (fail-open)**: with the provider killed but config enabled, does
     traffic flow? (curl from the VM + filter logs).
   - **P2 (XPC physics)**: kill the app process → does the filter observe
     connection invalidation, and when? Restart the filter → can the app
     re-establish? These need the app+filter both live (hence the connected
     snapshot).

Everything in step 3 is exactly the cross-process choreography the sim models
and that unit tests can't reach — and it's all headless once the approved
snapshot exists.

## Open question for Jared

Are you willing to do the one-time GUI approval (or let me script the app
launch and you click the single "Allow")? If so, a `gertrude-approved`
snapshot turns P1/P2/P3 into fully agent-drivable witness captures. If not,
P1/P3 can fall back to Apple-doc-grounded rules (as several iOS rules did,
e.g. R10/R11 cite "Apple docs + on-device observation"), with the sim clearly
marking them lower-confidence than device-verified rules.

## Repro notes (for the next session)

- Boot: `tart run gertrude-tahoe --no-graphics &` then poll `tart ip
  gertrude-tahoe`.
- SSH: `sshpass -p franny ssh -o StrictHostKeyChecking=no -o
  UserKnownHostsFile=/dev/null -o LogLevel=ERROR franny@$IP '<cmd>'`.
- sudo is NOPASSWD but some scripts still pipe `echo franny | sudo -S` — both
  work.
- Quoting: complex `--predicate` strings get mangled through ssh+zsh; `scp` a
  script file and run it instead of inlining.
- screencapture: run as franny directly, not via `launchctl asuser`.
