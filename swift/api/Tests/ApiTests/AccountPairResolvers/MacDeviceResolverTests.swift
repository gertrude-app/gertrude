import Dependencies
import DuetSQL
import Gertie
import XCTest
import XExpect

@testable import Api

final class MacDeviceResolverTests: ApiTestCase, @unchecked Sendable {
  func testGetReturnsMacDetailsPeopleStatusesAndUpdateTargets() async throws {
    let parent = try await self.parent()
    let jude = try await self.db.create(Child(parentId: parent.id, name: "Jude"))
    let mabel = try await self.db.create(Child(parentId: parent.id, name: "Mabel"))
    let computer = try await self.db.create(Computer(
      parentId: parent.id,
      customName: "Family MacBook",
      appReleaseChannel: .beta,
      osVersion: Semver("26.0.0"),
      modelIdentifier: "Mac14,2",
      serialNumber: "C02TEST12345",
    ))
    let judePrimary = ComputerUser(
      childId: jude.id,
      computerId: computer.id,
      isAdmin: false,
      appVersion: "8999.0.0",
      username: "jude",
      fullUsername: "Jude",
      numericId: 501,
    )
    let judeSecondary = ComputerUser(
      childId: jude.id,
      computerId: computer.id,
      isAdmin: false,
      appVersion: "8998.0.0",
      username: "jude-school",
      fullUsername: "Jude School",
      numericId: 502,
    )
    let mabelUser = ComputerUser(
      childId: mabel.id,
      computerId: computer.id,
      isAdmin: false,
      appVersion: "8999.0.0",
      username: "mabel",
      fullUsername: "Mabel",
      numericId: 503,
    )
    try await self.db.create([judePrimary, judeSecondary, mabelUser])
    try await self.db.create([
      Release.mock {
        $0.semver = "9000.0.0"
        $0.channel = .stable
      },
      Release.mock {
        $0.semver = "9001.0.0"
        $0.channel = .beta
      },
      Release.mock {
        $0.semver = "9002.0.0"
        $0.channel = .canary
      },
    ])
    let judeUserIds = Set([judePrimary.id, judeSecondary.id])

    let output = try await withDependencies {
      $0.websockets.status = { computerUserId in
        judeUserIds.contains(computerUserId)
          ? .filterOn
          : .downtime(ending: .reference)
      }
    } operation: {
      try await GetMacDevice.resolve(
        with: .init(deviceId: computer.id),
        in: self.accountContext(parent),
      )
    }

    expect(output.id).toEqual(computer.id)
    expect(output.name).toEqual("Family MacBook")
    expect(output.modelName).toEqual("M2 MacBook Air (2022)")
    expect(output.modelIdentifier).toEqual("Mac14,2")
    expect(output.macOSVersion).toEqual("26.0.0")
    expect(output.appVersion).toEqual("8999.0.0")
    expect(output.releaseChannel).toEqual(.beta)
    expect(output.targetVersions.stable).toEqual("9000.0.0")
    expect(output.targetVersions.beta).toEqual("9001.0.0")
    expect(output.targetVersions.canary).toEqual("9002.0.0")
    expect(output.people.map(\.id)).toEqual([jude.id, mabel.id])
    expect(output.people.map(\.status)).toEqual([
      .filterOn,
      .downtime(ending: .reference),
    ])
  }

  func testGetRejectsMacFromAnotherAccount() async throws {
    let child = try await self.child().withDevice()
    let otherParent = try await self.parent()

    try await expectErrorFrom {
      try await GetMacDevice.resolve(
        with: .init(deviceId: child.computer.id),
        in: self.accountContext(otherParent),
      )
    }.toContain("notFound")
  }

  func testUpdateTrimsAndClearsNameAndChangesReleaseChannel() async throws {
    let child = try await self.child().withDevice(computer: {
      $0.customName = nil
      $0.appReleaseChannel = .stable
    })

    var output = try await UpdateMacDevice.resolve(
      with: .init(
        deviceId: child.computer.id,
        name: "  Family Mac  ",
        releaseChannel: .beta,
      ),
      in: self.accountContext(child.parent),
    )

    expect(output).toEqual(.success)
    var updated = try await self.db.find(child.computer.id)
    expect(updated.customName).toEqual("Family Mac")
    expect(updated.appReleaseChannel).toEqual(.beta)

    output = try await UpdateMacDevice.resolve(
      with: .init(
        deviceId: child.computer.id,
        name: " \n ",
        releaseChannel: .canary,
      ),
      in: self.accountContext(child.parent),
    )

    expect(output).toEqual(.success)
    updated = try await self.db.find(child.computer.id)
    expect(updated.customName).toBeNil()
    expect(updated.appReleaseChannel).toEqual(.canary)
  }

  func testUpdateRejectsMacFromAnotherAccount() async throws {
    let child = try await self.child().withDevice(computer: {
      $0.customName = "Original"
      $0.appReleaseChannel = .stable
    })
    let otherParent = try await self.parent()

    try await expectErrorFrom {
      try await UpdateMacDevice.resolve(
        with: .init(
          deviceId: child.computer.id,
          name: "Not allowed",
          releaseChannel: .canary,
        ),
        in: self.accountContext(otherParent),
      )
    }.toContain("notFound")

    let unchanged = try await self.db.find(child.computer.id)
    expect(unchanged.customName).toEqual("Original")
    expect(unchanged.appReleaseChannel).toEqual(.stable)
  }
}
