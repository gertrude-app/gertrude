# iOS Supervision Onboarding Recommendations

## Overview

This document outlines the recommended approach for integrating the Gertrude supervision
tool into the iOS app onboarding flow, enabling 18+ users to use Gertrude without the
previous Apple Configurator erase requirement.

## The Three Components

1. **Dashboard** (web) - Parent/supervisor's Gertrude account management
2. **iOS App** (on the phone) - Gets killed during supervision reboot
3. **Supervision Tool** (desktop Mac/Windows) - One-time 5-minute use, phone connected via
   USB

**Critical constraint:** The iOS app cannot poll during supervision because the device
reboots.

## Key Advantage

**Gertrude's supervision tool doesn't require erasing the device.** This is a major
differentiator vs TechLockdown and Apple Configurator. Emphasize this in all messaging.

---

## Flow Architecture

The flow has four distinct phases with a hard break (reboot) between phases 2 and 3:

### Phase 1: Pre-Supervision (iOS App Running)

1. User in onboarding identifies as 18+, needs supervision
2. iOS app generates 6-digit code
3. Code stored locally (UserDefaults/Keychain)
4. API call: `CreatePendingSupervision(vendorId, deviceInfo)` → returns code
5. Display code prominently with share options
6. Show instructions: "Give code to parent, re-open app after setup"
7. User closes app or hands phone to parent

Meanwhile, parent:

- Creates Gertrude account (or signs in) at dashboard
- Enters the 6-digit code to "claim" the device
- Downloads supervision tool

### Phase 2: Supervision (Desktop Tool + Phone via USB)

1. Parent runs supervision tool on their computer
2. Connects phone via USB
3. Disables Find My iPhone (guided)
4. Clicks "Supervise"
5. **Phone reboots** ← Hard break, iOS app killed
6. Tool shows "Complete!" with next steps

### Phase 3: Post-Supervision (iOS App Relaunches)

1. iOS app detects supervised status
2. Reads stored code from local storage
3. API call: `VerifySupervisionConnection(vendorId, code)`
4. API returns connection status + parent info
5. If claimed: "Connected to [Parent Name]"
6. If not claimed: Show code again, prompt parent to finish

### Phase 4: Profile Installation

1. Show: "One more step - install content filter"
2. Open Safari WebView to profile URL
3. Profile downloads automatically
4. Guide user through Settings → Profile Downloaded → Install
5. Verify profile installed
6. Done! Filter active, device connected to account

---

## State Machine Changes

### Current Supervision States

```swift
public enum Supervision: Equatable {
  case intro
  case explainSupervision
  case explainNeedFriendWithMac
  case explainRequiresEraseAndSetup  // REMOVE - no longer accurate
  case instructions
  case sorryNoOtherWay  // REPLACE
}
```

### Proposed Supervision States

```swift
public enum Supervision: Equatable {
  case intro
  case explainSupervision
  case generateSetupCode        // Show code, store locally
  case instructionsForParent    // Clear steps for parent
  case waitingToReopen          // "Re-open after supervision"

  // After reboot, detected supervised:
  case supervisionDetected      // "Great! You're supervised"
  case verifyingConnection      // Checking if code was claimed
  case connectionVerified       // "Connected to [Parent]"
  case promptInstallProfile     // "One more step..."
  case installingProfile        // Safari WebView open
  case profileInstalled         // Success!
  case setupComplete            // Done, transition to running

  // Error states
  case codeNotClaimed           // Parent didn't claim yet
  case sorryNoOtherWay          // Keep for truly unsupported cases
}
```

---

## API Endpoints Needed

### CreatePendingSupervision

iOS app creates pending device record before supervision.

```swift
struct CreatePendingSupervision: Pair {
  static let auth: ClientAuth = .none

  struct Input: PairInput {
    let vendorId: UUID
    let deviceModel: String
    let iosVersion: String
  }

  struct Output: PairOutput {
    let code: String        // "ABC-123" or "123456"
    let expiresAt: Date
  }
}
```

### ClaimSupervisionCode

Parent claims the code in dashboard.

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

### VerifySupervisionConnection

iOS app verifies connection after reboot.

```swift
struct VerifySupervisionConnection: Pair {
  static let auth: ClientAuth = .none

  struct Input: PairInput {
    let vendorId: UUID
    let code: String
  }

  struct Output: PairOutput {
    let status: Status
    let childName: String?
    let parentName: String?
    let profileUrl: URL?

    enum Status: String, Codable {
      case pending      // Code not claimed yet
      case claimed      // Parent claimed, ready for profile
      case complete     // Profile installed, all done
    }
  }
}
```

### GetSupervisionProfile

Get profile download URL.

