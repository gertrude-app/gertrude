# iOS Shields (ManagedSettings) — Protocol Extension

> **STATUS: DRAFT — sim-prototyped 2026-07-04, not device-integrated.** Extends
> `docs/ios-recording-protocol.md` to close the persistent-socket leak. The shield
> actuator now exists as a prototype: sim model (OS RULES R14/R15), controller
> reconciler + app edges in the production proxies (feature-gated on the allowlist
> register, which nothing in production writes yet), and the explorer's S3/L4/S1′
> oracle. In the sim, S1′ HOLDS with shields on (`explorerShieldsCloseTheSocketLeak`)
> and is violated without them (`explorerFindsPersistentSocketLeak`) — the flip
> promised when R13 landed. See §Prototype findings. Not normative until
> device-integrated and conformance-verified.

## The leak this closes

NE flow verdicts are final per socket: once the filter `allow()`s a flow, subsequent
data on that connection never re-consults the filter. A connection opened during a
recording-backed suspension (a YouTube HTTP/2 or QUIC connection, say) keeps carrying
data after the recording stops and blocking "resumes" — the child retains a partially
working app with no evidence flowing. Observed on device during the spring 2025
experiment (YouTube remained moderately functional post-suspension); confirmed as the
principal reason the feature was backed out. There is no socket-level fix available to
the extension: existing flows cannot be enumerated or killed, and holding every
suspension-era flow in data-verdict/peek mode indefinitely is unproven and
memory-prohibitive in the filter's budget (considered, rejected unless measured
otherwise).

Since the leak cannot be closed at the socket layer, it is closed at the
app-usability layer: ManagedSettings application shields. Steady state is shields UP
on every app except a parent-chosen allowlist; a live suspension drops them; the end
of evidence raises them again, making leaked sockets moot because the child cannot
use the app. This is the design Living Room (Chris's fork) shipped on — precedent
that the whole shape works in production.

## New protocol elements

| Element | Kind | Writer(s) | Readers | Semantics |
| --- | --- | --- | --- | --- |
| shield allowlist | register (group disk) | app (from parent config) | app, controller | opaque `ApplicationToken`s of never-shielded apps; pickable only on the child's device (`FamilyActivityPicker`) |
| shield state | **actuator** (named `ManagedSettingsStore`) | app (entry edge) + controller (reconciler) | the OS | persists across process death AND reboot until overwritten — this is not a register we read back so much as device policy we must keep reconciled |

The shield actuator is the protocol's first element with **inverted fail-safe
polarity**. Flow blocking fails safe by inaction: the next flow re-derives. Shields
fail *dangerous* by inaction: whoever dropped them must ensure something raises them,
and the dropped state survives everything including reboot. The cure is the same
discipline as D2/D7 — shield state is a **level-triggered reconciled projection of
`live()`**, never an edge:

```
shieldsDerived(now) = live(now) ? down : up     // for non-allowlisted apps
```

- **Controller (primary reconciler, D8):** on every flow it receives and at startup,
  re-derive the projection and write it UNCONDITIONALLY. An earlier draft said
  "compare derived state to last-written state; write when they differ" — the
  explorer refuted that on its first shields corpus run (seed 6, shrunk to 3
  actions): with two writers, the controller's memory of its own last write goes
  stale the moment the app writes, and the post-suspension raise was skipped (S3
  violated). Any skip optimization must come from reading the store back, never from
  caching own writes; until measured as needed, don't skip (spike: writes are 0-26ms
  and idempotent). The controller is the right home: less sandboxed than the filter,
  relaunched by the OS at boot (R6), reliably granted CPU while traffic flows, and
  ManagedSettings writes from the control provider are already prototype-proven under
  both authorization paths (Jared, 2026). Startup reconcile covers
  reboot-with-shields-down.
- **App (entry edge):** drops shields at `broadcastStarted` alongside writing the
  expiration. This edge is NOT optional — see the entry deadlock below. The app also
  writes the strict projection when it hears `broadcastFinished` / early-end (an
  exit accelerator only; the controller remains the guarantee).
- Two writers to one store deliberately violates the single-writer rule; it is safe
  only because both compute the same idempotent projection from the same registers
  and writes reconcile toward it (last writer converges). No other writer may exist.

## The traffic-coupling hazard (why entry/exit differ)

