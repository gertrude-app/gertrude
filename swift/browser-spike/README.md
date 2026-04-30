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
- [ ] Phase 3 — `WKContentRuleList` for subresources
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
