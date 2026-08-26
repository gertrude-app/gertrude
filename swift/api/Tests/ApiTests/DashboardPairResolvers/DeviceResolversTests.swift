import Dependencies
import XCTest
import XExpect

@testable import Api

final class DeviceResolversTests: ApiTestCase, @unchecked Sendable {
  func testGetAllDevices() async throws {
    try await self.db.delete(all: ComputerUser.self)
    try await self.db.delete(all: Computer.self)
    let child = try await self.child().withDevice { $0.appVersion = "2.2.2" }
    var device = child.computer
    device.appReleaseChannel = .canary
    device.customName = "Pinky"
    device.serialNumber = "1234567890"
    device.modelIdentifier = "MacBookPro16,1"
    try await self.db.update(device)

    let child2 = try await self.db.create(Child(parentId: child.parentId, name: "Bob"))

    // proves that we take the highest app version
    try await self.db.create(ComputerUser(
      childId: child2.id,
      computerId: device.id,
      isAdmin: false,
      appVersion: "2.0.1", // <-- lower app version
      username: "Bob",
      fullUsername: "Bob",
      numericId: 504,
    ))

    try await withDependencies {
      $0.websockets.status = { _ in .filterOn }
    } operation: {
      let output = try await GetAllDevices.resolve(in: context(child.parent))

      expect(output.computers.count).toEqual(1)
      let mac = output.computers[0]
      expect(mac.id).toEqual(device.id)
      expect(mac.name).toEqual("Pinky")
      expect(mac.modelIdentifier).toEqual("MacBookPro16,1")
      expect(mac.modelTitle).toEqual("16\" MacBook Pro (2019)")
      expect(mac.users.count).toEqual(2)
      let userNames = mac.users.map(\.name)
      expect(userNames.contains("Bob")).toBeTrue()
      expect(userNames.contains(child.name)).toBeTrue()
      expect(output.iosDevices).toEqual([])
    }
  }

  func testGetAllDevicesIncludesIOSDevices() async throws {
    try await self.db.delete(all: Computer.self)
    let child = try await self.child()
    let iosDevice = try await self.db.create(IOSDevice.mock {
      $0.childId = child.id
      $0.modelIdentifier = "iPhone15,2"
      $0.iosVersion = "18.4.0"
    })
    let install = try await self.db.create(
      BlockerApp.Install.mock { $0.deviceId = iosDevice.id },
    )
    _ = try await self.db.create(BlockerApp.Token(installId: install.id))

    try await withDependencies {
      $0.websockets.status = { _ in .offline }
    } operation: {
      let output = try await GetAllDevices.resolve(in: context(child.parent))

      expect(output.computers).toEqual([])
      expect(output.iosDevices.count).toEqual(1)
      let ios = output.iosDevices[0]
      expect(ios.id).toEqual(iosDevice.id)
      expect(ios.childId).toEqual(child.id)
      expect(ios.childName).toEqual(child.name)
      expect(ios.modelName).toEqual("iPhone 14 Pro")
      expect(ios.deviceType).toEqual("iPhone")
      expect(ios.iosVersion).toEqual("18.4.0")
      expect(ios.pendingSetup).toEqual(false)
    }
  }

  func testGetAllDevicesIOSPendingSetup() async throws {
    try await self.db.delete(all: Computer.self)
    let child = try await self.child()
    _ = try await self.db.create(IOSDevice.mock {
      $0.childId = child.id
    })

    try await withDependencies {
      $0.websockets.status = { _ in .offline }
    } operation: {
      let output = try await GetAllDevices.resolve(in: context(child.parent))
      expect(output.iosDevices.count).toEqual(1)
      expect(output.iosDevices[0].pendingSetup).toEqual(true)
    }
  }

  func testGetAllDevicesAmOnlyDeviceNotPendingSetup() async throws {
    try await self.db.delete(all: Computer.self)
    let child = try await self.child()
    let iosDevice = try await self.db.create(IOSDevice.mock {
      $0.childId = child.id
    })
    let install = try await self.db.create(
      PodcastApp.Install(deviceId: iosDevice.id, appVersion: "1.6.0"),
    )
    _ = try await self.db.create(PodcastApp.Token(installId: install.id))

    try await withDependencies {
      $0.websockets.status = { _ in .offline }
    } operation: {
      let output = try await GetAllDevices.resolve(in: context(child.parent))
      expect(output.iosDevices.count).toEqual(1)
      expect(output.iosDevices[0].pendingSetup).toEqual(false)
    }
  }

