import Dependencies
import XCTest
import XExpect

@testable import Api

final class DashboardWidgetsResolverTests: ApiTestCase, @unchecked Sendable {
  func testNumDevicesIncludesIOSDevices() async throws {
    let child = try await self.childWithIOSDevice()
    let output = try await DashboardWidgets.resolve(in: context(child.parent))
    expect(output.children.count).toEqual(1)
    expect(output.children[0].numDevices).toEqual(1)
  }

  func testNumDevicesIncludesBothMacAndIOS() async throws {
    let childWithMac = try await self.childWithComputer()

    try await self.db.create(IOSApp.Device.random {
      $0.childId = childWithMac.id
    })

    let output = try await withDependencies {
      $0.websockets.status = { _ in .filterOn }
    } operation: {
      try await DashboardWidgets.resolve(in: context(childWithMac.parent))
    }

    expect(output.children[0].numDevices).toEqual(2)
  }
}
