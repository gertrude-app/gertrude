import DuetSQL
import Gertie
import XCTest
import XExpect

@testable import Api

final class GetDevicesResolverTests: ApiTestCase, @unchecked Sendable {
  func testReturnsPhysicalDevicesWithPeopleAppsAndSupervision() async throws {
    let parent = try await self.parent()
    let jude = try await self.db.create(Child(parentId: parent.id, name: "Jude"))
    let mabel = try await self.db.create(Child(parentId: parent.id, name: "Mabel"))
    let computer = try await self.db.create(Computer(
      parentId: parent.id,
      customName: "Family MacBook",
      osVersion: Semver("26.0.0"),
      modelIdentifier: "Mac14,2",
      serialNumber: "family-macbook",
    ))
    try await self.db.create([
      ComputerUser(
        childId: jude.id,
        computerId: computer.id,
        isAdmin: false,
        appVersion: "2.9.7",
        username: "jude",
        fullUsername: "Jude",
        numericId: 501,
      ),
      ComputerUser(
        childId: jude.id,
        computerId: computer.id,
        isAdmin: false,
        appVersion: "2.9.7",
        username: "jude-school",
        fullUsername: "Jude School",
        numericId: 502,
      ),
      ComputerUser(
        childId: mabel.id,
        computerId: computer.id,
        isAdmin: false,
        appVersion: "2.9.7",
        username: "mabel",
        fullUsername: "Mabel",
        numericId: 503,
      ),
    ])

    let phone = try await self.db.create(IOSDevice(
      id: .init(),
      childId: jude.id,
      modelIdentifier: "iPhone16,1",
      iosVersion: "18.5",
    ))
    let blockerInstall = try await self.db.create(
      BlockerApp.Install(deviceId: phone.id, appVersion: "1.6.0"),
    )
    try await self.db.create(BlockerApp.Token(installId: blockerInstall.id))
    try await self.db.create(
      PodcastApp.Install(deviceId: phone.id, appVersion: "1.6.0"),
    )
    let musicInstall = try await self.db.create(
      MusicApp.Install(deviceId: phone.id, appVersion: "1.0.0"),
    )
    try await self.db.create(MusicApp.Token(installId: musicInstall.id))
    try await self.db.create(BlockerApp.Supervision(deviceId: phone.id))
    try await self.db.create(Claim(
      code: 123_456,
      intent: .blockerSupervise,
      deviceId: phone.id,
      childId: jude.id,
      expiresAt: .distantFuture,
      claimedAt: .reference,
    ))

    let output = try await GetDevices.resolve(in: self.accountContext(parent))

    expect(output.macs).toHaveCount(1)
    let mac = try XCTUnwrap(output.macs.first)
    expect(mac.id).toEqual(computer.id)
    expect(mac.name).toEqual("Family MacBook")
    expect(mac.modelName).toEqual("M2 MacBook Air (2022)")
    expect(mac.modelIdentifier).toEqual("Mac14,2")
    expect(mac.macOSVersion).toEqual("26.0.0")
    expect(mac.people.map(\.id)).toEqual([jude.id, mabel.id])
    expect(mac.people.map(\.name)).toEqual(["Jude", "Mabel"])

    expect(output.mobileDevices).toHaveCount(1)
    let mobile = try XCTUnwrap(output.mobileDevices.first)
    expect(mobile.id).toEqual(phone.id)
    expect(mobile.type).toEqual(.iphone)
    expect(mobile.modelName).toEqual("iPhone 15 Pro")
    expect(mobile.modelIdentifier).toEqual("iPhone16,1")
    expect(mobile.iOSVersion).toEqual("18.5")
    expect(mobile.person.id).toEqual(jude.id)
    expect(mobile.person.name).toEqual("Jude")
    expect(mobile.connectedApps).toEqual([.blocker, .music])
    expect(mobile.supervisionStatus).toEqual(.claimed)
  }

