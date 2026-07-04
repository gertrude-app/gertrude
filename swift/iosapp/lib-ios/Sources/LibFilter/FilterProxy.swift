import Dependencies
import GertieBlocker
import LibClients
import LibCore
import os.log
import XCore

#if canImport(NetworkExtension)
  import NetworkExtension
#else
  public struct NEProviderStopReason {} // CI
#endif

public struct FilterProxy {
  #if DEBUG
    static let FREQ_FAST: UInt = 10
    static let FREQ_NORMAL: UInt = 25
    static let FREQ_SLOW: UInt = 50
    static let FREQ_VERY_SLOW: UInt = 100
  #else
    static let FREQ_FAST: UInt = 25
    static let FREQ_NORMAL: UInt = 500
    static let FREQ_SLOW: UInt = 1000
    static let FREQ_VERY_SLOW: UInt = 3000
  #endif

  @Dependency(\.osLog) var logger
  @Dependency(\.date.now) public var now
  @Dependency(\.calendar) public var calendar

  // NB: The filter target is allowed to WRITE to UserDefaults,
  // but if it does, the operating system seems to *clone* the
  // underlying database, and it no longer is connected to the
  // group container. This is not documented directly, but I've
  // tested & verified it, and it fits with how the docs say that
  // the filter is heavily sandboxed and is not allowed to export
  // data, hence we use a storage client that can ONLY read
  @Dependency(\.sharedStorageReader) var storage

  var count: UInt = 0

  #if DEBUG
    let memoryLogs: LockIsolated<[String]> = LockIsolated([])
  #endif

  public private(set) var protectionMode: ProtectionMode = .emergencyLockdown
  public private(set) var suspension: RecordingSuspension?
  var lastSummon = Date.distantPast

  public init(protectionMode: ProtectionMode) {
    self.protectionMode = protectionMode
    #if DEBUG
      self.logger.setObserver { [logs = self.memoryLogs] msg, isDebug in
        if !isDebug {
          logs.withValue { $0.append("\(Date()) [G•] FILTER PROXY \(msg.prefix(100))") }
        }
      }
    #endif
    self.logger.setPrefix("FILTER PROXY")
    self.logger.log("Initialized filter proxy")
    Witness.filterProxyInit.emit()
  }

  mutating func shouldRequestUpdate() -> Bool {
    if self.count % FilterProxy.FREQ_VERY_SLOW == 0 {
      self.logger.log("re-read rules fallback, count: \(self.count)")
      self.loadAndSetRules()
    }
    switch self.protectionMode {
    case .normal:
      return self.count % FilterProxy.FREQ_SLOW == 0
    case .connected:
      return self.count % FilterProxy.FREQ_NORMAL == 0
    case .onboarding:
      return self.count % FilterProxy.FREQ_FAST == 0
    case .emergencyLockdown:
      self.loadAndSetRules()
      return self.count % FilterProxy.FREQ_FAST == 0
    }
  }

  mutating func loadAndSetRules() {
    let mode = self.storage.loadProtectionMode()
    self.logger.logReadProtectionMode(mode)
    mode.map { self.protectionMode = $0 }
  }

  // NB: from logging, it appears that this can get called from different threads
  // although big bursts of near simultaneous network connections seem to to be
  // handled by the same thread, instead of being interleaved, seems more like the
  // system puts the process to sleep after inactivity, then it wakes up on a new thread
  // so it's probably the correct mental model to consider this a single-threaded
  public mutating func decideFlow(_ systemFlow: NEFilterFlow) -> FlowVerdict {
    let flow = self.toFilterFlow(systemFlow)
    return self.decideFilterFlow(flow)
  }

