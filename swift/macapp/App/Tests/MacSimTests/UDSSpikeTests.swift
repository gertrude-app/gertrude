import Core
import Foundation
import XCTest
import XExpect

@testable import App
@testable import Filter

final class UDSSpikeTests: XCTestCase {
  var dir: String!
  var server: UDSSpikeServer!
  var client: UDSSpikeClient!

  override func setUp() {
    super.setUp()
    self.dir = "/tmp/uds-spike-test-\(UUID().uuidString.prefix(8))"
  }

  override func tearDown() {
    self.client?.stop()
    self.server?.stop()
    try? FileManager.default.removeItem(atPath: self.dir)
    super.tearDown()
  }

  func testBidirectionalCodableRoundTrip() throws {
    self.server = UDSSpikeServer(
      rootDir: self.dir,
      pushInterval: 0.2, // fast filter->app pushes for test
      validatePeer: { token, expectedUid in
        UDSSpikeServer.uidFromToken(token) == expectedUid // real LOCAL_PEERTOKEN plumbing
      },
    )
    self.server.start(uids: [getuid()])
    self.waitFor("socket bound") {
      FileManager.default.fileExists(atPath: UDSSpike.socketPath(for: getuid(), in: self.dir))
    }

    self.client = UDSSpikeClient(
      socketPath: UDSSpike.socketPath(for: getuid(), in: self.dir),
      pingInterval: 0.2,
    )
    self.client.start()

    self.waitFor("app->filter->app: helloAck + pong received") {
      let received = self.client.snapshot()
      return received.contains { if case .helloAck = $0 { true } else { false } }
        && received.contains { if case .pong = $0 { true } else { false } }
    }

    self.waitFor("filter->app->filter: push acked") {
      self.server.snapshot().received
        .contains { if case .pushAck = $0 { true } else { false } }
    }

    self.waitFor("client saw filterPush") {
      self.client.snapshot().contains { if case .filterPush = $0 { true } else { false } }
    }
  }

  func testPeerValidationFailureClosesConnection() throws {
    self.server = UDSSpikeServer(
      rootDir: self.dir,
      pushInterval: 0,
      validatePeer: { _, _ in false }, // reject everyone
    )
    self.server.start(uids: [getuid()])
    self.waitFor("socket bound") {
      FileManager.default.fileExists(atPath: UDSSpike.socketPath(for: getuid(), in: self.dir))
    }

    self.client = UDSSpikeClient(
      socketPath: UDSSpike.socketPath(for: getuid(), in: self.dir),
      pingInterval: 0.2,
    )
    self.client.start()

    Thread.sleep(forTimeInterval: 1.0)
    expect(self.server.snapshot().connectionCount).toEqual(0)
    expect(self.client.snapshot().isEmpty).toEqual(true)
  }

  func testServerRebindAfterRestartClientReconnects() throws {
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
      pingInterval: 0.2,
    )
    self.client.start()
    self.waitFor("first connection") {
      self.client.snapshot().contains { if case .helloAck = $0 { true } else { false } }
    }

    self.server.stop() // simulates filter kill: socket closed + unlinked
    self.server = UDSSpikeServer(
      rootDir: self.dir,
      pushInterval: 0,
      validatePeer: { token, uid in UDSSpikeServer.uidFromToken(token) == uid },
    )
    self.server.start(uids: [getuid()]) // respawned filter rebinds

    self.waitFor("client reconnected after rebind", timeout: 10) {
      self.client.snapshot()
        .count(where: { if case .helloAck = $0 { true } else { false } }) >= 2
    }
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
