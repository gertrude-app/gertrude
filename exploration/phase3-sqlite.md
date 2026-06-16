# Phase 3: SQLite / GRDB Probe

## Verdict: BLOCKED — sqlite3.h Not in Android Sysroot (Likely Solvable)

GRDB does not build for Android out of the box because the Swift Android SDK's sysroot does not include `sqlite3.h`. However, this appears to be a configuration/tooling gap rather than a fundamental impossibility.

## What Was Tested

Probe package at `exploration/phase3/grdb-probe/` with:
- `GRDB.swift` version `7.0.0+` (latest resolved: see Package.resolved)
- Simple read/write test (create table, insert, query episodes)
- Skip `native` mode with `skip-foundation`

## Build Command

```bash
source ~/.swiftly/env.sh && PATH="$(brew --prefix openjdk@17)/bin:$HOME/skip-bundle/bin:/opt/homebrew/bin:$PATH" \
  JAVA_HOME=$(brew --prefix openjdk@17) ANDROID_HOME=~/Library/Android/sdk \
  ~/skip-bundle/bin/skip android build \
  --package-path exploration/phase3/grdb-probe --product GRDBProbe
```

## Failure

```
GRDB.swift/Sources/GRDBSQLite/shim.h:1:10: error: 'sqlite3.h' file not found
GRDB/Core/Configuration.swift:10:8: error: could not build C module 'GRDBSQLite'
```

GRDB uses a `.systemLibrary` target named `GRDBSQLite` that wraps the system's sqlite3. On Apple platforms, `sqlite3.h` is part of the OS SDK. On Linux, it's installed via `apt install libsqlite3-dev`. On Android, the Swift SDK sysroot does not include sqlite3 headers.

## Root Cause Analysis

### What the Android sysroot has

The Swift Android SDK sysroot at:
```
~/.swiftpm/swift-sdks/swift-6.2.3-RELEASE_android.artifactbundle/swift-android/ndk-sysroot/
```

Contains standard Android NDK headers (bionic libc, OpenGL, audio, etc.) but **no `sqlite3.h`** and no `libsqlite3.so` stub.

### Why SQLite isn't exposed

Android devices have SQLite built into the OS (every Android device has it), but the Android NDK historically discouraged direct native sqlite3 access from C/C++ code. The NDK sysroot does not expose `sqlite3.h` because Google wants apps to use the Java `android.database.sqlite` API instead.

Since API 28, there is an unofficial path (`libsqlite.so` is on-device), but it's not in the NDK stubs, so it can't be linked at compile time via the standard sysroot.

### GRDB 7.10.0 Android claims

GRDB 7.10.0 (Feb 2025) added "Android and Windows adjustments" by `@marcprux`. However, from examining the package source, these adjustments appear to be code-level guards in GRDB itself, not a solution to the missing sysroot header. GRDB still requires `sqlite3.h` to be available.

The `@marcprux` contributor is affiliated with Skip.tools — so this work was likely done *assuming* the sqlite3 header would be provided through a different mechanism (e.g., bundled sqlite amalgamation).

## How This Could Be Fixed

### Option A: Bundle SQLite amalgamation (most viable)

GRDB supports `CustomSQLite` — building against a bundled `sqlite3.c`/`sqlite3.h` rather than the system library. This is used by GRDB+SQLCipher. The same approach could work for Android:

1. Download the SQLite amalgamation
2. Create a custom target in Package.swift that compiles `sqlite3.c` for Android
3. Use GRDB's `CustomSQLite` build path

This is non-trivial but is a known pattern. GRDB's `Tests/CustomSQLite/` directory shows how to do this.

### Option B: Skip's skip-sqlite package

Skip has a `skip-sqlite` package that wraps SQLite for cross-platform use. It likely handles the Android sysroot issue by bundling or differently configuring SQLite. This is worth investigating as it may provide the right path.

### Option C: Use Android's Java SQLite API via JNI bridge

Since GRDB is not the goal (SQLite access is), an alternative is to use Skip's native bridge to call Android's `android.database.sqlite` Java APIs directly. This would not give you GRDB's nice Swift API, but would provide SQLite access.

## What This Means for the AM App

The AM app uses `sqlite-data` from Point-Free, which is Apple-only and definitely doesn't work on Android. GRDB was the candidate replacement. The result:

- **`sqlite-data` (PFW)**: Complete blocker — Apple platforms only
- **GRDB as replacement**: Blocked by missing sysroot header, but potentially solvable
- **Path forward**: Investigate `skip-sqlite` or the SQLite amalgamation approach before declaring SQLite fully blocked

## Skip's Official Answer: skip-sql

Skip has a first-party package `skip-sql` ("A SQLite interface for Skip iOS+Android projects") at `https://source.skip.tools/skip-sql.git` (also mirrored at `https://github.com/skiptools/skip-sql`).

It solves the Android sysroot problem by **bundling the SQLite amalgamation** — it compiles `sqlite3.c` directly as a C target (`SQLExt`), providing its own headers. No system SQLite needed.

The API is Skip's own Swift wrapper around SQLite, not GRDB. It provides:
- `SkipSQL` — base SQLite Swift API
- `SkipSQLPlus` — extended version with additional features

This is the recommended path for SQLite on Skip Android. A follow-up probe using `skip-sql` directly should be attempted (see phase3-skip-sql.md if it exists, or add it to the task list).

## Next Step Recommendation

Try `skip-sql` directly rather than GRDB:
1. Create a probe with `skip-sql` as the dependency
2. Test basic CRUD operations through its API

GRDB as a direct dependency is blocked, but SQLite access on Android via `skip-sql` is likely viable. The question becomes whether `skip-sql`'s API is sufficient for what the AM app needs, or whether the effort of porting from GRDB patterns to `skip-sql` patterns is reasonable.

This is a **blocked but solvable** situation via `skip-sql`, not a hard blocker.
