# browser-spike

Throwaway WKWebView prototype to validate the architecture for a Gertrude-aware Mac
browser. See `../../claude.task.md` for the full plan and per-phase findings.

## Build & run

```sh
cd swift/browser-spike

# Plain SPM run (single-process, in-process Allowlist)
swift build
.build/debug/BrowserSpike

# Build as a real .app bundle (registers with LaunchServices)
./scripts/bundle.sh
open dist/BrowserSpike.app

# Run with the IPC policy stub instead of in-process allowlist
.build/debug/PolicyStub &
SPIKE_USE_IPC=1 .build/debug/BrowserSpike
```

Requires macOS 14+ and the Xcode command-line tools (Swift 6.0+ toolchain).

`scripts/bundle.sh` produces `dist/BrowserSpike.app` — a self-contained bundle
with `Info.plist` (declaring http/https URL types), an ad-hoc code signature,
and `lsregister`-driven LaunchServices registration. Once registered, you can
deliver URLs to it from any other app:

```sh
open -b com.gertrude.browser-spike https://news.ycombinator.com
```

…and `application(_:open:)` will fire in the running app. To make it the
system default browser, set it manually in **System Settings → Default web
browser** (macOS prompts for confirmation).

## Status by phase

- [x] Phase 1 — single window, omnibar, back/forward/reload, Web Inspector enabled
- [x] Phase 2 — `decidePolicyFor` allowlist + iframe blocking
- [x] Phase 3 — `WKContentRuleList` for subresources
- [ ] Phase 4 — minimum viable browser chrome (skipped intentionally)
- [x] Phase 5 — IPC stub + default-browser registration

## Recommendation

**Proceed with WKWebView.** Every load-bearing question the spike was meant to
answer landed on the favorable side:

- The policy hooks in `WKNavigationDelegate.decidePolicyFor` are synchronous,
  see every top-frame and subframe navigation including nested iframes, and
  expose enough metadata (`navigationType`, `sourceFrame`, `targetFrame`) to
  reason about the decision.
- `WKContentRuleList` covers the subresource layer (scripts, images, fetches)
  with `if-domain` / `unless-domain` / `resource-type` discrimination, and
  recompiles fast enough (50k rules in ~200 ms) that policy changes don't need
  to be batched.
- A separate `.app` bundle with `CFBundleURLTypes` registers as a default-browser
  candidate via `lsregister` alone — no Xcode project required for the spike.
- IPC to a separate policy daemon adds ~5 ms RTT on localhost. Well below the
  jank threshold. Failure of the daemon is recoverable (fail-closed with a
  block page) rather than silent.

What still needs to happen *before* this is a product, in rough order of
importance:

1. Browser chrome (tabs, JS dialogs, popups, downloads, find-in-page). This is
   the long, unglamorous tail. Phase 4 of the plan sketched the surface area;
   this spike skipped it intentionally.
2. Real IPC channel: `NSXPCConnection` with code-signing-identity verification
   on the daemon side, persistent channel rather than per-decision request.
3. Production build pipeline: real Developer ID signing, notarization,
   Sparkle (or whatever).
