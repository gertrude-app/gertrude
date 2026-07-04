import ConcurrencyExtras
import Dependencies
import Foundation
import GertieBlocker
import IOSRoute
import LibClients

public final class ScriptedApi: Sendable {
  public struct Config: Sendable {
    public var networkUp = true
    public var blockRules: [BlockRule] = [.targetContains(value: "blocked.com")]
    public var defaultBlockRules: [BlockRule] = [.targetContains(value: "default-blocked.com")]
    public var allBlockGroups: [GetBlockGroups.BlockGroupInfo] = []
    public var connected: ConnectedRules.Output?
    public var connectFeatureFlag = ConnectAccountFeatureFlag.Output(isEnabled: false)
    public var supervisionStatus: CheckSupervisionFlowStatus.Output?
    public var suspensionDecision: PollFilterSuspensionDecision.Output = .pending
    public var screenshotUploadsFailing = false

    public init() {}
  }

  public struct NetworkDown: Error, Sendable {
    public init() {}
  }

  public struct SuspensionRequest: Sendable, Equatable {
    public var duration: Int
    public var comment: String?

    public init(duration: Int, comment: String? = nil) {
      self.duration = duration
      self.comment = comment
    }
  }

  public let config: LockIsolated<Config>
  public let loggedEvents = LockIsolated<[String]>([])
  public let calls = LockIsolated<[String]>([])
  public let accountConnections = LockIsolated<[ChildIOSDeviceData_v2?]>([])
  public let suspensionRequests = LockIsolated<[SuspensionRequest]>([])
  public let uploadedScreenshots = LockIsolated<[ScreenshotData]>([])

  public init(_ config: Config = .init()) {
    self.config = LockIsolated(config)
  }

  public func received(_ call: String) -> Bool {
    self.calls.withValue { $0.contains(call) }
  }

  func client(for target: SimTarget) -> ApiClient {
    var client = ApiClient.testValue
    client.logEvent = { [self] id, _ in
      await Task.megaYield()
      if Task.isCancelled { return }
      self.record(target, "logEvent")
      self.loggedEvents.withValue { $0.append(id) }
    }
    client.fetchBlockRules = { [self] _, _ in
      try self.checkReachable(target, "fetchBlockRules")
      return self.config.value.blockRules
    }
    client.fetchDefaultBlockRules = { [self] _ in
      try self.checkReachable(target, "fetchDefaultBlockRules")
      return self.config.value.defaultBlockRules
    }
    client.fetchAllBlockGroups = { [self] _ in
      try self.checkReachable(target, "fetchAllBlockGroups")
      return self.config.value.allBlockGroups
    }
    client.connectedRules = { [self] in
      try self.checkReachable(target, "connectedRules")
      guard let connected = self.config.value.connected else { throw NetworkDown() }
      return connected
    }
    client.setAccountConnection = { [self] connection in
      self.record(target, "setAccountConnection")
      self.accountConnections.withValue { $0.append(connection) }
    }
    client.connectAccountFeatureFlag = { [self] in
      try self.checkReachable(target, "connectAccountFeatureFlag")
      return self.config.value.connectFeatureFlag
    }
    client.checkSupervisionFlowStatus = { [self] _ in
      try self.checkReachable(target, "checkSupervisionFlowStatus")
      guard let status = self.config.value.supervisionStatus else { throw NetworkDown() }
      return status
    }
    client.recoveryDirective = { [self] in
      try self.checkReachable(target, "recoveryDirective")
      return nil
    }
    client.crossPromos = { .init(promos: []) }
    client.createSuspendFilterRequest = { [self] duration, comment in
      try self.checkReachable(target, "createSuspendFilterRequest")
      self.suspensionRequests.withValue {
        $0.append(.init(duration: duration.rawValue, comment: comment))
      }
      return UUID(9)
    }
    client.pollSuspensionDecision = { [self] _ in
      try self.checkReachable(target, "pollSuspensionDecision")
      return self.config.value.suspensionDecision
    }
    client.uploadScreenshot = { [self] screenshot in
      try self.checkReachable(target, "uploadScreenshot")
      guard !self.config.value.screenshotUploadsFailing else {
        throw NetworkDown()
      }
      self.uploadedScreenshots.withValue { $0.append(screenshot) }
    }
    client.uploadScreenshotDirect = { [self] screenshot in
      try self.checkReachable(target, "uploadScreenshotDirect")
      guard !self.config.value.screenshotUploadsFailing else {
        throw NetworkDown()
      }
      self.uploadedScreenshots.withValue { $0.append(screenshot) }
    }
    return client
  }

  private func record(_ target: SimTarget, _ endpoint: String) {
    self.calls.withValue { $0.append("\(target.rawValue):\(endpoint)") }
  }

  private func checkReachable(_ target: SimTarget, _ endpoint: String) throws {
    try Task.checkCancellation()
    self.record(target, endpoint)
    guard self.config.value.networkUp else { throw NetworkDown() }
  }
}
