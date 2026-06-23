# Gertrude AM

Gertrude AM is a separate iOS podcast app for kids and accountability partners. It started
life as an anonymous standalone app using IAP that did **not** connect to a Gertrude
account, but since v1.6.0 (June 2026) it now connects to a Gertrude parent account,
requiring at least a Light subscription after a 30-day free trial.

## What It Is

- A basic podcast app with one core parental-control idea: searching for or adding new
  podcasts is gated by a PIN.
- Built for parents who want a child to be able to listen to approved podcasts without
  being able to freely search for and add anything they want. Works well also for
  adults/spouses in relationships of accountability.

## How It Works

- During onboarding, the parent/protector can connect/claim the device into a free or paid
  Gertrude account or skip connection, then they set a 6-digit PIN and confirm it.
- After that, the child/user can listen to already-added shows normally.
- To search for and add a new podcast feed, the app requires the PIN.
- The PIN is a 6-digit code that gates the search & add new podcast flow.
- It is stored only on device, and persisted in iOS Keychain, so it survives app deletion
  and re-install to prevent bypass.
- It can be changed from the app's settings area by confirming the current PIN, or reset
  through the Gertrude account if forgotten.
- It has basic podcast app features like controlling playback speed, removing/archiving
  episodes, ordering and sorting, bluetooth and AirPlay support.

## What It Does Not Do

- It does not currently have a "Play Next" queue feature, only tries to intelligently
  queue up the next episode when one finishes based on a set of hueristics.
- It does not use Screen Time authorization.
- It does not install a network filter.
- It does not have extensive settings, monitoring, or reporting within the Gertrude
  dashboard, although these may be added in the future. The dashboard connection currently
  only allows for PIN reset and subscription management, not any podcast-app-specific
  features.

## Subscription

- Gertrude AM is free to try without a subscription (or with a Free account) for 30 days.
  After that, the account must have at least a Light subscription to continue updating
  shows and adding new shows.
- Prior to version 1.6.0, the app used Apple IAP for a $10/year subscription, but Jared
  messed up the IAP and made it a non-consumable (non-repeating) purchase. Account
  connections made by users who already paid via IAP are grandfathered in with 3 months
  extra time after paid 12 months to switch to a Gertrude account.

## Support Notes

- Support volume is relatively low compared with the Mac app and main iOS app.
- Older installs from before account connection shipped can still exist unconnected in the
  wild, so don't assume every AM user is connected.
- The most likely support topics are:
  - setting or changing the PIN
  - recovering a forgotten PIN (and whether the app is connected to a Gertrude account,
    which determines what reset options exist)
  - feature requests

## Significant Recent Changes

- **June 2026:** account connection rolled out, subscription model changed, and iOS
  version requirement lowered to 17. See `../../swift/podcasts/readme.md` for more details
  if necessary.
- **October 23, 2025** initial release.
