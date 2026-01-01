# Task 08: api-mark-setup-complete

## Summary

Implement `MarkSetupComplete` API endpoint called by iOS app when filter is running.

## Type

⚡ Parallel | 📦 Safe to ship

## Dependencies

**Blocked by:** Tasks 01, 02 (database models)
**Blocks:** Task 15 (iOS connection verified flow)

## Details

Create endpoint for iOS app to confirm profile is installed and filter is running, completing the setup flow.

### Endpoint Definition

```swift
struct MarkSetupComplete: Pair {
  static let auth: ClientAuth = .none  // or device token

  struct Input: PairInput {
    let code: String
    let vendorId: UUID
  }

  struct Output: PairOutput {
    let success: Bool
    let deviceToken: String   // For future authenticated API calls
    let childName: String
    let parentName: String
  }
}
```

### Implementation

1. Look up PendingSupervision by code
2. Verify vendorId matches
3. Verify supervision was completed
4. Update PendingSupervision:
   - Set `profileInstalledAt` to now
5. Update IOSDevice:
   - Set `profileInstalledAt` to now
6. Fetch or return existing device token
7. Optionally: archive/cleanup PendingSupervision record
8. Return success with device credentials

### Post-Completion

After this call, the device should transition to normal "running" state and use the device token for all future API calls (fetching block rules, etc.).

### Files to Create/Modify

- `swift/pairql-iosapp/Sources/IOSRoute/UnauthedPairs/MarkSetupComplete.swift` - Route
- `swift/api/Sources/Api/PairQL/iOS/Resolvers/MarkSetupComplete.swift` - Resolver

### Cleanup Consideration

Should PendingSupervision records be:
- Deleted after completion?
- Archived with a `completedAt` timestamp?
- Kept for audit trail?

Recommendation: Keep for audit, add `completedAt` field, exclude from active queries.
