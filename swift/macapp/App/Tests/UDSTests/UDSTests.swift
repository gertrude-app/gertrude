import Core
import Darwin
import Foundation
import Gertie
import XCTest
import XExpect

@testable import Filter
@testable import LiveFilterXPCClient

final class UDSTests: XCTestCase {
  var dir: String!
  var server: UDSServer!
  var client: UDSClient!
  var rawFd: Int32 = -1

  override func setUp() {
    super.setUp()
    // NB: /tmp not scratchpad, sun_path is capped at 104 bytes
    self.dir = "/tmp/uds-test-\(UUID().uuidString.prefix(8))"
  }

  override func tearDown() {
    if self.rawFd != -1 {
      close(self.rawFd)
      self.rawFd = -1
    }
    self.client?.stop()
    self.server?.stop()
    try? FileManager.default.removeItem(atPath: self.dir)
    super.tearDown()
  }

  func testHandshakeAndRequestReplyRoundTrip() async throws {
    self.startServer()
    try await self.startClientAndAwaitHealthy()

    let randomInt = 12345
    let reply = try await self.client.request(.ackRequest(randomInt: randomInt, userId: getuid()))
    guard case .ack(let ack) = reply else {
      return XCTFail("expected .ack, got \(reply)")
    }
    expect(ack.randomInt).toEqual(randomInt)
    expect(ack.version).toEqual("1.0.0-test")

    let received = self.server.snapshot().received
    expect(received.contains { if case .hello = $0 { true } else { false } }).toEqual(true)
  }

  func testConcurrentRequestsCorrelateReplies() async throws {
    self.startServer()
    try await self.startClientAndAwaitHealthy()

    try await withThrowingTaskGroup(of: (Int, UDS.Message).self) { group in
      for randomInt in 1 ... 20 {
        group.addTask {
          let reply = try await self.client.request(
            .ackRequest(randomInt: randomInt, userId: getuid()),
            timeout: 10,
          )
          return (randomInt, reply)
        }
      }
      for try await (randomInt, reply) in group {
        guard case .ack(let ack) = reply else {
          return XCTFail("expected .ack, got \(reply)")
        }
        expect(ack.randomInt).toEqual(randomInt) // replies matched by correlation id
      }
    }
  }

  func testRequestTimesOutWhenNoReply() async throws {
    self.startServer(handleMessage: { _, _ in nil }) // never replies
    self.client = UDSClient(
      socketPath: UDS.socketPath(for: getuid(), in: self.dir),
      heartbeatInterval: 0,
    )
    self.client.start()
    try await self.waitFor("client connected") {
      self.server.snapshot().connectionCount == 1
    }

    do {
      _ = try await self.client.request(.alive(userId: getuid()), timeout: 0.5)
      XCTFail("expected timeout")
    } catch {
      guard let xpcErr = error as? XPCErr, case .timeout = xpcErr else {
        return XCTFail("expected timeout, got \(error)")
      }
    }
  }

  func testPeerValidationFailureClosesConnection() async throws {
    self.startServer(validatePeer: { _, _ in false }) // reject everyone
    self.client = UDSClient(
      socketPath: UDS.socketPath(for: getuid(), in: self.dir),
      heartbeatInterval: 0,
    )
    self.client.start()

    try await Task.sleep(nanoseconds: 1_000_000_000)
    expect(self.server.snapshot().connectionCount).toEqual(0)
    expect(self.server.snapshot().received.isEmpty).toEqual(true)
  }

  func testServerRebindAfterRestartClientReconnects() async throws {
    self.startServer()
    try await self.startClientAndAwaitHealthy()

    self.server.stop() // simulates filter kill: socket closed + unlinked
    self.startServer() // respawned filter rebinds

    try await self.waitFor("client reconnected after rebind", timeout: 10) {
      self.server.snapshot().received
        .contains { if case .hello = $0 { true } else { false } }
    }
    let health = await self.client.health()
    expect(health.healthy).toEqual(true)
  }

  func testRealisticMaxUserRulesRoundTripsWithHeadroom() async throws {
    self.startServer()
    try await self.startClientAndAwaitHealthy()

    let message = makeUserRules(chains: 40, keysPerChain: 250, manifestApps: 2000)
    let encoded = try UDSFrame.encode(UDS.Envelope(message: message))
    expect(encoded.count > 1024 * 1024).toEqual(true) // proves a genuinely large frame
    expect(encoded.count < UDSFrame.maxPayloadBytes / 4).toEqual(true) // >= 4x headroom

    let reply = try await self.client.request(message, timeout: 30)
    expect(reply).toEqual(.success)
    expect(self.server.snapshot().received.contains(message)).toEqual(true) // intact payload
  }

