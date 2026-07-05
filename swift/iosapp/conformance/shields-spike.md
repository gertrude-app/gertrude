# Shields Conformance Spike — Runbook

Answers the device questions in `docs/ios-shields-protocol.md` §Conformance spike
questions before any shields implementation or sim modeling (R14/R15). Everything here
is DEBUG-only lab tooling: the 🛡️ overlay button (bottom-right of the app), four
`shields-*` debug sentinels, and witnesses analyzed by `check.mjs --shields`.

**Mechanics being verified, not assumed:** (a) shield writes from the CONTROLLER
extension context — production's reconcile path; (b) the token round-trip — picker
selection encoded by the app into group defaults, decoded inside the controller;
(c) shield persistence across reboot; (d) `.all(except:)` device-wide behavior;
(e) web-domain shielding for the Safari leak; (f) background audio under a fresh
shield; (g) the device-passcode revocation sharp edge on this iOS version.

All shield writes go to a dedicated store named `shields-lab`, isolated from the
production webPolicy store. Recovery at any point: lab "Clear shields" button, or
Settings → Screen Time → remove Gertrude's access (no ST passcode set on this phone).

## Setup

1. Fresh DEBUG Xcode install on the phone; note exact iOS version (Settings → General
   → About) — needed for the revocation question.
2. Filter must be installed & running (normal dev onboarding).
3. Open the 🛡️ overlay → confirm authorization shows `approved` (dev onboarding
   requests `.individual`). If not, tap "Request .individual authorization".
4. Pick victim app (WhatsApp) — and in the same picker, if the UI offers a websites
   section, add `youtube.com`; if it doesn't, note that (question e falls back to the
   `webContent.blockedByFilter` path already shipped for webPolicy).
5. Tap "Save selection to group defaults" (this is the token round-trip register
   write).

## Provocations (note wall-clock time + what you SEE at each step)

### 1. App-context baseline

1. "Shield selected apps" → home screen → launch WhatsApp. EXPECT: shield screen.
   Note how fast the shield appeared (icon dim / launch behavior).
2. "Clear shields" → launch WhatsApp. EXPECT: normal.

### 2. Controller-context writes (THE spike question) — repeat 3x

1. "shields-up (selected apps)" → wait ~2s → launch WhatsApp. EXPECT: shield screen.
   (The sentinel needs a flow to ride: the button fires a real HTTPS request, which IS
   the flow.)
2. "shields-down (clear)" → launch WhatsApp. EXPECT: normal.
3. Repeat the up/down pair twice more for latency stats.

### 3. Reboot persistence

1. "shields-up" → confirm WhatsApp shielded.
2. Reboot the phone. Do NOT open Gertrude.
3. Launch WhatsApp. EXPECT (per Apple docs, unverified): still shielded — shields are
   device policy, not process state. Record what actually happens.
4. Open Gertrude → lab → "shields-down".

### 4. All-except (timeboxed — production shape)

1. Re-read recovery options above. Then "shields-all (all except selected)".
2. Observe ~60 seconds: Which apps shield? What happens to Phone, Settings, Messages,
   Safari, App Store? Does anything system-critical break? Screenshot the home screen.
3. "shields-down". Confirm everything returns.

### 5. Web domains (Safari leak question)

Only if the picker offered website selection in Setup 4:

1. "shields-web (selected domains)" → open Safari → youtube.com. EXPECT: shield/block.
2. Also try: start a YouTube video BEFORE the write, then write mid-playback — does
   playback stop? (This is the closest analog to post-suspension web-socket leakage.)
3. "shields-down".

### 6. Background audio

1. Start audio playing in WhatsApp (voice note) or YouTube — something that keeps
   playing with the screen off or app backgrounded.
2. "shields-up" mid-playback. EXPECT: unknown — does audio stop, or keep playing while
   only the UI is shielded? This decides whether a shield fully closes the leak or
   leaves an audio residue.
3. "shields-down".

### 7. Revocation sharp edge (LAST — may take the filter down)

1. Note iOS version again. Settings → Screen Time → scroll to Gertrude's access.
2. Attempt to remove it. Record which passcode iOS demands: DEVICE passcode (the
   pre-~26.4 bug — unsafe for supervised-adult accountability) or Screen Time
   passcode / no barrier (this phone has no ST passcode — note exact behavior).
3. If removal succeeded: what happened to the filter? To the lab shields? Re-onboard
   afterward.

## Addendum — session 2 (items missed in session 1, 2026-07-04)

Session 1 findings are recorded in `docs/ios-shields-protocol.md` §Device findings.
These four remain; same setup (WhatsApp + changelog.com selection saved), same
capture/analysis flow at the end.

