# Task 14: ios-profile-install-flow

## Summary

Implement profile download and installation guidance screens.

## Type

⚡ Parallel | 📦 N/A (iOS unreleased)

## Dependencies

**Blocked by:** Task 07 (profile serving API), Task 11 (state machine) **Blocks:** Nothing

## Details

Build the screens that guide users through downloading and installing the configuration
profile that enables content filtering.

### Screen 1: Prompt Install Profile (`promptInstallProfile`)

```
┌────────────────────────────────────────┐
│  One More Step                         │
│                                        │
│  To enable content filtering, you      │
│  need to install a configuration       │
│  profile.                              │
│                                        │
│  This takes about 30 seconds.          │
│                                        │
│  [Next]                                │
└────────────────────────────────────────┘
```

### Screen 2: Explain Profile Download (`explainProfileDownload`)

```
┌────────────────────────────────────────┐
│  Allow the Download                    │
│                                        │
│  ┌─────────────────────────────────┐   │
│  │  [Graphic showing Safari        │   │
│  │   download prompt with arrow    │   │
│  │   pointing to "Allow" button]   │   │
│  └─────────────────────────────────┘   │
│                                        │
│  When the browser opens, tap           │
│  "Allow" to download the profile.      │
│                                        │
│  [Got it]                              │
└────────────────────────────────────────┘
```

### Screen 3: Installing Profile (`installingProfile`)

On "Got it":

1. Get profile URL from API
2. Open Safari WebView to profile URL
3. Profile auto-downloads
4. User taps "Allow" in Safari prompt
5. iOS shows "Profile Downloaded" notification
6. Safari closes, return to app

Implementation: Use `ASWebAuthenticationSession` or `SFSafariViewController`

### Screen 4: Explain Profile Install (`explainProfileInstall`)

```
┌────────────────────────────────────────┐
│  Install the Profile                   │
│                                        │
│  ┌─────────────────────────────────┐   │
│  │  [Graphic showing Settings      │   │
│  │   with "Profile Downloaded"     │   │
│  │   banner highlighted]           │   │
│  └─────────────────────────────────┘   │
│                                        │
│  1. Tap "Profile Downloaded" at top    │
│  2. Tap "Install"                      │
│  3. Enter your passcode                │
│                                        │
│  [Open Settings]                       │
└────────────────────────────────────────┘
```

### Screen 5: Verifying (`verifyingProfileInstall`)

After user returns from Settings:

1. Poll/check if filter is now running
2. Show loading spinner
3. If running → success
4. If not → prompt to try again

```
┌────────────────────────────────────────┐
│  Checking...                           │
│                                        │
│        ⟳                               │
│                                        │
│  Verifying profile installation        │
└────────────────────────────────────────┘
```

### Files to Create/Modify

- `swift/iosapp/lib-ios/Sources/LibApp/IOSReducer.swift` - Flow logic
- `swift/iosapp/app/` - SwiftUI views with graphics
- Safari/WebView integration
- Settings app deep link: `UIApplication.openSettingsURLString`

### Graphics Needed

- Safari download prompt mockup with arrow
- Settings "Profile Downloaded" banner mockup

### Notes

- Follow existing pattern from `dontGetTrickedPreAuth` screens
- Consider: what if user cancels in Safari? Retry option
- Consider: what if profile already downloaded but not installed?

### Related Research

- [00_profile-removal-prevention.md](./00_profile-removal-prevention.md) -
  `PayloadRemovalDisallowed`, profile replacement mechanism, and recommended
  update/removal flows
