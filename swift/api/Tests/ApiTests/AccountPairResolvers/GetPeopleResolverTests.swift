import Dependencies
import Gertie
import XCTest
import XExpect

@testable import Api

final class GetPeopleResolverTests: ApiTestCase, @unchecked Sendable {
  func testReturnsPeopleWithConnectedDevices() async throws {
    let parent = try await self.parent()
    let person = try await self.db.create(Child(parentId: parent.id, name: "Jude"))
    let personWithoutDevices = try await self.db.create(
      Child(parentId: parent.id, name: "Mabel"),
    )
    let computer = try await self.db.create(Computer(
      parentId: parent.id,
      customName: "Jude's MacBook",
      osVersion: Semver("15.6.0"),
      modelIdentifier: "Mac14,2",
      serialNumber: "test-serial",
    ))
    let computerUser = try await self.db.create(ComputerUser(
      childId: person.id,
      computerId: computer.id,
      isAdmin: false,
      appVersion: "2.9.7",
      username: "jude",
      fullUsername: "Jude",
      numericId: 502,
    ))
    let iPhone = try await self.db.create(IOSDevice(
      id: .init(),
      childId: person.id,
      modelIdentifier: "iPhone16,1",
      iosVersion: "18.5",
    ))
    let iPad = try await self.db.create(IOSDevice(
      id: .init(),
      childId: person.id,
      modelIdentifier: "iPad13,16",
      iosVersion: "18.6",
    ))

    let otherParent = try await self.parent()
    try await self.db.create(Child(parentId: otherParent.id, name: "Someone Else"))

    let output = try await withDependencies {
      $0.websockets.status = { id in
        id == computerUser.id ? .filterOn : .offline
      }
    } operation: {
      try await GetPeople.resolve(in: self.accountContext(parent))
    }

    expect(output).toHaveCount(2)
    let returnedPerson = try XCTUnwrap(output.first { $0.id == person.id })
    expect(returnedPerson.name).toEqual("Jude")
    expect(returnedPerson.devices).toHaveCount(3)

    guard case .mac(let mac) = returnedPerson.devices[0] else {
      return XCTFail("Expected a Mac device")
    }
    expect(mac.id).toEqual(computerUser.id)
    expect(mac.name).toEqual("Jude's MacBook")
    expect(mac.macOSVersion).toEqual("15.6.0")
    expect(mac.modelName).toEqual("M2 MacBook Air (2022)")
    expect(mac.modelIdentifier).toEqual("Mac14,2")
    expect(mac.online).toBeTrue()

    guard case .ios(let phone) = returnedPerson.devices[1] else {
      return XCTFail("Expected an iOS device")
    }
    expect(phone.id).toEqual(iPhone.id)
    expect(phone.type).toEqual(.iphone)
    expect(phone.iOSVersion).toEqual("18.5")
    expect(phone.modelName).toEqual("iPhone 15 Pro")
    expect(phone.modelIdentifier).toEqual("iPhone16,1")

    guard case .ios(let tablet) = returnedPerson.devices[2] else {
      return XCTFail("Expected an iOS device")
    }
    expect(tablet.id).toEqual(iPad.id)
    expect(tablet.type).toEqual(.ipad)
    expect(tablet.iOSVersion).toEqual("18.6")
    expect(tablet.modelName).toEqual("iPad Air (5th gen)")
    expect(tablet.modelIdentifier).toEqual("iPad13,16")

    let returnedPersonWithoutDevices = try XCTUnwrap(
      output.first { $0.id == personWithoutDevices.id },
    )
    expect(returnedPersonWithoutDevices.devices).toBeEmpty()
  }

  func testReturnsEmptyWhenAccountHasNoPeople() async throws {
    let parent = try await self.parent()
    let output = try await GetPeople.resolve(in: self.accountContext(parent))
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