  func testFilterToAppBurstSurvivesSlowReader() async throws {
    self.startServer()
    self.rawFd = rawConnect(to: UDS.socketPath(for: getuid(), in: self.dir))
    expect(self.rawFd != -1).toEqual(true)
    try await self.waitFor("raw client accepted") {
      self.server.snapshot().connectionCount == 1
    }

    let messages = (1 ... 6).map { makeUserRules(chains: 20, keysPerChain: 250, seed: $0) }
    for message in messages {
      self.server.send(message, toUid: getuid()) // ~6MB wire, vs ~8KB kernel buf
    }
    Thread.sleep(forTimeInterval: 0.5) // reader stalls against a full kernel buffer

    var received: [UDS.Envelope] = []
    let parser = UDSFrameParser()
    var buf = [UInt8](repeating: 0, count: 256 * 1024)
    let deadline = Date().addingTimeInterval(60)
    var sawEof = false
    while received.count < messages.count, Date() < deadline {
      let n = read(self.rawFd, &buf, buf.count)
      if n > 0 {
        received += parser.append(Data(buf[..<n]))
        Thread.sleep(forTimeInterval: 0.005) // keep draining slower than server can fill
      } else if n == 0 {
        sawEof = true
        break
      } else if errno == EINTR {
        continue
      } else {
        break
      }
    }

    expect(sawEof).toEqual(false) // write queue parks bytes instead of killing the conn
    expect(received.map(\.message) == messages).toEqual(true) // intact, in order
    expect(self.server.snapshot().connectionCount).toEqual(1)
  }

  func testOutboundOverflowClosesWedgedConnection() async throws {
    self.startServer(maxOutboundBytes: 2 * 1024 * 1024)
    self.rawFd = rawConnect(to: UDS.socketPath(for: getuid(), in: self.dir))
    expect(self.rawFd != -1).toEqual(true)
    try await self.waitFor("raw client accepted") {
      self.server.snapshot().connectionCount == 1
    }

    for seed in 1 ... 4 { // ~4MB at a never-reading peer trips the 2MB cap
      self.server.send(makeUserRules(chains: 20, keysPerChain: 250, seed: seed), toUid: getuid())
    }
    try await self.waitFor("wedged never-reading conn dropped") {
      self.server.snapshot().connectionCount == 0
    }
  }

  func testPerUidConnectionLimitShedsOldest() async throws {
    self.startServer()
    self.rawFd = rawConnect(to: UDS.socketPath(for: getuid(), in: self.dir))
    let second = rawConnect(to: UDS.socketPath(for: getuid(), in: self.dir))
    defer { close(second) }
    try await self.waitFor("two conns accepted") {
      self.server.snapshot().connectionCount == 2
    }

    let third = rawConnect(to: UDS.socketPath(for: getuid(), in: self.dir))
    defer { close(third) }
    try await self.waitFor("oldest conn shed, still at limit") {
      var buf = [UInt8](repeating: 0, count: 1)
      // oldest (rawFd) sees EOF when the limit sheds it
      return read(self.rawFd, &buf, 1) == 0 && self.server.snapshot().connectionCount == 2
    }
  }

  // MARK: - helpers

  private func startServer(
    maxOutboundBytes: Int = 64 * 1024 * 1024,
    validatePeer: @escaping UDSServer.PeerValidation = { token, uid in
      UDSServer.uidFromToken(token) == uid // real LOCAL_PEERTOKEN plumbing
    },
    handleMessage: @escaping UDSServer.MessageHandler = UDSTests.testMessageHandler,
  ) {
    self.server = UDSServer(
      rootDir: self.dir,
      maxOutboundBytes: maxOutboundBytes,
      validatePeer: validatePeer,
      handleMessage: handleMessage,
    )
    self.server.start(uids: [getuid()])
    let path = UDS.socketPath(for: getuid(), in: self.dir)
    let deadline = Date().addingTimeInterval(5)
    while !FileManager.default.fileExists(atPath: path), Date() < deadline {
      Thread.sleep(forTimeInterval: 0.05)
    }
  }

  static let testMessageHandler: UDSServer.MessageHandler = { message, uid in
    switch message {
    case .ackRequest(let randomInt, let userId):
      .ack(.init(randomInt: randomInt, version: "1.0.0-test", userId: userId, numUserKeys: 0))
    case .alive:
      .aliveAck(true)
    case .hello, .helloAck, .ack, .aliveAck, .userTypes, .success, .failure,
         .blockedRequest, .filterSuspensionEnded, .filterLogs, .userTypesRequest:
      nil
    case .userRules, .pauseDowntime, .endDowntimePause, .setBlockStreaming,
         .disconnectUser, .setUserExemption, .suspendFilter, .endFilterSuspension,
         .deleteAllStoredState:
      .success
    }
  }

