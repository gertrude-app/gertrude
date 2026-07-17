import Core
import Foundation
import Gertie
import os.log

public extension NetworkFilter {
  func newFlowDecision(
    _ flow: FilterFlow,
    auditToken: Data? = nil,
  ) -> FilterDecision.FromFlow? {
    #if DEBUG
      if let mock = self.__TEST_MOCK_FLOW_DECISION { return mock }
    #endif
    return self.flowDecision(flow, auditToken: auditToken, canDefer: true)
  }

  func completedFlowDecision(
    _ flow: inout FilterFlow,
    readBytes: Data,
    auditToken: Data? = nil,
  ) -> FilterDecision.FromFlow {
    if flow.url == nil {
      _ = flow.parseOutboundData(readBytes)
    }
    return self.completedFlowDecision(&flow, auditToken: auditToken)
  }

  func completedFlowDecision(
    _ flow: inout FilterFlow,
    auditToken: Data? = nil,
  ) -> FilterDecision.FromFlow {
    #if DEBUG
      if case .some(.some(let mock)) = self.__TEST_MOCK_FLOW_DECISION { return mock }
    #endif
    return self.flowDecision(flow, auditToken: auditToken, canDefer: false) ??
      .block(.defaultNotAllowed)
  }

  private func flowDecision(
    _ flow: FilterFlow,
    auditToken: Data?,
    canDefer: Bool,
  ) -> FilterDecision.FromFlow? {

    if flow.isDnsRequest {
      return .allow(.dnsRequest)
    }

    if flow.isSystemUiServerInternal {
      // special allowance for system app that causes menubar flakiness if blocked
      return .allow(.systemUiServerInternal)
    }

    let fromGertrude = flow.isFromGertrude
    if fromGertrude, flow.hostname?.contains(".xpc.") != true {
      return .allow(.fromGertrudeApp)
    }

    guard let userId = flow.userId ?? security.userIdFromAuditToken(auditToken) else {
      return .block(.missingUserId)
    }

    if fromGertrude, flow.hostname == XPC.URLMessage.alive(userId).hostname {
      // sync:bc81c515 url-message fallback
      return .block(.urlMessage(.alive(userId)))
    }

    if self.state.macappsAliveUntil[userId] == nil,
       self.state.userKeychains[userId] != nil
       || self.state.filteringDisabledUsers.contains(userId)
       || self.state.userAlwaysBlocked[userId] != nil {
      return .block(.macappAWOL(userId))
    }

    // always-blocked rules override suspensions, filtering-disabled, and allow-keys.
    // only checked when the user has rules assigned — zero cost otherwise.
    let alwaysBlocked = self.state.userAlwaysBlocked[userId]
    if let alwaysBlocked,
       let matched = alwaysBlocked.first(where: { $0.blocksFlow(flow) }) {
      return .block(.alwaysBlocked(matched))
    }

    // non-WebKit flows (Chrome, Firefox, Electron, native sockets) arrive at
    // new-flow time with a nil hostname — SNI isn't parsed until peek. if we
    // early-allow here for filtering-disabled or suspension, the flow never
    // peeks and AB rules never get a chance to match the real hostname. defer
    // so the outbound peek round-trip can re-run flowDecision with hostname.
    let deferForAlwaysBlocked = canDefer
      && flow.hostname == nil
      && alwaysBlocked?.isEmpty == false

    // QUIC (UDP/443) ClientHello is encrypted, so we can't parse SNI — meaning
    // hostname-dependent always-blocked rules can never match. when a user with
    // AB rules would otherwise be blindly allowed (suspension/filtering-disabled),
    // block QUIC so Chrome/etc. fall back to TCP+TLS where SNI is visible.
    let blockQuicForAlwaysBlocked = deferForAlwaysBlocked
      && flow.isUDP
      && flow.port == .https(443)

    if self.state.filteringDisabledUsers.contains(userId) {
      if blockQuicForAlwaysBlocked {
        return .block(.quicBlockedForAlwaysBlocked(userId))
      }
      return deferForAlwaysBlocked ? nil : .allow(.filteringDisabled(userId))
    }

    let app = appDescriptor(for: flow.bundleId ?? "", auditToken: auditToken)
    if self.activeSuspension(for: userId, permits: app) {
      if blockQuicForAlwaysBlocked {
        return .block(.quicBlockedForAlwaysBlocked(userId))
      }
      return deferForAlwaysBlocked ? nil : .allow(.filterSuspended)
    }

    let keychains = self.state.userKeychains[userId] ?? []
    guard !keychains.isEmpty else {
      return .block(.noUserKeys)
    }

    let lowercasedHostname = flow.hostname?.lowercased()
    let hostnameUTF8 = lowercasedHostname.map { Array($0.utf8) }
    let lowercasedUrl = flow.url?.regexRemove("^https?://").lowercased()

    if let utf8 = hostnameUTF8,
       let index = self.state.userKeychainIndexes[userId] {
      let normalized = KeychainIndex.normalizeUTF8(utf8)
      if let matches = index.exactDomains[normalized] {
        for match in matches {
          if match.schedule?.active(at: self.now, in: self.calendar) == false {
            continue
          }
          if match.scope.permits(app) {
            return .allow(.permittedByKey(match.ruleKeyId))
          }
        }
      }

      for remainder in index.remainders {
        if remainder.schedule?.active(at: self.now, in: self.calendar) == false {
          continue
        }
        for ruleKey in remainder.keys {
          switch ruleKey.key {
          case .anySubdomain(domain: let domain, scope: let scope):
            if scope.permits(app), domain.matchesAnySubdomainUTF8(utf8) {
              return .allow(.permittedByKey(ruleKey.id))
            }

          case .skeleton(scope: let singleScope):
            if AppScope.single(singleScope).permits(app) {
              return .allow(.permittedByKey(ruleKey.id))
            }

          case .domainRegex(pattern: let pattern, scope: let scope):
            if let hostname = lowercasedHostname,
               matchesDomainRegex(hostname, pattern: pattern.regex),
               scope.permits(app) {
              return .allow(.permittedByKey(ruleKey.id))
            }

          case .ipAddress(ipAddress: let ip, scope: let scope):
            if let ipAddress = flow.ipAddress,
               ipAddress == ip.string,
               scope.permits(app) {
              return .allow(.permittedByKey(ruleKey.id))
            }

          case .path(path: let path, scope: let scope):
            if let url = lowercasedUrl,
               path.matches(lowercasedUrl: url),
               scope.permits(app) {
              return .allow(.permittedByKey(ruleKey.id))
            }

          case .domain:
            break
          }
        }
      }
    } else {
      for keychain in keychains {
        if keychain.schedule?.active(at: self.now, in: self.calendar) == false {
          continue
        }
        for ruleKey in keychain.keys {
          switch ruleKey.key {

          case .domain(domain: let domain, scope: let scope):
            if let utf8 = hostnameUTF8, scope.permits(app),
               domain.matchesUTF8(utf8) {
              return .allow(.permittedByKey(ruleKey.id))
            }

          case .anySubdomain(domain: let domain, scope: let scope):
            if let utf8 = hostnameUTF8,
               scope.permits(app),
               domain.matchesAnySubdomainUTF8(utf8) {
              return .allow(.permittedByKey(ruleKey.id))
            }

          case .skeleton(scope: let singleScope):
            if AppScope.single(singleScope).permits(app) {
              return .allow(.permittedByKey(ruleKey.id))
            }

          case .domainRegex(pattern: let pattern, scope: let scope):
            if let hostname = lowercasedHostname,
               matchesDomainRegex(hostname, pattern: pattern.regex),
               scope.permits(app) {
              return .allow(.permittedByKey(ruleKey.id))
            }

          case .ipAddress(ipAddress: let ip, scope: let scope):
            if let ipAddress = flow.ipAddress,
               ipAddress == ip.string,
               scope.permits(app) {
              return .allow(.permittedByKey(ruleKey.id))
            }

          case .path(path: let path, scope: let scope):
            if let url = lowercasedUrl,
               path.matches(lowercasedUrl: url),
               scope.permits(app) {
              return .allow(.permittedByKey(ruleKey.id))
            }
          }
        }
      }
    }

    // no need to wait for more flow data if we already have the url
    if flow.url != nil || !canDefer {
      return .block(.defaultNotAllowed)
    }

    return nil
  }

  private func activeSuspension(
    for userId: uid_t,
    permits app: AppDescriptor,
  ) -> Bool {
    // sync:086c6b0b clocked suspension decisions
    guard let suspension = state.suspensions[userId], suspension.isActive(at: self.now) else {
      return false
    }
    return suspension.scope.permits(app)
  }
}
