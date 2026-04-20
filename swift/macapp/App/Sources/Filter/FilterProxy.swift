import Combine
import Core
import Foundation
import Gertie
import NetworkExtension
import os.log

/// A proxy for the FilterDataProvider, which is impossible to test
/// and now mostly forwards functionality to this class, passing DTOs
/// where it traffics in types that are not constructable in tests.
public class FilterProxy {
  struct DeferredOutboundFlow: Equatable {
    let userId: uid_t?
    var round: Int
    var accumulatedReadBytes: Data
  }

  static let initialOutboundPeekBytes = 2048
  static let maxOutboundRetryBytes = 16384

  #if !DEBUG
    let store: FilterStore
  #else
    var store: FilterStore
  #endif

  var deferredOutboundFlows: [UUID: DeferredOutboundFlow] = [:]
  var cancellables: Set<AnyCancellable> = []

  // give the FilterDataProvider a simple boolean it can
  // quickly check to decide if it needs to pass the decision
  // on to the store - the vast majority of the time, nothing
  // needs to be sent, and the filter is sometimes making a huge
  // number of decisions, so keeping this lookup as fast as possible
  // for the normal case is important
  var sendingBlockDecisions = false

  // right now we just log in verbose mode whenever we're streaming blocks
  // but in the future, we might have a separate boolean and an app->filter message
  // to enable this for a specific period
  var verboseLogging: Bool { self.sendingBlockDecisions }

  public func handleNewFlow(_ flow: NEFilterFlow.DTO) -> NEFilterNewFlowVerdict {
    let userId: uid_t
    let earlyUserDecision = self.store.earlyUserDecision(auditToken: flow.sourceAppAuditToken)
    if self.verboseLogging {
      os_log("[D•] FILTER received new flow: %{public}s", "\(flow.description)")
      os_log("[D•] FILTER early user decision: %{public}@", "\(earlyUserDecision)")
      let checkFlow = FilterFlow(flow, userId: nil)
      if checkFlow.bundleId?.contains("com.apple.webfilterproxyd") == true {
        self.store.log(event: .init(
          id: "933aa385",
          detail: "possible screen time filter flow: `\(checkFlow.bundleId ?? "")`",
        ))
      }
    }

    let filterFlow: FilterFlow

    switch earlyUserDecision {
    case .block:
      return dropNewFlow()
    case .allow:
      return .allow()
    case .blockDuringDowntime(let id):
      userId = id
      filterFlow = FilterFlow(flow, userId: userId)
      if filterFlow.isFromGertrude || filterFlow.isSystemUiServerInternal {
        if self.verboseLogging {
          os_log(
            "[D•] FILTER ALLOW during downtime, bundleId: %{public}s",
            "\(filterFlow.bundleId ?? "(nil)")",
          )
        }
        return .allow()
      } else {
        if self.verboseLogging {
          os_log(
            "[D•] FILTER DROP during downtime, bundleId: %{public}s",
            "\(filterFlow.bundleId ?? "(nil)")",
          )
        }
        return dropNewFlow()
      }
    case .none(let id):
      userId = id
      filterFlow = FilterFlow(flow, userId: userId)
    }

    self.store.logAppRequest(from: filterFlow.bundleId)

    let decision = self.store.newFlowDecision(filterFlow, auditToken: flow.sourceAppAuditToken)
    if self.verboseLogging {
      switch decision {
      case .some(let decision):
        os_log("[D•] FILTER new flow decision: %{public}@", "\(decision)")
      case .none:
        os_log("[D•] FILTER new flow decision: DEFER")
      }
    }

    switch decision {
    case .block(.urlMessage(let message)):
      self.store.send(urlMessage: message)
      return .drop()
    case .block(.alwaysBlocked), .block(.quicBlockedForAlwaysBlocked):
      return dropNewFlow()
    case .block:
      if self.sendingBlockDecisions {
        self.store.sendBlocked(filterFlow, auditToken: flow.sourceAppAuditToken)
      }
      return dropNewFlow()
    case .allow(.fromGertrudeApp):
      self.store.send(urlMessage: .alive(userId))
      return .allow()
    case .allow:
      return .allow()
    case nil:
      self.deferredOutboundFlows[flow.identifier] = .init(
        userId: userId,
        round: 0,
        accumulatedReadBytes: .init(),
      )
      return .filterDataVerdict(
        withFilterInbound: false,
        peekInboundBytes: Int.max,
        filterOutbound: true,
        peekOutboundBytes: Self.initialOutboundPeekBytes,
      )
    }
  }