1. **Safari mid-playback web shield:** start podcast audio (or video) playing on
   changelog.com in Safari → controller `shields-web` mid-playback. Does playback
   stop? (Closest analog to post-suspension web-socket leakage; page-level shielding
   may kill in-flight streams that socket semantics can't.)
   - *RESULT (session 2, 2026-07-05 ~07:20:33 EDT):* background audio did NOT stop
     passively when the web shield went up — kept playing ≥15-20s (run cut short;
     buffered content not ruled out). Foregrounding Safari showed the restricted
     screen and the audio stopped AT THAT MOMENT. Contrast session 1 finding 6 (app
     shields kill background audio instantly): web-domain shields enforce at page
     render/foreground, not against in-flight streams. Safari residual-leak
     implication: passive playback survives until the kid interacts; interactive
     use dies on return.
2. **Safari-by-token:** open the picker → is Safari itself pickable as an app? If
   yes: add it, save, `shields-up`, launch Safari. Does a token shield stick despite
   the category exemption? Afterward re-pick WhatsApp-only and save.
   - *RESULT (session 2, ~07:23-07:25 EDT):* Safari IS pickable. First attempt
     showed an alarming divergence — controller `shields-up` shielded only
     WhatsApp while the same write from the APP shielded Safari too — but the
     cross-context probe (item 5, ~07:46) explained it: the two-app selection had
     NOT been re-saved to group defaults, so the app wrote its in-memory
     {WhatsApp, Safari} selection while the controller decoded the stale saved
     {WhatsApp}. With the selection saved, a controller token write shields Safari
     fine (both apps visibly shielded). Safari-by-token from the reconciler is
     VIABLE — no writer-context divergence. Verify in the `--shields` capture:
     the ~07:24 controller write should report `applications=1`.
     ALSO: with changelog.com audio playing, shielding Safari-the-app did NOT stop
     the audio — even foregrounded at the restricted screen it kept playing.
     Session 1 finding 6 ("shields kill background audio") is WhatsApp-specific,
     not general: already-playing Safari/web audio survives web-domain shields,
     app-token shields, and the restricted screen itself.
3. **Post-boot window probe:** `shields-up` → confirm shielded → reboot → within the
   first ~2 seconds of springboard, try to actually LAUNCH and USE WhatsApp (session
   1 saw it *appear* unshielded ~1.5–2s after first boot, immediately-shielded after
   second boot). Repeat 2–3x. Question: is the window visual-only, or usable?
   `shields-down` after.
   - *RESULT (session 2, ~07:27-07:31 EDT, 2 reboots):* first boot — shielded
     immediately, app inaccessible. Second boot — unshielded APPEARANCE for ~1s,
     tapped the icon during the window, app came up RESTRICTED. The window is UI
     lag only, not usable. Closes the R14 boot-lag question: shield enforcement is
     continuous across reboot; the sim's not-modeling-it is correct, not a
     simplification.
4. **(extra credit) Shields sentinels during a live recording suspension:** grant +
   record (SQL flow from hinge-experiments.md), then fire `shields-up`/`shields-down`
   mid-recording — via the SENTINEL buttons (controller path); an app-direct write
   bypasses the filter and proves nothing here. Confirms the lab channel — and by
   extension the production reconcile path — is unaffected by suspension state (the
   filter forwards shields sentinels ahead of its suspension logic).
   - *RESULT (session 2, 11:51:19-11:51:45 UTC, witness-verified):* CONFIRMED end
     to end. Recording started (suspend fan-out x8, filter suspended until +30min),
     filter summoned controller (ALLOW recording=true, screenshot uploaded 200 OK),
     then mid-recording shields-up/down/up/down all forwarded by the SUSPENDED
     filter → controller writes landed 0-23ms (up applications=2 / down cleared),
     interleaved with evidence handling; suspension held throughout; stop →
     resume sentinel → filter-resumed clean. Sentinel→write latency all session:
     2-40ms; controller write errors 0 of 106.
5. **Cross-context clear probe (ADDED mid-session-2 after the Safari-by-token
   divergence):** are the app's and controller's same-named `ManagedSettingsStore`s
   one store, or two per-process stores the system merges? Selection: WhatsApp.
   - A: `shields-up (selected apps)` [controller] → confirm WhatsApp shielded →
     `Clear shields` [app-written] → is WhatsApp unshielded?
   - B: `Shield selected apps` [app-written] → confirm shielded → `shields-down
     (clear)` [controller] → unshielded?
   - After each write, note the lab's "current state" readout: it reads the APP
     process's store instance, so readout-vs-visible-shield disagreement is itself
     evidence of per-process stores.
   - Stakes: the prototype's entry edge is the app clearing controller-raised
     shields. If A fails, that design is broken on device and entry must be
     redesigned (app sentinel → controller drop, ≤36ms path already proven).
   - *RESULT (session 2, from 07:46:46 EDT):* BOTH directions clear — app clears
     controller-raised shields (A ✓, with Safari + WhatsApp both raised by the
     controller and both visibly cleared by the app) and controller clears
     app-raised (B ✓). Same effective store: the two-writer D8 design (app entry
     edge over a controller-reconciled store) is VALID on device. Wrinkle: the
     lab's app-process "current state" read-back showed `apps=0` immediately after
     the controller's write even while both apps were visibly shielded (it showed
     `apps=2` after the app's own write) — cross-process READ-BACK is stale or
     lazy, same class as session 1 finding 9 (authorizationStatus). Production
     must never gate shield decisions on store read-backs; write the projection
     unconditionally (which the prototype reconciler already does). This session
     also explains item 2's scare: the divergence was a stale saved selection, not
     writer context.

## Capture & analysis

Timestamps matter more than perfection — jot rough wall-clock times per step. Then:

```
./capture.sh collect 00008150-000148983AB8401C 2h
node check.mjs logs/witnesses-<ts>.ndjson --shields
```

The `--shields` report shows authorization readings, selection saves (token
round-trip), app writes, controller writes with per-write latency + store state, and
sentinel→write delivery latency. Shield *visibility* is human-observed — your notes
against the timestamps complete the record. Findings go to
`docs/ios-shields-protocol.md` (upgrade DRAFT claims to device-verified, with numbers)
and new R14/R15 rows in `docs/ios-conformance.md`.
