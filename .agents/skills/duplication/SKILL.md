---
name: duplication
description:
  Avoid and remove copy-pasted code in the Gertrude monorepo. Use when adding a test
  helper or fixture, reviewing a PR or diff for reuse, investigating `just dup`, or asked
  to deduplicate, extract, or consolidate code.
---

# Duplication

Search before creating a helper. Most duplication comes from not knowing a suitable helper
already exists.

## Before writing a helper or fixture

Search by both likely name and body shape. For API tests, also inspect `ApiTestCase`.

```bash
rg -n 'func (create|make|mock|stub|fake|seed|given)[A-Z]' --type swift swift/api/Tests
rg -n 'MarketingEmailSend.query' --type swift swift/api/Tests
rg -n '^\s+(func|var) ' swift/api/Tests/ApiTests/ApiTestCase.swift
```

If no suitable helper exists, put one used by multiple files in the appropriate shared
home—not as a `private` helper in the first test file that needs it.

| Kind                                     | Shared home                                          |
| ---------------------------------------- | ---------------------------------------------------- |
| API setup/factories                      | `swift/api/Tests/ApiTests/ApiTestCase.swift`         |
| API entity builders                      | `swift/api/Tests/ApiTests/Entities.swift`            |
| API mocks                                | `swift/api/Tests/ApiTests/Mocks/`                    |
| Mac helper used by multiple test targets | `swift/macapp/App/Sources/TestSupport/` (`public`)   |
| Mac helper used only by `AppTests`       | `swift/macapp/App/Tests/AppTests/TestSupport.swift`  |
| Podcasts / Music test support            | their target's existing `TestSupport` / fixture file |
| Cross-app Swift                          | an appropriate target under `swift/`                 |
| Shared web UI / logic                    | `web/ui/src/` / `web/shared/`                        |

## Finding and evaluating clones

```bash
just dup
just dup --tests
just dup --diff
```

`--diff` includes committed, staged, unstaged, and untracked edits. It is the required
review check; `just dup` is for existing repository debt.

Work in this order:

1. **Mechanical** — identical declarations. Extract within one target. If targets differ,
   inspect their package dependencies first: an existing common target may make the move
   easy. Do not add a new dependency merely to remove a tiny helper.
2. **Drifted** — near copies. Decide which behavior is correct before unifying them.
3. **Design** — similar structure requiring a refactor. Propose or isolate this work; do
   not fold it into a mechanical cleanup.

Leave intentional duplication when it protects a boundary or keeps distinct test scenarios
legible: migrations, PairQL versioned contracts, and enumerated test cases are common
examples. The test is whether a bug fix in one copy must also change the other.

Record deliberate cross-file duplication in the adjacent `duplication-ignore.json` with a
specific file pair and a real reason. Prefer that ledger over a broad glob or a new source
comment. Do not silence a finding merely because extraction is inconvenient.

## Validation

Run affected tests after an extraction, then `just dup --diff`. If you change the
detector, ledger, or CI gate, first read [detector maintenance](DETECTOR.md) and run
`just dup --self-test`.

## Limits

The detector compares whole declarations only. It cannot see copied blocks inside larger
functions or semantic duplication expressed with different vocabulary; normal review still
matters.