Shields suppress the very traffic that grants the protocol CPU. A shielded app
generates no user-initiated flows, so:

- **Entry deadlock:** if shield-drop waited on a controller flow-reconcile, the kid
  could never wake a shielded app to generate the flow. Entry must come from the app,
  which is foreground at "start recording" anyway.
- **Exit starvation:** raising shields relies on *some* post-suspension traffic
  (allowlisted apps, background refresh, the Gertrude app, the leaked connection's
  app opening any new socket). Believed adequate in practice; the explorer must probe
  it rather than assert it. If starvation is real, the escape hatch is a
  `DeviceActivityMonitor` schedule as a traffic-independent CPU source — but that is
  another extension target (n+1 again) and is a last resort the sim must justify.

## Invariants (extending S1/S2/L1-L3/C1)

- **S1 (rescoped, honesty):** S1 governs NEW flows only. It says nothing about data
  on connections verdicted before blocking resumed. The composite below is the real
  parent-facing property.
- **S3 (shield safety):** whenever `¬live()` persists beyond `shieldLatency` (bound
  TBD: reconcile trigger + write time), every non-allowlisted app is shielded.
- **L4 (shield liveness):** while `live()`, shields are down within `shieldLatency`
  of entry (UX: the kid can actually use the granted suspension).
- **S1′ (composite, the point of it all):** no *usable* data path for a
  non-allowlisted app while unrecorded beyond the latency bound — new flows blocked
  (S1) AND the app shielded (S3). Leaked sockets exist but are unusable.
- **C1 (extended):** convergence additionally requires shields up.

## Failure matrix (additions)

| Failure at t | Required behavior |
| --- | --- |
| process dies between shield-drop and raise | controller reconciles on next flow/startup; bounded by traffic + `shieldLatency` |
| reboot mid-suspension (shields down, persisted) | broadcast died → `¬live()` → controller startup reconcile raises shields (R6 guarantees launch) |
| connection opened during suspension, used after | new flows blocked (S1); app shielded (S3) makes the socket unusable (S1′); socket itself dies at reboot only |
| allowlist edited mid-suspension | next reconcile applies it; no special casing |
| Screen Time authorization revoked | filter + shields both die — device reverts to unprotected; app must detect and re-onboard (same class as filter removal today) |
| shielded app generates zero flows post-suspension | exit-starvation: reconcile delayed until ANY traffic; explorer probes whether this is reachable in realistic action mixes |

## Authorization (platform knowledge, 2026-07)

Two proven paths (both prototyped by Jared in spike apps):

1. **Unsupervised child:** child under 18 in an Apple Family — solid, standard
   FamilyControls story.
2. **Supervised adult:** individual-style Screen Time grant on a supervised device —
   proven to work. **Sharp edge:** iOS 26 below ~26.4 has a bug where apps granted
   Screen Time access can be revoked using the DEVICE passcode instead of the Screen
   Time passcode. For the accountability use-case (adult self-restricting; spouse or
   partner holds the ST passcode) those versions are UNSAFE: the user can strip the
   grant themselves. Fixed in later iOS 26 releases. Shipping gate: detect and warn
   on (or refuse) affected versions for supervised-adult installs; pin down the exact
   fixed build during the conformance spike.

## Known bounded leaks (named now, not discovered later)

- **Safari/web:** Safari is presumably allowlisted (or the device loses browsing),
  so a web-YouTube socket opened during suspension leaks post-suspension with no app
  shield to catch it. Session 2 sized the closable options: `shield.webDomains`
  blocks page re-renders but NOT in-flight playback (and domain tokens are
  picker-only); Safari-by-token from the controller works but likewise leaves
  already-playing audio running. Either narrows the leak to passive continuation of
  already-playing media — no navigation, no new use; dies at page re-render or
  reboot; new loads are S1-blocked.
- **Background audio:** split by app (session 2): WhatsApp audio dies instantly
  under an app shield; already-playing Safari/web audio survives every shield
  variant. The bounded passive-audio leak above is the accepted residue.

## Interaction with restart-within-grant

Jared leans yes (2026-07-04); UNDECIDED. Both policies are now modeled behind the
`\.grantPolicy` dependency (default `.burnOnFinish`, the shipped behavior) so the
decision can be made against passing evidence rather than speculation:

