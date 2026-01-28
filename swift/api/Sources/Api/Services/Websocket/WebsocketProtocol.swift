import Gertie
import NIOCore
import NIOWebSocket
import Vapor
import XCore

protocol WebsocketProtocol: Sendable {
  var eventLoop: EventLoop { get }
  var isClosed: Bool { get }
  var onClose: EventLoopFuture<Void> { get }
  func setupTextHandler(_ callback: @Sendable @escaping (String) -> Void)
  func setupPingHandler(_ callback: @Sendable @escaping () -> Void)
  func close(code: WebSocketErrorCode) async throws
  func close(code: WebSocketErrorCode) -> EventLoopFuture<Void>
  func send(_ text: String) async throws
}

extension WebSocket: WebsocketProtocol {
  func setupTextHandler(_ callback: @Sendable @escaping (String) -> Void) {
    self.onText { _, text in callback(text) }
  }

  func setupPingHandler(_ callback: @Sendable @escaping () -> Void) {
    self.onPing { _, _ in callback() }
  }
}

extension WebsocketProtocol {
  func send(codable msg: some Codable) async throws {
    try await self.send(JSON.encode(msg))
  }

  func send(app: WebSocketMessage.FromApiToApp) async throws {
    try await self.send(codable: app)
  }
}
