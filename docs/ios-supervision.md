# iOS Supervision Feature Summary

## What It Is

Adults (18+) on iOS cannot use content filters without Apple "supervision" — a device
configuration that Apple intended for schools and enterprises. Previously, achieving
supervision required erasing the device via Apple Configurator. Gertrude's supervision
feature performs supervision **without erasing the device**, using a custom desktop tool
connected via USB. The process takes ~5 minutes.

## The Four Components

1. **iOS App** (`swift/iosapp`) — Generates a 6-digit setup code, detects supervision
   after reboot, guides profile installation
2. **API** (`swift/api`) — Coordinates state across all components, serves the content
   filter profile
3. **Dashboard** (`web/dash`) — Parent claims the device code, pays for subscription,
   downloads the supervision tool
4. **Supervision Tool** (`web/supervise` + separate Tauri repo) — Cross-platform desktop
   app that supervises the iOS device over USB using libimobiledevice

## Happy Path Flow

The flow crosses four apps and involves a device reboot in the middle:

**Phase 1 — iOS App (on the phone to be supervised):** User taps through onboarding,
identifies as 18+, reaches supervision flow. App calls `CreateSupervisionClaimCode` to
generate a 6-digit code (e.g. `123456`) and displays it with the short URL
`gertrude.app/s/123456`. The code is stored locally to survive app kill and reboot.

**Phase 2 — Dashboard (on parent's computer):** Parent visits the short URL, which
redirects through the API (resolving device info) to the dashboard signup/login page.
After authenticating, parent lands on the claim flow where they name the child and call
`ClaimIOSDevice`. This creates the Child record, IOSDevice, auth token, and assigns block
groups. Parent then hits a payment gate (Light plan, $10/year) and downloads the
supervision tool.

**Phase 3 — Supervision Tool (on parent's computer, phone connected via USB):** Parent
enters the 6-digit code. Tool calls `GetPendingSupervision` for device context, then waits
for USB connection. When the phone is plugged in and trusted, tool calls
`RecordDeviceUSBConnection` with the device UDID. Parent disables Find My iPhone
(required), then clicks "Supervise Now." The tool sends the supervision payload — **the
phone reboots**. After reboot, parent verifies supervision in Settings and tool calls
`MarkSupervisionVerified`.

**Phase 4 — iOS App (back on the phone):** User opens Gertrude. App detects the stored
supervision code + no active filter = needs profile. App calls
`CheckSupervisionFlowStatus` which returns `.missingProfile` with auth token. If status is
`.claimed` but supervision isn't confirmed, user can self-report via
`SelfReportSupervision`. App opens an embedded Safari view download the supervision
profile, guides user through Settings to install it. Once the content filter activates,
setup is complete.

## PairQL Endpoints by Domain

### Blocker App Domain (`pairql-blocker`)

| Endpoint                          | Auth  | Purpose                                          |
| --------------------------------- | ----- | ------------------------------------------------ |
| `CreateSupervisionClaimCode`      | None  | Phone generates 6-digit claim code               |
| `CheckSupervisionFlowStatus`      | None  | Phone polls for claim/supervision/profile status |
| `SelfReportSupervision`           | Child | User manually confirms supervision worked        |
| `MarkSupervisionProfileInstalled` | Child | Phone confirms profile installed, setup complete |

### Dashboard Domain (`pairql-dashboard`)

| Endpoint                        | Auth   | Purpose                                     |
| ------------------------------- | ------ | ------------------------------------------- |
| `ClaimIOSDevice`                | Parent | Parent claims device with code + child name |
| `GetIOSDeviceClaimData`         | Parent | Fetch device info for claim UI              |
| `GetIOSDeviceSupervisionStatus` | Parent | Poll supervision progress for dashboard     |

### Supervision Tool Domain (`SuperviseRoute`)

| Endpoint                    | Auth | Purpose                               |
| --------------------------- | ---- | ------------------------------------- |
| `GetPendingSupervision`     | None | Tool fetches device context from code |
| `RecordDeviceUSBConnection` | None | Tool reports USB connection + UDID    |
| `MarkSupervisionVerified`   | None | Tool confirms supervision succeeded   |
| `ReportSupervisionFailed`   | None | Tool reports supervision failure      |
| `LogSupervisionEvent`       | None | Tool logs telemetry events            |

### HTTP Routes (non-PairQL)

| Route                                                    | Purpose                         |
| -------------------------------------------------------- | ------------------------------- |
| `GET /ios-profile/:deviceId`                             | Serves `.mobileconfig` profile  |
| `GET /download-supervision-app/:code/platform/:platform` | Supervision tool download       |
| `GET /claim-pending-supervision/:code`                   | Short URL redirect to dashboard |

## Redirect Chain

`gertrude.app/s/123456` → `api.gertrude.app/claim-pending-supervision/123456` (API looks
up device info) →
`parents.gertrude.app/signup?claimPendingSupervision=123456&modelName=...&redirect=/supervise-device/123456/claim`

## Tiered Pricing Integration

Supervision requires a paid subscription of Light or Full (not trialing). During the work
for this meta-feature, we moved from a single macapp-centric subscription model to a
tiered model that includes supervision as a key feature of the Light plan.

## Supervision Tool

The tool has a split architecture: React UI in the monorepo (`web/supervise/src/`),
Rust/Tauri backend in a private repo.

## Planning Archive

Detailed planning documents, task specs (36 tasks), decision logs, and design analysis for
this feature are archived at
https://github.com/gertrude-app/ios-supervision-planning
