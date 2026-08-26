import Dependencies
import DuetSQL
import Gertie
import XCTest
import XExpect

@testable import Api

final class GetPeopleResolverTests: ApiTestCase, @unchecked Sendable {
  func testReturnsPeopleWithConnectedDevicesAndRecentScreenshot() async throws {
    let parent = try await self.parent()
    let person = try await self.db.create(Child(
      parentId: parent.id,
      name: "Jude",
      relationship: .peer,
    ))
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
    let screenshotDate = Date(timeIntervalSince1970: floor(Date().timeIntervalSince1970))
    _ = try await self.db.create(Screenshot(
      computerUserId: computerUser.id,
      url: "\(self.env.s3.bucketUrl)/screenshots/older.jpg",
      width: 1280,
      height: 720,
      createdAt: screenshotDate.addingTimeInterval(-600),
    ))
    let newestScreenshot = try await self.db.create(Screenshot(
      computerUserId: computerUser.id,
      url: "\(self.env.s3.bucketUrl)/screenshots/newest.jpg",
      width: 1280,
      height: 720,
      createdAt: screenshotDate.addingTimeInterval(-300),
    ))
    let deletedScreenshot = try await self.db.create(Screenshot(
      computerUserId: computerUser.id,
      url: "\(self.env.s3.bucketUrl)/screenshots/deleted.jpg",
      width: 1280,
      height: 720,
      createdAt: screenshotDate.addingTimeInterval(-60),
    ))
    try await Screenshot.query().byId(deletedScreenshot.id).delete(in: self.db)

    let otherParent = try await self.parent()
    try await self.db.create(Child(parentId: otherParent.id, name: "Someone Else"))

    let output = try await withDependencies {
      $0.websockets.status = { id in
        id == computerUser.id ? .filterOn : .offline
      }
      $0.aws._signedS3GetUrl = { objectKey in
        URL(string: "https://signed.test/\(objectKey)")!
      }
    } operation: {
      try await GetPeople.resolve(in: self.accountContext(parent))
    }

    expect(output).toHaveCount(2)
    let returnedPerson = try XCTUnwrap(output.first { $0.id == person.id })
    expect(returnedPerson.name).toEqual("Jude")
    expect(returnedPerson.relationship).toEqual(.peer)
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
    expect(returnedPerson.screenshot?.url)
      .toEqual("https://signed.test/screenshots/newest.jpg")
    expect(returnedPerson.screenshot?.createdAt).toEqual(newestScreenshot.createdAt)

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
    expect(returnedPersonWithoutDevices.relationship).toEqual(.child)
    expect(returnedPersonWithoutDevices.devices).toBeEmpty()
    expect(returnedPersonWithoutDevices.screenshot).toBeNil()
  }

  func testIOSDeviceBlockerConnectedFlag() async throws {
    let parent = try await self.parent()
    let person = try await self.db.create(Child(parentId: parent.id, name: "Jude"))
    let connected = try await self.db.create(IOSDevice(
      id: .init(),
      childId: person.id,
      modelIdentifier: "iPhone16,1",
      iosVersion: "18.5",
    ))
    let connectedInstall = try await self.db.create(BlockerApp.Install(
      deviceId: connected.id,
      appVersion: "1.8.0",
    ))
    try await self.db.create(BlockerApp.Token(installId: connectedInstall.id))

    // install but no token: a sibling app's claim bound the child, blocker never connected
    let installOnly = try await self.db.create(IOSDevice(
      id: .init(),
      childId: person.id,
      modelIdentifier: "iPad13,16",
      iosVersion: "18.6",
    ))
    try await self.db.create(BlockerApp.Install(
      deviceId: installOnly.id,
      appVersion: "1.8.0",
    ))

    let noInstall = try await self.db.create(IOSDevice(
      id: .init(),
      childId: person.id,
      modelIdentifier: "iPhone14,7",
      iosVersion: "18.4",
    ))

    let output = try await GetPeople.resolve(in: self.accountContext(parent))

    let devices = try XCTUnwrap(output.first { $0.id == person.id }).devices
    let flags = devices.reduce(into: [IOSDevice.Id: Bool]()) { acc, device in
      if case .ios(let ios) = device { acc[ios.id] = ios.blockerConnected }
    }
    expect(flags[connected.id]).toEqual(true)
    expect(flags[installOnly.id]).toEqual(false) // install alone is not connected
    expect(flags[noInstall.id]).toEqual(false)
  }

  func testOmitsScreenshotsOlderThanTwoWeeks() async throws {
    let person = try await self.childWithComputer()
    try await self.db.create(Screenshot(
      computerUserId: person.computerUser.id,
      url: "\(self.env.s3.bucketUrl)/screenshots/stale.jpg",
      width: 1280,
      height: 720,
      createdAt: Date().addingTimeInterval(-(14 * 24 * 60 * 60 + 60)),
    ))

    let output = try await withDependencies {
      $0.websockets.status = { _ in .filterOn }
    } operation: {
      try await GetPeople.resolve(in: self.accountContext(person.parent))
    }

    let returnedPerson = try XCTUnwrap(output.first)
    expect(returnedPerson.screenshot).toBeNil()
  }

  func testReturnsEmptyWhenAccountHasNoPeople() async throws {
    let parent = try await self.parent()
    let output = try await GetPeople.resolve(in: self.accountContext(parent))
    expect(output).toBeEmpty()
  }
}
