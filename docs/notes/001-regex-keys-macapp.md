# 001 — Upgrading Macapp `domainRegex` keys to a real regex engine

_Date: 2026-05-04. Mac app cutoff: `2.9.3`._

## What we changed

Mac app `domainRegex` keys now use a real regex engine end-to-end (`NSRegularExpression`
on the client, `RegExp` on the dashboard, `caseInsensitive` on both). Before this work,
the feature was a tiny glob DSL pretending to be regex (`*` substituted for `.*`, `.`
force-escaped, no anchors honored), and every match-time evaluation used unanchored
`firstMatch` so a pattern like `*.edu` substring-matched `harvard.edu.attacker.com`.

## How we got here

A customer asked to unlock the entire `.edu` TLD. While exploring whether `domainRegex`
could express that, the feature itself turned out to be broken-by-design: a glob
masquerading as regex with several latent bugs and no real path to alternation, anchors,
or character classes — exactly the things a tech-savvy customer was asking for. So the
work pivoted from "support `.edu`" to "make the regex feature actually be regex."

## Why upgrade in place rather than add a new key type

We seriously considered three alternatives and rejected each:

- **Auto-anchor the existing glob DSL** (`^...$` around the compiled regex). Closes the
  substring-match footgun but doesn't unlock alternation, anchors, or character classes. A
  bandaid.
- **Add a new `regex` enum case alongside `domainRegex`.** Avoids touching old data, but
  forces (a) version-gating to ensure old Mac apps don't choke on the new case, _and_ (b)
  a permanent two-flavors UI on the dashboard ("the new regex" vs "the old regex"). Two
  flavors forever was the dealbreaker.
- **Bulk-migrate all 58 patterns to anchored real-regex form.** Rejected as a coordination
  nightmare — every existing customer becomes a migration risk on the Mac-app rollout.

The chosen path is in-place upgrade: existing rows stay as-is, the matcher becomes a real
regex engine, and the bulk of the legacy data gets retired _proactively_ via SQL before
any code ships.

## What anchored that decision: the production audit

We snapshotted every active `domainRegex` key in production — 58 keys across 4 parent
accounts. Findings:

- 46 / 58 patterns fail to even compile as raw `NSRegularExpression` (leading `*` is
  invalid regex).
- 12 / 58 compile but all 12 _semantically drift_ under raw-regex interpretation.
- 0 / 58 are safe to interpret as real regex without rewriting.
- Roughly two-thirds were `*.foo.bar`-shape patterns — exact behavioral equivalents to the
  existing `anySubdomain` key type. Authors apparently didn't realize `anySubdomain` was a
  better fit.

So _almost all_ of the surviving `domainRegex` rows weren't really regex at all. A
pre-flight psql script handled the bulk: junk deletion, mechanical conversion of
`*.foo.bar`-shape patterns to `anySubdomain` keys, and special-casing the public-keychain
stragglers (`clients*.google.com` → enumerated `anySubdomain` keys,
`*-contacts.icloud.com` deleted outright). That dropped the residual real-regex population
to ~2–3 keys across one or two customers — a small enough surface that we can handle
remaining customers by direct outreach in Phase 5 instead of automation.

## Backwards compatibility: lenient decode + server-side gate

The single architectural insight that made this work tractable was realizing that the Mac
app's `Key.DomainRegexPattern.init?` is failable, and `Key+Codable.swift` translated a
nil-init into a thrown `ModelDecodingError`. Because `RuleKeychain` and `RuleKey` both
synthesize `Codable`, _one_ bad regex key kills the entire `CheckIn_v2` decode — not just
the offending key, the whole API response. CheckIn dies, sync stops, the Mac app freezes
on cached data. Every migration scheme then becomes a coordination problem.

Two changes break the deadlock:

1. **Lenient decode (Mac app, ships in 2.9.3).** `Key.DomainRegexPattern.init` becomes
   non-failable, stores the pattern verbatim, and the matcher silently returns false for
   uncompilable or inert patterns. New Mac apps tolerate any data, including legacy globs
   they can't usefully match.
2. **Server-side `appVersion` gate (API, ships before the Mac app).** The CheckIn handler
   replicates the legacy `init?` logic and filters out any `domainRegex` key that would
   fail it for clients reporting `appVersion < 2.9.3`. Old Mac apps see a partial keychain
   (legacy-incompatible keys silently omitted) but never crash.

The gate is what protects the existing Mac-app population from any newly-authored
real-regex pattern, _by virtue of the deploy order_ (API ships first). No customer
discipline required, no migration timing required.

## Why not auto-anchor

The matcher uses `firstMatch` (substring), so an unanchored `\.edu` substring-matches
`harvard.edu.attacker.com`. We deliberately don't auto-anchor: real regex authors expect
to control anchoring themselves, and silently rewriting their patterns would be more
surprising than the explicit footgun. The dashboard help blurb calls this out instead.

## Strict-on-write, lenient-on-read

The dashboard `SaveKey` resolver runs strict validation (compile + heuristics: length cap
200, reject empty-string match, reject canary-hostname match, reject patterns with no
literal alphanumeric content) and rejects authoring of pathological patterns with useful
error messages. The same heuristics run client-side in the dashboard form. But the
read/match path stays lenient: any pattern that survives `Codable` decode either compiles
and matches, or fails to compile and silently never matches. Invalid data in the wild
can't ever break decode again.

We deliberately skipped exhaustive ReDoS detection. Threat model is "parent attacks own
filter" — not worth engineering against. If it ever becomes a problem, we can switch to
RE2 or add complexity validation later.

The API gate can be dropped once the legacy Mac-app population is small enough — a trivial
DB query (`SELECT count(*) FROM computer_users WHERE app_version < '2.9.3'`) tells us
when.
