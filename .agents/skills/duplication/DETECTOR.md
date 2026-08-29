# Duplication detector maintenance

Read this only when changing `find-duplication.mjs` or `duplication-ignore.json` in this
directory, or `.github/workflows/duplication.yml`.

## Purpose and gate

The detector is a deterministic, offline candidate generator. It compares Swift,
TypeScript, and TSX declarations, then reports four tiers:

| Tier | Meaning | CI behavior |
| --- | --- | --- |
| `mechanical` | Exact cross-file declaration | Fails `--diff` |
| `drifted` at 90% or higher | Likely lightly edited paste | Fails `--diff` |
| Other `drifted` | Similar code with meaningful divergence | Reports only |
| `design` / `same-file` | Refactor candidate or repeated cases | Reports only |

The gate intentionally does not fail on lower-similarity findings. Blocking those trains
contributors to suppress legitimate parallel tests instead of acting on actionable copies.
Calibrate the 90% threshold from real PRs: raise it if justified ignores become common;
lower it only when obvious lightly edited copies repeatedly pass.

`--diff` must include changes committed since the merge base plus staged, unstaged, and
untracked source files. That makes the command useful during local work and preserves CI
coverage.

## Intentional-duplication ledger

Each `intentionalPairs` entry must name both sides and explain the decision. Prefer exact
file pairs. A broad glob can hide a future accidental clone, so use one only for a genuine,
stable category such as append-only migrations.

Use the ledger for a deliberate boundary or semantically distinct tests—not for a clone
that should have been extracted. `--all` audits ignored findings.

## Self-test

Run:

```bash
just dup --self-test
```

The self-test has no network or repository-data dependency. When fixing detector behavior,
add a regression assertion at the lowest useful seam, and run it before updating the CI
gate. It should cover parser behavior, matching/ignore behavior, changed-file selection,
and gate policy; keep the assertion count derived rather than hard-coded.

Keep the script source free of raw control bytes—write separators as escapes such as
`\u0001`—so Git continues to render a reviewable text diff.

## Constraints

This is heuristic tooling, not a parser or a semantic analyzer. It deliberately misses
duplicated blocks inside larger declarations and code expressed with different vocabulary.
Do not increase its scope with embeddings or a costly service unless the existing report
has demonstrated a persistent, high-value blind spot.
