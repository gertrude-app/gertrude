# Music verification

Cross-surface loop (simulator app + real dashboard + API):

1. Build and install Gertrude Music on the selected simulator.
2. Launch with clean simulator app state.
3. Read the app-generated music claim code from the simulator hierarchy.
4. Claim that code for the paid Ben fixture parent by driving the **real dashboard claim UI
   with Cypress** (assign the device to a new child, reach the connected screen).
5. Wait for the app to finish its claim poll and show the empty approved-albums library.
6. Approve the known test album `Stories from the Outside` by driving the **real dashboard
   music-curation UI with Cypress** (search Apple Music, click "Allow album") — behavior
   under test, not a side-channel.
7. Let the app load the approved album, then drive play and pause through Maestro.

The simulator app uses app-side simulator implementations for Apple Music setup and playback,
so this loop does not require an Apple Music subscription on the simulator. The API does need
real Apple Music catalog access — `MUSICKIT_KEY_ID`, `MUSICKIT_TEAM_ID`, and
`MUSICKIT_PRIVATE_KEY` in `swift/api/.env` — for **both** the dashboard's catalog search (step
6) and expanding approved albums into playable tracks (step 7). These are configured; without
them the dashboard search returns nothing and the app shows `No tracks yet`.

The Cypress claim and album-approval specs live in `dashboard/` (a self-contained project,
mirroring the podcasts scenario) and drive the live local dashboard at `DASH_PORT`.

Current commands:

```bash
just verify-music
just verify-music app
just verify-music flow
just verify-music claim
just verify-music approve
just verify-music e2e
```

`flow` drives the Maestro-only slice to the claim-code screen; `claim` reads the code, drives
the dashboard claim with Cypress, and waits for the app's empty approved-albums library;
`approve` drives the dashboard album approval and then play/pause in the app. `e2e` composes
reset → app → flow → claim → approve.

Append `--headed` (or `--chrome`) to run the dashboard Cypress step in a visible browser, e.g.
for demo recordings:

```bash
just verify-music e2e --headed
```
