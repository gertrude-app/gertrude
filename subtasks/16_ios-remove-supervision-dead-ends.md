# Task 16: ios-remove-supervision-dead-ends

## Summary

Clean up old supervision messaging and remove dead-end screens.

## Type

⚡ Parallel | 📦 N/A (iOS unreleased)

## Dependencies

**Blocked by:** Task 11 (state machine)
**Blocks:** Nothing

## Details

Remove or update screens that contain outdated messaging about supervision requirements.

### Screens to Remove

1. **`sorryNoOtherWay`** - This dead-end screen is no longer needed
   - Was: "Sorry, Gertrude only works on minor or supervised devices"
   - Now: Route to new supervision flow instead

2. **`explainRequiresEraseAndSetup`** - Completely inaccurate now
   - Was: "This requires erasing your device..."
   - Remove entirely

### Screens to Update

1. **`explainSupervision`**
   - Old: References Apple Configurator and device erase
   - New: "We can enable supervision in about 5 minutes without erasing your data. You'll need a Mac or Windows computer."

2. **`explainNeedFriendWithMac`**
   - Update messaging to be more positive
   - Old: Felt like a barrier
   - New: Emphasize it's quick and easy, just need computer access

3. **`instructions`** (if still used)
   - Remove Apple Configurator video links
   - Update to point to new supervision tool

### Remove "Convert to Child Account" Suggestion

In the `major` flow, there's a suggestion to convert an 18+ user's Apple account to a child account. This doesn't work - Apple doesn't allow converting adult accounts to child status.

Find and remove:
- `explainFixAccountTypeEasyWay` or similar
- Any references to changing Apple account type for 18+ users

### Updated Flow

```
User is 18+
  → explainSupervision (updated messaging)
  → checkHasAccount
  → generateSetupCode
  → instructionsForParent
```

No more dead ends!

### Files to Modify

- `swift/iosapp/lib-ios/Sources/LibApp/IOSReducer+State.swift` - Remove old states
- `swift/iosapp/lib-ios/Sources/LibApp/IOSReducer.swift` - Update navigation
- `swift/iosapp/app/` - Remove old views, update text content

### Text Updates

**Old:**
> "This requires erasing your device and setting it up fresh with Apple Configurator"

**New:**
> "We can enable supervision in about 5 minutes without erasing any of your data. You'll need access to a Mac or Windows computer."

**Old:**
> "Sorry, there's no other way. Gertrude only works on devices belonging to someone under 18, or supervised devices."

**New:**
> (Remove entirely - there IS another way now!)

### Notes

- Be thorough - search for "Apple Configurator", "erase", "sorry" in codebase
- Update any related copy in explainer screens
- This is cleanup/polish work, low risk
