import Combine
import Core
import Darwin
import Dependencies
import Foundation
import os.log

public final class UDSServer: @unchecked Sendable {
  public static let shared = UDSServer(
    validatePeer: UDSServer.livePeerValidation,
    handleMessage: UDSServer.shadowMessageHandler,
  )

  public typealias PeerValidation = @Sendable (_ auditToken: Data, _ expectedUid: uid_t) -> Bool
  public typealias MessageHandler = @Sendable (_ message: UDS.Message, _ uid: uid_t)
    -> UDS.Message?

  private struct Listener {
    let fd: Int32
    let uid: uid_t
    let source: DispatchSourceRead
  }

  private final class Conn {
    let fd: Int32
    let uid: uid_t
    let acceptedAt = Date()
    let source: DispatchSourceRead
    let writeSource: DispatchSourceWrite
    let parser: UDSFrameParser
    var outbound: [Data] = []
    var outboundOffset = 0
    var outboundBytes = 0
    var writeSourceArmed = false

    init(
      fd: Int32,
      uid: uid_t,
      source: DispatchSourceRead,
      writeSource: DispatchSourceWrite,
      maxPayloadBytes: Int,
    ) {
      self.fd = fd
      self.uid = uid
      self.source = source
      self.writeSource = writeSource
      self.parser = UDSFrameParser(maxPayloadBytes: maxPayloadBytes)
    }
  }

  private let queue = DispatchQueue(label: "com.netrivet.gertrude.uds-server")
  private let rootDir: String
  private let maxOutboundBytes: Int
  private let maxPayloadBytes: Int
  private let maxConnsPerUid: Int
  private let maxTotalConns: Int
  private let validatePeer: PeerValidation
  private let handleMessage: MessageHandler
  private var listeners: [uid_t: Listener] = [:]
  private var conns: [Int32: Conn] = [:]
  private var receivedLog: [UDS.Message] = []
  private var xpcEventCount = 0
  private var statsTimer: DispatchSourceTimer?
  private var xpcSubscription: AnyCancellable?

  public init(
    rootDir: String = UDS.socketDir,
    maxOutboundBytes: Int = 64 * 1024 * 1024,
    maxPayloadBytes: Int = UDSFrame.maxPayloadBytes,
    maxConnsPerUid: Int = 2,
    maxTotalConns: Int = 32,
    validatePeer: @escaping PeerValidation,
    handleMessage: @escaping MessageHandler,
  ) {
    self.rootDir = rootDir
    self.maxOutboundBytes = maxOutboundBytes
    self.maxPayloadBytes = maxPayloadBytes
    self.maxConnsPerUid = maxConnsPerUid
    self.maxTotalConns = maxTotalConns
    self.validatePeer = validatePeer
    self.handleMessage = handleMessage
  }

  public func start(uids: [uid_t] = UDSServer.discoverUids()) {
    self.queue.async {
      self.createSocketDir()
      for uid in Set(uids) {
        self.bindListener(for: uid)
      }
      self.startStatsTimer()
      self.subscribeToXpcEvents()
    }
  }

  public func stop() {
    self.queue.sync {
      self.statsTimer?.cancel()
      self.statsTimer = nil
      self.xpcSubscription = nil
      for conn in Array(self.conns.values) {
        self.closeConn(conn)
      }
      for listener in self.listeners.values {
        listener.source.cancel()
        close(listener.fd)
        unlink(UDS.socketPath(for: listener.uid, in: self.rootDir))
      }
      self.listeners = [:]
    }
  }

  public func send(_ message: UDS.Message, toUid uid: uid_t) {
    self.queue.async {
      for conn in self.conns.values where conn.uid == uid {
        self.send(UDS.Envelope(message: message), to: conn)
      }
    }
  }

  public func snapshot() -> (received: [UDS.Message], connectionCount: Int) {
    self.queue.sync { (self.receivedLog, self.conns.count) }
  }

  public static func discoverUids() -> [uid_t] {
    let names = (try? FileManager.default.contentsOfDirectory(atPath: "/Users")) ?? []
    return names.compactMap { name in
      guard !name.hasPrefix("."), name != "Shared" else { return nil }
      var info = stat()
      guard stat("/Users/\(name)", &info) == 0, info.st_uid >= 500 else { return nil }
      return info.st_uid
    }
  }

