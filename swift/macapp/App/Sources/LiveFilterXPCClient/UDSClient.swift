import Core
import Foundation
import Network
import os.log

final class UDSClient: @unchecked Sendable {
  static let shared = UDSClient()

  private let queue = DispatchQueue(label: "com.netrivet.gertrude.uds-client")
  private let socketPath: String
  private let heartbeatInterval: TimeInterval
  private let reconnectDelay: TimeInterval
  private var connection: NWConnection?
  private var connectionReady = false
  private var parser = UDSFrameParser()
  private var pending: [UUID: CheckedContinuation<UDS.Message, Error>] = [:]
  private var heartbeatTimer: DispatchSourceTimer?
  private var reconnectScheduled = false
  private var reconnectAttempts = 0
  private var started = false
  private var connectedAt: Date?
  private var lastRoundTripAt: Date?
  private var filterVersion: String?
  private var requestsSucceeded = 0
  private var requestsFailed = 0
  private var reconnects = 0

  init(
    socketPath: String = UDS.socketPath(for: getuid()),
    heartbeatInterval: TimeInterval = 60,
    reconnectDelay: TimeInterval = 2,
  ) {
    self.socketPath = socketPath
    self.heartbeatInterval = heartbeatInterval
    self.reconnectDelay = reconnectDelay
  }

  func start() {
    self.queue.async {
      guard !self.started else { return }
      self.started = true
      self.connect()
    }
  }

  func stop() {
    self.queue.sync {
      self.started = false
      self.heartbeatTimer?.cancel()
      self.heartbeatTimer = nil
      self.teardownConnection()
    }
  }

  // duplicate an outbound xpc message onto the shadow channel,
  // never delaying or failing the xpc path
  func mirror(_ message: UDS.Message) {
    Task { [weak self] in
      _ = try? await self?.request(message)
    }
  }

  func request(
    _ message: UDS.Message,
    timeout: TimeInterval = 3,
  ) async throws -> UDS.Message {
    try await withCheckedThrowingContinuation { continuation in
      self.queue.async {
        guard let conn = self.connection, self.connectionReady else {
          self.requestsFailed += 1
          continuation.resume(throwing: XPCErr.noConnection)
          return
        }
        let envelope = UDS.Envelope(message: message)
        guard let data = try? UDSFrame.encode(envelope) else {
          self.requestsFailed += 1
          continuation.resume(throwing: XPCErr.encode(
            fn: "UDSClient.request",
            type: "\(UDS.Envelope.self)",
            error: "frame encode failed",
          ))
          return
        }
        self.pending[envelope.id] = continuation
        self.queue.asyncAfter(deadline: .now() + timeout) { [weak self] in
          guard let self, let pending = self.pending.removeValue(forKey: envelope.id) else {
            return
          }
          self.requestsFailed += 1
          pending.resume(throwing: XPCErr.timeout)
        }
        conn.send(content: data, completion: .contentProcessed { [weak self] error in
          guard let self, error != nil else { return }
          self.queue.async {
            if let pending = self.pending.removeValue(forKey: envelope.id) {
              self.requestsFailed += 1
              pending.resume(throwing: XPCErr.noConnection)
            }
          }
        })
      }
    }
  }

  // point-in-time status + counters since last report (counters reset on take)
  func takeStatusReport() -> UDS.ShadowStatusReport {
    self.queue.sync {
      let report = UDS.ShadowStatusReport(
        connected: self.connectionReady,
        filterVersion: self.filterVersion,
        connectedForSeconds: self.connectedAt.map { Int(Date().timeIntervalSince($0)) },
        lastRoundTripAgeSeconds: self.lastRoundTripAt.map { Int(Date().timeIntervalSince($0)) },
        requestsSucceeded: self.requestsSucceeded,
        requestsFailed: self.requestsFailed,
        reconnects: self.reconnects,
      )
      self.requestsSucceeded = 0
      self.requestsFailed = 0
      self.reconnects = 0
      return report
    }
  }

  func health() async -> UDS.ShadowHealth {
    let (ready, connectedAt, lastRoundTripAt) = self.queue.sync {
      (self.connectionReady, self.connectedAt, self.lastRoundTripAt)
    }
    guard ready else {
      return .init(healthy: false, detail: "not connected\(self.ageDetail(lastRoundTripAt))")
    }
    let randomInt = Int.random(in: 0 ... 10000)
    do {
      let reply = try await self.request(.ackRequest(randomInt: randomInt, userId: getuid()))
      guard case .ack(let ack) = reply, ack.randomInt == randomInt else {
        return .init(healthy: false, detail: "unexpected reply")
      }
      return .init(
        healthy: true,
        detail: "round-trip ok, filter v\(ack.version)\(self.ageDetail(connectedAt, "connected"))",
      )
    } catch {
      return .init(
        healthy: false,
        detail: "round-trip failed: \(error)\(self.ageDetail(lastRoundTripAt))",
      )
    }
  }

