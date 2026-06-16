# Phase 3: skip-sql (SkipSQLPlus) Probe

## Verdict: SUCCESS — SQLite Works on Android via SkipSQLPlus

`SkipSQLPlus` from Skip's official `skip-sql` package builds successfully for Android. This is the path for SQLite on Android.

## What Was Tested

Probe package at `exploration/phase3/skip-sql-probe/` using:
- `skip-sql` version `0.16.0` (latest pre-1.0)
- `SkipSQLPlus` product (not `SkipSQL` — see Key Finding below)
- Simple CRUD: create table, insert 3 rows, query all

## Build Result

```
Build of product 'SkipSQLProbe' complete! (1.58s)
```

Clean success. No errors. The library compiled, linked, and produced `libSkipSQLProbe.so`.

## How It Works

`skip-sql` has two products:
- `SkipSQL` — uses the system SQLite. On Apple platforms this is `SQLite3` (built into the OS). On Android via Skip JVM/Kotlin path, it uses `SQLiteJNALibrary`. But via the Swift Android SDK path (non-Skip transpiler), it hits a `fatalError("no platform SQLiteCLibrary available; use SkipSQLPlus instead")`.
- `SkipSQLPlus` — bundles the SQLite amalgamation (`sqlite3.c` compiled from source) along with libtomcrypt. This bypasses the system header problem entirely.

The `SQLiteConfiguration.plus` static property selects the bundled library:
```swift
#if SKIP
SQLiteConfiguration(library: SQLPlusJNALibrary.shared)
#else
SQLiteConfiguration(library: SQLPlusCLibrary.shared)  // compiled sqlite3.c
#endif
```

## Working Code

```swift
import SkipSQLPlus
import Foundation

func runSQLProbe() throws -> String {
    let db = try SQLContext(path: ":memory:", configuration: .plus)

    try db.exec(sql: "CREATE TABLE episode (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, duration_seconds INTEGER NOT NULL)")

    try db.exec(sql: "INSERT INTO episode (title, duration_seconds) VALUES (?, ?)",
                parameters: [.text("Episode 1: Intro"), .long(1800)])
    try db.exec(sql: "INSERT INTO episode (title, duration_seconds) VALUES (?, ?)",
                parameters: [.text("Episode 2: Deep Dive"), .long(3600)])

    let rows = try db.selectAll(sql: "SELECT id, title, duration_seconds FROM episode ORDER BY id")
    var results: [String] = []
    for row in rows {
        if case .text(let title) = row[1], case .long(let duration) = row[2] {
            results.append("\(title) (\(duration)s)")
        }
    }

    return "Fetched \(results.count) episodes: \(results.joined(separator: ", "))"
}
```

## API Notes

The `SkipSQLCore` API (used by both SkipSQL and SkipSQLPlus) is lower-level than GRDB:
- Parameters use `SQLValue` enum: `.text(String)`, `.long(Int64)`, `.real(Double)`, `.blob(Data)`, `.null`
- `exec(sql:parameters:)` for write operations
- `selectAll(sql:parameters:)` returns `[[SQLValue]]` for raw queries
- `cursor()` for streaming results
- Also has `SQLCodable` protocol for ORM-style access (higher level)

There is also a `SQLContext.query<T: SQLCodable>()` API for type-safe queries — this is the higher-level path and may be closer to what the AM app uses with GRDB.

## Skip Version Note

`skip-sql` is at `0.16.0` — it hasn't reached 1.0 yet. The API may have breaking changes before 1.0.

## Implications for AM App

This is a significant positive finding:

1. **SQLite is accessible on Android** via `SkipSQLPlus`
2. The API is different from both GRDB and PFW's `sqlite-data`/`structured-queries`
3. Any SQLite-using code will need to be ported to `SkipSQLCore` API (or wrapped behind an abstraction)
4. The `SQLCodable` protocol may allow some ORM-like patterns but it's not as rich as GRDB

The migration path would be:
- Define a platform abstraction layer (protocol) for database operations
- Implement with `SkipSQLPlus` on Android, with GRDB or `sqlite-data` on iOS
- This is a clean seam and is the recommended cross-platform pattern

## What This Replaces

The AM app uses:
- `sqlite-data` (PFW) — Apple only, **must be replaced**
- `swift-structured-queries` (PFW) — the query builder, Apple only, **must be replaced**

Both get replaced by `SkipSQLPlus`/`SkipSQLCore` on Android, or wrapped behind an abstraction used by both platforms.
