# MacSim VM Witness Findings

Durable evidence summary for OS behavior modeled by `VirtualMac` and
`MacExplorer`. This file records what the simulator is allowed to assume about
macOS and NetworkExtension behavior. It is intentionally not a step-by-step
operational runbook.

## Purpose

MacSim tests the app against a simulated world, not directly against macOS. Any
simulated OS behavior that can affect verdicts should have one of:

- A VM witness summarized here.
- A production-code `sync:<id>` marker when the behavior is not OS behavior, but a
  mirror of Gertrude Swift implementation.
- A clear note that the behavior is provisional or outside the current model.

`mac-explorer.md` describes the explorer and the `sync:<id>` convention.

## Evidence Matrix

| Area | Sim model | Evidence basis | Status | Gaps / next audit |
| --- | --- | --- | --- | --- |
| M1 provider lifecycle | Enabled provider relaunch creates a fresh filter process | VM witness | Accepted for boot/relaunch paths | App-driven stop/start/replace state strings are out of model until explicitly added |
| M1 durable reload | Fresh filter reloads `Persistent.State`; memory state is empty | VM witness plus production `Filter.loadedPersistentState` | Accepted | Keep `sync:56acb165` with reload behavior |
| M3 provider absence | With no provider process, MacSim returns `.allow` | VM witness | Accepted for recovery scenarios | Public docs should keep this high level |
| M4 verdict finality | Already-allowed simulated connections are not rechecked until reboot | VM witness | Accepted at socket-lifetime granularity | Exact socket lifetime edges are abstracted |
| M5 single-user reconnect | App/provider relaunch re-establishes app/filter XPC | VM witness | Accepted | None for single-user reconnect |
| M5 per-user routing | One retained app connection per uid; targeted sends route by uid; logs route to most recent | Production `XPCManager` behavior, VM witness, unit tests, simulator `sync:31af50b5` markers | Accepted | Re-audit if `XPCManager` routing semantics change |
| Flow delivery | New flows go through `handleNewFlow`; deferred flows can continue through `handleOutboundData` | Production `FilterProxy` code and tests; partial OS understanding | Accepted for current explorer universe | Add VM evidence before modeling broader browser/socket distinctions |
| App liveness | App messages refresh `macappsAliveUntil`; heartbeat reaps stale liveness | Production `Filter` behavior plus unit tests; simulator `sync:ded93bed` and `sync:d8356a06` markers | Accepted | Re-audit if heartbeat interval or liveness buffer changes |
| Clock control | Sim uses injected time for suspension/downtime decisions | Production seam `FilterSuspension.isActive(at:)`; simulator `sync:086c6b0b` marker | Accepted | Guard against reintroducing raw `Date()` in filter decisions |
| Key matching oracle | Oracle independently derives exact-domain hosts for a small key universe | Independent test oracle, not production `KeychainIndex` | Accepted for exact-domain unrestricted rules | Expand separately for schedules, regex, subdomains, app scopes |

## Witnessed Behavior

### M1: Provider lifecycle and durable reload

An enabled NetworkExtension provider is relaunched by macOS after reboot and
after provider termination. Each relaunch creates a fresh filter process. The
fresh process reloads durable filter state from its own defaults domain, while
in-memory state such as app liveness, live suspensions, and downtime pauses is
lost.

MacSim models this by constructing a new `FilterExtensionProcess` on boot or
relaunch and by reloading `Persistent.State` from `filterDisk`.

### M3: Provider absence

When no provider process is running, traffic is outside filter enforcement until
the provider is relaunched. This is modeled as `.allow` while `filterProcess` is
nil.

MacSim scenarios use this only to verify app/filter recovery semantics. The
public tests and docs should avoid carrying operational reproduction details.

### M4: Verdict finality

A connection that was already allowed remains usable for that socket's lifetime.
Later provider relaunch or rule reload affects new flows, not already-verdicted
connections. A full device reboot clears those open connections.

MacSim models this with `openConnections`: new flows are evaluated through the
filter, while existing simulated connections are not rechecked until reboot.

### M5: App/filter XPC lifecycle

The single-user reconnect path is witnessed: app or provider relaunch leads to a
new app/filter XPC connection.

The multi-user path was witnessed July 16, 2026 in a macOS Tahoe VM with two
simultaneously logged-in users, Franny (uid 502) and Suzy (uid 503), showing the
filter's retained app-connection map and each app's effective uid:

| Observation | Result |
| --- | --- |
| Suzy connected before Franny | Filter map contained `users=[503]` and received Suzy rules |
| Franny connected through Fast User Switching | Filter map became `users=[502,503]` |
| Suzy remained alive after Franny connected | Filter continued receiving app-alive messages from uid 503 |
| Franny opened blocked-request streaming and triggered blocks | Filter targeted uid 502; Franny app received messages as current uid 502 |
| Suzy opened blocked-request streaming and triggered blocks | Filter targeted uid 503; Suzy app received messages as current uid 503 |
| Filter logs flushed while both users were connected | Logs routed to the most recently attached app connection |

This accepts the simulator's M5 per-user XPC model for the current app/filter
contract:

- One retained app connection per effective user id.
- Same-user reconnect replaces that user's connection.
- Connection invalidation removes only the current matching entry.
- Targeted filter-to-app messages route by user id.
- Filter logs route to the most recently attached app connection.

The VM run did not separately exercise quitting and relaunching one user while
the other stayed connected; that same-user replacement behavior is covered by
`XPCManager` unit tests, and the routing policy itself (replace-on-reconnect,
most-recent-wins for logs) is the shared `Core.UserConnectionMap` executed by
both the production filter and the simulator; `sync:31af50b5` markers cover the
remaining mirrored delivery/invalidation behavior.

## Still Useful To Audit

- App-driven stop/start/replace extension-state strings, if MacSim starts
  modeling those states.

## VM Snapshot

The witness work used a reusable VM snapshot with the app onboarded and the
system extension approved. That snapshot lets future witness runs start from a
known app/filter state without repeating GUI setup.