- `.burnOnFinish`: `broadcastFinished` clears the register; a lock consumes the
  grant; restarting the broadcast does not re-lift
  (`lockBurnsGrantUnderBurnOnFinishPolicy`).
- `.restartWithinGrant`: `broadcastFinished` leaves a still-future register in place
  (the tombstone re-blocks via L1 regardless); the kid restarts within the ORIGINAL
  window — `broadcastStarted` never rewrites a still-future register, so the window
  is preserved, not extended; once it lapses (or the app hears a finish after lapse)
  the grant is consumed (`lockPreservesGrantUnderRestartWithinGrantPolicy`).

Shields cycle correctly under both (explorer corpus runs both policies green). As
predicted, restart-within-grant falls out of register-authority (D7) + shields as a
projection of `live()`; no app-side grant state machine was required beyond a
policy check at the two write points.

## Sim model requirements (honesty clause)

- **R13 — flow verdict finality / socket persistence** *(landed)*: an `allow()`ed
  flow becomes a persistent connection; data over it never consults the filter;
  connections die at reboot. Lets the explorer demonstrate S1′ violation against
  the WITHOUT-SHIELDS design — the motivating counterexample.
- **R14 — ManagedSettings persistence** *(landed 2026-07-04, evidence: spike
  session 1)*: shield state as world state surviving process death and reboot;
  written only by authorized processes (app, controller — the sim withholds the
  dependency from filter/recorder so a stray write fails); `.all(except:)` exempts
  the spike's observed system-app class. Not modeled: the ~2s first-boot
  application lag (unconfirmed exploitability — addendum probe), revocation.
- **R15 — shields gate app usability** *(landed 2026-07-04)*: user-initiated flows
  and socket use from a shielded app do not happen; background-refresh traffic may.
  This coupling is what lets the explorer probe entry-deadlock/exit-starvation
  (measured as entry/exit gap stats rather than asserted invariants — both are
  traffic-bounded by design).

## Prototype findings — sim, 2026-07-04

What landed: sim world state + OS RULES R14/R15 (`VirtualDevice.swift`), controller
reconciler + app entry/exit edges in the production proxies (feature-gated on the
allowlist register; nothing writes that register in production yet), the explorer's
shields oracle (S3/L4 level checks at every reconcile opportunity, S1′ leak
detector, C1-extended convergence, entry/exit gap stats), 8 named scenarios
(`ShieldScenarioTests.swift`), and both grant policies. Findings:

1. **The explorer found a real protocol bug on its first shields corpus run** (the
   D7 story repeating itself, now for D8): the reconciler's last-written cache is
   unsound under two writers. Fixed to unconditional writes; regression scenario
   `appEntryEdgeDoesNotStaleControllerReconcile`; spec text amended above.
2. **Allowlisted apps' leaked sockets stay usable while unrecorded — by design.**
   The explorer flagged it (seed 37: parent adds an app to the allowlist
   mid-suspension); S1′ scopes to non-allowlisted apps, so the detector was refined,
   not the design. Parents own that tradeoff when they allowlist an app.
3. **Gertrude must be exempt from its own shields or the feature deadlocks** — a
   shielded Gertrude can't be opened to request a suspension and its sentinels are
   R15-suppressed. The sim initially modeled Gertrude as shieldable
   (conservative); the device answered on 2026-07-05: `.all(except:)` EXEMPTS the
   managing app (conformance Q7), so the deadlock is unreachable and no
   allowlist-onboarding guarantee is needed. Sim model updated to match
   (`gertrudeIsExemptFromItsOwnShields`).
4. **Starvation exposure, quantified:** across the 25-seed corpus (both policies),
   max entry gap 15s (live suspension waiting for a reconcile to drop shields — the
   app edge kept the common path instant), max exit gap 255s (shields down while
   unrecorded, no traffic to summon the controller). The exit number is the one to
   watch on device: it is exactly the "bounded by traffic" clause of S3, and the
   `DeviceActivityMonitor` escape hatch exists if real-device traffic patterns make
   it materially worse.

## Device findings — spike session 1, 2026-07-04 (iPhone, iOS 26.5.1)

DEBUG build, `.individual` authorization, runbook `conformance/shields-spike.md`,
capture `witnesses-20260704-163920.ndjson` + `check.mjs --shields`. All provocations
run except the addendum items (runbook §Addendum). Numbers below are device-measured.

