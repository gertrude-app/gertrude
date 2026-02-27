# Apple Configurator → Gertrude Unsupervision Test

**Date:** 2026-02-24

## Purpose

Determine whether an iOS device supervised via Apple Configurator can be unsupervised
using the Gertrude Tauri USB tool (which sends `IsSupervised: false` via backup restore),
without data loss. This is relevant for users who have Configurator-supervised phones and
want to switch to Gertrude-managed supervision.

## Questions to Answer

1. Does the Gertrude unsupervision tool successfully remove Configurator-applied
   supervision?
2. Is user data preserved (wallpaper, photos, notes, contacts, apps)?
3. What happens to the Configurator-delivered profile — does it remain, get removed, or
   break?

## Device

- **Model:** iPhone 11 (MWKM2LL/A)
- **iOS version:** 26.2
- **Supervisied by:** Apple Configurator
- **Configurator org name:** `Gertie Xfer Test Duex`

## Pre-Unsupervision Setup

### Configurator profile applied with:

- `allowCamera: false` — Camera app removed from home screen
- `allowSafari: false` — Safari removed from home screen
- Security: "With Authorization" (password-protected removal)

### Personalizations:

- Distinctive wallpaper set
- Photo taken (in camera roll)
- Note saved in Notes app
- Contact saved

### Pre-unsupervision state confirmed:

- Device showed "This iPhone is supervised..." in Settings > General > About
- Camera app absent from home screen
- Safari absent from home screen
- Profile visible in Settings > General > VPN & Device Management

## Unsupervision

- Tool: Gertrude Tauri USB unsupervision tool (sends `IsSupervised: false` via backup
  restore)
- Find My disabled prior to running
- Private Relay disabled prior to running
- **Result:** Completed successfully, device rebooted

## Post-Unsupervision Checks

### 1. Supervision removed?

Settings > General > About — does "This iPhone is supervised..." still appear?

- Result: **No — supervision removed successfully**

### 2. Profile still present?

Settings > General > VPN & Device Management — is the Configurator profile still listed?

- Result: **No — profile is gone.** VPN & Device Management section is empty (just shows
  "Sign in to Work or School Account"). Likely because the profile contained
  supervised-only restriction keys (`allowCamera`, `allowSafari`), so iOS removed it when
  the device lost supervised state. Or iOS may tie Configurator-delivered profiles to the
  supervision identity and clean them up on unsupervision.

### 3. Profile restrictions still active?

- Camera app: **back on home screen** — restriction no longer active
- Safari: **back on home screen** — restriction no longer active
- Consistent with profile being removed entirely

### 4. Profile removable?

If the profile is still present, can it be viewed? Does it still require a password to
remove?

- Result: **N/A — profile was removed entirely by unsupervision**

### 5. Wallpaper preserved?

- Result: **Yes**

### 6. Photo preserved?

Check camera roll for the photo taken earlier.

- Result: **Yes**

### 7. Note preserved?

Open Notes app, check for the saved note.

- Result: **Yes**

### 8. Contact preserved?

Open Contacts, check for the saved contact.

- Result: **Yes**

### 9. Apps preserved?

Are all previously installed apps still present?

- Result: **Yes**

### 10. iCloud still signed in?

Settings > [account name] at top — still signed in?

- Result: **Partially.** Account identity preserved (name still shown) but authentication
  session invalidated — avatar gone, prompting to sign in again with password. This is a
  known pattern observed in both supervision and unsupervision directions. Not fully
  investigated yet — separate to-do to explore further.

### 11. Any other observations?

Anything unexpected — new setup screens, changed settings, errors, etc.

- Result: **Nothing else notable**

## Findings Summary

1. **Unsupervision works.** The Gertrude Tauri USB tool successfully removed
   Configurator-applied supervision.
2. **All user data preserved.** Wallpaper, photos, notes, contacts, and apps all survived.
3. **Configurator profile was automatically removed.** iOS removed the profile entirely
   when supervision was removed — likely because it contained supervised-only restriction
   keys. All restrictions (camera, Safari) were lifted.
4. **iCloud partially signed out.** Account identity preserved but authentication session
   invalidated — user prompted to re-enter password. This happens in both supervision and
   unsupervision directions and needs further investigation.

## Implications

- **Configurator → Gertrude migration is viable.** Users with Configurator-supervised
  devices can be unsupervised without data loss, then re-supervised via Gertrude's tool.
- **The Configurator profile will be lost.** Any restrictions from the old Configurator
  profile will be removed during unsupervision. The user would need to install the new
  Gertrude profile after re-supervision.
- **Users will need to re-authenticate iCloud.** Should be communicated as part of the
  process — have your Apple ID password handy.
- **The full migration flow would be:** unsupervise (Gertrude tool) → re-supervise
  (Gertrude tool) → install Gertrude profile (iOS app) → re-enter iCloud password.
