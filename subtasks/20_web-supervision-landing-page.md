# Task 20: web-supervision-landing-page

## Summary

Create `gertrude.app/s/{code}` landing page with auth and tool download.

## Type

⚡ Parallel | 📦 Safe to ship

## Dependencies

**Blocked by:** Tasks 01, 04 (CreatePendingSupervision, ClaimSupervisionCode APIs)
**Blocks:** Nothing

## Details

Create a web landing page that parents visit from the short URL shown on the iOS device. This page handles account creation/sign-in, code claiming, and tool download.

### URL Structure

```
gertrude.app/s/{code}
gertrude.app/s/ABC123
```

### Page Flow

#### 1. Initial Load (Unauthenticated)

```
┌────────────────────────────────────────────────┐
│                                                │
│  Set Up Supervision                            │
│                                                │
│  You're about to set up Gertrude on:           │
│                                                │
│  📱 iPhone 14 · iOS 18.2                       │
│                                                │
│  ─────────────────────────────────────────     │
│                                                │
│  Sign in to continue:                          │
│                                                │
│  Email:    [____________________]              │
│  Password: [____________________]              │
│                                                │
│  [Sign In]                                     │
│                                                │
│  Don't have an account? [Create one]           │
│                                                │
└────────────────────────────────────────────────┘
```

Fetch device info from API using the code (read-only, no auth needed).

#### 2. After Authentication + Claim

```
┌────────────────────────────────────────────────┐
│                                                │
│  ✓ Device Connected                            │
│                                                │
│  Luke's iPhone 14 is ready to be supervised.   │
│                                                │
│  ─────────────────────────────────────────     │
│                                                │
│  Download Gertrude Supervise                   │
│                                                │
│  [Download for Mac]  [Download for Windows]    │
│                                                │
│  ─────────────────────────────────────────     │
│                                                │
│  After downloading:                            │
│  1. Open the app                               │
│  2. Enter code: ABC123                         │
│  3. Connect the iPhone with a USB cable        │
│  4. Follow the prompts (~5 minutes)            │
│                                                │
└────────────────────────────────────────────────┘
```

### Name Input

If creating new account or first time claiming:

```
┌────────────────────────────────────────────────┐
│                                                │
│  Who owns this device?                         │
│                                                │
│  Enter the name of the person whose            │
│  device you're setting up:                     │
│                                                │
│  [____________________]                        │
│                                                │
│  [Continue]                                    │
│                                                │
└────────────────────────────────────────────────┘
```

### API Integration

1. On page load: Fetch device info (unauthenticated, code only)
2. On sign in/sign up: Standard auth flow
3. After auth: Call `ClaimSupervisionCode` with code + name
4. Show success + download links

### Error States

- Invalid code: "This link is invalid or has expired."
- Already claimed: "This device has already been set up." (show dashboard link)
- Auth errors: Standard sign-in error handling

### Platform Detection

Auto-detect OS to highlight appropriate download:
- macOS → Emphasize Mac download
- Windows → Emphasize Windows download
- Linux/Other → Show both equally

### Files to Create

- `web/site/app/routes/s.$code.tsx` - Dynamic route (or similar for site structure)
- Components for auth forms (may reuse from existing)
- API integration for device lookup and claiming

### Notes

- This could live on the marketing site or dashboard
- Consider: redirect to dashboard after claiming?
- The code should be prominently displayed for copying to supervision tool
- Mobile-friendly design (parent might visit from their phone first)
