import Dependencies
import XCTest
import XExpect

@testable import Api

final class DashboardWidgets_v3ResolverTests: ApiTestCase, @unchecked Sendable {
  func testNumDevicesIncludesIOSDevices() async throws {
    let child = try await self.childWithIOSDevice()
    let output = try await withDependencies {
      $0.aws._signedS3GetUrl = { _ in URL(string: "https://signed.test/img.jpg")! }
    } operation: {
      try await DashboardWidgets_v3.resolve(in: context(child.parent))
    }
    expect(output.children.count).toEqual(1)
    expect(output.children[0].devices.count).toEqual(1)
  }

  func testAmConnectedIOSDeviceShowsSetupComplete() async throws {
    let child = try await self.child()
    let iosDevice = try await self.db.create(IOSDevice.mock {
      $0.childId = child.id
    })
    let install = try await self.db.create(
      PodcastApp.Install(deviceId: iosDevice.id, appVersion: "1.6.0"),
    )
    _ = try await self.db.create(PodcastApp.Token(installId: install.id)) // <-- am connected

    let output = try await withDependencies {
      $0.aws._signedS3GetUrl = { _ in URL(string: "https://signed.test/img.jpg")! }
    } operation: {
      try await DashboardWidgets_v3.resolve(in: context(child.parent))
    }

    expect(output.children.count).toEqual(1)
    expect(output.children[0].devices.count).toEqual(1)
    expect(output.children[0].devices[0].iosStatus).toEqual(.setupComplete)
  }

  func testUnconnectedIOSDeviceShowsPendingSetup() async throws {
    let child = try await self.child()
    try await self.db.create(IOSDevice.mock {
      $0.childId = child.id
    })

    let output = try await withDependencies {
      $0.aws._signedS3GetUrl = { _ in URL(string: "https://signed.test/img.jpg")! }
    } operation: {
      try await DashboardWidgets_v3.resolve(in: context(child.parent))
    }

    expect(output.children[0].devices[0].iosStatus).toEqual(.pendingSetup)
  }

  func testNumDevicesIncludesBothMacAndIOS() async throws {
    let childWithMac = try await self.childWithComputer()

    try await self.db.create(IOSDevice.random {
      $0.childId = childWithMac.id
    })

    let output = try await withDependencies {
      $0.websockets.status = { _ in .filterOn }
      $0.aws._signedS3GetUrl = { _ in URL(string: "https://signed.test/img.jpg")! }
    } operation: {
      try await DashboardWidgets_v3.resolve(in: context(childWithMac.parent))
    }

    expect(output.children[0].devices.count).toEqual(2)
  }
}
