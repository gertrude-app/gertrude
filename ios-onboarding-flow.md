# iOS Onboarding Flow - Structured Reference

## Overview

This document describes the complete iOS app onboarding flow for Gertrude parental
controls. Use this as a reference for understanding all paths, states, and decision
points.

**Architecture:** TCA (The Composable Architecture) with SwiftUI **Key Files:**

- State: `swift/iosapp/lib-ios/Sources/LibApp/IOSReducer+State.swift`
- Reducer: `swift/iosapp/lib-ios/Sources/LibApp/IOSReducer.swift`
- Views: `swift/iosapp/app/App.swift`

---

## State Machine Structure

```
Screen (top-level)
├── launching
├── onboarding(Onboarding)
│   ├── happyPath(HappyPath)
│   ├── appleFamily(AppleFamily)
│   ├── major(Major)
│   ├── supervision(Supervision)
│   ├── authFail(AuthFail)
│   ├── installFail(InstallFail)
│   ├── onParentDeviceFail
│   └── childIsOnboardingFail
├── supervisionSuccessFirstLaunch
└── running(RunningState)
    ├── notConnected
    └── connected
```

---

## FLOW 1: Happy Path (Standard Child Device)

**Entry:** App launch on new device **Exit:** Running state (connected or not connected)
**Screens:** 19

### Screen Sequence

| #   | Screen                              | Description                      | Buttons                                                         | Next                                                                                                                         |
| --- | ----------------------------------- | -------------------------------- | --------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| 1   | `hiThere`                           | Welcome screen                   | Primary: "Get Started"                                          | → timeExpectation                                                                                                            |
| 2   | `timeExpectation`                   | "5-7 minutes"                    | Primary: "Next"                                                 | → confirmChildsDevice                                                                                                        |
| 3   | `confirmChildsDevice`               | "Is this the device to protect?" | Primary: "Yes" / Secondary: "No"                                | Yes→explainMinorOrSupervised, No→**onParentDeviceFail**                                                                      |
| 4   | `explainMinorOrSupervised`          | Apple requirements               | Primary: "Next"                                                 | → confirmMinorDevice                                                                                                         |
| 5   | `confirmMinorDevice`                | "Is this under 18?"              | Primary: "Yes" / Secondary: "No"                                | Yes→confirmParentIsOnboarding, No→**major.explainHarderButPossible**                                                         |
| 6   | `confirmParentIsOnboarding`         | "Are you the parent?"            | Primary: "Yes" / Secondary: "No"                                | Yes→confirmInAppleFamily, No→**childIsOnboardingFail**                                                                       |
| 7   | `confirmInAppleFamily`              | "In Apple Family?"               | Primary: "Yes" / Secondary: "No" / Tertiary: "Not sure"         | Yes→explainTwoInstallSteps, No→**appleFamily.explainRequiredForFiltering**, NotSure→**appleFamily.explainWhatIsAppleFamily** |
| 8   | `explainTwoInstallSteps`            | 2-step process                   | Primary: "Next"                                                 | → explainAuthWithParentAppleAccount                                                                                          |
| 9   | `explainAuthWithParentAppleAccount` | Use parent Apple ID              | Primary: "Got it"                                               | → dontGetTrickedPreAuth                                                                                                      |
| 10  | `dontGetTrickedPreAuth`             | Warning: Click "Continue"        | Primary: "Got it" [async]                                       | → **SYSTEM AUTH**                                                                                                            |
| 11  | `explainInstallWithDevicePasscode`  | Use device passcode              | Primary: "Got it"                                               | → dontGetTrickedPreInstall                                                                                                   |
| 12  | `dontGetTrickedPreInstall`          | Warning: Click "Allow"           | Primary: "Got it" [async]                                       | → **FILTER INSTALL**                                                                                                         |
| 13  | `offerAccountConnect`               | Connect to Gertrude?             | Primary: "Skip" / Secondary: "Connect" / Tertiary: "More info"  | Skip→optOutBlockGroups, Connect→**ConnectAccount modal**, MoreInfo→explainAccountConnect                                     |
| 14  | `explainAccountConnect`             | Account benefits                 | Primary: "Back" / Secondary: "Read blog"                        | → offerAccountConnect                                                                                                        |
| 15  | `connectSuccess`                    | "Device connected!"              | Primary: "Next"                                                 | → promptClearCache                                                                                                           |
| 16  | `optOutBlockGroups`                 | Choose what to block             | Primary: "Done"                                                 | → promptClearCache                                                                                                           |
| 17  | `promptClearCache`                  | Clear browser cache?             | Primary: "Clear" / Secondary: "Skip"                            | Clear→ClearCacheFeature, Skip→requestAppStoreRating                                                                          |
| 18  | `requestAppStoreRating`             | Rate the app?                    | Primary: "Rating" / Secondary: "Review" / Tertiary: "No thanks" | All→doneQuit                                                                                                                 |
| 19  | `doneQuit`                          | "All set!"                       | —                                                               | → **running**                                                                                                                |

