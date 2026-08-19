# iOS Block Findings

Durable record of "can we block X in <app>?" investigations. Add new findings here so we
don't re-run captures we've already done.

For the investigation **workflow** (capture commands, log analysis), see
[`ios-block-rule-analysis.md`](./ios-block-rule-analysis.md).

## Key architectural limitation

The iOS NE filter only fires verdicts at **flow establishment**. Anything multiplexed onto
a pre-existing HTTP/2 stream or long-lived WebSocket is invisible to the filter. This is
why chat / AI features that ride a persistent transport (Spotify Messages, GroupMe Copilot
text) cannot be blocked without killing the whole app.

## Ad-hoc rules

For one-off customer requests where the trade-off is acceptable to _that_ customer but not
as a shipped group, attach the rule directly to the device by setting `device_id` (and
leaving `group_id` NULL) on a `blocker_app.block_rules` row.

---

## Filter presence breaks app

### 2026-05-21: Minecraft Bedrock hangs whenever the iOS NE filter is enabled

Minecraft Bedrock hangs on launch whenever Gertrude's iOS content filter
(`NEFilterDataProvider` socket filtering) is installed and enabled. **No filter-layer fix
exists on iOS.**

- **Root cause:** not rules / verdicts / dropped traffic / Family Controls. With the
  filter present every Minecraft flow is _allowed_ and traffic flows _more_ heavily than
  when it works, yet the app wedges. Cause is the per-flow verdict **gating inherent to
  the filter's data-path presence**: at launch Minecraft fires a burst of simultaneous
  flows, the gating serializes/stalls them, and its network-coupled UI freezes. Proven — a
  no-op allow-everything filter still hangs; removing the filter (Family Controls
  retained) makes it playable.
- **Unfixable on iOS:** a content filter can only return a per-flow verdict; the most
  permissive (`.allow()`) already hangs, and iOS has **no** flow-exclusion API
  (`NEFilterSettings` is macOS-only). No auto-mitigation either (can't detect app launch
  or self-disable the filter).
- **Action / customer guidance:** treat as a hard compatibility limitation — Minecraft
  needs the filter removed/disabled. Likely affects any iOS content-filter app, not just
  Gertrude (unconfirmed; no public competitor reports found).

**Full investigation** (all 5 states, pcap analysis, mechanism, sources):
<https://gist.github.com/jaredh159/4931596cc733cf02a2e282bc31f75f62>

---

## Apple Music

### 2026-05-15: artwork leak via itunescloudd (favorited artists / playlists)

**Trigger:** customer reported album artwork still appearing in Apple Music after
favoriting artists / playlists, despite the existing artwork rules being active.

**Tested:** capture during favorite → navigate to album. Existing `com.apple.Music`-scoped
rules DROPped ~786 flows to `is1-ssl.mzstatic.com`, but 2 ALLOWs slipped through from
`.com.apple.itunescloudd` (iCloud Music Library daemon). Artwork bytes from itunescloudd's
allowed fetches appear to be cached at a system-level image cache shared with the Music
app, so Apple Music's own DROPped requests still find the artwork locally and render it.

**Verdict:** existing bundle scope (`com.apple.Music`) was too narrow. `itunescloudd` is a
sibling carrier hitting the same `ssl.mzstatic.com` host.

**Shipped 2026-05-15:** sibling rule added to the Apple Music group (SQL at
`logs/apple-music-itunescloudd-artwork-rule.sql`):

```json
{
  "a": { "case": "bundleIdContains", "value": "itunescloudd" },
  "b": { "case": "targetContains", "value": "ssl.mzstatic.com" },
  "case": "both"
}
```

Re-test confirmed: 83 DROPs from itunescloudd during the next favorite/navigate sequence,
artwork no longer rendered. Note: BlockRule has no native OR, so this is a parallel rule
rather than a broadening of the existing one. `itunescloudd` also hits `librarydaap`,
`genius-*`, `p42-buy`, `pd.itunes.apple.com` — metadata, not artwork, left allowed.

### 2026-04-30 → 2026-05-01: artwork blocks cause audio playback failure

**Trigger:** customer reported audio dying ~15s after song start when filter active.

**Tested:**

- Existing artwork rules (`*.mzstatic.com`, scoped to `com.apple.Music`) caused Music to
  retry-storm on blocked artwork hosts (~800+ flows in 15s). Retry storm appears to trip a
  process-wide URLSession circuit breaker, killing the audio stream on the allowed audio
  host.
