# Screen Time + Supervision Interaction Test

## Goal

Replicate Jonas's experience: he had Screen Time Content & Privacy Restrictions configured
to block Safari and App Store, then supervised his iPhone with Gertrude. After supervision,
Screen Time broke — enabling Content & Privacy Restrictions reduced him to ~5 usable apps
instead of his normal setup.

We want to isolate exactly what causes this: supervision itself, our profile payload, or
the combination — so we can ship a fix that doesn't break users' existing Screen Time
setups.

## Baseline Setup (replicating Jonas's pre-Gertrude state)

1. Start with unsupervised iPhone, Screen Time enabled with passcode
2. Content & Privacy Restrictions turned on
3. Safari toggled off under Allowed Apps
4. App Store toggled off
5. Confirm all other apps accessible and working normally

## Test Sequence

### Phase 1: Supervise only (no profile)

Supervise the device but don't install any Gertrude profile yet. Check:

- Is Screen Time still enabled?
- Are Content & Privacy Restrictions still on?
- Are Safari and App Store still blocked?
- Are all other apps still accessible?
- Did the Allowed Apps toggles change?

### Phase 2: Install Gertrude profile

Install the supervision profile (with current restriction keys: `allowAppRemoval`,
`allowEraseContentAndSettings`). Check:

- Same questions as Phase 1
- Does the `com.apple.applicationaccess` payload compound with Screen Time?

### Phase 3: Toggle Screen Time off and back on

Turn Content & Privacy Restrictions off, then back on. Check:

- Do the Allowed Apps toggles reset to a restrictive default?
- Is this the "5 apps" state Jonas described?

## Theories

**Primary theory:** On a supervised device, iOS defaults the Content & Privacy Restrictions
"Allowed Apps" toggles to mostly OFF (instead of mostly ON), because it assumes an MDM
admin will configure allowed apps via profile. Jonas hit this when he re-enabled Screen
Time after it got disrupted during supervision.

**Alternative theory:** Gertrude's `com.apple.applicationaccess` profile payload compounds
with Screen Time's content restrictions, producing a more restrictive combined result.

## Observations

### Baseline confirmed

- Screen Time enabled with passcode
- Content & Privacy Restrictions on
- Safari removed (toggled off)
- App Store removed (toggled off)
- All other apps accessible and working normally

### Phase 1: Supervise only (no profile)

Device supervised via Gertrude iOS app. No profile downloaded/installed yet.

**Screen Time state:**

- Screen Time still shows as enabled
- Passcode still set and required
- Content & Privacy Restrictions still toggled on

**Allowed Apps toggles vs. actual behavior:**

- Safari toggle still shows OFF in Screen Time settings — but Safari appeared on home
  screen and is launchable
- iTunes Store toggle still shows OFF — but App Store appeared and is usable
- Other apps all still accessible, no apps lost

**Key finding: Supervision causes iOS to stop honoring Screen Time's Allowed Apps
restrictions.** The toggles remain in their configured state but are no longer enforced.
iOS appears to defer to the supervised/MDM layer for app access control once a device is
supervised, effectively making Screen Time's Allowed Apps inert.

**Revised understanding of Jonas's experience:** Safari and App Store came back immediately
after supervision, which is what prompted his frustration. His "5 apps" description may
have resulted from further Screen Time toggling/troubleshooting on the supervised device,
potentially hitting a different default state. The core problem is that supervision silently
overrides Screen Time app restrictions without any indication to the user.

**Implication for Gertrude:** We can't detect what the user's Screen Time settings were
before supervision. We need to think about sensible defaults for the supervision profile
restriction keys, and/or guide users through configuring their profile settings to replace
what Screen Time was doing for them. This is not as simple as just mirroring Screen Time —
it's a UX/onboarding challenge.

### Phase 2: Install Gertrude profile

