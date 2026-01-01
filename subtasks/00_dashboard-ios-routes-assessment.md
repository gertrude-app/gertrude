# Assessment: Existing Dashboard iOS Device Routes

## Current State

### Hidden Routes

Two routes exist but are not linked in navigation:

- `/ios-devices` - Lists all iOS devices for parent account
- `/ios-devices/:deviceId` - Full management page for single device

### Features in IOSDevice.tsx

The device management page (`/ios-devices/:deviceId`) has three feature sections:

1. **Block Groups** - Toggle which block groups apply to device
   - Simple, non-controversial, should be exposed to all users

2. **Web Content Filter Policy** - 5-tier filtering system
   - `allowAll` - Unrestricted
   - `blockAdult` - Limit adult websites
   - `blockAdultAnd` - Blocklist plus limit adult websites
   - `blockAllExcept` - Only approved websites (shows allowlist)
   - `blockAll` - Block everything
   - More advanced, may want to gate this initially

3. **Block Rules** - Custom app and address blocking
   - Complex rule builder with conditions
   - Most advanced feature, definitely gate this initially

### Current Usage

Only your daughter's device uses this. The routes are functional but hidden (no navigation links).

---

## Options

### Option A: Admin Flag Approach (Recommended)

Add a flag to gate advanced features by account.

**Implementation:**
1. Add `showAdvancedIOSFeatures: Bool` to Parent model (or use existing admin check)
2. API returns this flag with parent data
3. Dashboard conditionally renders Web Policy and Block Rules sections
4. Block Groups always visible

**Pros:**
- Clean separation
- Your account keeps full functionality
- Easy to enable for other accounts later
- No changes to routes or data model

**Cons:**
- Need to manage the flag (but it's just your account for now)

**Code change (IOSDevice.tsx):**
```tsx
// Fetch parent settings or use context
const showAdvanced = parentData.showAdvancedIOSFeatures;

return (
  <div>
    {/* Block Groups - always shown */}
    <BlockGroupsSection ... />

    {/* Web Policy - gated */}
    {showAdvanced && <WebPolicySection ... />}

    {/* Block Rules - gated */}
    {showAdvanced && <BlockRulesSection ... />}
  </div>
);
```

---

### Option B: Separate Routes Entirely

Keep `/ios-devices/*` for your account only, create new simpler routes for supervised devices.

**Implementation:**
1. Gate `/ios-devices` route entirely behind admin check
2. New supervised devices appear on child page instead
3. Child page shows simplified device card with Block Groups only

**Pros:**
- Complete separation
- New users never see advanced features

**Cons:**
- Two different UIs for iOS devices
- More code to maintain
- Harder to promote users to advanced features later

---

### Option C: Device Type Feature Gating

Show features based on device type (minor vs supervised adult).

**Implementation:**
1. Add `deviceType: minor | supervised` to IOSDevice
2. Advanced features only for minor devices (your daughter)
3. Supervised devices get simpler UI

**Pros:**
- Logical separation by use case

**Cons:**
- Doesn't match your goal (your daughter's device would lose features if marked supervised)
- May want advanced features for supervised devices later

---

## Recommendation

**Go with Option A (Admin Flag)** with a phased approach:

### Phase 1: Immediate (no code changes)
- Keep routes hidden and working as-is
- Your daughter's device continues working
- New supervised devices won't have dashboard management yet anyway

### Phase 2: When adding supervised device UI (Task 10)
- Add `showAdvancedIOSFeatures` flag to Parent (default: false, yours: true)
- Gate Web Policy and Block Rules sections
- Block Groups visible to all
- New `/ios-devices` link in nav only if parent has any iOS devices

### Phase 3: Future
- Consider exposing Web Policy to all (simple dropdown)
- Keep Block Rules as advanced/admin feature
- Or: enable per-device based on parent request

---

## Data Model Note

Looking at the existing iOS device data, here's what's safe to expose vs gate:

| Feature | Expose Now | Gate Initially | Notes |
|---------|-----------|----------------|-------|
| Device list | ✅ | | Basic info |
| Block Groups | ✅ | | Simple toggles |
| Web Policy | | ✅ | Could expose later |
| Web Policy Domains | | ✅ | Depends on policy |
| Block Rules | | ✅ | Complex, keep gated |

---

## Files That Would Change

For Option A implementation:

1. **API:**
   - Add flag to Parent model or admin check
   - Return flag in relevant API responses

2. **Dashboard:**
   - `web/dash/app/src/components/routes/IOSDevice.tsx` - Conditional rendering
   - Possibly add nav link for iOS devices (gated)

3. **No changes needed:**
   - `/ios-devices` route itself
   - IOSDevices.tsx (list page)
   - Block rules components
   - API endpoints for iOS device management

---

## Integration with Supervision Tasks

This assessment relates to:
- **Task 10 (dash-supervision-device-status)** - Where supervised devices appear in dashboard
- **Task 09 (dash-claim-supervised-device)** - Code claiming creates the device record

When implementing Task 10, incorporate the admin flag gating for advanced features.