  // MARK: - listening

  private func createSocketDir() {
    try? FileManager.default.createDirectory(
      atPath: self.rootDir,
      withIntermediateDirectories: true,
      attributes: [.posixPermissions: 0o755],
    )
  }

  private func bindListener(for uid: uid_t) {
    let path = UDS.socketPath(for: uid, in: self.rootDir)
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

    guard self.conns.count < self.maxTotalConns else {
      os_log("[G•] UDS server: max connections reached, rejecting uid %{public}d", uid)
      close(fd)
      return
    }

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

    let uidConns = self.conns.values
      .filter { $0.uid == uid }
      .sorted { $0.acceptedAt < $1.acceptedAt }
    if uidConns.count >= self.maxConnsPerUid, let oldest = uidConns.first {
      // the newest connection is the live app (e.g. relaunched); stale
      // connections the kernel hasn't EOF'd yet are the ones to shed
      os_log("[G•] UDS server: uid %{public}d conn limit, closing oldest", uid)
      self.closeConn(oldest)
    }

    let flags = fcntl(fd, F_GETFL)
    _ = fcntl(fd, F_SETFL, flags | O_NONBLOCK)

    let source = DispatchSource.makeReadSource(fileDescriptor: fd, queue: self.queue)
    let writeSource = DispatchSource.makeWriteSource(fileDescriptor: fd, queue: self.queue)
    let conn = Conn(
      fd: fd,
      uid: uid,
      source: source,
      writeSource: writeSource,
      maxPayloadBytes: self.maxPayloadBytes,
    )
    source.setEventHandler { [weak self] in
      self?.readAvailable(from: conn)
    }
    writeSource.setEventHandler { [weak self] in
      self?.drainOutbound(conn)
    }
    source.resume()
    self.conns[fd] = conn
  }

  // MARK: - reading & handling