  func testGetAllDevicesMusicOnlyDeviceNotPendingSetup() async throws {
    try await self.db.delete(all: Computer.self)
    let child = try await self.child()
    let iosDevice = try await self.db.create(IOSDevice.mock {
      $0.childId = child.id
    })
    let install = try await self.db.create(
      MusicApp.Install(deviceId: iosDevice.id, appVersion: "1.0.0"),
    )
    _ = try await self.db.create(MusicApp.Token(installId: install.id))

    try await withDependencies {
      $0.websockets.status = { _ in .offline }
    } operation: {
      let output = try await GetAllDevices.resolve(in: context(child.parent))
      expect(output.iosDevices.count).toEqual(1)
      expect(output.iosDevices[0].pendingSetup).toEqual(false)
    }
  }

  func testGetAllDevicesSupervisionClaimedButNotComplete() async throws {
    try await self.db.delete(all: Computer.self)
    let child = try await self.child()
    let iosDevice = try await self.db.create(IOSDevice.mock { $0.childId = child.id })
    try await self.createClaim(
      .blockerSupervise,
      iosDevice.id,
      child.id,
      claimedAt: .reference,
    )
    let install = try await self.db.create(
      BlockerApp.Install.mock { $0.deviceId = iosDevice.id },
    )
    _ = try await self.db.create(BlockerApp.Token(installId: install.id))
    _ = try await self.db.create(BlockerApp.Supervision(deviceId: iosDevice.id))

    try await withDependencies {
      $0.websockets.status = { _ in .offline }
    } operation: {
      let output = try await GetAllDevices.resolve(in: context(child.parent))
      expect(output.iosDevices.count).toEqual(1)
      expect(output.iosDevices[0].pendingSetup).toEqual(true)
    }
  }

  func testGetAllDevicesMixedMacAndIOS() async throws {
    try await self.db.delete(all: ComputerUser.self)
    try await self.db.delete(all: Computer.self)
    let child = try await self.child().withDevice { $0.appVersion = "2.2.2" }
    let iosDevice = try await self.db.create(IOSDevice.mock {
      $0.childId = child.id
      $0.modelIdentifier = "iPad14,1"
      $0.iosVersion = "18.3.0"
    })
    let install = try await self.db.create(
      BlockerApp.Install.mock { $0.deviceId = iosDevice.id },
    )
    _ = try await self.db.create(BlockerApp.Token(installId: install.id))

    try await withDependencies {
      $0.websockets.status = { _ in .filterOn }
    } operation: {
      let output = try await GetAllDevices.resolve(in: context(child.parent))
      expect(output.computers.count).toEqual(1)
      expect(output.computers[0].id).toEqual(child.computer.id)
      expect(output.iosDevices.count).toEqual(1)
      expect(output.iosDevices[0].id).toEqual(iosDevice.id)
      expect(output.iosDevices[0].childName).toEqual(child.name)
      expect(output.iosDevices[0].deviceType).toEqual("iPad")
      expect(output.iosDevices[0].pendingSetup).toEqual(false)
    }
  }

  func testSaveDevice() async throws {
    let child = try await self.childWithComputer()
    var device = child.computer
    device.appReleaseChannel = .stable
    device.customName = nil
    try await self.db.update(device)

    var output = try await SaveDevice.resolve(
      with: .init(id: device.id, name: "Pinky", releaseChannel: .beta),
      in: context(child.parent),
    )

    expect(output).toEqual(.success)

    let retrieved = try await self.db.find(device.id)
    expect(retrieved.customName).toEqual("Pinky")
    expect(retrieved.appReleaseChannel).toEqual(.beta)

    output = try await SaveDevice.resolve(
      with: .init(
        id: device.id,
        name: nil, // <-- remove name
        releaseChannel: .beta,
      ),
      in: context(child.parent),
    )

    let retrievedAgain = try await self.db.find(device.id)
    expect(retrievedAgain.customName).toBeNil()
  }
}