### System Authorization (after dontGetTrickedPreAuth)

```
SUCCESS → explainInstallWithDevicePasscode
FAILURE:
  - invalidAccountType    → authFail.invalidAccount(.letsFigureThisOut)
  - authorizationCanceled → authFail.authCanceled
  - restricted            → authFail.restricted
  - authorizationConflict → authFail.authConflict
  - networkError          → authFail.networkError
  - passcodeRequired      → authFail.passcodeRequired
  - unexpected            → authFail.unexpected
```

### Filter Installation (after dontGetTrickedPreInstall)

```
SUCCESS → offerAccountConnect (or optOutBlockGroups if feature disabled)
FAILURE:
  - configurationPermissionDenied → installFail.permissionDenied
  - other                         → installFail.other
```

---

## FLOW 2: Apple Family Diversion

**Entry:**

- confirmInAppleFamily → "No"
- confirmInAppleFamily → "Not sure"
- authFail.invalidAccount screens

**Exit:** Returns to confirmInAppleFamily

### Screen Sequence

| Screen                        | Description               | Next                                                                             |
| ----------------------------- | ------------------------- | -------------------------------------------------------------------------------- |
| `explainRequiredForFiltering` | Apple requires Family     | → explainSetupFreeAndEasy                                                        |
| `explainSetupFreeAndEasy`     | Setup is free             | → howToSetupAppleFamily                                                          |
| `howToSetupAppleFamily`       | Instructions + links      | Tertiary: "Done" → **return**                                                    |
| `explainWhatIsAppleFamily`    | Definition                | → checkIfInAppleFamily                                                           |
| `checkIfInAppleFamily`        | "See Family in Settings?" | Primary: "Yes" → **return** / Secondary: "Not yet" → explainRequiredForFiltering |

---

## FLOW 3: Major (18+) User Flow

**Entry:** confirmMinorDevice → "No" (not under 18) **Exit:**

- Returns to confirmMinorDevice (try with minor account)
- → supervision flow (no Mac or not in Apple Family)

### Screen Sequence

| Screen                         | Description         | Buttons/Next                                                                                         |
| ------------------------------ | ------------------- | ---------------------------------------------------------------------------------------------------- |
| `explainHarderButPossible`     | Harder but possible | → askSelfOrOtherIsOnboarding                                                                         |
| `askSelfOrOtherIsOnboarding`   | Who is setting up?  | "Helping someone"→askIfOtherIsParent, "My device"→askIfInAppleFamily                                 |
| `askIfOtherIsParent`           | Is helper a parent? | Yes→explainFixAccountTypeEasyWay, No→askIfOwnsMac                                                    |
| `explainFixAccountTypeEasyWay` | Easiest solution    | "Done"→**confirmMinorDevice**, "Another way?"→askIfOwnsMac                                           |
| `askIfOwnsMac`                 | Own a Mac?          | Yes/No→**supervision.intro**                                                                         |
| `askIfInAppleFamily`           | In Apple Family?    | Yes→explainFixAccountTypeEasyWay, No→**supervision.intro**, "What's that?"→explainAppleFamily(sheet) |
| `explainAppleFamily`           | Sheet modal         | Dismiss→askIfInAppleFamily                                                                           |

### State Tracking

- `majorOnboarder`: `.self` or `.other` (who is setting up)
- `ownsMac`: Boolean (affects supervision path)

---

## FLOW 4: Supervision Flow

**Entry:** From major flow when:

- Not in Apple Family AND owns Mac
- Doesn't own Mac
- Setting up own 18+ device

**Exit:**

- Instructions (success path)
- sorryNoOtherWay (dead end)

### Screen Sequence

| Screen                         | Description               | Buttons/Next                                                             |
| ------------------------------ | ------------------------- | ------------------------------------------------------------------------ |
| `intro`                        | Introduce supervised mode | → explainSupervision                                                     |
| `explainSupervision`           | What is supervision?      | Conditional→explainNeedFriendWithMac OR explainRequiresEraseAndSetup     |
| `explainNeedFriendWithMac`     | Need Mac friend           | "Got someone"→explainRequiresEraseAndSetup, "No one"→**sorryNoOtherWay** |
| `explainRequiresEraseAndSetup` | Device erase required     | "Show me"→instructions, "No thanks"→**sorryNoOtherWay**                  |
| `instructions`                 | Tutorial + video links    | Share link option                                                        |
| `sorryNoOtherWay`              | Dead end                  | "Support" / "Start over"→hiThere                                         |

