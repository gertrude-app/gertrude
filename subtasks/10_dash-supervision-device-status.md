# Task 10: dash-supervision-device-status

## Summary

Show supervision status and pending devices in dashboard device views.

## Type

⚡ Parallel | 📦 Safe to ship

## Dependencies

**Blocked by:** Tasks 01, 02 (for reading status fields)
**Blocks:** Nothing

## Details

Update dashboard device views to show supervision-related status information.

### Status Display

#### In Child's Device List

Show status indicators for supervised devices:
- 🟡 "Waiting for supervision" - claimed but not yet supervised
- 🟠 "Supervised, waiting for profile" - supervised but profile not installed
- 🟢 "Active" - fully set up and running
- Badge: "Supervised" vs "Minor" to distinguish device types

#### Device Detail View

Show additional supervision info:
- Supervision method (Gertrude Tool, Apple Configurator, etc.)
- Date supervised
- Profile installation date
- UDID (maybe hidden/expandable for debugging)

### Pending Devices Section

Consider adding a "Pending Devices" section that shows:
- Devices where code was claimed but supervision not complete
- Prompt to continue setup
- Link to supervision tool download

### API Changes

May need to update existing device list endpoints to include new fields:
- `isSupervised`
- `supervisionMethod`
- `supervisionStatus` (derived: pending/supervised/complete)

### Files to Modify

- `web/dash/app/routes/children/` - Child detail pages
- `web/dash/app/components/` - Device list/card components
- `swift/pairql-dashboard/` - Update device query outputs if needed
- `swift/api/Sources/Api/PairQL/Dashboard/` - Resolver updates

### Notes

- All changes are additive - existing minor devices show as before
- New fields should have sensible defaults for existing data
- Consider: real-time status updates via polling or websockets?