1. **Controller-context shield writes: PROVEN.** 75/75 writes, zero errors, write
   latency 0–26ms, sentinel-arrival→applied-shield ≤36ms, store read-back consistent
   after every write, shield visibility behaviorally instant. Spike question 1 could
   not have gone better; D8's controller-primary reconciler is viable.
2. **Idempotency is load-bearing, empirically.** Every sentinel press fanned out into
   2–8 controller writes (the known R7 one-send→many-flows fan-out). The idempotent
   reconcile absorbed all of it; an edge-triggered design would have double-fired 75
   times in the first real session.
3. **Token round-trip: PROVEN.** `FamilyActivitySelection` (1 app + 1 web domain,
   580 bytes) encoded by the app into group defaults, decoded and applied inside the
   controller extension. The allowlist register mechanism works as specced.
4. **`.all(except:)` is category-based and exempts system apps.** Shielded: every
   third-party app, plus categorized first-party (Music, Mail). NOT shielded: Phone,
   Settings, Messages, Safari, Maps, Find My, Clock. Phone/Settings exemptions are
   desirable (emergency/anti-abuse); **Safari and Messages are the named residual
   surfaces** — Safari must be covered by the web path below (or by explicit token,
   untested), Messages is a product-level question (communication limits).
5. **Web-domain shields work from the controller** — restricted screen renders inside
   Safari. BUT tokens are picker-only (the picker offered a list, seemingly from the
   user's Safari context; no arbitrary domain entry), so production cannot
   dynamically shield arbitrary domains. Options: parent-pre-picked domains, the
   shipped `webContent.blockedByFilter` path, or accept the bounded leak.
   Mid-playback behavior untested (addendum).
6. **Shields kill in-progress background audio immediately** (WhatsApp mp3 died the
   moment shields went up); no auto-resume on clear. No audio residue weakens S1′.
   *(CORRECTED by session 2: this is app-specific, not general — already-playing
   Safari/web audio survives every shield variant; see session 2 finding 4.)*
7. **Shields persist across reboot** (device policy, as hoped). Wrinkle: on the first
   reboot WhatsApp appeared UNshielded for ~1.5–2s after springboard before the
   shield applied; on a deliberate second reboot it was shielded immediately. Whether
   an app is actually *launchable* in that window is unconfirmed (addendum probe).
   Even if real, a ≤2s boot window is far smaller than the filter's own boot-time
   story and is bounded by L1 semantics. *(RESOLVED by session 2: the window is UI
   lag only — a tap inside it opened the app restricted; see session 2 finding 5.)*
8. **Revocation (weak proxy — dev device, `.individual`):** Face ID (device-level
   auth) sufficed to remove Screen Time access; iOS cleared the shield store
   silently; **the filter did NOT die** (no stop/relaunch witnesses, blocking
   continued). The supervised-adult revocation story — the actual sharp-edge case —
   still needs its own test on a supervised configuration; this device runs 26.5.1,
   past the reported device-passcode-bug fix window.
9. **`AuthorizationCenter.authorizationStatus` reads are unreliable** — returned
   `notDetermined` twice mid-session while writes were demonstrably working (stale
   async reads). Production must never gate shield behavior on a synchronous status
   read; authorization truth is "do writes take effect."

## Device findings — spike session 2, 2026-07-05 (same device, addendum)

Runbook §Addendum items 1-5, capture `witnesses-20260705-075826.ndjson` +
`check.mjs --shields`. Controller writes this session: 106, zero errors,
sentinel→write latency 2-40ms. Detailed per-item results live inline in the runbook;
the protocol-level conclusions:

1. **The two-writer design is VALID on device (cross-context clear probe, both
   directions).** App clears controller-raised shields; controller clears
   app-raised. Same effective store despite separate processes — the app entry edge
   over a controller-reconciled store works as specced. This was run because of an
   alarming apparent divergence (controller token write shielded WhatsApp but not
   Safari while an app write shielded both) which turned out to be a STALE REGISTER,
   not writer context: the two-app selection hadn't been re-saved to group defaults,
   so the controller decoded the old one-app selection — witness-confirmed
   (controller wrote `applications=1` at 11:23:55, app wrote `applications=2` at
   11:24:12; after the save, controller wrote `applications=2`). An accidental
   proof of the register discipline: writers reading different register states
   compute different projections.
2. **Cross-process store READ-BACK is stale/lazy** — the app-process store instance
   read `apps=0` immediately after a controller write while both apps were visibly
   shielded (its own writes read back fine). Same class as finding 9. Rule
   confirmed from a second direction: never gate on read-backs; write the
   projection unconditionally (the sim explorer independently forced the same rule
   — §Prototype findings 1).
3. **Safari-by-token from the controller WORKS** (once the register is fresh) —
   reopens token-shielding Safari as a residual-leak option, with the audio caveat
   below. Safari is pickable in the picker.
4. **Web/audio enforcement is weaker than app shields, for already-playing media:**
   `shield.webDomains` mid-playback did NOT stop background audio (≥15-20s observed;
   died only when Safari was foregrounded and the restricted screen replaced the
   page); token-shielding Safari-the-app ALSO left playing audio running — even
   foregrounded AT the restricted screen. Session 1's "shields kill background
   audio" was WhatsApp-specific. Net: already-playing web streams are a leak no
   shield variant closes; bounded to passive continuation (no navigation, no new
   use — S1′'s *usable data path* is closed for everything interactive).
5. **Post-boot window RESOLVED: UI lag only.** Two reboots; the ~1s "unshielded"
   appearance was tappable and the app opened RESTRICTED. Shield enforcement is
   continuous across reboot — no boot window exists in the enforcement layer.
6. **Reconcile path is suspension-proof (extra credit, witness-verified):**
   mid-recording, the suspended filter forwarded shields sentinels ahead of its
   suspension logic; controller shield writes landed 0-23ms interleaved with
   evidence drains; suspension held; stop → clean resume. The production
   reconciler will work identically during and after recordings.
7. **`.all(except:)` exempts the managing app (Q7 ANSWERED, follow-up probe):**
   with shields-all up — written from either context — Gertrude itself stayed
   launchable and usable without being in the exception set. No entry deadlock; no
   Gertrude-allowlist onboarding requirement. Human-observed (shield visibility
   has no witness line); sim model updated from the conservative assumption to
   match (`gertrudeIsExemptFromItsOwnShields`).

Still open after session 2: supervised-adult revocation (needs a supervised
device); exit-starvation timing (needs the recording feature integrated); Q7 below.

## Conformance spike questions (device, before implementation)

1. Controller-written `ManagedSettingsStore`: reliability, write latency, behavior
   under both auth paths (child + supervised adult). *(session 1: ANSWERED for
   `.individual` — 75/75, ≤36ms; session 2 added 106/106 incl. mid-suspension;
   child + supervised-adult paths still owed)*
2. Shield persistence across reboot; who can clear it besides us. *(ANSWERED:
   persists; revocation clears it; session 2 — the ~2s first-boot "window" is UI
   lag only, enforcement continuous; cross-context clears work both directions,
   same effective store)*
3. `shield.webDomains` viability for the Safari leak. *(session 2: weak — works
   from controller but does not stop in-flight playback, and domain tokens are
   picker-only; Safari-by-token now proven as an alternative, with the same
   already-playing-audio caveat)*
4. Background audio behavior under a freshly-raised shield. *(ANSWERED, split:
   WhatsApp audio dies instantly; already-playing Safari/web audio survives all
   shield variants until page re-render — bounded passive leak, accepted)*
5. Exact iOS 26 build that fixed the device-passcode revocation bug. *(open — needs a
   supervised configuration; test device is 26.5.1)*
6. Post-suspension traffic availability (exit-starvation reality check): with all
   non-allowlisted apps shielded, how quickly does the controller actually receive a
   flow? *(open — needs the recording feature integrated; sim corpus measured a
   255s worst case under its action mix — see §Prototype findings)*
7. Does `.all(except:)` shield the store-owning app (Gertrude itself)? *(ANSWERED
   2026-07-05, session 2 follow-up: NO — with shields-all up from either writer
   context, Gertrude stayed launchable and usable without being in the exception
   set. iOS exempts the managing app; no entry deadlock, no Gertrude-allowlist
   onboarding requirement. Human-observed — shield visibility has no witness line —
   one device/26.5.1/`.individual`; re-verify on new iOS majors like every OS RULE)*
