# Task 11: ios-supervision-state-machine

## Summary

Update the iOS app `Supervision` state enum with new states for the supervision flow.

## Type

⚡ Parallel | 📦 N/A (iOS unreleased)

## Dependencies

**Blocked by:** Nothing (can start immediately)
**Blocks:** Tasks 12-16 (all iOS screen tasks)

## Details

Refactor the `Supervision` enum in the iOS app state machine to support the new supervision tool flow.

### Current States (to remove/replace)

```swift
public enum Supervision: Equatable {
  case intro
  case explainSupervision
  case explainNeedFriendWithMac
  case explainRequiresEraseAndSetup  // REMOVE - no longer accurate
  case instructions
  case sorryNoOtherWay               // REPLACE - no longer a dead end
}
```

### New States

```swift
public enum Supervision: Equatable {
  // Pre-supervision (before phone reboots)
  case intro
  case explainSupervision            // Updated messaging
  case checkHasAccount               // "Do you have a Gertrude account?"
  case generateSetupCode             // Show code, store locally
  case instructionsForParent         // Clear steps for parent

  // Post-supervision (after phone reboots, detected supervised)
  case supervisionDetected           // "Great! Your device is supervised"
  case verifyingConnection           // Loading: checking if code was claimed
  case connectionVerified            // "Connected to [Parent Name]"
  case codeNotClaimed                // Parent didn't claim yet, show code again

  // Profile installation
  case promptInstallProfile          // "One more step..."
  case explainProfileDownload        // Help screen before Safari
  case installingProfile             // Safari WebView open
  case explainProfileInstall         // Help screen for Settings
  case verifyingProfileInstall       // Checking if filter is running
  case profileInstalled              // Success!

  // Completion
  case setupComplete                 // "You're all set!" → running

  // Error states
  case supervisionFailed             // Manual verification failed
  case networkError                  // API call failed
}
```

### Reducer Updates

Add stub case handlers in the reducer for all new states. Actual navigation logic will be implemented in subsequent tasks.

```swift
case .onboarding(.supervision(.generateSetupCode)):
  // TODO: Task 12
  return .none

case .onboarding(.supervision(.supervisionDetected)):
  // TODO: Task 13
  return .none
```

### Files to Modify

- `swift/iosapp/lib-ios/Sources/LibApp/IOSReducer+State.swift` - State definitions
- `swift/iosapp/lib-ios/Sources/LibApp/IOSReducer.swift` - Reducer stubs

### Notes

- This task is foundational - get the state structure right
- Keep backward compatibility considerations minimal (app unreleased)
- State names should be clear about what screen/phase they represent
