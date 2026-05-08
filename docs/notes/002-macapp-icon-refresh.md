# 002 — Throttling Mac app icon refreshes

_Date: 2026-05-08._

## What we changed

Mac app icon uploads are no longer requested on every mismatch between the client-rendered
icon hash and the single global hash stored for a bundle ID. The API now treats an icon
as upload-worthy when it is missing, or when the stored icon is stale enough to refresh.
When a newer Mac app can report the installed app's own raw
`CFBundleShortVersionString`, that version is used as a best-effort signal to prefer
refreshes from newer app builds.

The `macos.mac_apps` table now records `icon_uploaded_at` and nullable raw
`icon_source_app_version` so icon freshness is separate from ordinary app catalog
metadata updates. Existing rows are backfilled with a deterministic per-bundle timestamp
spread across the prior 45 days so refresh eligibility rolls forward gradually instead of
creating a synchronized day-91 cliff after deploy. Duplicate uploads with the same hash
do not reset freshness or downgrade stored source version provenance.

## Why

The original design assumed the rendered PNG hash for a bundle ID would be stable across
Macs, and that a hash mismatch would usually mean the app's icon had changed. Production
route telemetry showed the opposite: new catalog entries tailed off, but `UploadAppIcon`
traffic stayed high. That means the hash is not a safe global freshness signal by itself.

The likely cause is that different Macs can render byte-distinct PNGs for the same
logical app icon due to OS version, app version, source asset, renderer behavior, or image
metadata. With one global hash per bundle ID, clients can keep replacing each other's
hashes.

## Tradeoffs

We deliberately avoided adding a separate `icon_last_upload_requested_at` throttle field.
That means when a stale icon first becomes eligible, more than one client may be asked to
upload before the first successful upload updates `icon_uploaded_at`. This is acceptable
for now because the stale window is coarse and should reduce traffic by orders of
magnitude. The migration backfill uses deterministic jitter over 45 days to avoid
concentrating the first refresh wave at a single future timestamp. App version comparison
is deliberately loose: dotted numeric versions are
compared segment-by-segment, and otherwise changed raw strings are treated as a weak
refresh signal. We should review `UploadAppIcon` telemetry after this ships and add an
explicit request-throttle column if stale-window refreshes still spike.
