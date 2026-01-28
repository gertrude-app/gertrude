import Dependencies
import Gertie
import NIOConcurrencyHelpers
import NIOCore
import NIOEmbedded
import NIOWebSocket
import XCTest

@testable import Api

final class AppConnectionsFlushTests: XCTestCase {
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
