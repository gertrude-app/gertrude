# browser-spike

Throwaway WKWebView prototype to validate the architecture for a Gertrude-aware Mac
browser. See `../../claude.task.md` for the full plan and per-phase findings.

## Build & run

```sh
cd swift/browser-spike
swift build
.build/debug/BrowserSpike
```

Requires macOS 14+ and the Xcode command-line tools (Swift 6.0+ toolchain).

The app launches without an `.app` bundle. Dock icon + menu bar work because we
explicitly `setActivationPolicy(.regular)` and install a minimal `NSApp.mainMenu`.
If we end up needing entitlements (e.g. for code-signed XPC, default-browser
registration) we'll add an `.xcodeproj` in a later phase, but not until forced.

## Status by phase

- [x] Phase 1 — single window, omnibar, back/forward/reload, Web Inspector enabled
- [x] Phase 2 — `decidePolicyFor` allowlist + iframe blocking
- [x] Phase 3 — `WKContentRuleList` for subresources
- [ ] Phase 4 — minimum viable browser chrome
- [ ] Phase 5 — IPC stub + default-browser registration

## Recommendation

Too early — fill in after phase 5. Phase 2 confirms the core thesis is plausible:
synchronous policy decisions on every top-frame and iframe navigation, including
nested iframes, are reachable through `WKNavigationDelegate.decidePolicyFor`.

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