  package mutating func decideFilterFlow(_ flow: FilterFlow) -> FlowVerdict {
    self.count &+= 1 // wrapping add

    if flow.hostname == MagicStrings.readRulesSentinalHostname {
      Witness.filterSentinel.emit("read-rules")
      self.loadAndSetRules()
      return .drop
    }

    if flow.hostname == MagicStrings.refreshRulesSentinalHostname {
      self.logger.log("refresh rules requested from app")
      Witness.filterSentinel.emit("refresh-rules")
      return .needRules
    }

    if flow.hostname == MagicStrings.suspendFilterSentinalHostname {
      Witness.filterSentinel.emit("suspend-filter")
      if isGertrude(flow.bundleId),
         let suspension = RecordingSuspension.entered(
           expiration: self.storage.loadSuspensionExpiration(),
           now: self.now,
         ) {
        self.suspension = suspension
        self.logger.log("filter suspended until \(suspension.expiration)")
        Witness.filterSuspended.emit("until=\(suspension.expiration)")
      }
      return .drop
    }

    if flow.hostname == MagicStrings.resumeFilterSentinalHostname {
      Witness.filterSentinel.emit("resume-filter")
      if isGertrude(flow.bundleId), self.suspension != nil {
        self.endSuspension(reason: "requested")
      }
      return .drop
    }

    #if DEBUG
      if isShieldsLabSentinel(flow.hostname) {
        Witness.filterSentinel.emit("shields-lab \(flow.hostname ?? "")")
        return .needRules
      }
    #endif

    if self.suspension == nil,
       let rederived = RecordingSuspension.rederived(
         expiration: self.storage.loadSuspensionExpiration(),
         lastScreenshot: self.storage.loadScreenshotLastSaved(),
         now: self.now,
       ) {
      self.suspension = rederived
      self.logger.log("filter suspension rederived, until \(rederived.expiration)")
      Witness.filterSuspended.emit("rederived until=\(rederived.expiration)")
    }

    if let suspension = self.suspension {
      let lastScreenshot = self.storage.loadScreenshotLastSaved()
      let valid = suspension.isValid(
        expiration: self.storage.loadSuspensionExpiration(),
        lastScreenshot: lastScreenshot,
        now: self.now,
      )
      Witness.filterLivenessCheck.emit({
        let saw = lastScreenshot.map { "\($0.timeIntervalSince1970)" } ?? "nil"
        let elapsed = lastScreenshot
          .map { "\(Int(self.now.timeIntervalSince($0) * 1000))" } ?? "nil"
        return "sawTs=\(saw) elapsedMs=\(elapsed) valid=\(valid)"
      }())
      if valid {
        if RecordingSuspension.recordingIsLive(lastScreenshot: lastScreenshot, now: self.now),
           self.now.timeIntervalSince(self.lastSummon) >= RecordingSuspension.heartbeatInterval {
          self.lastSummon = self.now
          Witness.filterSummonedController.emit()
          return .needRules
        }
        return .allow
      }
      self.endSuspension(reason: "expired-or-recording-stopped")
    }

    #if DEBUG
      if flow.hostname == MagicStrings.dumpLogsSentinalHostname {
        for (i, logs) in self.memoryLogs.withValue({ $0 }).chunked(into: 6).enumerated() {
          os_log("[G•] FILTER memory logs %d:\n%{public}s", i + 1, logs.joined(separator: "\n"))
        }
        return .drop
      }

      let target = (flow.target ?? "nil").prefix(25)
      self.logger.log("Decide flow `\(target)`, rules: \(self.protectionMode.shortDesc)")
    #endif

    if self.shouldRequestUpdate() {
      self.logger.log("request update, count: \(self.count)")
      Witness.filterNeedRules.emit("count=\(self.count)")
      return .needRules
    }

    return self.decideNewFlow(flow)
  }

  public mutating func handleRulesChanged() {
    self.logger.log(".handleRulesChanged() called")
    Witness.filterRulesChanged.emit()
    self.loadAndSetRules()
  }

  public mutating func startFilter() {
    self.logger.log("Starting filter")
    Witness.filterStart.emit()
    self.loadAndSetRules()
    if let suspension = RecordingSuspension.rederived(
      expiration: self.storage.loadSuspensionExpiration(),
      lastScreenshot: self.storage.loadScreenshotLastSaved(),
      now: self.now,
    ) {
      self.suspension = suspension
      self.logger.log("filter suspension rederived, until \(suspension.expiration)")
      Witness.filterSuspended.emit("rederived until=\(suspension.expiration)")
    }
  }

  private mutating func endSuspension(reason: String) {
    self.suspension = nil
    self.logger.log("filter resumed: \(reason)")
    Witness.filterResumed.emit(reason)
  }

  public func stopFilter(reason: NEProviderStopReason) {
    Witness.filterStop.emit(String(describing: reason))
  }
}

extension FilterProxy: FlowDecider {
  public func log(_ message: String) {
    self.logger.log(message)
  }

  public func debugLog(_ message: String) {
    self.logger.debug(message)
  }
}

// helpers

private func isGertrude(_ bundleId: String?) -> Bool {
  guard let bundleId else { return false }
  return bundleId == .gertrudeBundleIdLong || bundleId == .gertrudeBundleIdShort
    || bundleId == .gertrudeRecorderBundleIdLong || bundleId == .gertrudeRecorderBundleIdShort
}

#if DEBUG
  private func isShieldsLabSentinel(_ hostname: String?) -> Bool {
    hostname == MagicStrings.shieldsUpSentinalHostname
      || hostname == MagicStrings.shieldsAllSentinalHostname
      || hostname == MagicStrings.shieldsWebSentinalHostname
      || hostname == MagicStrings.shieldsDownSentinalHostname
  }
#endif

// "exports" for filter

public typealias BlockRule = GertieBlocker.BlockRule
public typealias FlowType = GertieBlocker.FlowType
