# Task 01: ios-pending-supervision-model

## Summary

Add `PendingSupervision` database model and migration.

## Type

🔒 Blocking | 📦 Safe to ship

## Dependencies

**Blocked by:** Nothing
**Blocks:** Tasks 03-08 (all API endpoints)

## Details

Add new `PendingSupervision` model to track supervision attempts initiated by iOS devices.

### Model Fields

```swift
struct PendingSupervision: Model {
  var id: Id
  var code: String                     // "ABC123" - unique, indexed
  var vendorId: UUID                   // iOS device vendor identifier
  var deviceModel: String              // "iPhone 14 Pro"
  var iosVersion: String               // "18.2"
  var claimedByParentId: Parent.Id?    // Set when parent claims code
  var childId: Child.Id?               // Set when child record created
  var supervisionCompletedAt: Date?    // Set after supervision tool completes
  var profileInstalledAt: Date?        // Set after profile installed
  var expiresAt: Date                  // Code expiration (7 days?)
  var createdAt: Date
  var updatedAt: Date
}
```

### Migration

- Create `iosapp.pending_supervisions` table
- Add unique index on `code`
- Add index on `vendorId`
- Add foreign key: `claimedByParentId` → `parents.id` (SET NULL on delete)
- Add foreign key: `childId` → `parent.children.id` (SET NULL on delete)

### Files to Modify

- `swift/api/Sources/Api/Models/IOS/` - Add new model file
- `swift/api/Sources/Api/Database/Migrations/` - Add new migration
- `swift/api/Sources/Api/Database/Client+Live.swift` - Register model

### Notes

- No API endpoints in this task - just the model
- Code format decision: `ABC123` (6 alphanumeric) recommended for typeability
- Consider: should expired records be auto-cleaned?
