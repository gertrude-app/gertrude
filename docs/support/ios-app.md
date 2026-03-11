# iOS App

The Gertrude iOS app was released later than the Mac app and serves a different purpose.
It first launched in the App Store on **October 23, 2024** as **Gertrude Blocker**.

## What It Is

- The iOS app is a focused tool for **plugging holes in Apple's Screen Time controls**.
- It began as a response to Apple removing the parent's ability to disable `#images` GIF
  search in Messages in **iOS 17** and still not fixing it in **iOS 18**.
- It has since expanded to block other risky or hard-to-control iOS content surfaces.
- It runs mostly in the background after setup and usually does not need to be opened
  regularly.

## What It Does

- Installs an iOS network content filter.
- Blocks `#images` GIF search in Messages.
- Blocks other loopholes and risky content areas through **block groups**.
- Can block or reduce content in areas like:
  - Spotlight internet image search
  - Apple Maps business-listing images
  - App Store images
  - some AI/image-related features
  - some WhatsApp media/features
  - Spotify images/artwork
- Supports account connection so parents can remotely manage block groups for connected
  devices.
- Supports supervised-mode setup for adults or other users who cannot use Apple's under-18
  Family Sharing authorization path.

## What It Does Not Do

- It is **not** the same kind of product as the Mac app.
- It does **not** provide deny-by-default internet filtering.
- It does **not** offer screenshot monitoring.
- It does **not** offer keylogging.
- It does **not** use Mac-style unlock requests, keychains, or filter suspensions.
- It does **not** give parents the same depth of control that exists on macOS.

## How Filtering Works

- The iOS app uses Apple's network/content-filter framework under the hood.
- Unlike the Mac app, the iOS app is fundamentally a **blocklist** product, not an
  allowlist product.
- Unknown traffic is generally allowed unless it matches a rule Gertrude blocks.
- This matters a lot for support: the iOS app should be described as **closing known
  Screen Time gaps**, not as fully locking down the internet in the same way the Mac app
  does.
- The rules are organized into **block groups** that can be enabled or disabled.

## Installation Paths

- There are currently two main ways to get the iOS app fully installed:
  - **Under-18 / Apple Family path:** for devices signed into an Apple account belonging
    to someone under 18 who is part of Apple Family Sharing
  - **Supervision path:** for devices used by adults or others who cannot use the under-18
    Family Sharing path
- In the under-18 path, a parent/guardian in the Apple family authorizes the installation
  using Apple's Screen Time / family authorization flow.
- Once installed that way, the filter is difficult for the child to remove without the
  parent re-authenticating.

## Adults And Supervision

- Apple does not make iOS content filtering straightforward for devices used by people
  over 18.
- For most of the product's history, adults could only use the app by putting the device
  into **Supervised Mode**, usually with Apple Configurator.
- That older path required:
  - access to a Mac
  - putting the device into supervised mode
  - usually wiping/factory-resetting the device
- This was a major source of friction and many users did not complete setup.

## Gertrude Supervision

- In **early 2026**, Gertrude added its own supervision flow.
- This allows users to supervise an iPhone or iPad **without erasing the device** by using
  Gertrude's desktop supervision tool over USB.
- The flow uses a 6-digit claim code generated on the iOS device, then completed through
  the dashboard and desktop supervision tool.
- This path requires a Gertrude account and currently ties into the **Light** plan.
- Repo reference: [ios-supervision.md](../ios-supervision.md)

## Relationship To Gertrude Accounts

- This is one of the most important support facts because the answer changed recently.
- For most of the iOS app's history, it was effectively **standalone** and had **no real
  connection to a Gertrude parent account or dashboard**.
- That means many older support threads will be misleading on this point.
- Account-connection work began in **August 2025**, was later hidden behind a feature flag
  in **November 2025**, and was publicly rolled out in **February 2026**.
- Today, iOS devices **can** be connected to a Gertrude account and appear in the parent
  dashboard.
- All devices that go through Gertrude's supervision flow are connected to an account.
- Devices installed through the under-18 Apple-family path can also now be connected to a
  free Gertrude account.

## Why Connection Matters

- Originally, block-group choices were made only during installation.
- That was intentional: the install flow was the one moment Gertrude knew the parent or
  protector was the person holding the device.
- If an iOS device is **not connected** to a Gertrude account, block groups generally
  cannot be safely changed later from the device itself.
- In that case, the practical way to change the selected block groups is often to delete
  and reinstall the app/filter.
- If the device **is connected** to a Gertrude account, parents can change block groups
  later from the dashboard.
- This is an important support distinction and a frequent source of questions.

## Plans And Current Account Model

- **Free plan:** can connect eligible iOS devices and allows basic dashboard control of
  connected iOS block groups.
- **Light plan:** currently centered on Gertrude-managed supervision for iOS devices and
  is priced in the codebase and site copy as **$10/year**.
- **Full plan:** includes the Mac-app-oriented product and broader dashboard usage.
- The dashboard has been evolving in late 2025 and early 2026 to support this more mixed
  Mac+iOS account model.

## Onboarding

- The iOS app has a substantial onboarding flow.
- It explains the authorization path, walks the user through installing the filter, and
  verifies that filtering is active.
- After onboarding, the app usually does not need ongoing interaction.
- In recent versions, onboarding also branches based on whether the user is under 18, over
  18, connected to an account, or entering supervision flow.

## Cache Clearing

- A recurring support issue is that **previously downloaded images may still be visible**
  even when blocking is working correctly.
- Gertrude includes a **cache clearing** feature to help with this.
- The implementation is basically a workaround: the app writes data until iOS reports that
  the device is out of space, which puts pressure on the system to evict cached content.
- It is often effective, but it is **best effort** and does not always fully clear every
  cached image.
- Cache clearing is offered at the end of onboarding, and in current versions it can also
  be run again from the app's **Info** screen.
- Useful support flow:
  - First, verify that blocking itself is working. For example, if a `#images` search for
    a unusual query shows gray placeholder boxes, the filter is working and any visible
    images are from the cache.
  - Second, have the user run the cache-clearing feature again from the Info screen.
  - Third, if cached images still remain, explain that the feature is not guaranteed to
    remove everything.
- A practical fallback some users report helps is recording high-definition video until
  the device storage fills up. This puts similar pressure on iOS cache eviction and may
  clear more content in some cases.

## Significant Recent Changes

- **October 2024:** App Store launch of Gertrude Blocker (`1.0.0`), initially focused on
  `#images` GIF search and a few other Screen Time loopholes.
- **March 2025:** onboarding was significantly expanded, and users gained opt-out block
  groups plus a clear-cache flow after install.
- **August to November 2025:** account connection work landed, then was partially hidden
  behind a feature flag before broader rollout.
- **November 2025:** `1.5.0` added Spotify blocking and hidden-behind-flag account
  connection.
- **February 2026:** account connection was publicly rolled out, and the new supervision
  feature became the major new path for over-18 devices.
