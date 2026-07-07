import Core
import Darwin
import Foundation
import os.log

public final class UDSSpikeServer: @unchecked Sendable {
  public static let shared = UDSSpikeServer(validatePeer: UDSSpikeServer.livePeerValidation)

  public typealias PeerValidation = @Sendable (_ auditToken: Data, _ expectedUid: uid_t) -> Bool

  private struct Listener {
    let fd: Int32
    let uid: uid_t
    let source: DispatchSourceRead
  }

  private final class Conn {
    let fd: Int32
    let uid: uid_t
    let source: DispatchSourceRead
    let writeSource: DispatchSourceWrite
    let parser = UDSFrameParser()
    var outbound: [Data] = []
    var outboundOffset = 0
    var outboundBytes = 0
    var writeSourceArmed = false

    init(fd: Int32, uid: uid_t, source: DispatchSourceRead, writeSource: DispatchSourceWrite) {
      self.fd = fd
      self.uid = uid
      self.source = source
      self.writeSource = writeSource
    }
  }

  private let queue = DispatchQueue(label: "com.netrivet.gertrude.uds-spike-server")
  private let rootDir: String
  private let pushInterval: TimeInterval
  private let maxOutboundBytes: Int
  private let validatePeer: PeerValidation
  private var listeners: [uid_t: Listener] = [:]
  private var conns: [Int32: Conn] = [:]
  private var pushTimer: DispatchSourceTimer?
  private var pushSeq = 0
  private var receivedLog: [UDSSpikeMessage] = []

  public init(
    rootDir: String = UDSSpike.socketDir,
    pushInterval: TimeInterval = 30,
    maxOutboundBytes: Int = 64 * 1024 * 1024,
    validatePeer: @escaping PeerValidation,
  ) {
    self.rootDir = rootDir
    self.pushInterval = pushInterval
    self.maxOutboundBytes = maxOutboundBytes
    self.validatePeer = validatePeer
  }

  public static let livePeerValidation: PeerValidation = { token, expectedUid in
    let security = SecurityClient.liveValue
    guard let uid = security.userIdFromAuditToken(token), uid == expectedUid else {
      os_log("[G•] UDS server: peer rejected, uid mismatch")
      return false
    }
    let app = security.rootAppFromAuditToken(token)
    guard app.bundleId == "com.netrivet.gertrude.app" else {
      os_log(
        "[G•] UDS server: peer rejected, bundle id: %{public}s",
        app.bundleId ?? "(nil)",
      )
      return false
    }
    return true
  }

  public static func uidFromToken(_ token: Data) -> uid_t? {
    SecurityClient.liveValue.userIdFromAuditToken(token)
  }

  public func startIfEnabled() {
    guard UDSSpike.isEnabled else { return }
    os_log("[G•] UDS server: spike enabled, starting")
    self.start(uids: Self.discoverUids())
  }

  public func start(uids: [uid_t]) {
    self.queue.async {
      self.createSocketDir()
      for uid in Set(uids) {
        self.bindListener(for: uid)
      }
      self.startPushTimer()
    }
  }

  public func stop() {
    self.queue.sync {
      self.pushTimer?.cancel()
      self.pushTimer = nil
      for conn in Array(self.conns.values) {
        self.closeConn(conn)
      }
      for listener in self.listeners.values {
        listener.source.cancel()
        close(listener.fd)
        unlink(UDSSpike.socketPath(for: listener.uid, in: self.rootDir))
      }
      self.listeners = [:]
    }
  }

  public func snapshot() -> (received: [UDSSpikeMessage], connectionCount: Int) {
    self.queue.sync { (self.receivedLog, self.conns.count) }
  }

  public func broadcast(_ msg: UDSSpikeMessage) {
    self.queue.async {
      for conn in self.conns.values {
        self.send(msg, to: conn)
      }
    }
  }

  static func discoverUids() -> [uid_t] {
    let names = (try? FileManager.default.contentsOfDirectory(atPath: "/Users")) ?? []
    return names.compactMap { name in
      guard !name.hasPrefix("."), name != "Shared" else { return nil }
      var info = stat()
      guard stat("/Users/\(name)", &info) == 0, info.st_uid >= 500 else { return nil }
      return info.st_uid
    }
  }

  private func createSocketDir() {
    try? FileManager.default.createDirectory(
      atPath: self.rootDir,
      withIntermediateDirectories: true,
      attributes: [.posixPermissions: 0o755],
    )
  }

