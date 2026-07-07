import Core
import Darwin
import Foundation
import Gertie
import XCTest
import XExpect

@testable import App
@testable import Filter

final class UDSSpikePayloadTests: XCTestCase {
  var dir: String!
  var server: UDSSpikeServer!
  var client: UDSSpikeClient!
  var rawFd: Int32 = -1

  override func setUp() {
    super.setUp()
    self.dir = "/tmp/uds-spike-payload-test-\(UUID().uuidString.prefix(8))"
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

  func testRealisticUserRulesPayloadFitsFrameCapWithHeadroom() throws {
    let keychains = (0 ..< 40).map { chainIdx in
      RuleKeychain(keys: (0 ..< 250).map { keyIdx in
        RuleKey(key: .anySubdomain(
          domain: .init(string: "sub-\(chainIdx)-\(keyIdx).realistic-domain-name.com"),
          scope: keyIdx % 3 == 0
            ? .webBrowsers
            : .single(.bundleId("com.example.app-\(keyIdx)")),
        ))
      })
    } // 40 chains x 250 keys = 10k keys, well past heaviest observed users
    let filterData = UserFilterData(keychains: keychains, filteringDisabled: false)
    let manifest = AppIdManifest(
      apps: .init(uniqueKeysWithValues: (0 ..< 2000).map { i in
        ("app-slug-\(i)", Set(["com.vendor\(i).product\(i)", ".com.vendor\(i).product\(i)"]))
      }),
      displayNames: .init(uniqueKeysWithValues: (0 ..< 2000).map { i in
        ("app-slug-\(i)", "Display Name For App \(i)")
      }),
      categories: .init(uniqueKeysWithValues: (0 ..< 15).map { i in
        ("category-\(i)", Set((0 ..< 130).map { "app-slug-\($0 + i * 130)" }))
      }),
    )

    let filterBytes = try JSONEncoder().encode(filterData).count
    let manifestBytes = try JSONEncoder().encode(manifest).count
    let total = filterBytes + manifestBytes
    print(
      "realistic-max userRules payload: filterData=\(filterBytes) manifest=\(manifestBytes) total=\(total) frameCap=\(UDSFrame.maxPayloadBytes)",
    )
    expect(total < UDSFrame.maxPayloadBytes / 4).toEqual(true) // >= 4x headroom
  }

  func testLargeBlobRoundTripBothDirections() throws {
    self.startServerAndClient()
    let appBlob = makeBlob(4 * 1024 * 1024, seed: 1)
    self.client.send(.blob(seq: 1, data: appBlob))
    self.waitFor("app->filter 4MB blob acked", timeout: 30) {
      self.client.snapshot().contains(
        .blobAck(seq: 1, byteCount: appBlob.count, checksum: UDSFrame.checksum(appBlob)),
      )
    }

    let filterBlob = makeBlob(4 * 1024 * 1024, seed: 2)
    self.server.broadcast(.blob(seq: 2, data: filterBlob))
    self.waitFor("filter->app 4MB blob acked", timeout: 30) {
      self.server.snapshot().received.contains(
        .blobAck(seq: 2, byteCount: filterBlob.count, checksum: UDSFrame.checksum(filterBlob)),
      )
    }
  }

  func testAppToFilterBurstOfLargeFrames() throws {
    self.startServerAndClient()
    let blobs = (1 ... 8).map { makeBlob(2 * 1024 * 1024, seed: UInt8($0)) }
    for (i, blob) in blobs.enumerated() {
      self.client.send(.blob(seq: i + 1, data: blob)) // ~21MB wire burst, no pacing
    }
    let expected = blobs.enumerated().map { self.ack(seq: $0.offset + 1, blob: $0.element) }
    self.waitFor("all 8 blobs acked in order", timeout: 60) {
      self.acksReceived(by: self.client.snapshot()) == expected
    }
  }

  func testFilterToAppBurstSurvivesSlowReader() throws {
    self.server = UDSSpikeServer(
      rootDir: self.dir,
      pushInterval: 0,
      validatePeer: { token, uid in UDSSpikeServer.uidFromToken(token) == uid },
    )
    self.server.start(uids: [getuid()])
    self.waitFor("socket bound") {
      FileManager.default.fileExists(atPath: UDSSpike.socketPath(for: getuid(), in: self.dir))
    }

    self.rawFd = rawConnect(to: UDSSpike.socketPath(for: getuid(), in: self.dir))
    expect(self.rawFd != -1).toEqual(true)
    self.waitFor("raw client accepted") { self.server.snapshot().connectionCount == 1 }

    let blobs = (1 ... 6).map { makeBlob(1024 * 1024, seed: UInt8($0)) }
    for (i, blob) in blobs.enumerated() {
      self.server.broadcast(.blob(seq: i + 1, data: blob)) // ~8MB wire, vs ~8KB kernel buf
    }
    Thread.sleep(forTimeInterval: 0.5) // reader stalls well past old 100ms usleep-retry budget

    var received: [UDSSpikeMessage] = []
    let parser = UDSFrameParser()
    var buf = [UInt8](repeating: 0, count: 256 * 1024)
    let deadline = Date().addingTimeInterval(60)
    var sawEof = false
    while received.count < blobs.count, Date() < deadline {
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

    expect(sawEof).toEqual(false) // old usleep-retry code kills the conn instead
    let expected = blobs.enumerated().map { UDSSpikeMessage.blob(
      seq: $0.offset + 1,
      data: $0.element,
    ) }
    expect(received == expected).toEqual(true)
    expect(self.server.snapshot().connectionCount).toEqual(1)
  }

  func testOutboundOverflowClosesWedgedConnection() throws {
    self.server = UDSSpikeServer(
      rootDir: self.dir,
      pushInterval: 0,
      maxOutboundBytes: 2 * 1024 * 1024, // small cap so a never-reading peer trips it fast
      validatePeer: { token, uid in UDSSpikeServer.uidFromToken(token) == uid },
    )
    self.server.start(uids: [getuid()])
    self.waitFor("socket bound") {
      FileManager.default.fileExists(atPath: UDSSpike.socketPath(for: getuid(), in: self.dir))
    }

    self.rawFd = rawConnect(to: UDSSpike.socketPath(for: getuid(), in: self.dir))
    expect(self.rawFd != -1).toEqual(true)
    self.waitFor("raw client accepted") { self.server.snapshot().connectionCount == 1 }

    for i in 1 ... 4 {
      self.server.broadcast(.blob(seq: i, data: makeBlob(1024 * 1024, seed: UInt8(i))))
    }
    self.waitFor("wedged never-reading conn dropped") {
      self.server.snapshot().connectionCount == 0
    }
  }

  private func startServerAndClient() {
    self.server = UDSSpikeServer(
      rootDir: self.dir,
      pushInterval: 0,
      validatePeer: { token, uid in UDSSpikeServer.uidFromToken(token) == uid },
    )
    self.server.start(uids: [getuid()])
    self.waitFor("socket bound") {
      FileManager.default.fileExists(atPath: UDSSpike.socketPath(for: getuid(), in: self.dir))
    }
    self.client = UDSSpikeClient(
      socketPath: UDSSpike.socketPath(for: getuid(), in: self.dir),
      pingInterval: 0,
    )
    self.client.start()
    self.waitFor("client connected") {
      self.client.snapshot().contains { if case .helloAck = $0 { true } else { false } }
    }
  }

  private func ack(seq: Int, blob: Data) -> UDSSpikeMessage {
    .blobAck(seq: seq, byteCount: blob.count, checksum: UDSFrame.checksum(blob))
  }

  private func acksReceived(by messages: [UDSSpikeMessage]) -> [UDSSpikeMessage] {
    messages.filter { if case .blobAck = $0 { true } else { false } }
  }

  private func waitFor(
    _ what: String,
    timeout: TimeInterval = 5,
    _ condition: () -> Bool,
  ) {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
      if condition() { return }
      Thread.sleep(forTimeInterval: 0.05)
    }
    XCTFail("timed out waiting for: \(what)")
  }
}

private func makeBlob(_ size: Int, seed: UInt8) -> Data {
  var bytes = [UInt8](repeating: 0, count: size)
  var state = UInt32(seed) &+ 1
  for i in 0 ..< size {
    state = state &* 1_664_525 &+ 1_013_904_223
    bytes[i] = UInt8(truncatingIfNeeded: state >> 16)
  }
  return Data(bytes)
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
