import Foundation
import Gertie
import NIOWebSocket
import Tagged
import Vapor
import XCore

struct ComputerUserStatus: Equatable, Sendable {
  enum SnapshotFreshness: Equatable, Sendable {
    case fresh
    case stale
    case unsupported
    case missing
  }

  let apiReachable: Bool
  let effectiveFilterStatus: ChildComputerStatus?
  let snapshotReceivedAt: Date?
  let snapshotFreshness: SnapshotFreshness

  var legacyStatus: ChildComputerStatus {
    guard self.apiReachable, self.snapshotFreshness != .stale else { return .offline }
    return self.effectiveFilterStatus ?? .offline
  }

  static let unreachable = Self(
    apiReachable: false,
    effectiveFilterStatus: nil,
    snapshotReceivedAt: nil,
    snapshotFreshness: .missing,
  )
}

final class AppConnection: Sendable {
  struct Ids: Sendable {
    let computerUser: ComputerUser.Id
    let child: Child.Id
    let keychains: [Keychain.Id]
  }

  struct FilterStateData: Sendable {
    enum Value: Sendable {
      case withoutTimes(FilterState.WithoutTimes)
      case withTimes(FilterState.WithTimes)
    }

    let value: Value
    let receivedAt: Date
  }

  let id: Id
  let ids: Ids
  let appVersion: Semver
  let ws: any WebsocketProtocol
  let filterState: Mutex<FilterStateData?> = Mutex(nil)
  let lastActivity = Mutex(Date())

  init(ws: any WebsocketProtocol, ids: Ids, appVersion: Semver) {
    self.id = .init(UUID())
    self.ids = ids
    self.appVersion = appVersion
    self.ws = ws
    // https://github.com/vapor/websocket-kit/issues/139
    self.ws.eventLoop.execute {
      self.ws.setupTextHandler { [weak self] text in self?.onText(text) }
      self.ws.setupPingHandler { [weak self] in self?.onPing() }
      self.ws.onClose.whenComplete { result in
        switch result {
        case .success:
          self.log("onclose success")
          Task { await with(dependency: \.websockets).remove(self) }
        case .failure(let err):
          self.log("onclose fail", extra: "err: \(err)")
        }
      }
    }
  }

  func log(_ primary: String, extra: String? = nil) {
    var childMsg = "[WS] child=\(self.ids.child.lowercased): \(primary)"
    if let extra { childMsg += " \(extra)" }
    with(dependency: \.logger).info("\(childMsg)")
    var computerMsg = "[WS] compu=\(self.ids.computerUser.lowercased): \(primary)"
    if let extra { computerMsg += " \(extra)" }
    with(dependency: \.logger).info("\(computerMsg)")
  }

  func onPing() {
    self.lastActivity.withLock { $0 = Date() }
  }

  var isAlive: Bool {
    if self.ws.isClosed {
      return false
    }
    return self.lastActivity.withLock { lastActivity in
      let elapsed = Date().timeIntervalSince(lastActivity)
      return elapsed < 100 // 90 seconds is our macapp ping interval
    }
  }

  var isDead: Bool {
    !self.isAlive
  }

  func onText(_ json: String) {
    self.lastActivity.withLock { $0 = Date() }
    guard let message = try? JSON.decode(json, as: IncomingMessage.self) else {
      self.log("ERR failed to decode msg", extra: "json=\(json)")
      return
    }
    self.log("got message", extra: "\(message)")
    switch message {
    case .currentFilterState(let filterStateWithoutTimes):
      self.filterState.withLock {
        $0 = .init(value: .withoutTimes(filterStateWithoutTimes), receivedAt: Date())
      }
    case .currentFilterState_v2(let filterState):
      self.filterState.withLock {
        $0 = .init(value: .withTimes(filterState), receivedAt: Date())
      }
    case .goingOffline:
      Task { await with(dependency: \.websockets).remove(self) }
    }
  }
}

// NB: `nil` the dates while still supporting < `v2.7.0`
extension FilterState.WithoutTimes {
  var status: ChildComputerStatus {
    switch self {
    case .off:
      .filterOff
    case .on:
      .filterOn
    case .unfiltered:
      .unfiltered
    case .suspended:
      .filterSuspended(resuming: nil)
    case .downtime:
      .downtime(ending: nil)
    case .downtimePaused:
      .downtimePaused(resuming: nil)
    }
  }
}

extension FilterState.WithTimes {
  var status: ChildComputerStatus {
    switch self {
    case .off:
      .filterOff
    case .on:
      .filterOn
    case .unfiltered:
      .unfiltered
    case .suspended(let resuming):
      .filterSuspended(resuming: resuming)
    case .downtime(let ending):
      .downtime(ending: ending)
    case .downtimePaused(let resuming):
      .downtimePaused(resuming: resuming)
    }
  }
}

extension AppConnection {
  typealias Id = Tagged<AppConnection, UUID>
  typealias IncomingMessage = WebSocketMessage.FromAppToApi
}
