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
- [ ] Phase 2 — `decidePolicyFor` allowlist + iframe blocking
- [ ] Phase 3 — `WKContentRuleList` for subresources
- [ ] Phase 4 — minimum viable browser chrome
- [ ] Phase 5 — IPC stub + default-browser registration

## Recommendation

Too early — fill in after phase 5.

## Notes

- We use `WKWebsiteDataStore.nonPersistent()` so each launch is clean. No cookies,
  no cache, no localStorage survives a relaunch. Simplifies the spike; flip later
  if/when persistence is wanted.
- Logs go to stdout. `print` was block-buffered when stdout was redirected, so
  `main.swift` sets `setbuf(stdout, nil)`.
