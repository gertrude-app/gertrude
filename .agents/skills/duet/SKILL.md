---
name: duet
description: Write queries and mutations with Gertrude's custom Duet/DuetSQL ORM.
---

# Duet / DuetSQL

## Query Style

Import `DuetSQL` when using the fluent query DSL. It provides operators like `==`,
`!=`, `<`, `>`, `.&&`, `.||`, and `|=|`.

Prefer operator-style predicates over explicit enum cases:

```swift
import DuetSQL
try await Parent.query()
  .where(.email == email)
  .where(.deletedAt == nil)
  .all(in: db)
```

Use `.deletedAt == nil` / `.deletedAt != nil`, not `.isNull(.deletedAt)` or
`.not(.isNull(.deletedAt))`. For grouped logic, prefer
`(.deletedAt == nil .|| .deletedAt > cutoff) .&& .email == email`.

## Transactions

Duet has `db.transaction { tx in ... }`. In the API target, prefer
`db.withTransaction { tx in ... }` when dependency values are used inside the closure;
it carries dependency context across SQLKit/Postgres and avoids surprising test failures.

Use transactions for rare and IMPORTANT multi-step writes that must commit or roll back together to preserve critical business invariantes. Our customer base is small, and our API almost never crashes, so we don't need to be over defensive.
Do not wrap every resolver, single insert, or low-value cleanup by default; they add
complexity and may cost a little performance.

## Backdating `createdAt` in tests

If you need to backdate `createdAt` for tests, use the `modifyCreatedAt` helper.

## Models and column types

Model structs are declared with `@DuetModel(schema: "parent", table: "dash_announcements")`,
which generates `Id`, `CodingKeys`, and `insertValues` from the stored properties — never
hand-write those. Column values bind via `PostgresBindable`; primitives, `Date`, `UUID`,
`Tagged`, and optionals are built in. For custom property types, add a conformance in
`api/Sources/Api/Models/Models+DuetSQL.swift`:

- string-backed enum → conform to `PostgresRawBindable` (binds `rawValue`); the column is
  `text` with a `CHECK` constraint. NEVER create a Postgres enum type (`CREATE TYPE ... AS
  ENUM`) — this codebase deliberately eliminated them because check constraints are far
  easier to evolve
- codable type stored as jsonb → conform to `PostgresJsonable`
