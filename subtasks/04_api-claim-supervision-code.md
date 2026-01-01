# Task 04: api-claim-supervision-code

## Summary

Implement `ClaimSupervisionCode` API endpoint for parent to claim a device.

## Type

⚡ Parallel | 📦 Safe to ship

## Dependencies

**Blocked by:** Tasks 01, 02 (database models)
**Blocks:** Task 09 (dashboard claim UI), Task 20 (landing page)

## Details

Create parent-authenticated endpoint to claim a pending supervision code, creating the Child and IOSDevice records.

### Endpoint Definition

```swift
struct ClaimSupervisionCode: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let code: String
    let childName: String
  }

  struct Output: PairOutput {
    let childId: Child.Id
    let deviceId: IOSDevice.Id
  }
}
```

### Implementation (Transaction)

1. Validate code exists in PendingSupervision
2. Check code not expired
3. Check code not already claimed
4. Create new `Child` record with provided name
5. Create `IOSDevice` linked to child
   - Set `isSupervised: false` (not yet supervised)
   - Copy `vendorId`, `deviceModel`, `iosVersion` from pending record
6. Create `IOSApp.Token` for the device
7. Assign ALL BlockGroups to device (existing pattern)
8. Update PendingSupervision:
   - Set `claimedByParentId` to current parent
   - Set `childId` to new child
9. Return IDs

### Error Cases

- `codeNotFound` - Invalid code
- `codeExpired` - Code past expiration
- `codeAlreadyClaimed` - Already claimed by another parent

### Files to Create/Modify

- `swift/pairql-dashboard/Sources/DashboardRoute/AuthedPairs/ClaimSupervisionCode.swift` - Route
- `swift/api/Sources/Api/PairQL/Dashboard/Resolvers/ClaimSupervisionCode.swift` - Resolver

### Notes

- This is a dashboard route (parent auth), not iOS route
- Large transaction but all-or-nothing is correct
- Consider: should we allow re-claiming if supervision never completed?
