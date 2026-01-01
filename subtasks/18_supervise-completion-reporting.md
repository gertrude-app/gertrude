# Task 18: supervise-completion-reporting

## Summary

Report supervision completion to API with UDID after successful supervision.

## Type

⚡ Parallel | 📦 Safe to ship

## Dependencies

**Blocked by:** Task 06 (MarkSupervisionComplete API), Task 17 (code entry)
**Blocks:** Nothing

## Details

After the supervision tool successfully supervises a device, report completion to the Gertrude API.

### UDID Capture

When device is connected via USB, the tool can retrieve the UDID:
- This is a unique device identifier
- Different from iOS `vendorId` (which is app-specific)
- Useful for verification and audit trail

```swift
// Pseudo-code - actual implementation depends on tool's device communication
let udid = connectedDevice.udid  // e.g., "00008030-001A2D3E4F5G6H7I"
```

### API Call Timing

After supervision completes successfully:

```
1. Supervision payload sent to device
2. Device begins reboot
3. Tool detects supervision complete
4. → Call MarkSupervisionComplete(code, udid)
5. Show "Waiting for restart..." screen
```

### Implementation

```swift
func onSupervisionComplete() async {
  guard let code = storedSetupCode else {
    // No code - standalone mode, skip API call
    return
  }

  do {
    let result = try await api.markSupervisionComplete(
      code: code,
      udid: device.udid
    )
    // Update UI with next steps
    showNextSteps(childName: result.childName)
  } catch {
    // Log error but don't block - supervision succeeded
    // The iOS app will handle verification on its end
    logger.error("Failed to report completion: \(error)")
  }
}
```

### Updated Completion Screen

```
┌─────────────────────────────────────────┐
│  GERTRUDE SUPERVISE                     │
├─────────────────────────────────────────┤
│                                         │
│  ✓ Supervision Complete                 │
│                                         │
│  Luke's iPhone is now supervised.       │
│                                         │
│  Next steps:                            │
│  1. Wait for the phone to restart       │
│  2. Open the Gertrude app on the phone  │
│  3. Follow prompts to complete setup    │
│                                         │
│  [Done]                                 │
└─────────────────────────────────────────┘
```

### Error Handling

API call failure should NOT block the flow:
- Supervision already succeeded on device
- iOS app can recover via CheckSupervisionStatus
- Log error for debugging but show success to user

### Files to Modify

- Supervision tool codebase at `~/gertie/supervise`
- Add API client for MarkSupervisionComplete
- Update completion flow/screen

### Notes

- API call is "fire and hope" - don't retry aggressively
- UDID format validation before sending
- Store UDID in case we need to retry later