  public func handleOutboundData(
    from flow: NEFilterFlow.DTO,
    readBytesStartOffset: Int,
    readBytes: Data,
  ) -> NEFilterDataVerdict {
    let existingDeferred = self.deferredOutboundFlows[flow.identifier]
    let hasDeferredState = existingDeferred != nil
    var deferred = existingDeferred ?? .init(
      // Defensive fallback: outbound callbacks should normally have a deferred
      // entry already. On a miss, let downstream decisioning recover userId
      // from the audit token rather than failing open here.
      userId: nil,
      round: 0,
      accumulatedReadBytes: .init(),
    )

    let accumulatedReadBytes = mergeOutboundBytes(
      existing: deferred.accumulatedReadBytes,
      readBytesStartOffset: readBytesStartOffset,
      readBytes: readBytes,
    )
    var filterFlow = FilterFlow(flow, userId: deferred.userId)
    let parseResult = filterFlow.parseOutboundData(accumulatedReadBytes)

    if case .needMoreBytes(let requestedTotal) = parseResult,
       deferred.round == 0 {
      let clampedTotal = min(
        max(requestedTotal, accumulatedReadBytes.count),
        Self.maxOutboundRetryBytes,
      )
      let additionalPeekBytes = max(0, clampedTotal - accumulatedReadBytes.count)
      if additionalPeekBytes > 0,
         hasDeferredState || self.deferredOutboundFlows.count < 100 {
        deferred.round = 1
        deferred.accumulatedReadBytes = accumulatedReadBytes
        self.deferredOutboundFlows[flow.identifier] = deferred
        return .init(passBytes: accumulatedReadBytes.count, peekBytes: additionalPeekBytes)
      }
    }

    self.deferredOutboundFlows.removeValue(forKey: flow.identifier)

    let decision = self.store.completedFlowDecision(
      &filterFlow,
      auditToken: flow.sourceAppAuditToken,
    )

    if self.verboseLogging {
      os_log("[D•] FILTER outbound flow: %{public}s", "\(filterFlow.shortDescription)")
      os_log("[D•] FILTER outbound flow decision: %{public}@", "\(decision)")
      os_log("[D•] FILTER outbound flow bytes: %{public}s", bytesToAscii(accumulatedReadBytes))
    }

    switch decision {
    case .block(.alwaysBlocked), .block(.quicBlockedForAlwaysBlocked):
      return dropFlow()
    case .block:
      if self.sendingBlockDecisions {
        self.store.sendBlocked(filterFlow, auditToken: flow.sourceAppAuditToken)
      }
      return dropFlow()
    case .allow:
      return .allow()
    }
  }

  public func startFilter() {
    self.store.shouldSendBlockDecisions().sink { [weak self] in
      os_log("[G•] FILTER data provider: toggle send block decisions %{public}d", $0)
      self?.sendingBlockDecisions = $0
    }.store(in: &self.cancellables)
  }

  public func filterSettings() -> NEFilterSettings {
    let networkRule = NENetworkRule(
      remoteNetwork: nil,
      remotePrefix: 0,
      localNetwork: nil,
      localPrefix: 0,
      protocol: .any,
      direction: .outbound,
    )

    let filterRule = NEFilterRule(networkRule: networkRule, action: .filterData)
    return NEFilterSettings(rules: [filterRule], defaultAction: .allow)
  }

  public func sendExtensionStopping() {
    self.store.sendExtensionStopping()
  }

  public func sendExtensionStarted() {
    self.store.sendExtensionStarted()
  }

  public init(store: FilterStore = .init()) {
    self.store = store
  }
}

private func mergeOutboundBytes(
  existing: Data,
  readBytesStartOffset: Int,
  readBytes: Data,
) -> Data {
  guard !existing.isEmpty || readBytesStartOffset > 0 else {
    return readBytes
  }

  if readBytesStartOffset > existing.count {
    // This should not happen for outbound peek callbacks, but if it does,
    // reset accumulation rather than fabricate bytes we never observed.
    return readBytes
  }

  var merged = existing
  let overlapEnd = min(existing.count, readBytesStartOffset + readBytes.count)
  let overlapCount = max(0, overlapEnd - readBytesStartOffset)

  if overlapCount > 0 {
    merged.replaceSubrange(
      readBytesStartOffset ..< overlapEnd,
      with: readBytes.prefix(overlapCount),
    )
  }
  if overlapCount < readBytes.count {
    merged.append(readBytes.dropFirst(overlapCount))
  }
  return merged
}

public extension NEFilterFlow {
  /// A data transfer object for `NEFilterFlow`.
  /// NB: the original object has more data
  struct DTO {
    let identifier: UUID
    let sourceAppAuditToken: Data?
    let description: String
    let url: URL?
    let flowType: FlowType?

    public init(
      identifier: UUID = .init(),
      sourceAppAuditToken: Data? = nil,
      description: String,
      url: URL? = nil,
      flowType: FlowType? = nil,
    ) {
      self.identifier = identifier
      self.sourceAppAuditToken = sourceAppAuditToken
      self.description = description
      self.url = url
      self.flowType = flowType
    }
  }

  var dto: DTO { .init(
    identifier: self.identifier,
    sourceAppAuditToken: self.sourceAppAuditToken,
    description: self.description,
    url: self.url,
    // per NEFilterFlow.h: "The flow's HTTP request URL. Will be nil if the
    // flow did not originate from WebKit." On macOS this is the only
    // documented browser-vs-socket signal (NEFilterBrowserFlow is iOS-only),
    // so `.browser` here specifically means "WebKit-originated" — Safari,
    // WKWebView embeddings, SFSafariViewController. Chrome/Chromium, Firefox,
    // Edge, Arc, Brave, and Electron apps all use their own network stacks
    // and will classify as `.socket` despite being "browsers" colloquially.
    // Treat `.flowTypeIs(.browser)` on Mac as a Safari/WebKit-only signal,
    // not a general browser detector.
    flowType: self.url != nil ? .browser : .socket,
  ) }
}

extension FilterFlow {
  init(_ flow: NEFilterFlow.DTO, userId: uid_t? = nil) {
    self.init(url: flow.url?.absoluteString, description: flow.description)
    self.userId = userId
    self.flowType = flow.flowType
  }
}

private func dropFlow() -> NEFilterDataVerdict {
  #if DEBUG
    return getuid() < 500 ? .allow() : .drop()
  #else
    return .drop()
  #endif
}

private func dropNewFlow() -> NEFilterNewFlowVerdict {
  #if DEBUG
    return getuid() < 500 ? .allow() : .drop()
  #else
    return .drop()
  #endif
}
