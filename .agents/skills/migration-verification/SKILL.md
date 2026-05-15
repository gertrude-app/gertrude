---
name: migration-verification
description:
  Verify non-trivial database migrations (data backfill, column drops, FK
  retargets, type changes, dedup) by capturing pre-migration baseline state,
  running the up/down/up cycle through the user, and asserting expected
  outcomes at each step. Use when a migration touches data — not just schema.
---

# Migration Verification Skill

For migrations that change data (backfills, drops, FK retargets, transforms),
schema-shape checks alone don't catch silent corruption — a wrong WHERE clause
in a backfill can leave columns the right type and NOT NULL while pointing at
the wrong rows. This skill walks the migration through up → down → up while
asserting against per-row baseline data, not just shape.

Skip this for trivial migrations (adding a nullable column, adding an index,
renaming with no data movement).

## Process

1. **Capture baseline.** Before the migration runs, snapshot the state the
   migration will touch. Mix of:
   - **Per-row sample**: a small set of rows with their key fields (the source
     and target columns of any backfill). Sample size: enough to be
     representative but small enough to eyeball — 20-50 rows typically.
   - **Counts**: `SELECT count(*) FROM ...` for each affected table.
   - **Cross-table derivations**: the SQL that *should* hold after the
     migration. E.g., for a backfill of `new_col` from a joined table, write
     the join now so you can rerun it later to verify each row was backfilled
     from the right source.
   - **Schema fingerprint**: `\d table` output (columns, NOT NULL, FK names,
     indexes).

2. **Save baseline + verification SQL in `agent.ledger.<topic>.md`** at the
   task root. The `agent.ledger.*` pattern is gitignored — the ledger won't
   be committed but survives across sessions, which matters if the
   verification spans more than one conversation. Include:
   - What you captured and the SQL that captured it
   - The assertions you'll re-run after each migration step
   - Expected result for each (post-up, post-down, post-up-again)

3. **Ask the user to run `just swift migrate-up`.** Then re-verify. Do NOT
   apply or revert migrations yourself unless the user explicitly asks — the
   user controls schema-state transitions.

4. **After up: assert.** Run the cross-table derivations against the new
   state. Compare counts. Compare schema fingerprint to expected post-up
   shape. Report any discrepancy with specifics (which rows, what differs).

5. **Ask the user to run `just swift migrate-down`.** Then re-verify that
   baseline data is restored — counts match, sample rows match, schema
   fingerprint matches baseline (modulo cosmetic differences like column
   ordering that ALTER can't preserve).

6. **Ask the user to run `just swift migrate-up` again.** Re-verify post-up
   expectations. This catches down migrations that "look right" but corrupt
   state on the second up.

7. **Report final verdict** with the specific checks that passed.

## What to assert

Use judgment. Match the assertions to the migration's risk surface — the goal
is confidence, not exhaustiveness. Don't overfit on these patterns:

- **Backfill correctness**: for each baseline row, the migration's derivation
  must be re-checkable. E.g., if backfilling `tokens.install_id` from
  `installs.device_id = tokens.device_id`, capture both sides before and
  assert the new value matches the derivation after.
- **No data loss**: row counts preserved through up/down/up unless the
  migration intentionally deletes. If it does, count the deletions.
- **Constraint shape**: verify FK name, ON DELETE behavior, uniqueness, NOT
  NULL placement match expectations.
- **Round-trip data identity**: after down, the columns the migration touched
  should hold values identical to the baseline (or, for derived columns,
  re-derive cleanly).

## Don'ts

- Don't apply or revert migrations yourself. Hand each transition to the user.
- Don't skip the down → up cycle — it catches down-migration bugs that a
  one-way verification misses.
- Don't overfit assertions. A handful of high-signal cross-table checks beats
  hundreds of row-by-row equality checks.
- Don't commit the ledger. The `agent.ledger.*` glob is gitignored for a
  reason; don't fight it.
