import Dependencies
import Gertie
import NIOConcurrencyHelpers
import NIOCore
import NIOEmbedded
import NIOWebSocket
import XCTest

@testable import Api

final class AppConnectionsFlushTests: XCTestCase {
  func testSendAttemptsEveryMatchingConnectionBeforeThrowing() async {
    let connections = AppConnections()
    let childId = Child.Id(UUID())
    let sockets = (0 ..< 4)
      .map { MockWebSocket(eventLoop: EmbeddedEventLoop(), failSends: $0 != 0) }
    for socket in sockets {
      await connections.add(AppConnection(
        ws: socket,
        ids: .init(computerUser: .init(UUID()), child: childId, keychains: []),
      ))
    }
    do {
      try await connections.send(.init(.userUpdated, to: .user(childId)))
      XCTFail("Expected the failed sends to be reported")
    } catch MockWebSocket.Failure.send {} catch {
      XCTFail("Unexpected error: \(error)")
    }
    XCTAssertEqual(sockets.map(\.sendCount), [1, 1, 1, 1])
    await connections.disconnectAll()
  }

  func testFlushClosesWebSocketBeforeRemoving() async {
    let eventLoop = EmbeddedEventLoop()
    let mock = MockWebSocket(eventLoop: eventLoop)
    let ids = AppConnection.Ids(
      computerUser: .init(UUID()),
      child: .init(UUID()),
      keychains: [],
    )

    let connection = AppConnection(ws: mock, ids: ids)
    await AppConnections.shared.add(connection)

    connection.lastActivity.withLock { $0 = Date().addingTimeInterval(-150) }

    XCTAssertTrue(connection.isDead)
    XCTAssertFalse(mock.closeWasCalled)

    await AppConnections.shared.flush()

    XCTAssertTrue(mock.closeWasCalled, "flush() should close WebSocket before removing")
  }
}

final class MockWebSocket: WebsocketProtocol, @unchecked Sendable {
  enum Failure: Error { case send }
  let eventLoop: EventLoop
  private let failSends: Bool
  private let _sendCount = NIOLockedValueBox(0)
  var sendCount: Int { self._sendCount.withLockedValue { $0 } }
  private let _isClosed: NIOLockedValueBox<Bool>
  private let _closeWasCalled: NIOLockedValueBox<Bool>
  let onClose: EventLoopFuture<Void>
  private let closePromise: EventLoopPromise<Void>

  var isClosed: Bool { self._isClosed.withLockedValue { $0 } }
  var closeWasCalled: Bool { self._closeWasCalled.withLockedValue { $0 } }

  init(eventLoop: EventLoop, failSends: Bool = false) {
    self.eventLoop = eventLoop
    self.failSends = failSends
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

  func send(_ text: String) async throws {
    self._sendCount.withLockedValue { $0 += 1 }
    if self.failSends { throw Failure.send }
  }
}
