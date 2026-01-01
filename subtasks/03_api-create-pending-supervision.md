# Task 03: api-create-pending-supervision

## Summary

Implement `CreatePendingSupervision` API endpoint for device-initiated code generation.

## Type

⚡ Parallel | 📦 Safe to ship

## Dependencies

**Blocked by:** Task 01 (PendingSupervision model)
**Blocks:** Task 12 (iOS pre-supervision screens), Task 17 (supervision tool code entry), Task 20 (landing page)

## Details

Create unauthed endpoint that iOS devices call to generate a supervision setup code.

### Endpoint Definition

```swift
struct CreatePendingSupervision: Pair {
  static let auth: ClientAuth = .none

  struct Input: PairInput {
    let vendorId: UUID
    let deviceModel: String
    let iosVersion: String
  }

  struct Output: PairOutput {
    let code: String        // "ABC123"
    let expiresAt: Date     // 7 days from now
  }
}
```

### Implementation

1. Generate unique 6-character alphanumeric code
2. Check for collisions (regenerate if exists)
3. Create `PendingSupervision` record
4. Set `expiresAt` to 7 days from now
5. Return code and expiration

### Code Generation

```swift
func generateCode() -> String {
  let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // No I/O/0/1 for clarity
  return String((0..<6).map { _ in chars.randomElement()! })
}
```

### Files to Create/Modify

- `swift/pairql-iosapp/Sources/IOSRoute/UnauthedPairs/CreatePendingSupervision.swift` - Route definition
- `swift/api/Sources/Api/PairQL/iOS/Resolvers/CreatePendingSupervision.swift` - Resolver

### Edge Cases

- If device already has pending supervision (same vendorId), return existing code or generate new?
- Handle rate limiting to prevent code exhaustion attacks
