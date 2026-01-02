# Task 12: ios-pre-supervision-screens

## Summary

Implement pre-supervision UI screens: account check, code generation, and handoff instructions.

## Type

⚡ Parallel | 📦 N/A (iOS unreleased)

## Dependencies

**Blocked by:** Task 01 (CreatePendingSupervision API), Task 11 (state machine)
**Blocks:** Nothing

## Details

Build the screens that guide users through generating a supervision code and handing off to their parent/supervisor.

### Screen 1: Account Check (`checkHasAccount`)

```
┌────────────────────────────────────────┐
│  Gertrude Account Required             │
│                                        │
│  Since this device belongs to someone  │
│  18 or older, you'll need a Gertrude   │
│  account to manage it.                 │
│                                        │
│  Do you already have a Gertrude        │
│  account?                              │
│                                        │
│  [Yes, I have an account]              │
│  [No, I need to create one]            │
└────────────────────────────────────────┘
```

Both buttons lead to the same next screen (code generation) - the question helps set expectations.

### Screen 2: Code Generation (`generateSetupCode`)

**On appear:**
1. Call `CreatePendingSupervision` API
2. Store code in UserDefaults/Keychain
3. Display code

```
┌────────────────────────────────────────┐
│  Your Setup Code                       │
│                                        │
│         ┌─────────────────┐            │
│         │   A B C 1 2 3   │            │
│         └─────────────────┘            │
│                                        │
│  [📋 Copy Code]                        │
│                                        │
│  [Next]                                │
└────────────────────────────────────────┘
```

### Screen 3: Handoff Instructions (`instructionsForParent`)

```
┌────────────────────────────────────────┐
│  Continue on Computer                  │
│                                        │
│  The next steps require a Mac or       │
│  Windows computer. Have your parent    │
│  or supervisor go to:                  │
│                                        │
│  ┌─────────────────────────────────┐   │
│  │  gertrude.app/s/ABC123          │   │
│  └─────────────────────────────────┘   │
│                                        │
│  [📋 Copy Link]  [📧 Email Link]       │
│                                        │
│  ─────────────────────────────────────  │
│                                        │
│  After they finish the computer        │
│  steps, open this app again.           │
│                                        │
│  [I understand]                        │
└────────────────────────────────────────┘
```

### Local Storage

Store in UserDefaults or Keychain:
- `pendingSupervisionCode: String`
- `pendingSupervisionCreatedAt: Date`

This persists across app kills and device reboots.

### Share Sheet Integration

- Copy button: copy code or URL to clipboard
- Email button: open Mail with pre-filled subject/body

### Files to Create/Modify

- `swift/iosapp/lib-ios/Sources/LibApp/IOSReducer.swift` - Actions and reducer logic
- `swift/iosapp/app/App.swift` or views directory - SwiftUI views
- Add API client call for CreatePendingSupervision

### Notes

- Error handling: what if API call fails? Show retry option
- Consider: should we show a loading state during API call?
- The "Email Link" could use native share sheet or MFMailComposeViewController
