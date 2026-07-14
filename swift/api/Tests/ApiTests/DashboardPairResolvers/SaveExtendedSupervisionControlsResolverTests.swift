import DuetSQL
import PairQL
import Vapor
import XCTest
import XExpect

@testable import Api

final class SaveExtendedSupervisionControlsResolverTests: ApiTestCase, @unchecked Sendable {
  func testWritePersistsListsAndNilClears() async throws {
    let parent = try await self.parent()
    try await self.db.create(BillingIdentity(parentId: parent.id, isComplimentary: true))
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random { $0.childId = child.id })
    try await self.db.create(BlockerApp.Supervision(
      deviceId: device.id,
      supervisedAt: .reference, // <-- supervised, required for writes
    ))

    let output = try await SaveExtendedSupervisionControls.resolve(
      with: .init(deviceId: device.id, controls: .init(
        whitelistedAppBundleIds: ["com.apple.mobilesafari"],
        webAllowList: [.init(url: "https://gertrude.app", title: "Gertrude")],
      )),
      in: parent.context,
    )

    expect(output).toEqual(.success)
    var settings = try await BlockerApp.ProfileSettings.ensure(for: device.id, in: self.db)
    expect(settings.whitelistedAppBundleIds).toEqual(["com.apple.mobilesafari"])
    expect(settings.webAllowList)
      .toEqual([.init(url: "https://gertrude.app", title: "Gertrude")])

    _ = try await SaveExtendedSupervisionControls.resolve(
      with: .init(deviceId: device.id, controls: .init(
        whitelistedAppBundleIds: nil,
        webAllowList: nil,
      )),
      in: parent.context,
    )

    settings = try await BlockerApp.ProfileSettings.ensure(for: device.id, in: self.db)
    expect(settings.whitelistedAppBundleIds).toBeNil()
    expect(settings.webAllowList).toBeNil()
  }

  func testWriteRejectedWithoutCapability() async throws {
    let parent = try await self.parent() // no billing identity -> free plan
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random { $0.childId = child.id })
    try await self.db.create(BlockerApp.Supervision(
      deviceId: device.id,
      supervisedAt: .reference,
    ))

    do {
      _ = try await SaveExtendedSupervisionControls.resolve(
        with: .init(deviceId: device.id, controls: .init(
          whitelistedAppBundleIds: ["com.apple.mobilesafari"],
          webAllowList: nil,
        )),
        in: parent.context,
      )
      XCTFail("expected payment required")
    } catch let error as PqlError {
      expect(error.type).toEqual(.paymentRequired)
    }

    let settings = try await BlockerApp.ProfileSettings.ensure(for: device.id, in: self.db)
    expect(settings.whitelistedAppBundleIds).toBeNil()
  }

  func testWriteRejectedForOtherParentsDevice() async throws {
    let owner = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = owner.id })
    let device = try await self.db.create(IOSDevice.random { $0.childId = child.id })
    let other = try await self.parent()
    try await self.db.create(BillingIdentity(parentId: other.id, isComplimentary: true))

    do {
      _ = try await SaveExtendedSupervisionControls.resolve(
        with: .init(deviceId: device.id, controls: .init(
          whitelistedAppBundleIds: nil,
          webAllowList: nil,
        )),
        in: other.context,
      )
      XCTFail("expected unauthorized")
    } catch let error as Abort {
      expect(error.status).toEqual(.unauthorized)
    }
  }
}
