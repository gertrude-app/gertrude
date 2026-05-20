# 003 — `vendorId` vs `deviceId` vs `installId` naming convention

_Date: 2026-05-14._

## The convention

- **`deviceId`** is the canonical name for the cross-app UUID that identifies a physical
  iOS device. It is the value originally retrieved from
  `UIDevice.current.identifierForVendor`, but we do not carry the Apple-platform name with
  it past the point of retrieval. From the keychain on through the PairQL surface, the
  database, the admin UI, and cross-app correlation, the name is `deviceId`.
- **`vendorId`** is the localized name **only at the platform-API boundary** — the single
  point where we first read `identifierForVendor` from `UIDevice`. In the podcast app that
  boundary is the `DeviceClient` dependency
  (`swift/podcasts/lib-tca/Sources/Deps/Device.swift`); the iOS app has the equivalent.
  Past that boundary the value is always `deviceId`.
- **`installId`** is a distinct, server-side-only concept: the random-UUID primary key of
  a per-app install row (e.g. `podcast_app.installs.id`, `blocker_app.installs.id`). Each
  row represents one app's installation on one physical device. Tokens foreign-key to
  their install row; the install row foreign-keys to the device via `device_id`.
  `installId` never appears in new PairQL inputs the apps call, and the apps don't store
  an install ID — they only ever know `deviceId`. It is purely a server-internal join key.

The mental model: **device** is the physical iOS device (one `child.ios_devices` row,
keyed on the vendor-derived `deviceId`); **install** is one of our app instances running
on that device (one row per app per device, keyed on its own random `installId` and
joining back to the device via `device_id`).

## Why we ended up here

The naming evolved through several refactors:

- **Migration 058 `VendorIdAsDeviceId`** (Jan 2026) dropped the `vendor_id` column from
  `child.ios_devices` entirely and set `ios_devices.id` to the vendor-derived UUID value.
  Referencing tables had their FK columns renamed from `vendor_id` to `device_id`. From
  this point forward, "vendor ID" was an Apple-API implementation detail, not a name we
  carried around the codebase.
- **Migration 069 `PodcastDeviceId`** (Mar 2026) renamed `podcasts.events.install_id` to
  `device_id` and made it non-nullable — and the AM podcast app got a new `DeviceClient`
  dep that reads `identifierForVendor` but stores it under a new keychain `case deviceId`
  (the older `case installId` was marked `@deprecated` and only kept for
  reading-and-migrating old random-UUID install IDs forward into the new device-ID-keyed
  world). `LogPodcastEvent_v3` was introduced with a `deviceId: UUID` input field
  replacing v2's `installId`.

The thread running through both refactors is the same: **the apps and the server have
always needed a stable per-device identity, and we already had one
(`identifierForVendor`); the historical drift had been to wrap it in ceremony — sometimes
calling it `vendorId`, sometimes assigning it a secondary random `installId` — instead of
just using it directly as our canonical `deviceId` everywhere.**

## Status of the migration: incomplete

Legacy PairQL pairs in shipped client versions still carry the old names and cannot be
renamed without a `_v3`/`_v4` bump that the apps must adopt:

- iOS app: `ConnectDevice_v2.Input.vendorId`, `CheckSupervisionFlowStatus.Input.vendorId`,
  `BlockRules_v2.Input.vendorId`, `LogIOSEvent_v2.Input.vendorId`,
  `RecoveryDirective_v2.Input.vendorId`. The corresponding server resolvers immediately do
  `deviceId: .init(input.vendorId)` to convert at the edge.
- AM podcast app: `LogPodcastEvent_v2.Input.installId`,
  `VerifyDbDownload.Input.installId`, `VerifyPromoCode.Input.installId`,
  `CreateDatabaseUpload.Input.installId`. The newer `LogPodcastEvent_v3.Input.deviceId`
  shows the target shape.

These holdouts are stuck on shipped-client compatibility, not on ambivalence. They can
roll forward to `deviceId` whenever a versioned pair bump happens for an unrelated reason.

## What this means for new code

- New PairQL pair inputs the apps call should take `deviceId: UUID`. Do not introduce new
  `vendorId` fields on PairQL.
- The single legitimate use of the name `vendorId` is at the `identifierForVendor`
  retrieval boundary in each app (the `DeviceClient.vendorId()` dep) and the
  comment-documented bridge into keychain `deviceId` storage. Don't propagate the name
  further.
- `installId` is fine on server-internal models, FKs, ephemeral state, and
  context-plumbing types where it refers to the per-app install row PK. It should not
  appear in PairQL inputs from the apps. (PairQL **outputs** can reference it if a
  dashboard-side flow legitimately needs to talk about a specific install — but the apps
  themselves don't.)
