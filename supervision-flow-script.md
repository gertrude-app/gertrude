# Supervision Onboarding Flow Script

## Scope & Constraints

**User personas (in scope):**

- Parent supervising adult child (18+)
- Spouse supervising spouse
- Accountability partner relationships

**Explicitly out of scope for now:**

- Self-management (someone locking down their own phone)

**Key assumption:** The person who owns the Gertrude account (supervisor) is different from
the person whose phone is being supervised.

---

## Scenario

**Characters:**

- **Ben** (dad): Has his own iPhone, has a MacBook, will own the Gertrude account
- **Luke** (19-year-old son): Has an iPhone that needs Gertrude installed + supervised

**Setup:** Ben is setting up Gertrude on Luke's iPhone. Luke is nearby but Ben is driving
the process.

**Alternative scenario (not scripted yet):** Luke initiates the setup on his own phone,
generates a code, and hands off to Ben who is in another room or another location. This
would test the "device initiates, parent claims" flow more explicitly.

---

## The Script

### Steps 1-6: Onboarding (Condensed)

_Setting: Living room. Ben has Luke's iPhone. Luke is nearby._

**BEN:** _(downloads Gertrude on Luke's iPhone, opens it)_

**BEN:** _(taps through: Get Started → Next → "Yes, this is the device to protect" → "No,
18 or older" → "I'm helping someone else")_

---

### Step 7: Supervision Explanation

_[Exact language TBD - explains that 18+ devices need "supervision" to enable content
filtering, takes ~5 minutes, requires a Mac or Windows computer, doesn't erase data]_

**LUKE'S iPHONE SCREEN:**

> ...supervision explanation...
>
> **[Next]**

**BEN:** _(taps Next)_

---

### Step 8a: Account Check

**LUKE'S iPHONE SCREEN:**

> Since this device belongs to someone 18 or older, you'll need a Gertrude account to
> manage it.
>
> Do you already have a Gertrude account?
>
> **[Yes, I have an account]** > **[No, I need to create one]**

**BEN:** _(taps "Yes, I have an account")_

---

### Step 8b: Handoff Screen

_[API call happens here: CreatePendingSupervision(vendorId, deviceInfo) → returns token +
short code]_

**LUKE'S iPHONE SCREEN:**

> # Continue on Your Computer
>
> The next steps require a Mac or Windows computer. You'll download a small app that takes
> about 5 minutes to run.
>
> Go to:
>
> ## **gertrude.app/s/ABC123**
>
> ---
>
> Or email yourself the link:
>
> `[ben@email.com________]` **[Send]**
>
> ---
>
> _Don't close this app — you'll need to open it again after the computer steps are done._

**BEN:** Okay, I need to go to my laptop. _(reads the short URL, sets Luke's iPhone down
on the coffee table, walks to his MacBook)_

---

### Step 9: Ben at His Mac

_Setting: Ben's home office, MacBook open_

**BEN:** What was that link... gertrude.app/s/ABC123 _(types it into Safari)_

---

### Step 10: Landing Page (Ben's Mac)

**BEN'S MACBOOK (Safari) SCREEN:**

> # Set Up Supervision
>
> You're about to set up **Gertrude** on:
>
> **iPhone 14** · iOS 18.2
>
> ---
>
> Sign in to continue:
>
> Email: `[____________]` Password: `[____________]`
>
> **[Sign In]**
>
> Don't have an account? **Create one**

**BEN:** _(taps "Create one", enters email/password, creates account)_

---

### Step 11: Name the Person

**BEN'S MACBOOK (Safari) SCREEN:**

> # Who owns this device?
>
> Enter the name of the person whose device you're setting up:
>
> `[____________]`
>
> **[Continue]**

**BEN:** _(types "Luke", taps Continue)_

---

### Step 12: Download Supervision Tool

**BEN'S MACBOOK (Safari) SCREEN:**

> # Download Gertrude Supervise
>
> **Luke's iPhone** is ready to be supervised.
>
> **[Download for Mac]** **[Download for Windows]**
>
> After downloading:
>
> 1. Open the app
> 2. Connect Luke's iPhone with a USB cable
> 3. Follow the prompts (~5 minutes)

**BEN:** _(clicks Download for Mac, waits for download, opens the .dmg, drags to
Applications, launches app)_

---

### Step 13: Supervision Tool Opens

**SUPERVISION TOOL SCREEN:**

> # Gertrude Supervise
>
> Enter your setup code:
>
> `[______]`
>
> **[Continue]**
>
> _(This is the code from gertrude.app)_

**BEN:** Oh right, that code from earlier... ABC123. _(types ABC123, clicks Continue)_

---

### Step 14: Tool Fetches Context

_[Tool calls API: GetPendingSupervision("ABC123") → returns { childName: "Luke",
deviceModel: "iPhone 14", iosVersion: "18.2" }]_

**SUPERVISION TOOL SCREEN:**

> # Set Up Luke's iPhone
>
> Connect **Luke's iPhone 14** to this computer with a USB cable.
>
> `⟳ Waiting for device...`

**BEN:** _(calls out)_ Luke! Bring your phone and a lightning cable!

---

### Step 15: Device Connected

**LUKE:** _(walks in, plugs his iPhone into Ben's MacBook)_

**LUKE'S iPHONE SCREEN:**

> Trust This Computer?
>
> **[Trust]** **[Don't Trust]**

**LUKE:** _(taps Trust, enters his passcode)_

---

### Step 16: Tool Detects Device

_[Tool detects USB device, retrieves UDID: `00008030-001A2D3E4F5G6H7I`]_

**SUPERVISION TOOL SCREEN:**

> # Luke's iPhone
>
> **iPhone 14** · iOS 18.2
>
> Ready to supervise.
>
> **[Next]**

**BEN:** _(clicks Next)_

---

### Step 17: Disable Find My

**SUPERVISION TOOL SCREEN:**

> # Turn Off Find My iPhone
>
> Before we can supervise, Find My iPhone must be temporarily disabled.
>
> On the iPhone:
>
> 1. Open **Settings**
> 2. Tap **[Luke's name]** at the top
> 3. Tap **Find My**
> 4. Turn off **Find My iPhone**
>
> **[I've turned it off]**

**BEN:** Luke, I need you to turn off Find My on your phone.

**LUKE:** _(picks up his phone, navigates to Settings → [Luke] → Find My → toggles off
Find My iPhone, enters his Apple ID password)_

**LUKE:** Okay, it's off.

**BEN:** _(clicks "I've turned it off")_

---

### Step 18: Ready to Supervise

**SUPERVISION TOOL SCREEN:**

> # Ready to Supervise
>
> This will take about 2-3 minutes. The phone will restart when complete.
>
> **Do not disconnect the phone until you see the success screen.**
>
> **[Supervise Now]**

**BEN:** _(clicks "Supervise Now")_

---

### Step 19: Supervision In Progress

**SUPERVISION TOOL SCREEN:**

> # Supervising...
>
> **Luke's iPhone 14**
>
> `████████████░░░░░░░░` 60%
>
> Do not disconnect the device.

_[~2 minutes pass, tool is sending the supervision payload to the device]_

---

### Step 20: Supervision Complete, Phone Rebooting

_[Tool calls API: MarkSupervisionComplete(code: "ABC123", udid:
"00008030-001A2D3E4F5G6H7I")]_

**LUKE'S iPHONE:** _(screen goes dark, Apple logo appears, phone is rebooting)_

**SUPERVISION TOOL SCREEN:**

> # Phone Restarting...
>
> Wait for Luke's iPhone to finish restarting, then verify supervision worked.
>
> `⟳ Waiting for restart to complete...`

_[~45 seconds pass, phone finishes rebooting]_

---

### Step 21: Verify Supervision (Manual Check)

_[Note: There's no iOS API to check supervision status programmatically, so we have the
user verify manually]_

**SUPERVISION TOOL SCREEN:**

> # Verify Supervision
>
> On Luke's iPhone, open **Settings**. At the very top, you should see:
>
> _"This iPhone is supervised and managed by..."_
>
> Do you see this message?
>
> **[Yes, I see it]** **[No, I don't see it]**

**LUKE:** _(unlocks phone, opens Settings)_

**LUKE'S iPHONE (Settings app):**

> This iPhone is supervised and managed by Gertrude
>
> [Luke's Apple ID] ...

**LUKE:** Yeah, it says supervised right at the top.

**BEN:** _(clicks "Yes, I see it")_

---

### Step 22: Prompt to Relaunch Gertrude

**SUPERVISION TOOL SCREEN:**

> # Almost Done!
>
> Now open the **Gertrude** app on Luke's iPhone to complete setup.
>
> ---
>
> **Don't forget:** You can re-enable **Find My iPhone** now.
>
> **[Done]**

**BEN:** Luke, open the Gertrude app. Oh, and you should turn Find My back on.

**LUKE:** _(goes to Settings → [Luke] → Find My → turns Find My iPhone back on)_

---

### Step 23: Luke Opens Gertrude App

**LUKE:** _(taps Gertrude app icon)_

_[App launches. Detection logic runs:]_

- _Pending supervision token in local storage? → Yes (ABC123)_
- _Filter currently running? → No_
- _Conclusion: Device is supervised, needs profile installation_

---

### Step 24: Profile Installation Prompt

**LUKE'S iPHONE (Gertrude App) SCREEN:**

> # One More Step
>
> To enable content filtering, you need to install a configuration profile.
>
> **[Next]**

**LUKE:** _(taps Next)_

---

### Step 25: Help Screen - Download Prompt

**LUKE'S iPHONE (Gertrude App) SCREEN:**

> # Allow the Download
>
> When the browser opens, you'll see a prompt asking to download a profile.
>
> ┌─────────────────────────┐ │ [Graphic showing Safari │ > │ download prompt with │ > │
> purple arrow pointing │ > │ to "Allow" button] │ └─────────────────────────┘
>
> Tap **Allow** to continue.
>
> **[Got it]**

**LUKE:** _(taps "Got it")_

_[Safari WebView opens to `gertrude.app/profile/...`, download prompt appears]_

**LUKE:** _(taps Allow in Safari)_

_[Profile downloads, iOS shows "Profile Downloaded" notification]_

---

### Step 26: Help Screen - Install in Settings

_[Safari WebView closes, returns to Gertrude app]_

**LUKE'S iPHONE (Gertrude App) SCREEN:**

> # Install the Profile
>
> Now open Settings and install the downloaded profile:
>
> ┌─────────────────────────┐ │ [Graphic showing │ > │ Settings app with │ > │ "Profile
> Downloaded" │ > │ banner highlighted] │ └─────────────────────────┘
>
> 1. Tap **Profile Downloaded** near the top
> 2. Tap **Install**
> 3. Enter your passcode
>
> **[Open Settings]**

**LUKE:** _(taps "Open Settings")_

---

### Step 27: Install Profile in Settings

**LUKE'S iPHONE (Settings app):**

> Profile Downloaded
>
> Gertrude Content Filter

**LUKE:** _(taps "Profile Downloaded")_

**LUKE'S iPHONE (Settings app):**

> Install Profile
>
> Gertrude Content Filter
>
> This profile will configure your iPhone:
>
> - Content Filter
>
> **[Install]**

**LUKE:** _(taps Install, enters his passcode)_

**LUKE'S iPHONE (Settings app):**

> Profile Installed

---

### Step 28: Return to Gertrude App - Completion

**LUKE:** _(switches back to Gertrude app)_

_[App detects filter is now running]_

_[App calls API: MarkSetupComplete(code: "ABC123", vendorId: "...")]_

**LUKE'S iPHONE (Gertrude App) SCREEN:**

> # You're All Set!
>
> Gertrude is now protecting this device.
>
> Your parent can manage settings from their Gertrude dashboard.
>
> **[Done]**

**LUKE:** _(taps Done)_

_[App transitions to normal running state]_

---

## Script Complete

**Total steps:** 28

**Approximate time:** 10-15 minutes

**Components involved:**

- iOS app (Luke's iPhone)
- Web landing page (gertrude.app/s/...)
- Supervision tool (Ben's Mac)
- API (coordinating state across all components)

---

## Design Decisions Captured

### Rejected: QR Code Handoff

Initially considered showing a QR code that Ben could scan with his personal iPhone.
Rejected because:

- Ben needs his Mac/PC anyway for the supervision tool
- QR → phone creates an extra unnecessary hop
- Short typeable URL is cleaner

### Handoff Mechanism

- iOS app calls `CreatePendingSupervision` API to generate a short code
- Short URL format: `gertrude.app/s/ABC123`
- Code stored locally on Luke's phone for post-reboot verification
- Email option available for deferred setup

### Landing Page Approach

The short URL goes to a contextual landing page that:

- Shows which device is being set up (iPhone 14, iOS 18.2)
- Has sign-in/sign-up form right on the page
- Feels purposeful, not redirect-y

### Account Check

Before showing the handoff screen, we ask if they already have a Gertrude account. This
lets us potentially optimize the flow differently for existing vs. new users.

### Supervision Tool API Integration

The supervision tool requires API connection (no offline mode). On launch, it asks for the
setup code (ABC123). Benefits:

- Tool shows personalized context: "Set Up Luke's iPhone"
- Tool can report completion status to API
- Tool captures UDID for later verification (useful for unsupervision flow)
- Creates coordinated experience across all three components

### UDID Capture

The supervision tool captures the device UDID when connected via USB. This is sent to the
API and stored with the device record. Useful for:

- Verifying it's the same device during unsupervision
- Audit trail
- Future device identification needs

Note: The iOS app uses vendorId (Apple's identifier), while the supervision tool uses
UDID. These are different identifiers for the same device.

### Token Persistence (Not Ephemeral)

The 6-digit setup code (ABC123) must persist in the database (on IOSDevice or
PendingSupervision model), not just ephemeral in-memory storage. The code needs to
survive:

- App being killed during supervision
- Phone rebooting
- Delays between steps (user takes a break, continues next day)

The code can be released/cleared once the entire flow completes:

- Device supervised ✓
- Profile installed ✓
- Filter running in supervised mode ✓

### Manual Supervision Verification

Since there's no iOS API to programmatically check supervision status, the supervision
tool includes a manual verification step:

- Tool prompts: "Check Settings - do you see 'This iPhone is supervised'?"
- User confirms: "Yes, I see it" or "No, I don't see it"
- Catches supervision failures before proceeding to profile installation

### iOS App State Detection

When the Gertrude iOS app launches, it determines state by checking:

1. Is there a pending supervision token in local storage?
2. Is the content filter currently running?

| Token? | Filter? | Conclusion                             |
| ------ | ------- | -------------------------------------- |
| Yes    | No      | Supervised, needs profile installation |
| Yes    | Yes     | Fully set up, go to running state      |
| No     | No      | Fresh install, start onboarding        |
| No     | Yes     | Connected without supervision (minor)  |

### Pre-Download Help Screens

Before opening the Safari WebView to download the profile, show help screens that prepare
the user for what they'll see:

1. "Allow the Download" - Shows graphic of Safari download prompt with arrow pointing to
   "Allow" button
2. "Install the Profile" - Shows graphic of Settings with "Profile Downloaded" banner

This matches the existing pattern in the app (e.g., `dontGetTrickedPreAuth` screens) and
reduces confusion during the multi-step profile installation.

### Profile Installation Ownership

For MVP, the iOS app owns the entire profile installation flow. The supervision tool's job
is done after showing "Open the Gertrude app." The tool can optionally poll for success
confirmation, but the actual guidance happens in the iOS app.

### Find My iPhone Reminder

The supervision tool reminds the user to re-enable Find My iPhone on the final screen.
This was disabled for supervision and should be turned back on for device security.

### Dynamic Profile Generation

Profiles are generated dynamically per-device/session rather than serving a static file.
This allows device-specific configuration if needed. The profile URL includes a token that
identifies the pending supervision.

### Profile Removal Prevention

Punted for now. Since the device is supervised, it should be possible to prevent profile
removal without approval. Implementation details TBD.

### API Completion Call

When the iOS app detects the filter is running after profile installation, it calls
`MarkSetupComplete(code, vendorId)` to notify the API. This allows:

- Dashboard to show accurate device status
- Supervision tool to optionally poll and show "Success!" confirmation
- Cleanup of pending supervision record

---

## Open Questions

1. **Short code format:** `ABC123` (6 alphanumeric) vs `ABC-123` (with hyphen for
   readability)?

2. **Code expiration:** How long should the short code be valid? 7 days?

3. **Email send:** Should the email come from Gertrude servers, or open the native mail
   client with pre-filled content?

4. **What if Ben closes the browser before downloading?** Recovery flow?

5. **UDID + vendorId:** Should we store both identifiers? How do we correlate them?

---

## Current Flow Issues to Fix

### "Convert to Child Account" Suggestion

The current iOS onboarding flow suggests converting an 18+ user to a child account in Apple
Family as the "easy way." This doesn't work for adults - Apple doesn't allow converting
accounts to child status for users 18+. The new flow should skip this suggestion entirely
when we know the user is 18+.

### Dead End at `sorryNoOtherWay`

The current supervision flow ends at a dead end (`sorryNoOtherWay`) that says there's no
option. This needs to be replaced with the new supervision tool flow.

---

## MVP vs Nice-to-Have

### MVP (Must Have)

- iOS app: Code generation screen, handoff instructions, post-supervision detection, profile
  installation flow
- API: `CreatePendingSupervision`, `ClaimSupervisionCode`, `VerifySupervisionConnection`,
  `MarkSetupComplete` endpoints
- Web: Landing page at `gertrude.app/s/{code}` with sign-in/sign-up and tool download
- Supervision tool: Code entry, API integration, manual verification step, Find My reminder
- Profile: Dynamic profile generation and serving

### Nice-to-Have (Post-MVP)

- Dashboard real-time status updates during setup
- Supervision tool polling for "Success!" confirmation after profile install
- Email link option (could use native mail client for MVP)
- Profile removal prevention / approval flow
- Alternative scenario scripting (Luke initiates)

---

## Scenarios to Test Later

1. **Luke initiates alone** - Luke starts setup, generates code, texts it to Ben, Ben claims
   later
2. **Ben already has account** - Existing Gertrude user adding a supervised device
3. **Multiple pending devices** - Ben setting up two kids' phones at once
4. **Interrupted flow** - User closes app mid-setup, returns later
5. **Supervision fails** - User taps "No, I don't see it" on verification screen
6. **Profile install fails** - User cancels profile install, needs to retry