  private func readAvailable(from conn: Conn) {
    var buf = [UInt8](repeating: 0, count: 4096)
    while true {
      let n = read(conn.fd, &buf, buf.count)
      if n > 0 {
        for envelope in conn.parser.append(Data(buf[..<n])) {
          self.handle(envelope, from: conn)
        }
        if conn.parser.failed {
          os_log("[G•] UDS server: oversized frame, closing uid %{public}d", conn.uid)
          self.closeConn(conn)
          return
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

  private func handle(_ envelope: UDS.Envelope, from conn: Conn) {
    self.receivedLog.append(envelope.message)
    if self.receivedLog.count > 512 {
      self.receivedLog.removeFirst(self.receivedLog.count - 512)
    }
    if case .hello(let pid, let uid, let version) = envelope.message {
      os_log(
        "[G•] UDS server: hello from pid %{public}d, uid %{public}d, version %{public}s",
        pid,
        uid,
        version,
      )
      self.send(UDS.Envelope(
        replyTo: envelope.id,
        message: .helloAck(pid: getpid(), version: filterVersion()),
      ), to: conn)
      return
    }
    if let reply = self.handleMessage(envelope.message, conn.uid) {
      self.send(UDS.Envelope(replyTo: envelope.id, message: reply), to: conn)
    }
  }

  // MARK: - writing

  private func send(_ envelope: UDS.Envelope, to conn: Conn) {
    guard let data = try? UDSFrame.encode(envelope) else {
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

  private func closeConn(_ conn: Conn) {
    conn.source.cancel()
    if !conn.writeSourceArmed {
      conn.writeSource.resume()
    }
    conn.writeSource.cancel()
    close(conn.fd)
    self.conns[conn.fd] = nil
  }

  // MARK: - shadow observability

  private func subscribeToXpcEvents() {
    self.xpcSubscription = xpcEventSubject.withValue { subject in
      Move(subject.eraseToAnyPublisher())
    }.consume().sink { [weak self] _ in
      guard let self else { return }
      self.queue.async { self.xpcEventCount += 1 }
    }
  }

  private func startStatsTimer() {
    guard self.statsTimer == nil else { return }
    let timer = DispatchSource.makeTimerSource(queue: self.queue)
    timer.schedule(deadline: .now() + 300, repeating: 300)
    timer.setEventHandler { [weak self] in
      guard let self else { return }
      os_log(
        "[G•] UDS server: shadow stats: conns %{public}d, uds received %{public}d, xpc events %{public}d",
        self.conns.count,
        self.receivedLog.count,
        self.xpcEventCount,
      )
    }
    timer.resume()
    self.statsTimer = timer
  }
}

// MARK: - live peer validation

public extension UDSServer {
  static let livePeerValidation: PeerValidation = { token, expectedUid in
    let security = SecurityClient.liveValue
    guard let uid = security.userIdFromAuditToken(token), uid == expectedUid else {
      os_log("[G•] UDS server: peer rejected, uid mismatch")
      return false
    }
    guard peerSatisfiesCodeRequirement(token) else {
      os_log("[G•] UDS server: peer rejected, code requirement not satisfied")
      return false
    }
    return true
  }

  static func uidFromToken(_ token: Data) -> uid_t? {
    SecurityClient.liveValue.userIdFromAuditToken(token)
  }

  static func peerSatisfiesCodeRequirement(_ token: Data) -> Bool {
    var secCode: SecCode?
    let status = SecCodeCopyGuestWithAttributes(
      nil,
      [kSecGuestAttributeAudit: token] as NSDictionary,
      [],
      &secCode,
    )
    guard status == errSecSuccess, let code = secCode else {
      return false
    }
    let requirementString = "anchor apple generic"
      + " and identifier \"\(Constants.APP_BUNDLE_ID)\""
      + " and certificate leaf[subject.OU] = \"\(Constants.TEAM_ID)\""
    var requirement: SecRequirement?
    guard SecRequirementCreateWithString(
      requirementString as CFString,
      [],
      &requirement,
    ) == errSecSuccess, let requirement else {
      return false
    }
    return SecCodeCheckValidity(code, [], requirement) == errSecSuccess
  }
}

// MARK: - live shadow message handling

public extension UDSServer {
  // phase A dark-ship: shadow-received messages are logged and answered,
  // but NEVER applied -- the filter's state only changes via XPC deliveries
  static let shadowMessageHandler: MessageHandler = { message, uid in
    os_log(
      "[G•] UDS server: shadow received %{public}s for uid %{public}d",
      caseName(of: message),
      uid,
    )
    switch message {
    case .ackRequest(let randomInt, let userId):
      return .ack(shadowAck(randomInt: randomInt, userId: userId))
    case .alive:
      return .aliveAck(true)
    case .userTypesRequest:
      return .userTypes(shadowUserTypes())
    case .hello, .helloAck, .ack, .aliveAck, .userTypes, .success, .failure,
         .blockedRequest, .filterSuspensionEnded, .filterLogs:
      return nil
    case .userRules, .pauseDowntime, .endDowntimePause, .setBlockStreaming,
         .disconnectUser, .setUserExemption, .suspendFilter, .endFilterSuspension,
         .deleteAllStoredState:
      return .success
    }
  }

  private static func shadowAck(randomInt: Int, userId: uid_t) -> XPC.FilterAck {
    @Dependency(\.storage) var storage
    @Dependency(\.filterExtension) var filterExtension
    let savedState = (try? storage.loadPersistentStateSync()) ?? nil
    return XPC.FilterAck(
      randomInt: randomInt,
      version: filterExtension.version(),
      userId: userId,
      numUserKeys: savedState?.userKeychains[userId]?.numKeys ?? 0,
      filteringDisabled: savedState?.filteringDisabledUsers?.contains(userId) == true
        ? true : nil,
    )
  }

  private static func shadowUserTypes() -> FilterUserTypes {
    @Dependency(\.storage) var storage
    let savedState = (try? storage.loadPersistentStateSync()) ?? nil
    let exemptUsers = Array(savedState?.exemptUsers ?? [])
    let protectedUsers = savedState.map {
      Array(Set($0.userKeychains.keys).union($0.filteringDisabledUsers ?? []))
    } ?? []
    return FilterUserTypes(exempt: exemptUsers, protected: protectedUsers)
  }
}

// MARK: - helpers

private func caseName(of message: UDS.Message) -> String {
  let description = String(describing: message)
  return String(description.prefix(while: { $0 != "(" }))
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

private func filterVersion() -> String {
  Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
}