```swift
struct GetSupervisionProfile: Pair {
  static let auth: ClientAuth = .none  // or device token?

  struct Input: PairInput {
    let vendorId: UUID
  }

  struct Output: PairOutput {
    let profileUrl: URL
  }
}
```

---

## UI Mockups

### Code Generation Screen

```
┌────────────────────────────────────────┐
│  Your setup code:                      │
│                                        │
│         ┌─────────────────┐            │
│         │   A B C - 1 2 3 │            │
│         └─────────────────┘            │
│                                        │
│  [📱 Text to Parent]  [📋 Copy]        │
│                                        │
│  Or have them scan:                    │
│         ┌─────────┐                    │
│         │ QR CODE │                    │
│         └─────────┘                    │
│  gertrude.app/supervise?code=ABC123    │
└────────────────────────────────────────┘
```

### Code Not Claimed Yet

```
┌────────────────────────────────────────┐
│  Almost there!                         │
│                                        │
│  Your device is supervised, but your   │
│  parent hasn't finished setting up     │
│  the account yet.                      │
│                                        │
│  Your code: ABC-123                    │
│                                        │
│  Ask them to enter this code at        │
│  gertrude.app/supervise                │
│                                        │
│  [Check Again]                         │
└────────────────────────────────────────┘
```

### Profile Installation

```
┌────────────────────────────────────────┐
│  One More Step                         │
│                                        │
│  To enable content filtering, you      │
│  need to install a configuration       │
│  profile.                              │
│                                        │
│  [Install Content Filter]              │
│                                        │
│  ↓ This will open a browser window     │
└────────────────────────────────────────┘
```

---

## Supervision Tool Integration (Future)

Optional account integration in the supervision tool:

```
┌─────────────────────────────────────────┐
│  GERTRUDE SUPERVISE                     │
├─────────────────────────────────────────┤
│                                         │
│  ○ Quick supervise (no account)         │
│  ● Connect to Gertrude account          │
│                                         │
│  [Sign in to Gertrude]                  │
│                                         │
│  ─────────────────────────────────────  │
│  You have 1 pending device:             │
│  • iPhone 14 Pro (code: ABC-123)        │
│    Requested 10 minutes ago             │
│                                         │
│  [Connect This Device]                  │
└─────────────────────────────────────────┘
```

---

## Friction Reduction Ideas

### 1. Easy Code Sharing

- Text/iMessage share sheet with pre-filled message
- QR code that opens `gertrude.app/supervise?code=ABC123`
- Copy button for manual sharing

### 2. Smart Landing Page

`gertrude.app/supervise` should:

- Auto-fill code from URL parameter
- Explain the process clearly
- Link to account creation/login
- Link to supervision tool download
- Show platform-specific instructions (Mac vs Windows)

### 3. Post-Supervision Prompt on Tool

After supervision completes, the tool should show clear next steps:

1. Wait for phone to reboot
2. Open Gertrude app on the phone
3. Follow prompts to install profile

### 4. Real-time Dashboard Status

Dashboard shows pending devices with status:

- "Waiting for supervision"
- "Supervised, waiting for profile"
- "Complete"

---

## MVP Implementation Path

### Step 1: Database & API Foundation

- Add `PendingSupervision` model (or repurpose existing)
- `CreatePendingSupervision` endpoint
- `ClaimSupervisionCode` endpoint
- `VerifySupervisionConnection` endpoint

### Step 2: iOS App Pre-Supervision Flow

- Replace dead-end screens
- Code generation and display
- Local storage of code
- Share sheet integration

### Step 3: iOS App Post-Supervision Flow

- Supervision detection (may already exist)
- Code verification flow
- "Not claimed yet" handling

### Step 4: Dashboard Integration

- "Add supervised device" flow
- Enter code UI
- Pending devices list

### Step 5: Profile Installation

- Profile serving endpoint
- Safari WebView integration in iOS app
- Installation guidance screens

### Step 6: Landing Page

- `gertrude.app/supervise` page
- Clear instructions
- Tool download links

### Step 7: Supervision Tool Integration (Optional)

- Account login in tool
- Pending device detection
- Auto-association on supervision

---

## Open Questions

1. **Profile removal prevention:** How does account connection prevent profile removal?
   MDM approval flow?

2. **Profile generation:** Static profile or dynamically generated per device?

3. **Code format:** `ABC-123` (readable) vs `123456` (typeable)?

4. **Code expiration:** 24 hours? 7 days? Never?

5. **Multiple pending devices:** Can one parent have multiple pending codes?

6. **Existing connection feature:** How does current iOS device connection fit? What needs
   to change?

---

## Messaging Updates

### Old (Inaccurate)

> "This requires erasing your device and setting it up fresh with Apple Configurator"

### New

