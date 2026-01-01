# Task 06: api-mark-supervision-complete

## Summary

Implement `MarkSupervisionComplete` API endpoint called by supervision tool after success.

## Type

⚡ Parallel | 📦 Safe to ship

## Dependencies

**Blocked by:** Tasks 01, 02 (database models)
**Blocks:** Task 18 (supervision tool completion reporting)

## Details

Create endpoint for the supervision tool to report successful supervision and capture the device UDID.

### Endpoint Definition

```swift
struct MarkSupervisionComplete: Pair {
  static let auth: ClientAuth = .none  // or tool-specific auth?

  struct Input: PairInput {
    let code: String
    let udid: String          // Captured via USB by supervision tool
  }

  struct Output: PairOutput {
    let success: Bool
    let childName: String?
    let nextSteps: String?    // "Open Gertrude app to complete setup"
  }
}
```

### Implementation

1. Look up PendingSupervision by code
2. Verify code is claimed (has childId)
3. Update PendingSupervision:
   - Set `supervisionCompletedAt` to now
4. Update IOSDevice:
   - Set `isSupervised: true`
   - Set `supervisionMethod: .gertrudeTool`
   - Set `udid` to provided value
5. Return success with next steps message

### Error Cases

- `codeNotFound` - Invalid code
- `codeNotClaimed` - Parent hasn't claimed yet
- `alreadySupervised` - Supervision already marked complete

### Files to Create/Modify

- `swift/pairql-iosapp/Sources/IOSRoute/UnauthedPairs/MarkSupervisionComplete.swift` - Route
- `swift/api/Sources/Api/PairQL/iOS/Resolvers/MarkSupervisionComplete.swift` - Resolver

### Open Questions

- Should this require some form of tool authentication?
- Should we validate UDID format?
- What if tool is run twice on same device?
