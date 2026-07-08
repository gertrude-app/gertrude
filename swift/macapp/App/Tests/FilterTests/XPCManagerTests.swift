import Core
import Foundation
import XCTest
import XExpect

@testable import Filter

final class XPCManagerTests: XCTestCase {
  private var listeners: [NSXPCListener] = []
  private var delegates: [AcceptAllDelegate] = []

  override func tearDown() {
    self.listeners.forEach { $0.invalidate() }
    self.listeners = []
    self.delegates = []
  }

  // connections to a live anonymous listener stay valid, unlike connections
  // to a nonexistent mach service, which the system invalidates async
  private func testXpcConnection() -> NSXPCConnection {
    let delegate = AcceptAllDelegate()
    let listener = NSXPCListener.anonymous()
    listener.delegate = delegate
    listener.resume()
    self.delegates.append(delegate) // <-- listener delegate is not retained
    self.listeners.append(listener)
    return NSXPCConnection(listenerEndpoint: listener.endpoint)
  }

  func testSendToUserWithNoConnectionThrowsNoConnection() async throws {
    let manager = XPCManager()
    try await expectErrorFrom {
      try await manager.notifyFilterSuspensionEnded(for: 501)
    }.toContain("noConnection")
  }

  func testSendLogsWithNoConnectionsThrowsNoConnection() async throws {
    let manager = XPCManager()
    try await expectErrorFrom {
      try await manager.sendLogs(.init(bundleIds: [:], events: [:]))
    }.toContain("noConnection")
  }

  func testRetainsOneConnectionPerUser() {
    let manager = XPCManager()
    let conn501 = self.testXpcConnection()
    let conn502 = self.testXpcConnection()
    manager.accept(connection: conn501, userId: 501)
    manager.accept(connection: conn502, userId: 502)
    expect(manager.connectionIds).toEqual([
      501: ObjectIdentifier(conn501),
      502: ObjectIdentifier(conn502),
    ])
  }

  func testSameUserReconnectReplacesPriorConnection() {
    let manager = XPCManager()
    let first = self.testXpcConnection()
    let second = self.testXpcConnection()
    manager.accept(connection: first, userId: 501)
    manager.accept(connection: second, userId: 501)
    expect(manager.connectionIds).toEqual([501: ObjectIdentifier(second)])
  }

  func testRemoveConnectionIgnoresStaleId() {
    let manager = XPCManager()
    let first = self.testXpcConnection()
    let second = self.testXpcConnection()
    manager.accept(connection: first, userId: 501)
    manager.accept(connection: second, userId: 501)

    manager.removeConnection(userId: 501, id: ObjectIdentifier(first)) // <-- stale
    expect(manager.connectionIds).toEqual([501: ObjectIdentifier(second)])

    manager.removeConnection(userId: 501, id: ObjectIdentifier(second)) // <-- current
    expect(manager.connectionIds).toEqual([:])
  }

  func testInvalidatedConnectionRemovedFromMap() async throws {
    let manager = XPCManager()
    let conn = self.testXpcConnection()
    manager.accept(connection: conn, userId: 501)
    expect(manager.connectionIds).toEqual([501: ObjectIdentifier(conn)])

    conn.invalidate() // <-- fires invalidation handler async

    try await self.waitUntil { manager.connectionIds.isEmpty }
  }

  func testStopListenerClearsConnections() {
    let manager = XPCManager()
    manager.accept(connection: self.testXpcConnection(), userId: 501)
    manager.accept(connection: self.testXpcConnection(), userId: 502)
    manager.stopListener()
    expect(manager.connectionIds).toEqual([:])
  }

  // helpers

  private func waitUntil(
    _ condition: () -> Bool,
    file: StaticString = #filePath,
    line: UInt = #line,
  ) async throws {
    for _ in 0 ..< 200 {
      if condition() { return }
      try await Task.sleep(nanoseconds: 10_000_000)
    }
    XCTFail("condition never met", file: file, line: line)
  }
}

private class AcceptAllDelegate: NSObject, NSXPCListenerDelegate {
  func listener(
    _ listener: NSXPCListener,
    shouldAcceptNewConnection newConnection: NSXPCConnection,
  ) -> Bool {
    newConnection.resume()
    return true
  }
}

private extension XPCManager {
  var connectionIds: [uid_t: ObjectIdentifier] {
    self.connections.withValue { $0.entries.mapValues(\.id) }
  }
}