  private func ageDetail(_ date: Date?, _ label: String = "last round-trip") -> String {
    guard let date else { return ", \(label): never" }
    return ", \(label) \(Int(Date().timeIntervalSince(date)))s ago"
  }

  // MARK: - connection lifecycle

  private func connect() {
    self.parser = UDSFrameParser()
    let conn = NWConnection(to: .unix(path: self.socketPath), using: .tcp)
    self.connection = conn
    conn.stateUpdateHandler = { [weak self] state in
      guard let self, self.connection === conn else { return }
      switch state {
      case .ready:
        os_log("[G•] UDS client: connection ready")
        self.connectionReady = true
        self.connectedAt = Date()
        self.reconnectAttempts = 0
        self.receiveLoop(on: conn)
        self.startHeartbeatTimer()
        self.sendHello()
      case .waiting(let error):
        // for unix endpoints NW never leaves .waiting; treat as fatal
        // and drive reconnection with our own timer
        os_log("[G•] UDS client: connection waiting: %{public}s", "\(error)")
        self.scheduleReconnect()
      case .failed(let error):
        os_log("[G•] UDS client: connection failed: %{public}s", "\(error)")
        self.scheduleReconnect()
      case .setup, .preparing, .cancelled:
        break
      @unknown default:
        break
      }
    }
    conn.start(queue: self.queue)
  }

  private func receiveLoop(on conn: NWConnection) {
    conn.receive(
      minimumIncompleteLength: 1,
      maximumLength: 65536,
    ) { [weak self] data, _, isComplete, error in
      guard let self, self.connection === conn else { return }
      if let data, !data.isEmpty {
        for envelope in self.parser.append(data) {
          self.handle(envelope)
        }
        if self.parser.failed {
          os_log("[G•] UDS client: oversized frame, reconnecting")
          self.scheduleReconnect()
          return
        }
      }
      if isComplete {
        os_log("[G•] UDS client: connection closed by server")
        self.scheduleReconnect()
      } else if let error {
        os_log("[G•] UDS client: receive error: %{public}s", "\(error)")
        self.scheduleReconnect()
      } else {
        self.receiveLoop(on: conn)
      }
    }
  }

  private func handle(_ envelope: UDS.Envelope) {
    guard let replyTo = envelope.replyTo,
          let continuation = self.pending.removeValue(forKey: replyTo) else {
      os_log(
        "[G•] UDS client: unexpected message: %{public}s",
        String(describing: envelope.message),
      )
      return
    }
    self.lastRoundTripAt = Date()
    self.requestsSucceeded += 1
    switch envelope.message {
    case .helloAck(_, let version):
      self.filterVersion = version
    case .ack(let ack):
      self.filterVersion = ack.version
    default:
      break
    }
    continuation.resume(returning: envelope.message)
  }

  private func sendHello() {
    let version = Bundle.main
      .infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    Task { [weak self] in
      guard let self else { return }
      let reply = try? await self.request(.hello(pid: getpid(), uid: getuid(), version: version))
      if case .helloAck(let pid, let filterVersion) = reply {
        os_log(
          "[G•] UDS client: helloAck from filter pid %{public}d, version %{public}s",
          pid,
          filterVersion,
        )
      }
    }
  }

  private func startHeartbeatTimer() {
    guard self.heartbeatInterval > 0 else { return }
    self.heartbeatTimer?.cancel()
    let timer = DispatchSource.makeTimerSource(queue: self.queue)
    timer.schedule(
      deadline: .now() + self.heartbeatInterval,
      repeating: self.heartbeatInterval,
    )
    timer.setEventHandler { [weak self] in
      guard let self else { return }
      self.mirror(.ackRequest(randomInt: Int.random(in: 0 ... 10000), userId: getuid()))
    }
    timer.resume()
    self.heartbeatTimer = timer
  }

  private func teardownConnection() {
    self.connectionReady = false
    self.connection?.cancel()
    self.connection = nil
    for continuation in self.pending.values {
      self.requestsFailed += 1
      continuation.resume(throwing: XPCErr.noConnection)
    }
    self.pending = [:]
  }

  private func scheduleReconnect() {
    guard !self.reconnectScheduled else { return }
    self.reconnectScheduled = true
    self.heartbeatTimer?.cancel()
    self.heartbeatTimer = nil
    self.teardownConnection()
    // capped backoff so a fleet member with no server (filter off, or
    // pre-uds filter version) isn't retrying every 2s indefinitely
    let delay = min(self.reconnectDelay * pow(2, Double(self.reconnectAttempts)), 30)
    self.reconnectAttempts += 1
    self.reconnects += 1
    self.queue.asyncAfter(deadline: .now() + delay) { [weak self] in
      guard let self else { return }
      self.reconnectScheduled = false
      guard self.started else { return }
      self.connect()
    }
  }
}