- Mitigation A — `.pause()` then drop: **macOS-only API**, not on iOS.
- Mitigation B — `.filterDataVerdict()` + drop on first byte: handshake succeeds, but
  audio still failed. ~78% of artwork retries are QUIC (UDP), so any TCP-graceful trick is
  moot for most flows.

**Verdict:** dead end at the iOS filter layer. The only remaining path is
`NEDNSProxyProvider` (NXDOMAIN responses), which is a significant architectural shift.

**Shipping:** original artwork rules remain. Cascade is a known limitation.

---

## Apple Maps

### 2026-03-03 → 2026-05-26: Street View / Look Around — ship, broke nav, rolled back, narrow re-ship

**Trigger:** customer (email thread ref `f25a8`) flagged Apple Maps Street View and Look
Around as image backdoors, supplying candidate hosts under `gspe*-ssl.ls.apple.com`.

**2026-03-03 — broad rule shipped, broke nav (rolled back next day):** added one
nested-`both` rule to `Apple Maps images` matching `.com.apple.Maps` +
`targetContains("gsp")` AND `targetContains("-ssl.ls.apple.com")` — intended as a wildcard
for the customer's subdomain list. Within ~24 hours a customer reported Apple Maps
navigation completely dead (forced offline). The pattern matched **every**
`gspeN-ssl.ls.apple.com` — Apple's general location-services backbone — not just
Street-View endpoints. Rolled back 2026-03-04, no replacement.

\*\*2026-05-26 — re-investigation with `idevicesyslog` on iOS 18.6.2 with rules scoped to
`.com.apple.Maps`:

- A `hostnameEquals "gspe76-ssl.ls.apple.com"` rule blocked **only** Street View (12 DROPs
  in a 125ms retry storm → on-device "street imagery can't be shown at this time"). Nav,
  business search, weather overlay all worked; nav-critical flows hit `gspe21` (and
  `gspe19` in a follow-up session) — untouched by the narrow rule.
- Re-applying the broad 2026-03 rule as a control reproduced the prod incident exactly
  (361 DROPs on `gspe19`, plus `gspe19-2`, `gspe76`, `gspe12`, `gsp-ssl`, all source
  `.com.apple.Maps`) — confirms the narrow-rule nav stability isn't a fluke.
- `gspe7-ssl.ls.apple.com` and `maps.apple.com` (other candidates from the customer's
  list) never appeared on iOS 18.6.2 — no-ops on this version. Kept `gspe7` in the shipped
  set for iOS 16/17 coverage; the customer's two-month proxy.pac history confirms it's
  nav-safe there.

**Shipped 2026-05-26** to the `Apple Maps images` group:

```json
// primary block — iOS 18 verified
{"a":{"case":"bundleIdContains","value":".com.apple.Maps"},
 "b":{"case":"hostnameEquals","value":"gspe76-ssl.ls.apple.com"},
 "case":"both"}

// iOS 16/17 fallback (per email ref f25a8); no-op on iOS 18
{"a":{"case":"bundleIdContains","value":".com.apple.Maps"},
 "b":{"case":"hostnameEquals","value":"gspe7-ssl.ls.apple.com"},
 "case":"both"}
```

**Residual risks:**

- Apple load-balances across the `gspeN` pool — saw `gspe12`, `gspe19`, `gspe21`,
  `gspe76`, `gspe79` in one session. `gspe76` showed up for Street View in two separate
  sessions (suggestive of pinning, n=2). If Apple rotates Street View off `gspe76`, the
  block silently stops working; if Apple rotates nav onto `gspe76`, the 2026-03 incident
  repeats.
- **Cache gotcha** (per customer): Apple caches Street View tiles. A block can appear
  successful via cache for hours — always test in an unbrowsed region or cache-clear
  before declaring success.

### 2026-08-18: follow-up — customer (B. Harlan) reports Street View blocked near

Destin FL but not in Miami — found a second UI entry point, `gspe72`

**Trigger:** customer screenshots showing Street View blocked around Destin but rendering
for Miami-area place-card searches (e.g. "Four Seasons Hotel Miami"), on a kid's device.

