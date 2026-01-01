# Task 13: ios-post-supervision-detection

## Summary

Implement launch detection logic to route supervised devices to the correct post-supervision state.

## Type

⚡ Parallel | 📦 N/A (iOS unreleased)

## Dependencies

**Blocked by:** Task 05 (CheckSupervisionStatus API), Task 11 (state machine)
**Blocks:** Nothing

## Details

When the iOS app launches, it needs to detect if:
1. There's a pending supervision in progress
2. The device is now supervised
3. The parent has claimed the code
4. Setup is complete

### Detection Matrix

| Stored Code? | Filter Running? | Conclusion                              |
|--------------|-----------------|----------------------------------------|
| Yes          | No              | Check API for supervision status        |
| Yes          | Yes             | Fully set up, go to running state       |
| No           | No              | Fresh install, start onboarding         |
| No           | Yes             | Minor device (existing flow)            |

### Launch Flow

```swift
func determineInitialState() async -> Screen {
  // 1. Check for stored pending supervision code
  guard let code = UserDefaults.pendingSupervisionCode else {
    // No pending supervision - use existing logic
    return existingLaunchLogic()
  }

  // 2. Check if filter is already running
  if filterManager.isFilterRunning {
    // Setup complete, clear stored code, go to running
    UserDefaults.pendingSupervisionCode = nil
    return .running(.connected)
  }

  // 3. Call API to check status
  let status = try await api.checkSupervisionStatus(code: code, vendorId: vendorId)

  switch status {
  case .pending:
    // Parent hasn't claimed yet
    return .onboarding(.supervision(.codeNotClaimed))

  case .claimed:
    // Claimed but not supervised - shouldn't happen if app was closed
    return .onboarding(.supervision(.instructionsForParent))

  case .supervised:
    // Supervised, needs profile installation
    return .onboarding(.supervision(.supervisionDetected))

  case .complete:
    // API says complete but filter not running? Verify profile
    return .onboarding(.supervision(.promptInstallProfile))

  case .expired, .notFound:
    // Code expired or invalid, start over
    UserDefaults.pendingSupervisionCode = nil
    return .onboarding(.happyPath(.hiThere))
  }
}
```

### Supervision Detection

Check if device is supervised:
- Look for "This iPhone is supervised" in Settings
- Unfortunately no direct API - we infer from:
  - Stored code + supervisionCompletedAt from API
  - Or: check if certain MDM capabilities are available

### Files to Modify

- `swift/iosapp/lib-ios/Sources/LibApp/IOSReducer.swift` - Launch logic
- `swift/iosapp/lib-ios/Sources/LibApp/` - API client for CheckSupervisionStatus
- UserDefaults/Keychain helpers for stored code

### Edge Cases

- Network error during status check → show retry or offline message
- Code expired → clear and restart onboarding
- App killed during supervision → status check on relaunch handles this