### Conditional Logic

```
IF ownsMac != true OR majorOnboarder == .self:
  → explainNeedFriendWithMac
ELSE:
  → explainRequiresEraseAndSetup
```

---

## FLOW 5: Account Connection (Modal)

**Entry:** offerAccountConnect → "Connect" **Exit:** connectSuccess (success) or return to
offerAccountConnect

### States

| State                     | Description                        | Actions                 |
| ------------------------- | ---------------------------------- | ----------------------- |
| `enteringCode`            | 6-digit code input (100000-999999) | Submit→connecting       |
| `connecting`              | Loading state                      | —                       |
| `connected(childName)`    | Success                            | Done→**connectSuccess** |
| `connectionFailed(error)` | Error message                      | Retry→enteringCode      |

### API Call

```
api.connectDevice(code: Int, vendorId: UUID)
→ Returns: ChildIOSDeviceData(childId, token, deviceId, childName)
```

---

## FLOW 6: Authorization Errors

**Entry:** System authorization fails **Exit:** Returns to explainTwoInstallSteps (retry)

### Error Types

| Error                   | Screen                             | Message                                |
| ----------------------- | ---------------------------------- | -------------------------------------- |
| `invalidAccountType`    | `invalidAccount.letsFigureThisOut` | → confirmInAppleFamily (decision tree) |
| `authorizationCanceled` | `authCanceled`                     | "Clicked wrong button"                 |
| `restricted`            | `restricted`                       | "MDM prevents installation"            |
| `authorizationConflict` | `authConflict`                     | "Another parental control app"         |
| `networkError`          | `networkError`                     | "No internet connection"               |
| `passcodeRequired`      | `passcodeRequired`                 | "Set device passcode"                  |
| `unexpected`            | `unexpected`                       | "Unknown error"                        |

### Invalid Account Decision Tree

```
letsFigureThisOut → confirmInAppleFamily
  ├── Yes → confirmIsMinor
  │         ├── 18+ → major.explainHarderButPossible
  │         └── Under 18 → unexpected (contact support)
  ├── No → appleFamily.explainRequiredForFiltering
  └── Not sure → appleFamily.checkIfInAppleFamily
```

---

## FLOW 7: Installation Errors

**Entry:** Filter installation fails **Exit:** Returns to explainInstallWithDevicePasscode
(retry)

| Error                           | Screen             | Message                |
| ------------------------------- | ------------------ | ---------------------- |
| `configurationPermissionDenied` | `permissionDenied` | "Clicked wrong button" |
| other                           | `other`            | "Something went wrong" |

---

## Terminal Error States

| State                   | Trigger                      | Message                                  |
| ----------------------- | ---------------------------- | ---------------------------------------- |
| `onParentDeviceFail`    | confirmChildsDevice→No       | "App must be on device to protect"       |
| `childIsOnboardingFail` | confirmParentIsOnboarding→No | "Give device to parent"                  |
| `sorryNoOtherWay`       | supervision flow dead end    | "Only works on minor/supervised devices" |

---

## Feature Flags

### ConnectAccountFeatureFlag

**API Route:** `UnauthedRoute.connectAccountFeatureFlag` **Current Default:**
`isEnabled: false`

| Property                       | Type    | Description            |
| ------------------------------ | ------- | ---------------------- |
| `isEnabled`                    | Bool    | Feature on/off         |
| `offerScreenText`              | String? | Custom offer text      |
| `offerScreenConnectBtnText`    | String? | Custom "Connect" label |
| `offerScreenSkipBtnText`       | String? | Custom "Skip" label    |
| `explainScreenText`            | String? | Custom explanation     |
| `connectAccountSheetInfoBlurb` | String? | Custom info in modal   |

---

## End States

| State                           | Condition                         |
| ------------------------------- | --------------------------------- |
| `running.connected`             | Filter active + account connected |
| `running.notConnected`          | Filter active + no account        |
| `supervisionSuccessFirstLaunch` | Supervised device first launch    |

---

## Summary Statistics

- **Total screens:** ~40
- **Decision points:** ~12
- **Error states:** ~11
- **Sub-flows:** 4 (Apple Family, Major, Supervision, Account Connect)
- **Terminal errors:** 3 (onParentDeviceFail, childIsOnboardingFail, sorryNoOtherWay)
