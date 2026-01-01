# Task 02: ios-device-supervision-fields

## Summary

Add supervision-related fields to existing `IOSDevice` model.

## Type

🔒 Blocking | 📦 Safe to ship

## Dependencies

**Blocked by:** Nothing (can run parallel with Task 01)
**Blocks:** Tasks 04, 06, 08

## Details

Extend the existing `IOSDevice` model with fields to track supervision status.

### New Fields

```swift
// Add to existing IOSDevice model
var isSupervised: Bool = false
var supervisionMethod: SupervisionMethod?
var udid: String?                      // Captured by supervision tool
var profileInstalledAt: Date?

enum SupervisionMethod: String, Codable {
  case gertrudeTool
  case appleConfigurator
  case mdm
  case unknown
}
```

### Migration

- Add `is_supervised` boolean column (default false)
- Add `supervision_method` enum/string column (nullable)
- Add `udid` string column (nullable)
- Add `profile_installed_at` timestamp column (nullable)

### Files to Modify

- `swift/api/Sources/Api/Models/IOS/IOSDevice.swift` - Add fields
- `swift/api/Sources/Api/Database/Migrations/` - Add migration

### Notes

- All new fields are nullable or have defaults - won't break existing devices
- `udid` is different from `vendorId` - supervision tool captures UDID via USB
- Existing minor devices will have `isSupervised: false`