  private func startClientAndAwaitHealthy() async throws {
    self.client = UDSClient(
      socketPath: UDS.socketPath(for: getuid(), in: self.dir),
      heartbeatInterval: 0,
    )
    self.client.start()
    let deadline = Date().addingTimeInterval(5)
    while Date() < deadline {
      let health = await self.client.health()
      if health.healthy { return }
      try await Task.sleep(nanoseconds: 50_000_000)
    }
    XCTFail("timed out waiting for healthy client")
  }

  private func waitFor(
    _ what: String,
    timeout: TimeInterval = 5,
    _ condition: () -> Bool,
  ) async throws {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
      if condition() { return }
      try await Task.sleep(nanoseconds: 50_000_000)
    }
    XCTFail("timed out waiting for: \(what)")
  }
}

final class UDSFrameParserTests: XCTestCase {
  func testOversizedFrameFailsParser() throws {
    let parser = UDSFrameParser(maxPayloadBytes: 1024)
    var length = UInt32(2048).bigEndian
    var data = Data(bytes: &length, count: 4)
    data.append(Data(repeating: 0, count: 8))
    expect(parser.append(data).isEmpty).toEqual(true)
    expect(parser.failed).toEqual(true)
  }

  func testUnknownMessageSkipsFrameKeepsStreamInSync() throws {
    let parser = UDSFrameParser()
    let good = try UDSFrame.encode(.init(message: .alive(userId: 501)))

    let unknownPayload = Data(#"{"newerAppMessage":{"_0":true}}"#.utf8) // version skew
    var length = UInt32(unknownPayload.count).bigEndian
    var unknown = Data(bytes: &length, count: 4)
    unknown.append(unknownPayload)

    var stream = good
    stream.append(unknown)
    stream.append(good)

    let envelopes = parser.append(stream)
    expect(envelopes.count).toEqual(2)
    expect(parser.skippedFrames).toEqual(1)
    expect(parser.failed).toEqual(false)
  }

  func testPartialFramesReassemble() throws {
    let parser = UDSFrameParser()
    let frame = try UDSFrame.encode(.init(message: .alive(userId: 501)))
    let mid = frame.count / 2
    expect(parser.append(frame.prefix(mid)).isEmpty).toEqual(true)
    let envelopes = parser.append(frame.suffix(from: mid))
    expect(envelopes.count).toEqual(1)
    expect(envelopes[0].message).toEqual(.alive(userId: 501))
  }
}

// MARK: - test data & raw socket helpers

private func makeUserRules(
  chains: Int,
  keysPerChain: Int,
  manifestApps: Int = 0,
  seed: Int = 0,
) -> UDS.Message {
  let keychains = (0 ..< chains).map { chainIdx in
    RuleKeychain(keys: (0 ..< keysPerChain).map { keyIdx in
      RuleKey(key: .anySubdomain(
        domain: .init(string: "sub-\(seed)-\(chainIdx)-\(keyIdx).realistic-domain-name.com"),
        scope: keyIdx % 3 == 0
          ? .webBrowsers
          : .single(.bundleId("com.example.app-\(keyIdx)")),
      ))
    })
  }
  let manifest = AppIdManifest(
    apps: .init(uniqueKeysWithValues: (0 ..< manifestApps).map { i in
      ("app-slug-\(i)", Set(["com.vendor\(i).product\(i)", ".com.vendor\(i).product\(i)"]))
    }),
    displayNames: .init(uniqueKeysWithValues: (0 ..< manifestApps).map { i in
      ("app-slug-\(i)", "Display Name For App \(i)")
    }),
    categories: [:],
  )
  return .userRules(
    userId: getuid(),
    manifest: manifest,
    filterData: .init(keychains: keychains, filteringDisabled: false),
  )
}

private func rawConnect(to path: String) -> Int32 {
  let fd = socket(AF_UNIX, SOCK_STREAM, 0)
  guard fd != -1 else { return -1 }
  var on: Int32 = 1
  setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout<Int32>.size))
  var rcvbuf: Int32 = 8192 // pin small so kernel backpressure hits fast + deterministically
  setsockopt(fd, SOL_SOCKET, SO_RCVBUF, &rcvbuf, socklen_t(MemoryLayout<Int32>.size))
  var tv = timeval(tv_sec: 5, tv_usec: 0) // blocking reads bail instead of hanging the test
  setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))
  var addr = sockaddr_un()
  addr.sun_family = sa_family_t(AF_UNIX)
  let pathBytes = path.utf8CString
  guard pathBytes.count <= MemoryLayout.size(ofValue: addr.sun_path) else {
    close(fd)
    return -1
  }
  withUnsafeMutableBytes(of: &addr.sun_path) { dest in
    pathBytes.withUnsafeBytes { src in
      dest.copyMemory(from: src)
    }
  }
  let result = withUnsafePointer(to: &addr) {
    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
      Darwin.connect(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
    }
  }
  guard result == 0 else {
    close(fd)
    return -1
  }
  return fd
}