4. Validation against the *real* Gertrude system network filter — confirm the
   trust model ("filter trusts the browser process by team ID, browser
   self-enforces internally") works in practice. Could not be tested in the
   spike.
5. Service-worker behavior. Not provoked during the spike; the risk of a
   service worker bypassing our policy hooks remains an open question. If
   that turns out to be a real problem, it's a CEF reason.

The fallback to CEF is real but is now a clearly second-best option: we'd
inherit a 4-week security treadmill and ~150 MB of binary weight in exchange
for marginally more API surface, none of which was needed by the spike.

## Notes

- We use `WKWebsiteDataStore.nonPersistent()` so each launch is clean. No cookies,
  no cache, no localStorage survives a relaunch. Simplifies the spike; flip later
  if/when persistence is wanted.
- Logs go to stdout. `print` was block-buffered when stdout was redirected, so
  `main.swift` sets `setbuf(stdout, nil)`.
- The hardcoded allowlist lives in `Sources/BrowserSpike/NavigationPolicy.swift`.
  Hosts match exactly or as a suffix (`wikipedia.org` covers `en.wikipedia.org`).
- `SPIKE_INITIAL_URL` env var picks the initial load. Useful values:
  - `spike:embeds` — fixture page with allowed/blocked iframes incl. nested
  - `spike:navtypes` — fixture page that fires every `WKNavigationType`
  - `spike:rules` — fixture page that probes content-rule subresource blocking
  - `spike:recompile` — re-compiles the rule list at 100/1k/5k/25k/50k rules and
    prints timings
- `SPIKE_USE_IPC=1` — route every navigation decision through the policy stub
  HTTP server (default port `127.0.0.1:7717`). Without this, the in-process
  hardcoded `Allowlist` is used.
- `SPIKE_STUB_PORT=NNNN` (set on `PolicyStub`) — alternate listen port.
- `SPIKE_STUB_DELAY_MS=N` (set on `PolicyStub`) — inject artificial latency on
  every reply, to feel out how an IPC RTT translates to navigation jank.

## Sample policy logs

Allowed iframe + blocked iframes + nested iframe (from `spike:embeds`):

```
[nav] ALLOW    kind=mainFrame type=other         url=https://example.com/spike-embeds source=
[nav] ALLOW    kind=subframe  type=other         url=https://en.wikipedia.org/wiki/HTTP source=https://example.com/spike-embeds
[nav] BLOCK-SUB kind=subframe type=other         url=https://www.youtube.com/embed/...  reason=host 'www.youtube.com' not in allowlist
[nav] BLOCK-SUB kind=subframe type=other         url=https://www.facebook.com/plugins/...
[nav] ALLOW    kind=subframe  type=other         url=about:srcdoc                       source=https://example.com/spike-embeds
[nav] BLOCK-SUB kind=subframe type=other         url=https://www.youtube.com/embed/...  source=about:srcdoc
```

Top-frame block (omnibar entry to `https://www.cnn.com`):

```
[nav] load url=https://www.cnn.com
[nav] BLOCK-MAIN kind=mainFrame type=other       url=https://www.cnn.com/               reason=host 'www.cnn.com' not in allowlist
[nav] ALLOW      kind=mainFrame type=other       url=about:blocked
```

`navigationType` cheat sheet (from `spike:navtypes`):

| Trigger                                       | `navigationType`   |
| --------------------------------------------- | ------------------ |
| omnibar / `loadHTMLString` / programmatic     | `other`            |
| `<a>` click (incl. JS-driven `el.click()`)    | `linkActivated`    |
| `<form>` submit                               | `formSubmitted`    |
| `location.href = ...`, `location.replace(...)`| `other`            |
| back / forward                                | `backForward`      |
| reload                                        | `reload`           |

## Content-rule probe results

From `spike:rules` (top-level `https://example.com/spike-rules`):

| Probe              | Resource type | URL                                            | Outcome   |
| ------------------ | ------------- | ---------------------------------------------- | --------- |
| ga-tracker         | script        | `www.google-analytics.com/analytics.js`        | blocked   |
| youtube-api        | script        | `www.youtube.com/iframe_api`                   | blocked   |
| httpbin-script     | script        | `httpbin.org/anything?as=script`               | blocked   |
| httpbin-image      | image         | `httpbin.org/image/png`                        | loaded    |
| placeholder-ok     | image         | `placehold.co/40x40.png`                       | loaded    |
| ws-attempt (fetch) | (websocket)   | `wss://www.google-analytics.com/socket`        | failed    |

The httpbin pair confirms `resource-type: ["script"]` is the discriminator —
the same host is reachable via image but not via script. The wss row is
*inconclusive*: rule-blocked vs. server-rejected handshake can't be told apart
from the page side. WebKit docs indicate `WKContentRuleList` does not see
WebSocket traffic; if we need to enforce there, it has to be at the system
network filter / `decidePolicyFor` for the upgrade request.

## IPC stub round-trip

```
[ipc] decided in   5 ms allow=true                   # no-op stub on localhost
[ipc] decided in 212 ms allow=true                   # SPIKE_STUB_DELAY_MS=200
[nav] BLOCK-MAIN reason=daemon unreachable (fail-closed)   # stub not running
```

`PolicyStub` is a tiny `Network.framework` HTTP server. `IPCPolicyClient` is a
`URLSession` actor with a 500 ms request timeout. Failure → fail-closed +
"Gertrude daemon unreachable" block page. Production should swap this for
`NSXPCConnection` (persistent channel, code-signing-identity-verified).

## Rule-list compile cost

```
[rules] compiled baseline rules in 0.002s
[rules] recompiled with 103   total rules in 0.003s
[rules] recompiled with 1003  total rules in 0.094s
[rules] recompiled with 5003  total rules in 0.021s
[rules] recompiled with 25003 total rules in 0.095s
[rules] recompiled with 50003 total rules in 0.190s
```

The 5003 outlier is suspicious — `WKContentRuleListStore` persists compiled
lists by identifier across launches, and our `spike:recompile` per-run unique
suffix may not be enough to defeat all caching. Order-of-magnitude conclusion:
even 50k rules compile in well under a second; recompiling on policy change
is cheap.
