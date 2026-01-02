# Task 01: ios-pending-supervision-model

## Summary

Add `PendingSupervision` database model, migration, and `CreatePendingSupervision` API
endpoint.

## Type

🔒 Blocking | 📦 Safe to ship

## Dependencies

**Blocked by:** Nothing **Blocks:** Tasks 04-08 (API endpoints), Task 12 (iOS
pre-supervision screens), Task 17 (supervision tool code entry), Task 20 (landing page)

## Details

### Part 1: Database Model

Add new `PendingSupervision` model to track supervision attempts initiated by iOS devices.

#### Model Fields

```swift
struct PendingSupervision: Model {
  var id: Id
  var code: Int                        // 6-digit code (100000-999999), unique, indexed
  var vendorId: UUID                   // iOS device vendor identifier
  var deviceType: String               // "iPhone" or "iPad"
  var iosVersion: String               // "18.2"
  var claimedByParentId: Parent.Id?    // Set when parent claims code
  var childId: Child.Id?               // Set when child record created
  var expiresAt: Date                  // Code expiration (7 days?)
  var createdAt: Date
  var updatedAt: Date
}
```

Use existing `verificationCode.generate()` dependency (see `Dependencies.swift`) for code
generation.

Note: `supervisionCompletedAt` and `profileInstalledAt` belong on `IosDevice` (Task 02),
not here. This model is a temporary bridge for the claim handshake.

#### Migration

- Create `iosapp.pending_supervisions` table
- Add unique index on `code`
- Add index on `vendorId`
- Add CHECK constraint on `device_type`: `CHECK (device_type IN ('iPhone', 'iPad'))` (see
  migration 049 for pattern)
- Add foreign key: `claimedByParentId` → `parents.id` (SET NULL on delete)
- Add foreign key: `childId` → `parent.children.id` (SET NULL on delete)

### Part 2: API Endpoint

Create unauthed endpoint that iOS devices call to generate a supervision setup code.

#### Endpoint Definition

```swift
struct CreatePendingSupervision: Pair {
  static let auth: ClientAuth = .none

  struct Input: PairInput {
    let vendorId: UUID
    let deviceType: String  // "iPhone" or "iPad"
    let iosVersion: String
  }

  struct Output: PairOutput {
    let code: Int           // 6-digit code (100000-999999)
    let expiresAt: Date     // 7 days from now
  }
}
```

### Part 4: hurl file

create an api .hurl file for testing, see existing api .hurl files

#### Implementation

1. Look up existing `PendingSupervision` by `vendorId` where `expiresAt > now`
2. If exists → return existing code and expiration (no DB write)
3. Generate unique 6-digit code (see collision handling below)
4. Create `PendingSupervision` record with `expiresAt` = 7 days from now
5. Return code and expiration

#### Existing Pending Supervision (same vendorId)

**Behavior:** Return existing unexpired code, regardless of claim status. Do not extend
expiration.

**Rationale:**

- **Idempotent** - same device, same code until expiration. No side effects on repeat
  calls.
- **Doesn't break in-progress flows** - if parent already claimed the code, it still works
- **Handles app state loss** - device reinstall/cache clear gets back the code it "forgot"
- **Parent's mental model stays correct** - if parent wrote down "expires Jan 10",
  silently extending server-side creates invisible inconsistency
- **Clean reset point** - letting codes expire naturally and regenerating is more
  predictable than perpetual extension

**Not solved (intentionally):** User can't manually reset to get a fresh code (e.g., gave
it to wrong person). 7-day expiration handles this naturally; explicit invalidation can be
added later if needed.

#### Code Collision Handling

Expired records are kept as an audit trail (not deleted). The unique constraint on `code`
means we must retry if we generate a code that already exists in the table.

```swift
for _ in 0..<10 {
  let code = verificationCode.generate()
  let exists = try await PendingSupervision.query()
    .where(.code == code)
    .exists(in: db)
  if !exists {
    return code
  }
}
throw "failed to generate unique code after 10 attempts"
```

**Why this is sustainable:** With 900,000 possible codes, even after 10 years at 100
supervisions/day (365,000 records), 535,000 codes remain available. Collision chance per
attempt is ~40%, but with a retry loop you'll find an unused code in 2-3 tries. This
approach works for 25+ years before becoming a concern.

### Files to Create/Modify

- `swift/api/Sources/Api/Models/IOS/` - Add new model file
- `swift/api/Sources/Api/Database/Migrations/` - Add new migration
- `swift/api/Sources/Api/Database/Client+Live.swift` - Register model
- `swift/pairql-iosapp/Sources/IOSRoute/UnauthedPairs/CreatePendingSupervision.swift` -
  Route definition
- `swift/api/Sources/Api/PairQL/iOS/Resolvers/CreatePendingSupervision.swift` - Resolver

### Notes

- Expired records are intentionally kept as an audit trail of supervision connections.
