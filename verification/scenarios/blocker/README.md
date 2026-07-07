# Blocker verification

Initial target loop:

1. Build and install the iOS blocker app on the selected simulator.
2. Launch with clean simulator app state.
3. Drive the happy-path onboarding screens through the simulator-backed authorization and filter-install path.
4. Read the app-generated blocker connection code from the simulator hierarchy.
5. Claim that code for the fixture parent by driving the **real dashboard claim UI with
   Cypress** (assign the device to a new child, reach the connected screen), then wait for
   the app to observe success.

The Cypress claim spec lives in `dashboard/` (a self-contained project, mirroring the
podcasts/music scenarios) and drives the live local dashboard at `DASH_PORT`.

Current commands:

```bash
just verify-blocker
just verify-blocker app
just verify-blocker flow
just verify-blocker claim
just verify-blocker e2e
```

`flow` drives the Maestro-only onboarding slice to the connection-code screen; `claim` reads
the code from the simulator, drives the dashboard claim with Cypress, and waits for the app
to observe success. `e2e` composes reset → app → flow → claim.

Append `--headed` (or `--chrome`) to run the dashboard Cypress step in a visible browser.

This scenario is intentionally narrower than the podcasts loop. The blocker app has real
device behaviors that cannot be faithfully exercised in Simulator, so this slice proves the
app can boot and that the simulator-drivable onboarding path is agent-drivable.

The app build uses the same deterministic simulator-build convention as podcasts:
`swift/iosapp/.derived-data/sim/Build/Products/Debug-iphonesimulator/app.app`. The runner
installs from that exact path instead of scanning global Xcode DerivedData. The app target's
Debug build configuration allows local HTTP API traffic.

By default the account connection uses the `blanca` reset fixture and creates a fresh
`Blocker Verification Child`. Override the child name with `BLOCKER_CHILD_NAME`.
