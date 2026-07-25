import Foundation
import XCTest
import XExpect

@testable import Api

final class GetSuspensionRequestsResolverTests: ApiTestCase, @unchecked Sendable {
  func testReturnsRecentPendingRequestsForAccountOldestFirst() async throws {
    let child = try await self.child(with: { $0.name = "Jude" }).withDevice()

    var olderRequest = try await self.db.create(MacApp.SuspendFilterRequest(
      computerUserId: child.computerUser.id,
      scope: .unrestricted,
      duration: .init(1800),
      requestComment: "School project",
    ))
    try await olderRequest.modifyCreatedAt(.exact(.reference - .minutes(30)))

    var newerRequest = try await self.db.create(MacApp.SuspendFilterRequest(
      computerUserId: child.computerUser.id,
      scope: .unrestricted,
      duration: .init(300),
    ))
    try await newerRequest.modifyCreatedAt(.exact(.reference - .minutes(5)))

    var resolvedRequest = try await self.db.create(MacApp.SuspendFilterRequest(
      computerUserId: child.computerUser.id,
      status: .accepted,
      scope: .unrestricted,
    ))
    try await resolvedRequest.modifyCreatedAt(.exact(.reference - .minutes(10)))

    var staleRequest = try await self.db.create(MacApp.SuspendFilterRequest(
      computerUserId: child.computerUser.id,
      scope: .unrestricted,
    ))
    try await staleRequest.modifyCreatedAt(.exact(.reference - .hours(2) - 1))

    let otherChild = try await self.child().withDevice()
    var otherParentRequest = try await self.db.create(MacApp.SuspendFilterRequest(
      computerUserId: otherChild.computerUser.id,
      scope: .unrestricted,
    ))
    try await otherParentRequest.modifyCreatedAt(.exact(.reference - .minutes(20)))

    let output = try await GetSuspensionRequests.resolve(
      in: self.accountContext(child.parent),
    )

    expect(output.map(\.id)).toEqual([olderRequest.id, newerRequest.id])

    let first = try XCTUnwrap(output.first)
    expect(first.personId).toEqual(child.id)
    expect(first.personName).toEqual("Jude")
    expect(first.deviceName).toBeNil()
    expect(first.requestedDurationInSeconds).toEqual(1800)
    expect(first.reason).toEqual("School project")
    expect(first.createdAt).toEqual(.reference - .minutes(30))

    let second = try XCTUnwrap(output.last)
    expect(second.requestedDurationInSeconds).toEqual(300)
    expect(second.reason).toBeNil()
  }

  func testIncludesDeviceNamesWhenPersonHasMultipleComputers() async throws {
    let child = try await self.child(with: { $0.name = "Jude" })
    let namedDevice = try await child.withDevice(computer: {
      $0.customName = "Jude's MacBook"
    })
    let unnamedDevice = try await child.withDevice(computer: {
      $0.customName = nil
      $0.modelIdentifier = "Mac16,10"
    })

    var namedRequest = try await self.db.create(MacApp.SuspendFilterRequest(
      computerUserId: namedDevice.computerUser.id,
      scope: .unrestricted,
    ))
    try await namedRequest.modifyCreatedAt(.exact(.reference - .minutes(10)))
    var unnamedRequest = try await self.db.create(MacApp.SuspendFilterRequest(
      computerUserId: unnamedDevice.computerUser.id,
      scope: .unrestricted,
    ))
    try await unnamedRequest.modifyCreatedAt(.exact(.reference - .minutes(5)))

    let output = try await GetSuspensionRequests.resolve(
      in: self.accountContext(child.parent),
    )

    let namedOutput = try XCTUnwrap(output.first { $0.id == namedRequest.id })
    expect(namedOutput.deviceName).toEqual("Jude's MacBook")
    let unnamedOutput = try XCTUnwrap(output.first { $0.id == unnamedRequest.id })
    expect(unnamedOutput.deviceName).toEqual(unnamedDevice.computer.model.shortDescription)
  }

  func testIncludesLegacyExtraMonitoringOptionsForSupportedMacs() async throws {
    let child = try await self.child(with: {
      $0.keyloggingEnabled = false
      $0.screenshotsEnabled = true
      $0.screenshotsFrequency = 120
    })
    let supportedDevice = try await child.withDevice {
      $0.appVersion = "2.1.0"
    }
    let unsupportedDevice = try await child.withDevice {
      $0.appVersion = "2.0.0"
    }

    var supportedRequest = try await self.db.create(MacApp.SuspendFilterRequest(
      computerUserId: supportedDevice.computerUser.id,
      scope: .unrestricted,
    ))
    try await supportedRequest.modifyCreatedAt(.exact(.reference - .minutes(10)))
    var unsupportedRequest = try await self.db.create(MacApp.SuspendFilterRequest(
      computerUserId: unsupportedDevice.computerUser.id,
      scope: .unrestricted,
    ))
    try await unsupportedRequest.modifyCreatedAt(.exact(.reference - .minutes(5)))

    let output = try await GetSuspensionRequests.resolve(
      in: self.accountContext(child.parent),
    )

    let supportedOutput = try XCTUnwrap(output.first { $0.id == supportedRequest.id })
    expect(supportedOutput.extraMonitoringOptions["k"]).toEqual("keylogging")
    expect(supportedOutput.extraMonitoringOptions["@60"]).toEqual("2x screenshots")
    expect(supportedOutput.extraMonitoringOptions["@40+k"])
      .toEqual("3x screenshots + keylogging")
    let unsupportedOutput = try XCTUnwrap(output.first { $0.id == unsupportedRequest.id })
    expect(unsupportedOutput.extraMonitoringOptions).toBeEmpty()
  }

  func testReturnsEmptyWhenAccountHasNoPeople() async throws {
    let parent = try await self.parent()
    let output = try await GetSuspensionRequests.resolve(in: self.accountContext(parent))
    expect(output).toBeEmpty()
  }

  private func accountContext(_ parent: ParentEntities) -> AccountOwnerContext {
    AccountOwnerContext(
      requestId: "test-request",
      dashboardUrl: "",
      accountOwner: parent.model,
      ipAddress: nil,
      telemetry: TelemetryBag(),
    )
  }
}
