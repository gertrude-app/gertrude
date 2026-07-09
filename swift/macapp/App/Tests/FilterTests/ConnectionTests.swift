import Core
import Foundation
import XCTest
import XExpect

final class ConnectionTests: XCTestCase {
  func testReplaceIfCurrentReplacesMatchingConnection() async throws {
    let connection = Connection { testXpcConnection() }
    let originalId = try await underlyingId(of: connection)

    await connection.replace(ifCurrent: originalId) { testXpcConnection() }

    let replacedId = try await underlyingId(of: connection)
    expect(replacedId == originalId).toBeFalse()
  }

  func testReplaceIfCurrentIgnoresStaleConnectionId() async throws {
    let connection = Connection { testXpcConnection() }
    let staleId = try await underlyingId(of: connection)

    await connection.replace(with: { testXpcConnection() }) // <-- staleId now stale
    let currentId = try await underlyingId(of: connection)

    await connection.replace(ifCurrent: staleId) { testXpcConnection() }

    let finalId = try await underlyingId(of: connection)
    expect(finalId == currentId).toBeTrue() // <-- stale id did not clobber
  }
}

// helpers

private func testXpcConnection() -> NSXPCConnection {
  NSXPCConnection(machServiceName: "com.netrivet.gertrude.test", options: [])
}

private func underlyingId(of connection: Connection) async throws -> ObjectIdentifier {
  let box = Mutex<ObjectIdentifier?>(nil)
  try await connection.withUnderlying { underlying in
    let id = ObjectIdentifier(underlying)
    box.replace(with: id)
  }
  return box.value!
}