  private func bindListener(for uid: uid_t) {
    let path = UDSSpike.socketPath(for: uid, in: self.rootDir)
    let fd = socket(AF_UNIX, SOCK_STREAM, 0)
    guard fd != -1 else {
      os_log("[G•] UDS server: socket() failed: %{public}s", String(cString: strerror(errno)))
      return
    }
    setNoSigPipe(fd)

    unlink(path)
    var addr = sockaddr_un()
    addr.sun_family = sa_family_t(AF_UNIX)
    let pathBytes = path.utf8CString
    guard pathBytes.count <= MemoryLayout.size(ofValue: addr.sun_path) else {
      os_log("[G•] UDS server: socket path too long: %{public}s", path)
      close(fd)
      return
    }
    withUnsafeMutableBytes(of: &addr.sun_path) { dest in
      pathBytes.withUnsafeBytes { src in
        dest.copyMemory(from: src)
      }
    }

    let bindResult = withUnsafePointer(to: &addr) {
      $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        Darwin.bind(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
      }
    }
    guard bindResult == 0 else {
      os_log(
        "[G•] UDS server: bind failed for %{public}s: %{public}s",
        path,
        String(cString: strerror(errno)),
      )
      close(fd)
      return
    }

    chmod(path, 0o600)
    if chown(path, uid, 0) != 0, getuid() == 0 {
      os_log(
        "[G•] UDS server: chown failed for %{public}s: %{public}s",
        path,
        String(cString: strerror(errno)),
      )
    }

    guard listen(fd, 4) == 0 else {
      os_log("[G•] UDS server: listen failed: %{public}s", String(cString: strerror(errno)))
      close(fd)
      return
    }

    let source = DispatchSource.makeReadSource(fileDescriptor: fd, queue: self.queue)
    source.setEventHandler { [weak self] in
      self?.acceptConnection(listenerFd: fd, uid: uid)
    }
    source.resume()
    self.listeners[uid] = Listener(fd: fd, uid: uid, source: source)
    os_log("[G•] UDS server: listening at %{public}s", path)
  }

  private func acceptConnection(listenerFd: Int32, uid: uid_t) {
    let fd = accept(listenerFd, nil, nil)
    guard fd != -1 else {
      os_log("[G•] UDS server: accept failed: %{public}s", String(cString: strerror(errno)))
      return
    }
    setNoSigPipe(fd)

    guard let token = peerAuditToken(fd) else {
      os_log("[G•] UDS server: no peer audit token, closing connection")
      close(fd)
      return
    }
    guard self.validatePeer(token, uid) else {
      os_log("[G•] UDS server: peer validation FAILED, closing connection")
      close(fd)
      return
    }
    os_log("[G•] UDS server: peer validated, connection accepted for uid %{public}d", uid)

    let flags = fcntl(fd, F_GETFL)
    _ = fcntl(fd, F_SETFL, flags | O_NONBLOCK)

    let source = DispatchSource.makeReadSource(fileDescriptor: fd, queue: self.queue)
    let writeSource = DispatchSource.makeWriteSource(fileDescriptor: fd, queue: self.queue)
    let conn = Conn(fd: fd, uid: uid, source: source, writeSource: writeSource)
    source.setEventHandler { [weak self] in
      self?.readAvailable(from: conn)
    }
    writeSource.setEventHandler { [weak self] in
      self?.drainOutbound(conn)
    }
    source.resume()
    self.conns[fd] = conn
  }

  private func readAvailable(from conn: Conn) {
    var buf = [UInt8](repeating: 0, count: 4096)
    while true {
      let n = read(conn.fd, &buf, buf.count)
      if n > 0 {
        for msg in conn.parser.append(Data(buf[..<n])) {
          self.handle(msg, from: conn)
        }
      } else if n == 0 {
        os_log("[G•] UDS server: connection EOF, uid %{public}d", conn.uid)
        self.closeConn(conn)
        return
      } else if errno == EAGAIN {
        return
      } else if errno == EINTR {
        continue
      } else {
        os_log("[G•] UDS server: read error: %{public}s", String(cString: strerror(errno)))
        self.closeConn(conn)
        return
      }
    }
  }

