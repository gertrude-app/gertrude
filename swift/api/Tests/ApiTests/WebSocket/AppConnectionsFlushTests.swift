import Dependencies
import Gertie
import NIOConcurrencyHelpers
import NIOCore
import NIOEmbedded
import NIOWebSocket
import XCore
import XCTest

@testable import Api

final class AppConnectionsFlushTests: XCTestCase {
  func testFilterStateSnapshotRecordsReceiptTime() throws {
    let eventLoop = EmbeddedEventLoop()
    let mock = MockWebSocket(eventLoop: eventLoop)
    let ids = AppConnection.Ids(
      computerUser: .init(UUID()),
      child: .init(UUID()),
      keychains: [],
    )
    let connection = AppConnection(ws: mock, ids: ids, appVersion: "2.9.7")
    let before = Date()

    try connection.onText(JSON.encode(
      AppConnection.IncomingMessage.currentFilterState_v2(.on),
    ))

    let after = Date()
    let snapshot = try XCTUnwrap(connection.filterState.withLock { $0 })
    guard case .withTimes(.on) = snapshot.value else {
      XCTFail("Expected filter-on snapshot")
      return
    }
    XCTAssertTrue((before ... after).contains(snapshot.receivedAt))
  }

  func testStatusFlushesDeadConnectionBeforeReturningStatus() async {
    let eventLoop = EmbeddedEventLoop()
    let mock = MockWebSocket(eventLoop: eventLoop)
    let ids = AppConnection.Ids(
      computerUser: .init(UUID()),
      child: .init(UUID()),
      keychains: [],
    )

    let connection = AppConnection(ws: mock, ids: ids, appVersion: "2.9.7")
    connection.filterState.withLock {
      $0 = .init(value: .withTimes(.on), receivedAt: Date())
    }
    await AppConnections.shared.add(connection)
    connection.lastActivity.withLock { $0 = Date().addingTimeInterval(-150) }

    let status = await AppConnections.shared.status(for: ids.computerUser)

    XCTAssertEqual(status, .offline)
    XCTAssertTrue(mock.closeWasCalled)
  }

  func testStatusDetailsDescribeSnapshotFreshness() async {
    let cases: [(
      version: Semver,
      snapshotAge: TimeInterval,
      expectedFreshness: ComputerUserStatus.SnapshotFreshness,
      expectedLegacyStatus: ChildComputerStatus,
    )] = [
      ("2.9.7", 160, .unsupported, .filterOn),
      ("2.9.8", 140, .fresh, .filterOn),
      ("2.9.8", 160, .stale, .offline),
    ]

    for testCase in cases {
      let eventLoop = EmbeddedEventLoop()
      let mock = MockWebSocket(eventLoop: eventLoop)
      let ids = AppConnection.Ids(
        computerUser: .init(UUID()),
        child: .init(UUID()),
        keychains: [],
      )
      let connection = AppConnection(
        ws: mock,
        ids: ids,
        appVersion: testCase.version,
      )
      let receivedAt = Date().addingTimeInterval(-testCase.snapshotAge)
      connection.filterState.withLock {
        $0 = .init(value: .withTimes(.on), receivedAt: receivedAt)
      }
      await AppConnections.shared.add(connection)

      let details = await AppConnections.shared.statusDetails(for: ids.computerUser)
      let legacyStatus = await AppConnections.shared.status(for: ids.computerUser)

      XCTAssertEqual(details, ComputerUserStatus(
        apiReachable: true,
        effectiveFilterStatus: .filterOn,
        snapshotReceivedAt: receivedAt,
        snapshotFreshness: testCase.expectedFreshness,
      ))
      XCTAssertEqual(
        legacyStatus,
        testCase.expectedLegacyStatus,
        "version \(testCase.version)",
      )
      XCTAssertFalse(mock.closeWasCalled)
      await AppConnections.shared.remove(connection)
    }
  }

  func testStatusDetailsDistinguishMissingAndUnreachable() async {
    let eventLoop = EmbeddedEventLoop()
    let mock = MockWebSocket(eventLoop: eventLoop)
    let ids = AppConnection.Ids(
      computerUser: .init(UUID()),
      child: .init(UUID()),
      keychains: [],
    )
    let connection = AppConnection(ws: mock, ids: ids, appVersion: "2.9.8")
    await AppConnections.shared.add(connection)

    let missing = await AppConnections.shared.statusDetails(for: ids.computerUser)
    XCTAssertEqual(missing, ComputerUserStatus(
      apiReachable: true,
      effectiveFilterStatus: nil,
      snapshotReceivedAt: nil,
      snapshotFreshness: .missing,
    ))

    await AppConnections.shared.remove(connection)

    let unreachable = await AppConnections.shared.statusDetails(for: ids.computerUser)
    XCTAssertEqual(unreachable, .unreachable)
  }

  func testFlushClosesWebSocketBeforeRemoving() async {
    let eventLoop = EmbeddedEventLoop()
    let mock = MockWebSocket(eventLoop: eventLoop)
    let ids = AppConnection.Ids(
      computerUser: .init(UUID()),
      child: .init(UUID()),
      keychains: [],
    )

    let connection = AppConnection(ws: mock, ids: ids, appVersion: "2.9.7")
    await AppConnections.shared.add(connection)

    connection.lastActivity.withLock { $0 = Date().addingTimeInterval(-150) }

    XCTAssertTrue(connection.isDead)
    XCTAssertFalse(mock.closeWasCalled)

    await AppConnections.shared.flush()

    XCTAssertTrue(mock.closeWasCalled, "flush() should close WebSocket before removing")
  }
}

final class MockWebSocket: WebsocketProtocol, @unchecked Sendable {
  let eventLoop: EventLoop
  private let _isClosed: NIOLockedValueBox<Bool>
  private let _closeWasCalled: NIOLockedValueBox<Bool>
  let onClose: EventLoopFuture<Void>
  private let closePromise: EventLoopPromise<Void>

  var isClosed: Bool { self._isClosed.withLockedValue { $0 } }
  var closeWasCalled: Bool { self._closeWasCalled.withLockedValue { $0 } }

  init(eventLoop: EventLoop) {
    self.eventLoop = eventLoop
    self._isClosed = NIOLockedValueBox(false)
    self._closeWasCalled = NIOLockedValueBox(false)
    self.closePromise = eventLoop.makePromise(of: Void.self)
    self.onClose = self.closePromise.futureResult
  }

  func setupTextHandler(_ callback: @Sendable @escaping (String) -> Void) {}
  func setupPingHandler(_ callback: @Sendable @escaping () -> Void) {}

  func close(code: WebSocketErrorCode) async throws {
    self._closeWasCalled.withLockedValue { $0 = true }
    self._isClosed.withLockedValue { $0 = true }
    self.closePromise.succeed(())
  }

  func close(code: WebSocketErrorCode) -> EventLoopFuture<Void> {
    self._closeWasCalled.withLockedValue { $0 = true }
    self._isClosed.withLockedValue { $0 = true }
    self.closePromise.succeed(())
    return self.onClose
  }

  func send(_ text: String) async throws {}
}
