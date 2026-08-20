import Dependencies
import XCTest
import XExpect

@testable import Api

final class GetComputerStatusesResolverTests: ApiTestCase, @unchecked Sendable {
  func testReturnsOnlyParentOwnedComputerUsers() async throws {
    let owned = try await self.childWithComputer()
    let other = try await self.childWithComputer()
    let receivedAt = Date.reference
    let details = ComputerUserStatus(
      apiReachable: true,
      effectiveFilterStatus: .filterOff,
      snapshotReceivedAt: receivedAt,
      snapshotFreshness: .fresh,
    )

    let output = try await withDependencies {
      $0.websockets.statusDetails = { computerUserId in
        expect(computerUserId).toEqual(owned.computerUser.id)
        return details
      }
    } operation: {
      try await GetComputerStatuses.resolve(in: context(owned.parent))
    }

    expect(output).toEqual([
      .init(
        computerUserId: owned.computerUser.id,
        computerId: owned.computer.id,
        childId: owned.id,
        status: .filterOff,
        apiReachable: true,
        effectiveFilterStatus: .filterOff,
        snapshotReceivedAt: receivedAt,
        snapshotFreshness: .fresh,
      ),
    ])
    XCTAssertFalse(output.contains { $0.computerUserId == other.computerUser.id })
  }
}
