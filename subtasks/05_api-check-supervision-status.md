# Task 05: api-check-supervision-status

## Summary

Implement `CheckSupervisionStatus` API endpoint for device to verify connection after reboot.

## Type

⚡ Parallel | 📦 Safe to ship

## Dependencies

**Blocked by:** Task 01 (PendingSupervision model)
**Blocks:** Task 13 (iOS post-supervision detection)

## Details

Create unauthed endpoint that iOS devices call after reboot to check if their code was claimed and get connection info.

### Endpoint Definition

```swift
struct CheckSupervisionStatus: Pair {
  static let auth: ClientAuth = .none

  struct Input: PairInput {
    let vendorId: UUID
    let code: String
  }

  struct Output: PairOutput {
    let status: Status
    let childName: String?
    let parentName: String?
    let deviceToken: String?  // For future API calls
    let profileUrl: URL?

    enum Status: String, Codable {
      case pending              // Code exists but not claimed
      case claimed              // Parent claimed, awaiting supervision
      case supervised           // Supervision complete, needs profile
      case complete             // All done
      case expired              // Code expired
      case notFound             // Code doesn't exist
    }
  }
}
```

### Implementation

1. Look up PendingSupervision by code
2. Verify vendorId matches (security check)
3. Determine status based on fields:
   - No record → `notFound`
   - `expiresAt` passed → `expired`
   - `claimedByParentId` null → `pending`
   - `supervisionCompletedAt` null → `claimed`
   - `profileInstalledAt` null → `supervised`
   - All set → `complete`
4. If claimed, fetch parent name and child name
5. If supervised, include device token and profile URL

### Files to Create/Modify

- `swift/pairql-iosapp/Sources/IOSRoute/UnauthedPairs/CheckSupervisionStatus.swift` - Route
- `swift/api/Sources/Api/PairQL/iOS/Resolvers/CheckSupervisionStatus.swift` - Resolver

### Security

- Must verify vendorId matches to prevent code enumeration
- Don't return sensitive info for mismatched vendorId
