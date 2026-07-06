import Core
import Foundation
import Network
import os.log

public final class UDSSpikeClient: @unchecked Sendable {
  public static let shared = UDSSpikeClient()

  private let queue = DispatchQueue(label: "com.netrivet.gertrude.uds-spike-client")
  private let socketPath: String
  private let pingInterval: TimeInterval
  private var connection: NWConnection?
  private var parser = UDSFrameParser()
  private var pingTimer: DispatchSourceTimer?
  private var pingSeq = 0
  private var reconnectScheduled = false
  private var receivedLog: [UDSSpikeMessage] = []

  public init(
    socketPath: String = UDSSpike.socketPath(for: getuid()),
    pingInterval: TimeInterval = 20,
  ) {
    self.socketPath = socketPath
    self.pingInterval = pingInterval
  }

  public func startIfEnabled() {
    guard UDSSpike.isEnabled else { return }
    os_log("[G•] UDS client: spike enabled, connecting")
    self.start()
  }

  public func start() {
    self.queue.async { self.connect() }
  }

  public func stop() {
    self.queue.sync {
      self.pingTimer?.cancel()
      self.pingTimer = nil
      self.connection?.cancel()
      self.connection = nil
    }
  }

  public func snapshot() -> [UDSSpikeMessage] {
    self.queue.sync { self.receivedLog }
  }

  private func connect() {
    self.parser = UDSFrameParser()
    let conn = NWConnection(to: .unix(path: self.socketPath), using: .tcp)
    self.connection = conn
    conn.stateUpdateHandler = { [weak self] state in
      guard let self else { return }
      switch state {
      case .ready:
        os_log("[G•] UDS client: connection ready")
        self.sendMsg(.hello(
          pid: getpid(),
          uid: getuid(),
          version: Bundle.main
            .infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
        ))
        self.receiveLoop(on: conn)
        self.startPingTimer()
      case .waiting(let error):
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
    conn
      .receive(
        minimumIncompleteLength: 1,
        maximumLength: 65536,
      ) { [weak self] data, _, isComplete, error in
        guard let self, self.connection === conn else { return }
        if let data, !data.isEmpty {
          for msg in self.parser.append(data) {
            self.handle(msg)
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

  private func handle(_ msg: UDSSpikeMessage) {
    self.receivedLog.append(msg)
    switch msg {
    case .helloAck(let filterPid, let filterVersion):
      os_log(
        "[G•] UDS client: received helloAck, filter pid %{public}d, version %{public}s",
        filterPid,
        filterVersion,
      )
    case .pong(let seq):
      os_log("[G•] UDS client: received pong %{public}d (app->filter->app proven)", seq)
    case .filterPush(let seq):
      os_log("[G•] UDS client: received filterPush %{public}d, acking", seq)
      self.sendMsg(.pushAck(seq: seq))
    case .hello, .ping, .pushAck:
      os_log("[G•] UDS client: unexpected message: %{public}s", "\(msg)")
    }
  }

  private func sendMsg(_ msg: UDSSpikeMessage) {
    guard let conn = self.connection, let data = try? UDSFrame.encode(msg) else { return }
    conn.send(content: data, completion: .contentProcessed { error in
      if let error {
        os_log("[G•] UDS client: send error: %{public}s", "\(error)")
      }
    })
  }

  private func startPingTimer() {
    guard self.pingInterval > 0 else { return }
    self.pingTimer?.cancel()
    let timer = DispatchSource.makeTimerSource(queue: self.queue)
    timer.schedule(deadline: .now() + self.pingInterval, repeating: self.pingInterval)
    timer.setEventHandler { [weak self] in
      guard let self else { return }
      self.pingSeq += 1
      self.sendMsg(.ping(seq: self.pingSeq))
    }
    timer.resume()
    self.pingTimer = timer
  }

  private func scheduleReconnect() {
    guard !self.reconnectScheduled else { return }
    self.reconnectScheduled = true
    self.pingTimer?.cancel()
    self.pingTimer = nil
    self.connection?.cancel()
    self.connection = nil
    self.queue.asyncAfter(deadline: .now() + 2) { [weak self] in
      guard let self else { return }
      self.reconnectScheduled = false
      os_log("[G•] UDS client: attempting reconnect")
      self.connect()
    }
  }
}
