---
title: 'Get user id from NEFilterFlow.sourceAppAuditToken'
date: '2021-04-19T12:55:43.000Z'
slug: macos-user-id-from-sourceappaudittoken
description:
  When building a Content Filter System extension for Mac OS, the instance of
  `NEFilterFlow` you receive in your `NEFilterDataProvider` class doesn't have much
  information (apart from the not-to-be-relied-upon `flow.description` string). Deriving
  useful data from these objects is tricky, and poorly documented.
category: engineering
---

When building a _Content Filter_ System extension for Mac OS, the instance of
`NEFilterFlow` you receive in your `NEFilterDataProvider` class doesn't have much
information (apart from the not-to-be-relied-upon `flow.description` string). Deriving
useful data from these objects is tricky, and poorly documented.

One thing I wanted to know was how to trace the flow back to a **user** on the system. The
flow has a process id (at least, the description shows that it knows about the pid), so
this info should be derivable. Turns out there is another _almost entirely undocumented_
low-level function you can call into to get this info: `audit_token_to_ruid()`. Thanks to
Quinn and Matt on [this thread](https://developer.apple.com/forums/thread/677517) for
pointing me in the right direction. Here's some working code from my implementation, using
the `sourceAppAuditToken` of the `NEFilterFlow` instance to derive the user id:

```swift
import Foundation

protocol SourceAppAuditor {
  func userId(fromAuditToken auditToken: Data?) -> uid_t?
}

class CachingSourceAppAuditor: SourceAppAuditor {
  private var userIdMap: [Data: uid_t] = [:]

  func userId(fromAuditToken auditToken: Data?) -> uid_t? {
    guard let auditToken = auditToken else {
      return nil
    }

    if let cached = userIdMap[auditToken] {
      return cached
    }

    guard auditToken.count == MemoryLayout<audit_token_t>.size else {
      return nil
    }

    let tokenT: audit_token_t? = auditToken.withUnsafeBytes { buf in
      guard let baseAddress = buf.baseAddress else {
        return nil
      }
      return baseAddress.assumingMemoryBound(to: audit_token_t.self).pointee
    }

    guard let token = tokenT else {
      return nil
    }

    let userId = audit_token_to_ruid(token)
    userIdMap[auditToken] = userId
    return userId
  }
}
```

A couple of notes:

- the `uid_t` is a `#define` typedef for `UInt32` (at least on Catalina). It represents a
  numeric user id.
- to get this code to build, you need to
  [link with libbsm](https://stackoverflow.com/questions/63315985/audit-token-to-pid-undefined-symbol)
- it appears that all regularly created MacOS users have user ids **higher than `500`**.
  This was a useful bit of errata, for my case.
- the above implementation caches a `[Data: uid_t]` dictionary, which Quinn says in some
  thread, is a reasonable thing to do, as the same apps will keep providing the same
  source app audit token.
