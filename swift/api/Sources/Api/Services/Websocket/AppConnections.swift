import Dependencies
import Foundation
import Gertie

@globalActor actor AppConnections {
  enum ActivityEvent {
    case opened
    case closed
    case removed
    case dupe
    case message
    case deadFlushed(Int)
  }

  struct ActivitySummary {
    var opened = 0
    var closed = 0
    var removed = 0
    var dupes = 0
    var messages = 0
    var deadFlushed = 0

    var isEmpty: Bool {
      self.opened + self.closed + self.removed + self.dupes + self.messages + self.deadFlushed == 0
    }
  }

  static let shared = AppConnections()

  var connections: [AppConnection.Id: AppConnection] = [:]
  var activity = ActivitySummary()
  var closeBurstWarned = false
  var removeBurstWarned = false
  var dupeBurstWarned = false

  @Dependency(\.logger) private var logger

  func start() async {
    var ticks = 0
    while true {
      try? await Task.sleep(seconds: 60)
      ticks += 1
      self.logActivitySummaryIfNeeded()
      if ticks.isMultiple(of: 2) {
        await self.flush()
      }
    }
  }

  func add(_ connection: AppConnection) {
    let dupes: [AppConnection] = self.connections.values.filter {
      $0.ids.computerUser == connection.ids.computerUser
    }
    if dupes.count > 0 {
      self.record(.dupe)
      connection.log("open dupe", extra: "dupes=\(dupes.count)", level: .warning)
      dupes.forEach { self.remove($0) }
    } else {
      connection.log("opened", level: .debug)
    }
    self.record(.opened)
    self.connections[connection.id] = connection
  }

  func remove(_ connection: AppConnection) {
    self.record(.removed)
    connection.log("being removed", level: .debug)
    self.connections.removeValue(forKey: connection.id)
  }

  func recordClosed() {
    self.record(.closed)
  }

  func recordMessage() {
    self.record(.message)
  }

  func disconnectAll() async {
    self.logger.notice("AppConnections: disconnecting all (ws)")
    for connection in self.connections.values {
      try? await connection.ws.close(code: .goingAway)
      self.remove(connection)
    }
  }

  func status(for computerId: ComputerUser.Id) async -> ChildComputerStatus {
    for connection in self.connections.values {
      if connection.ids.computerUser == computerId {
        let state = connection.filterState.withLock { $0 }
        switch state {
        case .withoutTimes(let filterState):
          return filterState.status
        case .withTimes(let filterState):
          return filterState.status
        case nil:
          return .offline
        }
      }
    }
    return .offline
  }

  func flush() async {
    let dead = self.connections.values.filter(\.isDead)
    if dead.count > 0 {
      self.record(.deadFlushed(dead.count))
      self.logger.info("AppConnections: flushing dead websockets count=\(dead.count)")
    }
    for connection in dead {
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

  private func record(_ event: ActivityEvent) {
    switch event {
    case .opened:
      self.activity.opened += 1
    case .closed:
      self.activity.closed += 1
    case .removed:
      self.activity.removed += 1
    case .dupe:
      self.activity.dupes += 1
    case .message:
      self.activity.messages += 1
    case .deadFlushed(let count):
      self.activity.deadFlushed += count
    }
    self.logBurstWarningsIfNeeded()
  }

  private func logActivitySummaryIfNeeded() {
    guard !self.activity.isEmpty else {
      return
    }
    self.logger.info(
      "AppConnections: ws summary opened=\(self.activity.opened) closed=\(self.activity.closed) removed=\(self.activity.removed) dupes=\(self.activity.dupes) messages=\(self.activity.messages) dead_flushed=\(self.activity.deadFlushed) active=\(self.connections.count)",
    )
    self.activity = ActivitySummary()
    self.closeBurstWarned = false
    self.removeBurstWarned = false
    self.dupeBurstWarned = false
  }

  private func logBurstWarningsIfNeeded() {
    if !self.closeBurstWarned, self.activity.closed >= 100 {
      self.logger.warning("\(self.burstMessage("websocket close burst"))")
      self.closeBurstWarned = true
    }
    if !self.removeBurstWarned, self.activity.removed >= 100 {
      self.logger.warning("\(self.burstMessage("websocket remove burst"))")
      self.removeBurstWarned = true
    }
    if !self.dupeBurstWarned, self.activity.dupes >= 10 {
      self.logger.warning("\(self.burstMessage("websocket duplicate-open burst"))")
      self.dupeBurstWarned = true
    }
  }

  private func burstMessage(_ name: String) -> String {
    "\(name) opened=\(self.activity.opened) closed=\(self.activity.closed) removed=\(self.activity.removed) dupes=\(self.activity.dupes) messages=\(self.activity.messages) dead_flushed=\(self.activity.deadFlushed) active=\(self.connections.count)"
  }
}
