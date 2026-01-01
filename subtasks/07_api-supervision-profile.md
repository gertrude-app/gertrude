# Task 07: api-supervision-profile

## Summary

Implement profile generation and serving infrastructure for supervised devices.

## Type

⚡ Parallel | 📦 Safe to ship

## Dependencies

**Blocked by:** Task 01 (PendingSupervision model)
**Blocks:** Task 14 (iOS profile install flow)

## Details

Create endpoints/routes for generating and serving the mobile configuration profile that enables content filtering on supervised devices.

### Approach Decision

**Option A: Static Profile**
- Single `.mobileconfig` file served to all devices
- Simpler, easier to debug
- Less flexible

**Option B: Dynamic Profile (Recommended)**
- Generated per-device with unique identifiers
- Can include device-specific config
- Better for tracking/verification

### Endpoint Definition

```swift
struct GetProfileUrl: Pair {
  static let auth: ClientAuth = .none  // or device token?

  struct Input: PairInput {
    let code: String
    let vendorId: UUID
  }

  struct Output: PairOutput {
    let profileUrl: URL       // e.g., gertrude.app/profile/abc123xyz
    let expiresAt: Date       // URL expiration
  }
}
```

### Profile Serving Route

```
GET /profile/{token}
Content-Type: application/x-apple-aspen-config
Content-Disposition: attachment; filename="Gertrude.mobileconfig"
```

### Profile Contents

The `.mobileconfig` XML should include:
- Content Filter payload (required for filtering to work)
- Unique identifier per device
- Gertrude branding/description
- Possibly: removal password or supervised-only removal flag

### Files to Create/Modify

- `swift/pairql-iosapp/Sources/IOSRoute/UnauthedPairs/GetProfileUrl.swift` - Route
- `swift/api/Sources/Api/PairQL/iOS/Resolvers/GetProfileUrl.swift` - Resolver
- `swift/api/Sources/Api/Routes/ProfileDownload.swift` - HTTP route for actual download
- Profile template or generation logic

### Research Needed

- Exact payload format for content filter
- How to prevent profile removal on supervised device
- Profile signing requirements (if any)
