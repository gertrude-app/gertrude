# Task 19: supervise-ux-improvements

## Summary

Polish supervision tool UX: manual verification step, Find My reminder, and improved messaging.

## Type

⚡ Parallel | 📦 Safe to ship

## Dependencies

**Blocked by:** Task 17 (code entry)
**Blocks:** Nothing

## Details

Add UX improvements to the supervision tool flow based on the happy path script.

### 1. Manual Supervision Verification

Since there's no programmatic way to verify supervision succeeded, add a manual verification step:

```
┌─────────────────────────────────────────┐
│  GERTRUDE SUPERVISE                     │
├─────────────────────────────────────────┤
│                                         │
│  Verify Supervision                     │
│                                         │
│  On the iPhone, open Settings.          │
│  At the very top, you should see:       │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ "This iPhone is supervised      │    │
│  │  and managed by..."             │    │
│  └─────────────────────────────────┘    │
│                                         │
│  Do you see this message?               │
│                                         │
│  [Yes, I see it]  [No, I don't see it]  │
└─────────────────────────────────────────┘
```

**If "No":**
- Show troubleshooting steps
- Offer to retry supervision
- Link to support

### 2. Find My iPhone Reminder

On the final completion screen, remind user to re-enable Find My:

```
┌─────────────────────────────────────────┐
│  ✓ Almost Done!                         │
│                                         │
│  Now open the Gertrude app on the       │
│  phone to complete setup.               │
│                                         │
│  ─────────────────────────────────────  │
│                                         │
│  💡 Don't forget to re-enable           │
│     Find My iPhone!                     │
│                                         │
│     Settings → [Name] → Find My →       │
│     Turn on Find My iPhone              │
│                                         │
│  [Done]                                 │
└─────────────────────────────────────────┘
```

### 3. Improved Progress Messaging

During supervision:

```
┌─────────────────────────────────────────┐
│  Supervising...                         │
│                                         │
│  Luke's iPhone 14                       │
│                                         │
│  ████████████░░░░░░░░  60%              │
│                                         │
│  Preparing supervision payload...       │
│                                         │
│  ⚠️ Do not disconnect the device        │
└─────────────────────────────────────────┘
```

Progress stages:
1. "Preparing supervision payload..."
2. "Sending to device..."
3. "Waiting for device to restart..."
4. "Verifying supervision..."

### 4. Better Error Messages

Clear, actionable error messages:

| Error | Message |
|-------|---------|
| Device disconnected | "Device was disconnected. Please reconnect and try again." |
| Find My still on | "Find My iPhone is still enabled. Please disable it and try again." |
| USB error | "USB connection error. Try a different cable or port." |

### Files to Modify

- Supervision tool codebase at `~/gertie/supervise`
- Verification screen/flow
- Completion screen
- Progress view
- Error handling

### Notes

- These are polish items - can be done incrementally
- Manual verification catches failures early
- Find My reminder is important for device security
