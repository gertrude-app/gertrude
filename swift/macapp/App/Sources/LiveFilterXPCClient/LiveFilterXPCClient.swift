import ClientInterfaces
import Core
import Dependencies
import Foundation
import Gertie
import TaggedTime

extension FilterXPCClient: @retroactive DependencyKey {
  public static var liveValue: Self {
    let xpc = ThreadSafeFilterXPC()
    // phase A dark-ship: xpc stays the live channel; every outbound message
    // is also duplicated onto the shadow uds channel for health comparison
    let shadow = UDSClient.shared
    shadow.start()
    return .init(
      establishConnection: { await .init {
        try await xpc.establishConnection()
      }},
      checkConnectionHealth: {
        shadow.mirror(.ackRequest(randomInt: Int.random(in: 0 ... 10000), userId: getuid()))
        return await .init {
          try await xpc.checkConnectionHealth()
        }
      },
      checkUdsShadowHealth: { await shadow.health() },
      takeUdsShadowStatusReport: { shadow.takeStatusReport() },
      disconnectUser: {
        shadow.mirror(.disconnectUser(userId: getuid()))
        return await .init {
          try await xpc.disconnectUser()
        }
      },
      endFilterSuspension: {
        shadow.mirror(.endFilterSuspension(userId: getuid()))
        return await .init {
          try await xpc.endFilterSuspension()
        }
      },
      endDowntimePause: {
        shadow.mirror(.endDowntimePause(userId: getuid()))
        return await .init {
          try await xpc.endDowntimePause()
        }
      },
      pauseDowntime: { expiration in
        shadow.mirror(.pauseDowntime(userId: getuid(), until: expiration))
        return await .init {
          try await xpc.pauseDowntime(until: expiration)
        }
      },
      requestAck: {
        shadow.mirror(.ackRequest(randomInt: Int.random(in: 0 ... 10000), userId: getuid()))
        return await .init {
          try await xpc.requestAck()
        }
      },
      requestUserTypes: {
        shadow.mirror(.userTypesRequest)
        return await .init {
          try await xpc.requestUserTypes()
        }
      },
      sendAlive: {
        shadow.mirror(.alive(userId: getuid()))
        return await .init {
          let success = try await xpc.sendAlive()
          if !success {
            await send(urlMessage: .alive(getuid()))
            _ = try await xpc.requestAck()
          }
          return success
        }
      },
      sendDeleteAllStoredState: {
        shadow.mirror(.deleteAllStoredState)
        return await .init {
          try await xpc.sendDeleteAllStoredState()
        }
      },
      sendURLMessage: send(urlMessage:),
      sendUserRules: { manifest, keychains, downtime, filteringDisabled, alwaysBlocked in
        shadow.mirror(.userRules(
          userId: getuid(),
          manifest: manifest,
          filterData: .init(
            keychains: keychains,
            downtime: downtime,
            filteringDisabled: filteringDisabled,
            alwaysBlocked: alwaysBlocked,
          ),
        ))
        return await .init {
          try await xpc.sendUserRules(
            manifest: manifest,
            keychains: keychains,
            downtime: downtime,
            filteringDisabled: filteringDisabled,
            alwaysBlocked: alwaysBlocked,
          )
        }
      },
      setBlockStreaming: { enabled in
        shadow.mirror(.setBlockStreaming(enabled: enabled, userId: getuid()))
        return await .init {
          try await xpc.setBlockStreaming(enabled: enabled)
        }
      },
      setUserExemption: { userId, enabled in
        shadow.mirror(.setUserExemption(userId: userId, enabled: enabled))
        return await .init {
          try await xpc.setUserExemption(userId: userId, enabled: enabled)
        }
      },
      suspendFilter: { duration in
        shadow.mirror(.suspendFilter(userId: getuid(), durationInSeconds: duration.rawValue))
        return await .init {
          try await xpc.suspendFilter(for: duration)
        }
      },
      events: {
        xpcEventSubject.withValue { subject in
          Move(subject.eraseToAnyPublisher())
        }.consume()
      },
    )
  }
}

actor ThreadSafeFilterXPC {
  private let filterXpc = FilterXPC()

  func establishConnection() async throws {
    try await self.filterXpc.establishConnection()
  }

  func checkConnectionHealth() async throws {
    try await self.filterXpc.checkConnectionHealth()
  }

  func endFilterSuspension() async throws {
    try await self.filterXpc.endFilterSuspension()
  }

  func pauseDowntime(until expiration: Date) async throws {
    try await self.filterXpc.pauseDowntime(until: expiration)
  }

  func endDowntimePause() async throws {
    try await self.filterXpc.endDowntimePause()
  }

  func suspendFilter(for duration: Seconds<Int>) async throws {
    try await self.filterXpc.suspendFilter(for: duration)
  }

  func disconnectUser() async throws {
    try await self.filterXpc.disconnectUser()
  }

  func requestAck() async throws -> XPC.FilterAck {
    try await self.filterXpc.requestAck()
  }

  func sendAlive() async throws -> Bool {
    try await self.filterXpc.sendAlive()
  }

  func sendUserRules(
    manifest: AppIdManifest,
    keychains: [RuleKeychain],
    downtime: Downtime?,
    filteringDisabled: Bool?,
    alwaysBlocked: [BlockRule]?,
  ) async throws {
    try await self.filterXpc.sendUserRules(
      manifest: manifest,
      keychains: keychains,
      downtime: downtime,
      filteringDisabled: filteringDisabled,
      alwaysBlocked: alwaysBlocked,
    )
  }

  func setBlockStreaming(enabled: Bool) async throws {
    try await self.filterXpc.setBlockStreaming(enabled: enabled)
  }

  func setUserExemption(userId: uid_t, enabled: Bool) async throws {
    try await self.filterXpc.setUserExemption(userId: userId, enabled: enabled)
  }

  func requestUserTypes() async throws -> FilterUserTypes {
    try await self.filterXpc.requestUserTypes()
  }

  func sendDeleteAllStoredState() async throws {
    try await self.filterXpc.sendDeleteAllStoredState()
  }
}

// helpers

@Sendable
private func send(urlMessage: XPC.URLMessage) async {
  // sync:bc81c515 url-message fallback
  var request = URLRequest(url: urlMessage.url)
  request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
  request.timeoutInterval = 2
  _ = try? await URLSession.shared.data(for: request)
}
