# iOS Supervision Onboarding - Task Breakdown

## Overview

21 tasks to implement supervised device onboarding for 18+ users. This enables adults to use Gertrude on their iOS devices without requiring Apple Configurator or device erasure.

## Pre-Implementation Assessment

- [00_dashboard-ios-routes-assessment.md](./00_dashboard-ios-routes-assessment.md) - Analysis of existing hidden `/ios-devices` routes and recommendations for feature gating

## Legend

- 🔒 **Blocking** - Must complete before dependent tasks
- ⚡ **Parallel** - Can run concurrently with other tasks at same level
- 📦 **Safe to ship** - Doesn't affect existing behavior when deployed

---

## Phase 1: Database Foundation

*Must complete first. Everything else depends on these.*

| # | Task | Type | Blocks |
|---|------|------|--------|
| 01 | [ios-pending-supervision-model](./01_ios-pending-supervision-model.md) | 🔒 📦 | Tasks 03-08 |
| 02 | [ios-device-supervision-fields](./02_ios-device-supervision-fields.md) | 🔒 📦 | Tasks 04, 06, 08 |

**Can run in parallel:** Tasks 01 and 02

---

## Phase 2: Core API Endpoints

*All can run in parallel after Phase 1 completes.*

| # | Task | Type | Blocked By | Blocks |
|---|------|------|------------|--------|
| 03 | [api-create-pending-supervision](./03_api-create-pending-supervision.md) | ⚡ 📦 | 01 | 12, 17, 20 |
| 04 | [api-claim-supervision-code](./04_api-claim-supervision-code.md) | ⚡ 📦 | 01, 02 | 09, 20 |
| 05 | [api-check-supervision-status](./05_api-check-supervision-status.md) | ⚡ 📦 | 01 | 13 |
| 06 | [api-mark-supervision-complete](./06_api-mark-supervision-complete.md) | ⚡ 📦 | 01, 02 | 18 |
| 07 | [api-supervision-profile](./07_api-supervision-profile.md) | ⚡ 📦 | 01 | 14 |
| 08 | [api-mark-setup-complete](./08_api-mark-setup-complete.md) | ⚡ 📦 | 01, 02 | 15 |

**Maximum parallelism:** 6 concurrent tasks

---

## Phase 3: Consumer Applications

*All can run in parallel after their API dependencies are met.*

### Dashboard

| # | Task | Type | Blocked By |
|---|------|------|------------|
| 09 | [dash-claim-supervised-device](./09_dash-claim-supervised-device.md) | ⚡ 📦 | 04 |
| 10 | [dash-supervision-device-status](./10_dash-supervision-device-status.md) | ⚡ 📦 | 01, 02 |

### iOS App

| # | Task | Type | Blocked By |
|---|------|------|------------|
| 11 | [ios-supervision-state-machine](./11_ios-supervision-state-machine.md) | ⚡ | None (start now!) |
| 12 | [ios-pre-supervision-screens](./12_ios-pre-supervision-screens.md) | ⚡ | 03, 11 |
| 13 | [ios-post-supervision-detection](./13_ios-post-supervision-detection.md) | ⚡ | 05, 11 |
| 14 | [ios-profile-install-flow](./14_ios-profile-install-flow.md) | ⚡ | 07, 11 |
| 15 | [ios-connection-verified-flow](./15_ios-connection-verified-flow.md) | ⚡ | 08, 11 |
| 16 | [ios-remove-supervision-dead-ends](./16_ios-remove-supervision-dead-ends.md) | ⚡ | 11 |

**Note:** Task 11 can start immediately (no API dependency). Tasks 12-16 depend on 11 plus their respective APIs.

### Supervision Tool

| # | Task | Type | Blocked By |
|---|------|------|------------|
| 17 | [supervise-code-entry-screen](./17_supervise-code-entry-screen.md) | ⚡ 📦 | 03 |
| 18 | [supervise-completion-reporting](./18_supervise-completion-reporting.md) | ⚡ 📦 | 06, 17 |
| 19 | [supervise-ux-improvements](./19_supervise-ux-improvements.md) | ⚡ 📦 | 17 |

### Web Landing Page

| # | Task | Type | Blocked By |
|---|------|------|------------|
| 20 | [web-supervision-landing-page](./20_web-supervision-landing-page.md) | ⚡ 📦 | 03, 04 |

---

## Phase 4: Integration Testing

| # | Task | Type | Blocked By |
|---|------|------|------------|
| 21 | [ios-supervision-e2e-testing](./21_ios-supervision-e2e-testing.md) | 🔒 | All iOS tasks |

---

## Dependency Graph

```
Phase 1 (Foundation):
  01 ─────┬─→ Phase 2
  02 ─────┘

Phase 2 (API - all parallel):
  03 ──┬──→ Phase 3
  04 ──┤
  05 ──┤
  06 ──┤
  07 ──┤
  08 ──┘

Phase 3 (Consumers - all parallel):
  ┌─ Dashboard: 09, 10
  ├─ iOS App:   11 → 12, 13, 14, 15, 16
  ├─ Supervise: 17 → 18, 19
  └─ Web:       20

Phase 4:
  21 (after all iOS complete)
```

---

## Quick Start

**Tasks that can start immediately:**
1. `01_ios-pending-supervision-model` - Database model
2. `02_ios-device-supervision-fields` - Database model
3. `11_ios-supervision-state-machine` - iOS state refactor (no API needed)

**Suggested parallel launch:**
```bash
gtask ios-pending-supervision-model
gtask ios-device-supervision-fields
gtask ios-supervision-state-machine
```

---

## Shipping Strategy

All database and API changes are **additive** and safe to ship incrementally:
- New tables/columns with nullable fields
- New API endpoints (no changes to existing)
- Dashboard UI is new features only

iOS app changes can be batched since app is unreleased.

---

## Related Docs

- [tasks.md](../tasks.md) - Initial context and goals
- [next.md](../next.md) - Brainstorming prompt
- [ios-onboarding-flow.md](../ios-onboarding-flow.md) - Current state machine
- [supervision-onboarding-recommendations.md](../supervision-onboarding-recommendations.md) - Detailed recommendations
- [supervision-flow-script.md](../supervision-flow-script.md) - Happy path script (Ben + Luke)
