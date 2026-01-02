# Task 17: supervise-code-entry-screen

## Summary

Add code entry screen to supervision tool that fetches context from API.

## Type

⚡ Parallel | 📦 Safe to ship (separate tool)

## Dependencies

**Blocked by:** Task 01 (CreatePendingSupervision - need a way to look up codes)
**Blocks:** Task 18

## Details

Modify the Gertrude supervision tool to accept a setup code on launch, fetching device context from the API.

### New Launch Flow

Instead of immediately prompting for device connection:

```
┌─────────────────────────────────────────┐
│  GERTRUDE SUPERVISE                     │
├─────────────────────────────────────────┤
│                                         │
│  Enter Setup Code                       │
│                                         │
│  Enter the code from the Gertrude app:  │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  [A][B][C][1][2][3]             │    │
│  └─────────────────────────────────┘    │
│                                         │
│  [Continue]                             │
│                                         │
│  ─────────────────────────────────────  │
│  Or continue without a code             │
│  (device won't connect to account)      │
└─────────────────────────────────────────┘
```

### API Integration

New endpoint needed: `GetPendingSupervision`

```swift
struct GetPendingSupervision: Pair {
  static let auth: ClientAuth = .none

  struct Input: PairInput {
    let code: String
  }

  struct Output: PairOutput {
    let valid: Bool
    let childName: String?       // "Luke"
    let deviceModel: String?     // "iPhone 14"
    let iosVersion: String?      // "18.2"
    let parentEmail: String?     // For display
  }
}
```

### Personalized Context Screen

After valid code entry:

```
┌─────────────────────────────────────────┐
│  GERTRUDE SUPERVISE                     │
├─────────────────────────────────────────┤
│                                         │
│  Set Up Luke's iPhone                   │
│                                         │
│  iPhone 14 · iOS 18.2                   │
│                                         │
│  Connect the device with a USB cable.   │
│                                         │
│        ⟳ Waiting for device...          │
│                                         │
└─────────────────────────────────────────┘
```

### Code Storage

Store the code locally in the tool for later use:
- Needed for `MarkSupervisionComplete` call (Task 18)
- Persist in memory during session

### Error Handling

- Invalid code → "Code not found. Check and try again."
- Expired code → "This code has expired. Generate a new one in the Gertrude app."
- Network error → "Couldn't connect to Gertrude. Check your internet connection."

### Files to Modify

- Supervision tool codebase at `~/gertie/supervise`
- Read `~/gertie/supervise/CLAUDE.md` for tool structure
- Add API client for GetPendingSupervision
- Update main window/flow

### Notes

- "Continue without code" option allows existing standalone use
- Code should auto-focus for quick entry
- Consider: paste support for copying code from messages