Downloaded and installed Gertrude supervision profile (standard profile, without the
PR #534 temp hack for Jonas's device).

**Screen Time state:**

- Screen Time still on
- Content & Privacy Restrictions still toggled on
- New: "View Profile" link appears at top of restrictions screen, saying "This device is
  also restricted by a profile"
- Allowed Apps toggles unchanged — Safari and iTunes Store still show OFF

**Actual behavior:**

- Safari still on home screen, still launchable, can browse (Yahoo loaded fine;
  apple.com blocked but that's Gertrude's content filter, not Screen Time)
- App Store still on home screen, still usable
- All other apps still accessible

**Finding: Profile installation caused no additional changes.** Screen Time was already
being ignored from Phase 1 (supervision alone). The profile's current restriction keys
(`allowAppRemoval`, `allowEraseContentAndSettings`) don't affect Safari/App Store visibility
since those aren't set in the standard profile.

iOS now shows an acknowledgment that a profile exists alongside Screen Time, but the two
systems don't appear to interact — Screen Time's Allowed Apps toggles remain inert
regardless of the profile.

### Phase 3: Toggle Content & Privacy Restrictions off and back on

Toggled Content & Privacy Restrictions off, then immediately back on (same passcode still
required and working).

**Result:**

- All settings appeared identical after re-enabling
- Safari disappeared from home screen — Screen Time enforcement restored
- App Store disappeared from home screen — Screen Time enforcement restored
- All other apps still accessible, no apps lost
- No "5 apps" issue — the toggle cycle cleanly re-enabled the existing restrictions

**Finding: Cycling Content & Privacy Restrictions off/on re-enables Screen Time Allowed
Apps enforcement on a supervised device.** The toggles were already in the correct state
from before supervision — they just weren't being honored. The off/on cycle kicks iOS back
into enforcing them.

**Jonas's "5 apps" issue not reproduced.** His more severe experience was likely specific
to his configuration (additional restrictions we didn't set up), his iOS version, or
manual changes he made while troubleshooting. The core bug — supervision silently breaking
Screen Time enforcement — is confirmed.

## Summary of Findings

1. **Supervision alone breaks Screen Time Allowed Apps enforcement.** This happens at the
   supervision reboot, before any profile is installed. Screen Time toggles remain in their
   configured state but iOS stops honoring them.

2. **Profile installation has no additional effect.** The standard Gertrude profile
   (with `allowAppRemoval` and `allowEraseContentAndSettings`) does not further disrupt
   Screen Time.

3. **Cycling Content & Privacy Restrictions off/on is a workaround.** This re-enables
   enforcement of the existing Screen Time settings. Users would not discover this on
   their own.

4. **We cannot detect or preserve the user's pre-supervision Screen Time settings.**
   This is a UX/onboarding challenge, not just a technical fix.

## Open Questions

- Should Gertrude's onboarding flow warn users that Screen Time app restrictions will stop
  working and guide them to cycle Content & Privacy Restrictions off/on?
- Should we set sensible defaults for restriction keys in the profile so that common
  Screen Time use cases (blocking Safari, App Store) are covered by default?
- What is the right set of profile restriction keys and defaults for the majority of users?
- Can we add a step in the supervision flow that detects Screen Time is active and
  proactively advises the user?

---

## Experiment 2: Does `allowEnablingRestrictions: true` in the profile fix enforcement?

### Background

From Apple Configurator mapping (session 1), the key `allowEnablingRestrictions` maps to
the UI label **"Allow Screen Time"** (supervised only). Default is `true`.

In the first experiment, Gertrude's profile does NOT set this key at all. Screen Time
remained accessible (toggles visible, passcode working) but its Allowed Apps restrictions
were not enforced after supervision.

### Question

If we explicitly include `allowEnablingRestrictions: true` in the Gertrude supervision
profile, does iOS treat that differently from the key being absent? Specifically: does
it cause Screen Time Allowed Apps restrictions to remain enforced through supervision,
eliminating the need for the off/on workaround?

### Setup

Need to unsupervise, reset to baseline (Screen Time on, Safari off, App Store off), then
re-supervise and install a modified profile with `allowEnablingRestrictions: true`.

**Complication: locked profile stranded on unsupervised device.** After unsupervising, the
Gertrude profile (with `PayloadRemovalDisallowed: true`) remained installed but the remove
button was not visible in Settings > VPN & Device Management. The profile was locked during
supervision and iOS did not unlock or auto-remove it when supervision was removed.

Attempted to download an unsigned replacement profile with same PayloadIdentifier and
`PayloadRemovalDisallowed: false`, but Safari was blocked by Screen Time (Phase 3
workaround had re-enabled Screen Time enforcement, which blocked Safari). No way to
download the replacement profile.

**Result: factory reset required.** This is a real failure mode — if a user unsupervises
without first removing or unlocking the profile, they can get permanently stuck with a
locked profile and no way to remove it.

**Important lesson for Gertrude's unsupervision flow:** Before unsupervising, the profile
should either be removed first, or changed to removable (`PayloadRemovalDisallowed: false`)
via a profile update. Alternatively, the unsupervision tool should handle this
automatically.

### Unexpected finding: iOS default Allowed Apps after factory reset

After factory reset, set up Screen Time with passcode, enabled Content & Privacy
Restrictions, and checked Allowed Apps & Features. The defaults were NOT all-on:

**OFF by default:** Mail, Safari, SharePlay, Camera, AirDrop
**ON by default:** FaceTime, Wallet, CarPlay, iTunes Store, Book Store, Podcasts, News,
Health, Fitness (and presumably others below the fold)

This is significant — it may explain Jonas's "5 apps" experience. If he reset or
re-enabled Screen Time during troubleshooting, he would have hit these restrictive defaults
rather than getting his previous settings back. Losing Mail, Safari, Camera, and AirDrop
on top of whatever he'd already had off would make it feel like very few apps were left.

### Experiment 2 baseline confirmed

- Factory-reset device, fresh setup
- Screen Time on with passcode
- Content & Privacy Restrictions on
- Safari toggled OFF in Allowed Apps
- App Store / iTunes Store toggled OFF in Allowed Apps
- Gertrude app installed
- Device personalized (wallpaper, photo, contact, custom app)
- All other apps accessible and working

### Experiment 2, Phase 1: Post-supervision, pre-profile

Device supervised via Gertrude app, rebooted. No profile downloaded yet.

**New finding: "App Restrictions Now Set to 4+"** — a yellow warning banner appeared in
Screen Time settings saying "Apps rated above this limit are not available on your device."
This content rating restriction was NOT set by the user — it appeared after supervision.
This is a new observation not seen in experiment 1 (may have been present but not noticed).
A 4+ age rating limit would hide most third-party apps.

**Screen Time state:**

- Screen Time still shows as on
- Content & Privacy Restrictions still toggled on

**Allowed Apps behavior (same pattern as experiment 1, with new details):**

- Safari toggle still shows OFF — but Safari appeared on home screen and is launchable
- However, Safari IS partially respecting Screen Time: browsing is restricted to "only
  approved websites" (tried Bing, got restricted). This "approved websites only" setting
  was not manually configured — appears to be another default applied by the supervised
  state.
- App Store toggle still shows OFF — but App Store appeared on home screen and is fully
  functional (no restrictions observed)
- Screen Time also shows "Don't Allow" for installing apps, deleting apps, and in-app
  purchases — but App Store works anyway, ignoring these restrictions

**Summary of post-supervision Screen Time weirdness:**

1. Allowed Apps toggles (Safari, App Store) remain OFF but are not enforced — apps visible
2. Safari partially working: appears despite toggle, browsing restricted to approved sites
3. App Store fully working: appears despite toggle AND despite "Don't Allow" install setting
4. New 4+ content rating appeared from nowhere — not user-configured
5. Web content restriction set to "approved websites only" — not user-configured

This is a messier picture than experiment 1. Supervision is not just ignoring Screen Time —
it's selectively overriding some settings while leaving others partially functional, AND
it's introducing new restrictions (4+ rating, approved websites) that the user didn't set.

### Phase 2: Install modified profile (with allowEnablingRestrictions: true)

Installed modified profile containing `allowEnablingRestrictions: true` plus
`allowSafari: true` and `allowAppInstallation: true` (from PR #534 leak — this was before
the fix was deployed).

- The 4+ content rating warning disappeared
- Screen Time Allowed Apps enforcement still broken (Safari and App Store still visible
  despite toggles OFF)
- Toggle off/on workaround did NOT work this time — Safari and App Store persisted even
  after cycling Content & Privacy Restrictions and full reboot

**Finding: `allowEnablingRestrictions: true` does not fix Screen Time enforcement.** The
toggle workaround failure was likely caused by the profile's explicit `allowSafari: true`
and `allowAppInstallation: true` overriding Screen Time. This theory needed verification
with a corrected profile (experiment 3).

---

## Experiment 3: Corrected profile (no explicit allowSafari/allowAppInstallation)

### Background

Experiment 2's toggle workaround failed, unlike experiment 1. The key difference: experiment
2's profile had explicit `allowSafari: true` and `allowAppInstallation: true` due to the
PR #534 leak that sent those keys to ALL devices. That bug has now been fixed and deployed
to production — the profile now only contains `allowAppRemoval` and
`allowEraseContentAndSettings` for non-Jonas devices.

### Question

With the corrected profile (no explicit `allowSafari`/`allowAppInstallation`), does the
toggle workaround (cycling Content & Privacy Restrictions off/on) work again? If yes, it
confirms the explicit profile keys were overriding Screen Time and the fix resolves it.

### Setup

- Factory-reset device, fresh setup
- Screen Time on with passcode
- Content & Privacy Restrictions on
- Safari toggled OFF in Allowed Apps
- iTunes & App Store Purchases: Don't Allow for install, delete, and in-app purchases
- All other apps accessible and working

### Phase 1: Post-supervision, pre-profile

Device supervised via Gertrude supervision tool. Confirmed "This iPhone is supervised and
managed by Gertrude" in Settings > General > About. Have NOT opened Gertrude app yet.

**Screen Time state:**

- Screen Time still on, passcode still set
- Content & Privacy Restrictions still toggled on
- Safari toggle still shows OFF
- iTunes & App Store Purchases still shows Don't Allow for all three options
- No "App Restrictions Now Set to 4+" warning (unlike experiment 2)

**Home screen:**

- Safari appeared on home screen (despite toggle OFF) — same as experiments 1 and 2
- App Store appeared on home screen (despite "Don't Allow" install setting) — same pattern

**Confirms prior finding:** Supervision alone breaks Screen Time Allowed Apps enforcement.
Toggles unchanged but not honored. Consistent across all three experiments.

### Phase 2: Install corrected Gertrude profile

Opened Gertrude app, completed onboarding, profile downloaded and installed. Profile
verified via curl to contain ONLY `allowAppRemoval: false` and
`allowEraseContentAndSettings: false` — no `allowSafari`, no `allowAppInstallation`.

**Screen Time state:**

- Safari toggle still shows OFF
- iTunes & App Store Purchases still shows "Don't Allow" for all three options
- No new warnings or phantom content ratings (unlike experiment 2's "4+" warning)

**Home screen:**

- Safari still visible despite toggle OFF
- App Store still visible despite "Don't Allow" setting

**Finding: Corrected profile installation caused no additional changes.** Same as
experiment 1's Phase 2 — the profile's restriction keys (`allowAppRemoval`,
`allowEraseContentAndSettings`) don't affect Safari/App Store visibility. Screen Time
enforcement remains broken from supervision alone.

### Phase 3: Toggle workaround — first attempt (FAILED)

Cycled Content & Privacy Restrictions off then back on.

- Safari still visible on home screen, still launchable
- App Store still visible on home screen, still usable
- No change from before the toggle

Tried full power-off reboot — no change. Workaround failed.

**This disproves the experiment 2 theory.** We attributed experiment 2's toggle failure to
the `allowSafari: true` leak from PR #534. But experiment 3 has no such leak, and the
toggle still failed. Looking back, experiment 1 also had the leak (PR #534 was deployed but
not yet discovered), and the toggle worked there. So the leak was never the variable.

### Phase 3b: iCloud re-authentication + toggle workaround (SUCCEEDED)

After supervision, the device was in the known "partial iCloud sign-out" state — iCloud
still knew the user's identity but required re-authentication (name visible but avatar
missing, prompting to sign in). This partial sign-out happens every time we supervise.

Fully re-authenticated iCloud by entering Apple ID password in Settings.

Then cycled Content & Privacy Restrictions off/on again.

**Result: Safari and App Store disappeared from home screen.** Screen Time enforcement
restored. The toggle workaround now works.

### Key finding: iCloud session state is the missing variable

Screen Time enforcement on a supervised device requires a fully authenticated iCloud
session. The sequence that restores Screen Time enforcement is:

1. Re-authenticate iCloud (enter Apple ID password in Settings after supervision)
2. Cycle Content & Privacy Restrictions off/on

Without step 1, the toggle alone does not work (experiment 3 Phase 3). With both steps,
enforcement is restored (experiment 3 Phase 3b).

**This likely explains all prior inconsistencies:**

- **Experiment 1:** Toggle worked — user probably re-authenticated iCloud before toggling
  without noting it (the partial sign-out was observed but iCloud re-auth wasn't tracked
  as a variable)
- **Experiment 2:** Toggle failed — iCloud was likely still in degraded state. The
  `allowSafari: true` leak was a red herring (it was also present in experiment 1 where
  the toggle worked)
- **Experiment 3:** Toggle failed initially (iCloud degraded), then succeeded after iCloud
  re-authentication

**Implication for users:** After supervising with Gertrude, users who rely on Screen Time
need to (1) re-authenticate iCloud, then (2) cycle Content & Privacy Restrictions off/on.
This is a two-step workaround that no user would discover on their own — it needs to be
part of onboarding guidance or automated if possible.
