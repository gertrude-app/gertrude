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