**Tested:** first tried to rule out `gspe76` being regionally load-balanced (i.e. the
customer's device landing on a different edge than ours) by tunneling the test device
through WireGuard VPNs in three distinct networks — home (Ohio), and DigitalOcean
droplets in Atlanta and San Francisco — reinstalling Maps fresh each time. Street View hit
`gspe76` and got DROPped identically in all three; this ruled out the load-balancing
theory (pinning now n=5+, up from n=2), but didn't explain the customer's report.

Replicating the customer's exact repro path (search a named place → tap its card → tap the **"Look
Around" button**, rather than the map-pin/zoomed-tease entry points used in the original
investigation) surfaced a previously-unseen host: `gspe72-ssl.ls.apple.com`, `ALLOW`ed.
The zoomed-map-tease entry point still correctly hits `gspe76` (already covered) — only
the place-card button path was missed.

**Verdict:** Street View has multiple distinct UI entry points in Maps that route to
different `gspeN` hosts. Confirmed `gspe72` is the place-card-specific host (not shared
nav infra) via the same narrow `hostnameEquals` + reinstall-verified methodology as
`gspe76`.

**Shipped 2026-08-18** to `Apple Maps images`:

```json
{
  "a": { "case": "bundleIdContains", "value": ".com.apple.Maps" },
  "b": { "case": "hostnameEquals", "value": "gspe72-ssl.ls.apple.com" },
  "case": "both"
}
```

**Residual risk:** confirms the existing `gspeN` pool risk applies per-entry-point, not
just per-region — there could be further undiscovered entry points (or hosts) beyond the
three now covered (`gspe76`, `gspe72`, `gspe7`). Revisit if another customer reports a
leak via a UI path we haven't tested.

---

## Music Recognition (Shazam / Control Center)

### 2026-05-14: recognition and artwork both cleanly blockable

**Trigger:** customer reported Control Center "identify song" feature working & album art
rendering after recognition.

**Tested:**

- Recognition daemon bundle `.com.apple.shazamd` hits `amp-api.shazam.apple.com`
  (recognition API) plus `fpinit.itunes.apple.com` and
  `sf-api-token-service.itunes.apple.com` (iTunes session bootstrap). All three are
  shazamd's only outbound — it does nothing else.
- UI app bundle `4GWDBCF5A4.com.apple.musicrecognition` fetches album art from
  `is1-ssl.mzstatic.com`.
- Both bundles are distinct from `com.apple.Music`, so Apple Music's existing scoped
  artwork rules don't incidentally cover this.

**Verdict:** cleanly blockable. Blocking the `shazamd` bundle produces a clean "This
device is not connected to the internet" failure in the Control Center bubble.

**Shipped 2026-05-14:** new opt-in block group "Music Recognition" with two rules (SQL at
`logs/music-recognition-group.sql`). Opt-in so it's only available to connected accounts
via the dashboard — felt heavy as a default for a niche feature.

```json
// kill recognition entirely
{"case":"bundleIdContains","value":"com.apple.shazamd"}

// suppress artwork in Music Recognition results UI
{"a":{"case":"bundleIdContains","value":"com.apple.musicrecognition"},"b":{"case":"targetContains","value":"ssl.mzstatic.com"},"case":"both"}
```

---

## GroupMe

### 2026-05-01: Group Copilot AI — text unblockable, images blockable with heavy collateral

**Trigger:** customer asked about GroupMe AI / Copilot (Microsoft GPT-4o feature in v15:
@Copilot in chat, DM-with-Copilot, Chat Summaries).

**Tested** with two image-gen prompts under filter capture:

- AI text/image **prompts** ride pre-existing chat HTTP/2 connections (primary
  `v2.groupme.com`, fallback `api.groupme.com` / `push.groupme.com`). Confirmed by
  DROPping `v2.groupme.com` and watching prompts still arrive server-side — they multiplex
  onto an already-open connection (see
  [Key architectural limitation](#key-architectural-limitation)).
- AI image **delivery** comes from `i.groupme.com`. Blocking it stops generated images
  (348 DROPs in one image-gen retry storm, image never renders, retry button dead).
- `tenor.googleapis.com` (GIF search) is already DROPped by existing rules.

**Verdict:** Copilot text cannot be blocked without killing the app. Image delivery _can_
be blocked, but `i.groupme.com` also serves **all chat photo attachments and avatars** —
coarse trade-off.

**Not shipped as a group** (collateral too high for a default offering).

**Ad-hoc rule** for a customer willing to lose all chat photos + avatars to suppress
Copilot image delivery (attach directly to a device row):

```sql
INSERT INTO blocker_app.block_rules (id, rule, comment, device_id, group_id, created_at, updated_at)
VALUES (
  gen_random_uuid(),
  '{"case":"targetContains","value":"i.groupme.com"}'::jsonb,
  'ad-hoc: block GroupMe Copilot image delivery (also kills chat photos + avatars)',
  '<device-uuid>',
  NULL,
  NOW(), NOW()
);
```

**Untested:**

- Whether normal chat-receive still works with the rule enabled (couldn't test — solo test
  group, no second human).

### 2026-05-26: user follow-up — rule breaks messaging and re-auth

Real-world test from one customer given the `i.groupme.com` ad-hoc rule above to a
customer device.

**Confirmed blocked (goal achieved):**

- Copilot
- AI image remixing
- Most avatars (small/tiny avatars occasionally still render; clicking shows blank)

**Confirmed broken (collateral worse than expected):**

- Sending messages — fails with "your message got lost, tap to retry"; retry no-op.
- Receiving messages — push notifications fire, message body absent in-app, sometimes
  appears later.
- Re-authentication — GroupMe forces logouts periodically (observed: customer and spouse
  both kicked the same week). Login PIN flow then fails ("something went wrong") and user
  is locked out.

"Log in first" workaround **falsified**: rule breaks messaging and re-auth even when
applied after the user is fully logged in.

**Status:** ad-hoc rule above is **not currently viable** for active GroupMe users. Needs
a more surgical block target before re-offering, may not be possible.

---

## Spotify

### 2026-08-07: Spotify share-sheet artwork not cleanly blockable

**Trigger:** customer report: Spotify artwork was hidden throughout the Spotify app but
appeared immediately after opening the iOS share sheet for a track.

**Reproduction:** local USB capture while opening Spotify share UI. Exact user-observed
artwork appearance was `2026-08-07 16:26:36 EDT`.

**Findings:** broad scan of the `16:26:20`-`16:26:40` window showed no Apple daemon,
Messages/LinkPresentation process, or other sibling bundle fetching Spotify artwork. The
only successful Spotify traffic near the moment of appearance was
`2FNC3A47ZF.com.spotify.client` to `guc3-spclient.spotify.com`. Artwork-looking hosts in
the same window were already dropped, including `image-cdn-fa.spotifycdn.com`,
`misc.scdn.co`, and `scontent-*.xx.fbcdn.net`.

**Failed diagnostic:** added a temporary device-scoped rule for `com.spotify.client` +
`guc3-spclient.spotify.com`. It made Spotify too broken to reach a useful reproduction
path, matching prior findings that `spclient` is core Spotify backend traffic rather than
an artwork-specific endpoint. Removed the diagnostic rule.

**Verdict:** no shippable block rule identified. The share-sheet artwork is likely coming
from Spotify's already-open backend/cache path or from image bytes Spotify has already
loaded locally, not from a narrow artwork host analogous to Apple Music's `itunescloudd`
leak.

### 2026-05-01: Spotify Messages chat unblockable

**Trigger:** customer asked whether Gertrude blocks Spotify Messages (in-app DMs, launched
2025-08-26: 1:1 and group chats up to 10, mobile-only, 16+, requires prior interaction
such as collaborative playlist).

**Reproduction:** two test accounts linked via a collaborative playlist (satisfies
Spotify's prior-interaction prereq), then sent text + shared song.

**Findings:** chat messages produce **no new flow visible to the filter**. They ride the
long-lived `guc3-dealer.g2.spotify.com` WebSocket and `spclient` HTTP/2 connections
Spotify opens at startup. The same backbone hosts carry playback, search, recommendations,
presence, _and_ chat — blocking them breaks Spotify entirely. No chat-specific subdomain
exists.

**Verdict:** chat itself is not blockable at the iOS filter layer. Embedded chat visuals
(album art, Canvas, etc.) are already degraded by existing CDN rules (`image-cdn-fa`,
`pickasso`, `i.scdn.co`, ...), but text passes.

**Customer reply:** Spotify has an in-app account-level toggle to disable Messages and a
per-user block; if that's not enough, don't allow Spotify.

### 2026-08-18: Music Videos (newer feature, distinct from Canvas) — cleanly blockable

**Trigger:** customer report (Connor) — Spotify video content not blocked. Refers to
Spotify's newer Premium-only "Music Videos" feature (Now Playing "Switch to Video" toggle,
"Videos for You" playlist), not the older Canvas looping-video feature already covered by
the existing (undocumented, pre-dates this doc) `Spotify images` group and its blanket
`hostnameEndsWith: .scdn.co` rule.

**Tested:** USB capture on `com.spotify.client` under a Premium trial while watching
videos from the "Videos for You" playlist. `video-cf.spotifycdn.com` was the only
`ALLOW`ed host not already covered by the existing `.scdn.co` wildcard or the legacy
`video-*` rules — confirmed as the actual delivery host.

**Verdict:** cleanly blockable. Blocking it kills both Music Videos and video podcasts
(same host serves both); regular audio (music tracks and a non-video podcast) unaffected.
Untested: whether a video podcast's audio still plays with its video suppressed.

**Shipped 2026-08-18** to the existing `Spotify images` group:

```json
{
  "a": { "case": "bundleIdContains", "value": "com.spotify.client" },
  "b": { "case": "hostnameEquals", "value": "video-cf.spotifycdn.com" },
  "case": "both"
}
```

---

## Gabb Music

### 2026-08-18: album artwork (in-app, lock screen, Control Center) — cleanly blockable

**Trigger:** customer queue item asking whether album artwork can be blocked in the Gabb
Music app.

**Context:** `com.gabb.music`, installable on any iOS 14+ device (no Gabb phone required).
Not built on Apple Music or Spotify — white-labeled via Tuned Global, a B2B music
licensing platform. No free tier; needed a paid trial account to test.

**Tested:** USB capture on iPhone Air (iOS 26.6, new test device — old iPhone 12 mini
retired) while browsing/playing. Artwork and audio split across three random-subdomain
CloudFront hosts:

- `dd8l2wcg0g8nf.cloudfront.net` — **audio**. Blocking it killed playback; not a target.
- `dxfve6m7pg0pq.cloudfront.net` — **in-app artwork**. Verified clean via full
  delete+reinstall (rules out the cache false-positive that bit the Maps investigation).
- `d16npyvi7pcxgr.cloudfront.net` — **lock screen / Control Center artwork**, a sibling
  fetch distinct from the in-app host (same shape as the Apple Music `itunescloudd`
  finding). Confirmed on two never-before-played artists.

**Verdict:** cleanly blockable, no collateral (playback + both widgets tested clean).

**Shipped 2026-08-18:** new default (non-opt-in) block group `Gabb Music artwork`:

```json
{"a":{"case":"bundleIdContains","value":"com.gabb.music"},"b":{"case":"hostnameEquals","value":"dxfve6m7pg0pq.cloudfront.net"},"case":"both"}
{"a":{"case":"bundleIdContains","value":"com.gabb.music"},"b":{"case":"hostnameEquals","value":"d16npyvi7pcxgr.cloudfront.net"},"case":"both"}
```

**Residual risk:** unlike `mzstatic.com`/`images-na.ssl-images-amazon.com`, these are
auto-generated per-distribution CloudFront hostnames with no stability guarantee — could
go stale silently on a Gabb app update. Revisit if artwork reappears.

---

## Discord (Klipy GIFs)

### 2026-08-18: GIF picker/search blockable, sent GIFs are not

**Trigger:** customer report (thread w/ H. Stannie) — Discord's GIF picker slipping past
the blocker. Discord switched its default GIF provider from Tenor to Klipy in 2026, after
Google shut down Tenor's third-party API.

**Tested:** USB capture on `com.hammerandchisel.discord` while browsing, searching, and
sending GIFs.

- `static.klipy.com` — picker/search thumbnails.
- `images-ext-1.discordapp.net` — the actual GIF once sent. Confirmed via a
  precisely-timed test (sent at 14:31:02; the only flow in that window was this host).
  It's Discord's general external-image proxy — also carries link-preview embeds for any
  pasted URL — and the filter only sees hostname, not request path, so a Klipy GIF and an
  unrelated link preview are indistinguishable here. Too broad to block.

**Verdict:** partial win only. Picker/search can be blinded; a sent/received GIF still
renders. Shipped anyway as meaningful harm reduction — a kid can no longer browse/preview
to find explicit GIFs, only send blind.

**Shipped 2026-08-18** to the existing `GIFs` group:

```json
{
  "a": { "case": "bundleIdContains", "value": "com.hammerandchisel.discord" },
  "b": { "case": "targetContains", "value": "klipy.com" },
  "case": "both"
}
```