> "We can enable supervision in about 5 minutes without erasing your data. You'll need a
> Mac or Windows computer and someone to help supervise your device."

---

## Related Files

- State: `swift/iosapp/lib-ios/Sources/LibApp/IOSReducer+State.swift`
- Reducer: `swift/iosapp/lib-ios/Sources/LibApp/IOSReducer.swift`
- Views: `swift/iosapp/app/App.swift`
- Feature flag:
  `swift/pairql-iosapp/Sources/IOSRoute/UnauthedPairs/ConnectAccountFeatureFlag.swift`
- Supervision tool: `~/gertie/supervise`

---

## Existing iOS Connection Infrastructure Analysis

This section analyzes the existing (unreleased) iOS device connection feature and how it
relates to the supervision onboarding flow.

### Current Data Model

```
Parent (account holder)
  └─ Child (e.g., "Jimmy")          ← Must exist BEFORE code is generated
       └─ IOSApp.Device             ← Created when device enters code
            ├─ IOSApp.Token         ← Auth for API calls (X-DeviceToken header)
            ├─ IOSApp.DeviceBlockGroup (junction table)
            │    └─ IOSApp.BlockGroup
            ├─ IOSApp.BlockRule     ← Filtering rules
            ├─ IOSApp.WebPolicyDomain ← Whitelist/blacklist
            └─ IOSApp.SuspendFilterRequest ← Filter pause requests
```

### Current Connection Flow

```
Dashboard                              iOS Device
─────────                              ──────────
1. Parent has Child profile
2. Parent clicks "Connect Device"
3. CreatePendingAppConnection ────────→ Ephemeral stores: code → childId
4. Shows 6-digit code (expires 2 days)
                                       5. User enters code in app
                                       6. ConnectDevice(code, vendorId, ...)
7. Ephemeral lookup: code → childId
8. Create IOSDevice record
9. Create IOSApp.Token
10. Assign ALL BlockGroups to device   ←── Returns: token, deviceId, childName
```

### Key Database Tables

| Table                            | Schema                      | Purpose                         |
| -------------------------------- | --------------------------- | ------------------------------- |
| `child.ios_devices`              | IOSApp.Device               | Device records                  |
| `child.iosapp_tokens`            | IOSApp.Token                | Auth tokens (unique on `value`) |
| `iosapp.block_rules`             | IOSApp.BlockRule            | Filtering rules                 |
| `iosapp.block_groups`            | IOSApp.BlockGroup           | Rule categories                 |
| `iosapp.device_block_groups`     | IOSApp.DeviceBlockGroup     | Device↔Group junction           |
| `iosapp.suspend_filter_requests` | IOSApp.SuspendFilterRequest | Filter pause requests           |
| `iosapp.web_policy_domains`      | IOSApp.WebPolicyDomain      | Whitelist/blacklist             |

### Foreign Key Constraints

```sql
ios_devices.child_id → parent.children.id (CASCADE DELETE)
iosapp_tokens.device_id → child.ios_devices.id (CASCADE DELETE)
suspend_filter_requests.device_id → child.ios_devices.id (CASCADE DELETE)
block_rules.device_id → child.ios_devices.id (CASCADE DELETE)
```

**No foreign keys need to be removed.** The schema is well-designed and CASCADE deletes
handle cleanup properly.

### Key Files

| File                                                                     | Purpose             |
| ------------------------------------------------------------------------ | ------------------- |
| `swift/api/Sources/Api/Models/IOS/IOSDevice.swift`                       | Device model        |
| `swift/api/Sources/Api/Models/IOS/IOSAppToken.swift`                     | Token model         |
| `swift/api/Sources/Api/PairQL/iOS/Resolvers/ConnectDevice.swift`         | Connection resolver |
| `swift/api/Sources/Api/Environment/Ephemeral.swift`                      | Code management     |
| `swift/api/Sources/Api/Database/Migrations/039_IOSConnection.swift`      | Schema              |
| `swift/pairql-iosapp/Sources/IOSRoute/UnauthedPairs/ConnectDevice.swift` | Route definition    |

### Feature Flag Status

```swift
// swift/api/Sources/Api/PairQL/iOS/Resolvers/ConnectAccountFeatureFlag.swift
extension ConnectAccountFeatureFlag: NoInputResolver {
  static func resolve(in ctx: Context) async throws -> Output {
    .init(isEnabled: false)  // ← CURRENTLY DISABLED
  }
}
```

### What Can Be Reused (Already Done ✓)