  private func handle(_ msg: UDSSpikeMessage, from conn: Conn) {
    self.receivedLog.append(msg)
    switch msg {
    case .hello(let pid, let uid, let version):
      os_log(
        "[G•] UDS server: received hello, pid %{public}d, uid %{public}d, version %{public}s",
        pid,
        uid,
        version,
      )
      self.send(.helloAck(filterPid: getpid(), filterVersion: bundleVersion()), to: conn)
    case .ping(let seq):
      os_log("[G•] UDS server: received ping %{public}d", seq)
      self.send(.pong(seq: seq), to: conn)
    case .pushAck(let seq):
      os_log("[G•] UDS server: received pushAck %{public}d (filter->app->filter proven)", seq)
    case .blob(let seq, let data):
      os_log("[G•] UDS server: received blob %{public}d, %{public}d bytes", seq, data.count)
      self.send(
        .blobAck(seq: seq, byteCount: data.count, checksum: UDSFrame.checksum(data)),
        to: conn,
      )
    case .helloAck, .pong, .filterPush, .blobAck:
      os_log("[G•] UDS server: unexpected message: %{public}s", "\(msg)")
    }
  }

  private func send(_ msg: UDSSpikeMessage, to conn: Conn) {
    guard let data = try? UDSFrame.encode(msg) else {
      os_log("[G•] UDS server: encode failed")
      return
    }
    guard conn.outboundBytes + data.count <= self.maxOutboundBytes else {
      os_log(
        "[G•] UDS server: outbound buffer overflow (%{public}d pending), closing uid %{public}d",
        conn.outboundBytes,
        conn.uid,
      )
      self.closeConn(conn)
      return
    }
    conn.outbound.append(data)
    conn.outboundBytes += data.count
    self.drainOutbound(conn)
  }

  private func drainOutbound(_ conn: Conn) {
    guard self.conns[conn.fd] === conn else { return }
    while let chunk = conn.outbound.first {
      let n = chunk.withUnsafeBytes { bytes in
        Darwin.send(
          conn.fd,
          bytes.baseAddress! + conn.outboundOffset,
          chunk.count - conn.outboundOffset,
          0,
        )
      }
      if n > 0 {
        conn.outboundOffset += n
        conn.outboundBytes -= n
        if conn.outboundOffset == chunk.count {
          conn.outbound.removeFirst()
          conn.outboundOffset = 0
        }
      } else if errno == EAGAIN {
        self.armWriteSource(conn)
        return
      } else if errno == EINTR {
        continue
      } else {
        os_log("[G•] UDS server: send failed: %{public}s", String(cString: strerror(errno)))
        self.closeConn(conn)
        return
      }
    }
    self.disarmWriteSource(conn)
  }

  private func armWriteSource(_ conn: Conn) {
    guard !conn.writeSourceArmed else { return }
    conn.writeSourceArmed = true
    conn.writeSource.resume()
  }

  private func disarmWriteSource(_ conn: Conn) {
    guard conn.writeSourceArmed else { return }
    conn.writeSourceArmed = false
    conn.writeSource.suspend()
  }

  private func startPushTimer() {
    guard self.pushInterval > 0, self.pushTimer == nil else { return }
    let timer = DispatchSource.makeTimerSource(queue: self.queue)
    timer.schedule(deadline: .now() + self.pushInterval, repeating: self.pushInterval)
    timer.setEventHandler { [weak self] in
      guard let self else { return }
      self.pushSeq += 1
      let seq = self.pushSeq
      for conn in self.conns.values {
        os_log("[G•] UDS server: pushing filterPush %{public}d to uid %{public}d", seq, conn.uid)
        self.send(.filterPush(seq: seq), to: conn)
      }
    }
    timer.resume()
    self.pushTimer = timer
  }

  private func closeConn(_ conn: Conn) {
    conn.source.cancel()
    if !conn.writeSourceArmed {
      conn.writeSource.resume()
    }
    conn.writeSource.cancel()
    close(conn.fd)
    self.conns[conn.fd] = nil
  }
}

private func peerAuditToken(_ fd: Int32) -> Data? {
  var token = audit_token_t()
  var length = socklen_t(MemoryLayout<audit_token_t>.size)
  let result = withUnsafeMutablePointer(to: &token) { ptr in
    getsockopt(fd, SOL_LOCAL, LOCAL_PEERTOKEN, ptr, &length)
  }
  guard result == 0, length == socklen_t(MemoryLayout<audit_token_t>.size) else {
    return nil
  }
  return withUnsafeBytes(of: &token) { Data($0) }
}

private func setNoSigPipe(_ fd: Int32) {
  var on: Int32 = 1
  setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout<Int32>.size))
}

private func bundleVersion() -> String {
  Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
}