  func testReturnsEachSupervisionPhase() async throws {
    let parent = try await self.parent()
    let person = try await self.db.create(Child(parentId: parent.id, name: "Jude"))

    let pendingClaim = try await self.device(for: person, modelIdentifier: "iPhone16,1")
    try await self.db.create(BlockerApp.Supervision(deviceId: pendingClaim.id))
    try await self.db.create(Claim(
      code: 111_111,
      intent: .blockerSupervise,
      deviceId: pendingClaim.id,
      expiresAt: .distantFuture,
    ))

    let claimed = try await self.device(for: person, modelIdentifier: "iPhone16,2")
    try await self.db.create(BlockerApp.Supervision(deviceId: claimed.id))
    try await self.db.create(Claim(
      code: 222_222,
      intent: .blockerSupervise,
      deviceId: claimed.id,
      childId: person.id,
      expiresAt: .distantFuture,
      claimedAt: .reference,
    ))

    let supervised = try await self.device(for: person, modelIdentifier: "iPhone17,1")
    try await self.db.create(BlockerApp.Supervision(
      deviceId: supervised.id,
      supervisedAt: .reference,
    ))

    let complete = try await self.device(for: person, modelIdentifier: "iPhone17,2")
    try await self.db.create(BlockerApp.Supervision(
      deviceId: complete.id,
      supervisedAt: .reference,
      profileInstalledAt: .reference,
    ))

    let ordinary = try await self.device(for: person, modelIdentifier: "iPhone17,3")

    let output = try await GetDevices.resolve(in: self.accountContext(parent))
    let statuses = Dictionary(
      uniqueKeysWithValues: output.mobileDevices.map { ($0.id, $0.supervisionStatus) },
    )

    expect(statuses[pendingClaim.id]).toEqual(.pendingClaim)
    expect(statuses[claimed.id]).toEqual(.claimed)
    expect(statuses[supervised.id]).toEqual(.supervised)
    expect(statuses[complete.id]).toEqual(.complete)
    let ordinaryOutput = try XCTUnwrap(
      output.mobileDevices.first { $0.id == ordinary.id },
    )
    expect(ordinaryOutput.supervisionStatus).toBeNil()
  }

  func testExcludesDevicesOutsideAccountAndUnassignedIOSDevices() async throws {
    let parent = try await self.parent()
    let person = try await self.db.create(Child(parentId: parent.id, name: "Jude"))
    _ = try await self.device(for: person, modelIdentifier: "iPad13,16")
    try await self.db.create(IOSDevice(
      id: .init(),
      modelIdentifier: "iPhone16,1",
      iosVersion: "18.5",
    ))

    let otherParent = try await self.parent()
    let otherPerson = try await self.db.create(
      Child(parentId: otherParent.id, name: "Someone Else"),
    )
    _ = try await self.device(for: otherPerson, modelIdentifier: "iPhone17,1")
    let otherComputer = try await self.db.create(Computer(
      parentId: otherParent.id,
      modelIdentifier: "Mac14,2",
      serialNumber: "other-parent-mac",
    ))
    try await self.db.create(ComputerUser(
      childId: otherPerson.id,
      computerId: otherComputer.id,
      isAdmin: false,
      appVersion: "2.9.7",
      username: "other",
      fullUsername: "Other",
      numericId: 501,
    ))

    let output = try await GetDevices.resolve(in: self.accountContext(parent))

    expect(output.macs).toBeEmpty()
    expect(output.mobileDevices).toHaveCount(1)
    expect(output.mobileDevices[0].person.id).toEqual(person.id)
    expect(output.mobileDevices[0].type).toEqual(.ipad)
  }

  func testReturnsEmptyWhenAccountHasNoPeople() async throws {
    let parent = try await self.parent()

    let output = try await GetDevices.resolve(in: self.accountContext(parent))

    expect(output.macs).toBeEmpty()
    expect(output.mobileDevices).toBeEmpty()
  }

  private func device(
    for person: Child,
    modelIdentifier: String,
  ) async throws -> IOSDevice {
    try await self.db.create(IOSDevice(
      id: .init(),
      childId: person.id,
      modelIdentifier: modelIdentifier,
      iosVersion: "18.5",
    ))
  }
}