| Component                     | Status           | Notes                                       |
| ----------------------------- | ---------------- | ------------------------------------------- |
| IOSApp.Device model           | ✅ Ready         | Minor additions needed (supervision fields) |
| IOSApp.Token model            | ✅ Complete      | Auth system works perfectly                 |
| Block rules/groups            | ✅ Complete      | Full filtering infrastructure               |
| Parent→Child→Device hierarchy | ✅ Sound         | Works for supervision                       |
| Dashboard device management   | ✅ Complete      | IOSDevices, GetIOSDevice, UpdateIOSDevice   |
| Ephemeral code pattern        | ✅ Concept ready | Need parallel implementation                |
| X-DeviceToken auth            | ✅ Complete      | No changes needed                           |

### What Needs to Change

#### 1. Code Generation Direction

| Aspect        | Current          | Supervision          |
| ------------- | ---------------- | -------------------- |
| Who initiates | Parent           | Device               |
| Code maps to  | `code → childId` | `code → deviceInfo`  |
| Child timing  | Must exist first | Created when claimed |

**Recommendation:** Don't merge flows. Keep both:

- `CreatePendingAppConnection` - for minors (parent initiates)
- `CreatePendingSupervision` - for 18+ (device initiates)

#### 2. New PendingSupervision Model

```swift
struct PendingSupervision: Model {
  var id: Id
  var code: String                     // "ABC-123"
  var vendorId: UUID
  var deviceModel: String
  var iosVersion: String
  var claimedByParentId: Parent.Id?    // Set when parent claims
  var childId: Child.Id?               // Set when child created
  var supervisionCompletedAt: Date?    // Set after supervision
  var profileInstalledAt: Date?        // Set after profile
  var expiresAt: Date
  var createdAt: Date
  var updatedAt: Date
}
```

#### 3. IOSDevice Model Additions

```swift
// Add to existing IOSDevice model
var isSupervised: Bool = false
var supervisionMethod: SupervisionMethod?
var profileInstalledAt: Date?

enum SupervisionMethod: String, Codable {
  case gertrudeTool
  case appleConfigurator
  case mdm
  case unknown
}
```

#### 4. New API Endpoints

| Endpoint                   | Auth         | Direction       | Purpose                    |
| -------------------------- | ------------ | --------------- | -------------------------- |
| `CreatePendingSupervision` | None         | Device → API    | Device generates code      |
| `ClaimSupervisionCode`     | Parent       | Dashboard → API | Parent claims device       |
| `CheckSupervisionStatus`   | None         | Device → API    | Device checks claim status |
| `MarkSupervisionComplete`  | Parent/Tool  | Tool → API      | After supervision done     |
| `GetProfileUrl`            | Device token | Device → API    | Get profile download URL   |
| `MarkProfileInstalled`     | Device token | Device → API    | Confirm profile installed  |

### Roadblocks & Challenges

#### 1. The "Child" Terminology

The system uses "Child" everywhere. For adult supervision (spouse, accountability
partner), this is awkward.

**Options:**

- A) Rename to "SupervisedUser" - **Major refactor, breaks things**
- B) Keep "Child" in code, display "Supervised Person" in UI - **Recommended**
- C) Add `userType` field to Child - **Adds complexity**

**Recommendation:** Option B. Internal code stays "Child", UI shows appropriate labels.

#### 2. Child Creation Timing

Current: Child must exist before code generation. Supervision: Child created when parent
claims code.

`ClaimSupervisionCode` needs to:

1. Validate code
2. Create new Child (with name from parent)
3. Create IOSDevice linked to Child
4. Create Token
5. Assign BlockGroups
6. Mark pending supervision as claimed

Larger transaction but straightforward.

#### 3. Profile Serving Infrastructure

Need to build:

- Profile generation (static or per-device?)
- Unique URLs per device/session
- Profile download endpoint
- Installation verification

#### 4. Supervision Tool Integration (Optional)

For tighter integration:

- Tool authenticates with Gertrude account
- Tool updates API when supervision completes
- Tool shows pending devices for logged-in parent

Optional for MVP but improves UX.

### Summary Table

| Category                           | Status                     |
| ---------------------------------- | -------------------------- |
| Device model                       | ✅ Ready (minor additions) |
| Token auth                         | ✅ Complete                |
| Block rules                        | ✅ Complete                |
| Parent→Child→Device hierarchy      | ✅ Works                   |
| Code generation (parent-initiated) | ✅ Keep for minors         |
| Code generation (device-initiated) | ❌ New                     |
| Pending supervision tracking       | ❌ New model               |
| Supervision status on device       | ❌ New fields              |
| Profile delivery                   | ❌ New feature             |
| Dashboard claim flow               | ❌ New UI                  |

### Conclusion

The existing infrastructure is solid. The supervision feature is an **addition**, not a
replacement. Main work:

1. New `PendingSupervision` model
2. Device-initiated code flow (parallel to existing)
3. Profile delivery system
4. iOS app screens for new flow
5. Dashboard "claim code" UI
