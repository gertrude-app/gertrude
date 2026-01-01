# Task 15: ios-connection-verified-flow

## Summary

Implement screens for connection verification, "code not claimed" state, and setup completion.

## Type

⚡ Parallel | 📦 N/A (iOS unreleased)

## Dependencies

**Blocked by:** Task 08 (MarkSetupComplete API), Task 11 (state machine)
**Blocks:** Nothing

## Details

Build the screens that show connection status and handle the setup completion flow.

### Screen 1: Connection Verified (`connectionVerified`)

Shown when API confirms parent has claimed the code:

```
┌────────────────────────────────────────┐
│  ✓ Connected                           │
│                                        │
│  This device is now connected to       │
│  Ben's Gertrude account.               │
│                                        │
│  [Continue]                            │
└────────────────────────────────────────┘
```

### Screen 2: Code Not Claimed (`codeNotClaimed`)

Shown when parent hasn't claimed the code yet:

```
┌────────────────────────────────────────┐
│  Almost There                          │
│                                        │
│  Your device is supervised, but your   │
│  parent hasn't finished setting up     │
│  the account yet.                      │
│                                        │
│  Your code:                            │
│         ┌─────────────────┐            │
│         │   A B C 1 2 3   │            │
│         └─────────────────┘            │
│                                        │
│  Ask them to go to:                    │
│  gertrude.app/s/ABC123                 │
│                                        │
│  [Check Again]                         │
└────────────────────────────────────────┘
```

"Check Again" calls `CheckSupervisionStatus` and updates state.

### Screen 3: Setup Complete (`setupComplete`)

Shown after profile is installed and filter is running:

```
┌────────────────────────────────────────┐
│  🎉 You're All Set!                    │
│                                        │
│  Gertrude is now protecting this       │
│  device.                               │
│                                        │
│  Your parent can manage settings       │
│  from their Gertrude dashboard.        │
│                                        │
│  [Done]                                │
└────────────────────────────────────────┘
```

**On Done:**
1. Call `MarkSetupComplete` API
2. Store device token for future API calls
3. Clear pending supervision code from local storage
4. Transition to `.running(.connected)` state

### Reducer Logic

```swift
case .onboarding(.supervision(.setupComplete(.doneTapped))):
  return .run { send in
    let result = try await api.markSetupComplete(
      code: state.pendingCode,
      vendorId: device.vendorId
    )
    // Store token
    await keychain.setDeviceToken(result.deviceToken)
    // Clear pending state
    UserDefaults.pendingSupervisionCode = nil
    // Transition
    await send(.transitionToRunning)
  }
```

### Files to Create/Modify

- `swift/iosapp/lib-ios/Sources/LibApp/IOSReducer.swift` - Actions and reducer
- `swift/iosapp/app/` - SwiftUI views
- Keychain helper for storing device token

### Notes

- "Check Again" should have loading state and debouncing
- Consider: auto-poll every 30 seconds on codeNotClaimed screen?
- Device token storage should match existing IOSApp.Token pattern
