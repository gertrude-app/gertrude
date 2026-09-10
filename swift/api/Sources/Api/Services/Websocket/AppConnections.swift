import Dependencies
import Foundation
import Gertie

@globalActor actor AppConnections {
  static let shared = AppConnections()

  var connections: [AppConnection.Id: AppConnection] = [:]

  @Dependency(\.logger) private var logger

  private static let latestVersionWithoutSemanticHeartbeat: Semver = "2.9.7"
  private static let maxFilterStateAge: TimeInterval = 150

  func start() async {
    while true {
      try? await Task.sleep(seconds: 120)
      await self.flush()
    }
  }

  func add(_ connection: AppConnection) {
    let dupes: [AppConnection] = self.connections.values.filter {
      $0.ids.computerUser == connection.ids.computerUser
    }
    if dupes.count > 0 {
      connection.log("ERR! open dupe", extra: "dupes: \(dupes.count)")
      dupes.forEach { self.remove($0) }
    } else {
      connection.log("opened")
    }
    self.connections[connection.id] = connection
  }

  func remove(_ connection: AppConnection) {
    connection.log("being removed")
    self.connections.removeValue(forKey: connection.id)
  }

  func disconnectAll() async {
    self.logger.notice("AppConnections: disconnecting all (ws)")
    for connection in self.connections.values {
      try? await connection.ws.close(code: .goingAway)
      self.remove(connection)
    }
  }

  func status(for computerId: ComputerUser.Id) async -> ChildComputerStatus {
    await self.statusDetails(for: computerId).legacyStatus
  }

  func statusDetails(for computerId: ComputerUser.Id) async -> ComputerUserStatus {
    await self.flush()
    guard let connection = connections.values.first(where: {
      $0.ids.computerUser == computerId
    }) else {
      return .unreachable
    }
    guard let state = connection.filterState.withLock({ $0 }) else {
      return ComputerUserStatus(
        apiReachable: true,
        effectiveFilterStatus: nil,
        snapshotReceivedAt: nil,
        snapshotFreshness: .missing,
      )
    }
    let filterStatus = switch state.value {
    case .withoutTimes(let filterState): filterState.status
    case .withTimes(let filterState): filterState.status
    }
    let freshness: ComputerUserStatus.SnapshotFreshness =
      if connection.appVersion <= Self.latestVersionWithoutSemanticHeartbeat {
        .unsupported
      } else if Date().timeIntervalSince(state.receivedAt) >= Self.maxFilterStateAge {
        .stale
      } else {
        .fresh
      }
    return ComputerUserStatus(
      apiReachable: true,
      effectiveFilterStatus: filterStatus,
      snapshotReceivedAt: state.receivedAt,
      snapshotFreshness: freshness,
    )
  }

  func flush() async {
    for connection in self.connections.values.filter(\.isDead) {
      try? await connection.ws.close(code: .goingAway)
      self.remove(connection)
    }
  }

  private func currentConnections() async -> [AppConnection] {
    await self.flush()
    return Array(self.connections.values)
  }

  func send(_ event: AppEvent) async throws {
    let conns = await self.currentConnections()
    let matching = conns.filter { $0.ids.satisfies(matcher: event.matcher) }
    for conn in matching {
      try await conn.ws.send(app: event.message)
    }
  }

  deinit {
    connections.values.forEach { _ = $0.ws.close(code: .goingAway) }
    connections = [:]
  }
}
