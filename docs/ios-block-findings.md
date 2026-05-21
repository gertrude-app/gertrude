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

- **Root cause:** not rules / verdicts / dropped traffic / Family Controls. With the filter
  present every Minecraft flow is _allowed_ and traffic flows _more_ heavily than when it
  works, yet the app wedges. Cause is the per-flow verdict **gating inherent to the
  filter's data-path presence**: at launch Minecraft fires a burst of simultaneous flows,
  the gating serializes/stalls them, and its network-coupled UI freezes. Proven — a no-op
  allow-everything filter still hangs; removing the filter (Family Controls retained) makes
  it playable.
- **Unfixable on iOS:** a content filter can only return a per-flow verdict; the most
  permissive (`.allow()`) already hangs, and iOS has **no** flow-exclusion API
  (`NEFilterSettings` is macOS-only). No auto-mitigation either (can't detect app launch or
  self-disable the filter).
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

**Tested:** capture during favorite → navigate to album. Existing
`com.apple.Music`-scoped rules DROPped ~786 flows to `is1-ssl.mzstatic.com`, but 2
ALLOWs slipped through from `.com.apple.itunescloudd` (iCloud Music Library daemon).
Artwork bytes from itunescloudd's allowed fetches appear to be cached at a
system-level image cache shared with the Music app, so Apple Music's own DROPped
requests still find the artwork locally and render it.

**Verdict:** existing bundle scope (`com.apple.Music`) was too narrow. `itunescloudd`
is a sibling carrier hitting the same `ssl.mzstatic.com` host.

**Shipped 2026-05-15:** sibling rule added to the Apple Music group (SQL at
`logs/apple-music-itunescloudd-artwork-rule.sql`):

```json
{"a":{"case":"bundleIdContains","value":"itunescloudd"},"b":{"case":"targetContains","value":"ssl.mzstatic.com"},"case":"both"}
```

Re-test confirmed: 83 DROPs from itunescloudd during the next favorite/navigate
sequence, artwork no longer rendered. Note: BlockRule has no native OR, so this is a
parallel rule rather than a broadening of the existing one. `itunescloudd` also hits
`librarydaap`, `genius-*`, `p42-buy`, `pd.itunes.apple.com` — metadata, not artwork,
left allowed.

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

- Whether `cdn.groupme.com` is a fallback image CDN that would leak around the block.
- Whether normal chat-receive still works with the rule enabled (couldn't test — solo test
  group, no second human).

---

## Spotify

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
