import Dependencies
import DuetSQL
import Gertie
import GertieIOS
import Vapor
import XCore

enum AdminBen {
  enum Ids {
    static let ben = Parent.Id.from("BE100000-0000-0000-0000-000000000000")
    static let lukesId = Child.Id.from("00000000-BE10-BE10-0000-000000000000")
    static let lukesDevice = IOSApp.Device.Id.from("DD00BE10-0000-0000-0000-000000000000")
  }

  static func create() async throws {
    @Dependency(\.db) var db
    let ben = try await db.create(Parent(
      id: Ids.ben,
      email: "ben-ios-only" |> Reset.testEmail,
      password: Bcrypt.hash("ben123"),
      emailVerifiedAt: Date(),
    ))

    try await db.create(Subscription(
      parentId: ben.id,
      tier: .light,
      billingStatus: .paid,
      stripeId: "sub_fake_ben_ios_only_12345",
      statusExpiresAt: Date() + .days(365),
    ))

    try await db.create(Parent.DashToken(
      value: .init(rawValue: ben.id.rawValue),
      parentId: ben.id,
    ))

    try await self.createChild(ben)
  }

  private static func createChild(_ ben: Parent) async throws {
    @Dependency(\.db) var db
    let luke = try await db.create(Child(
      id: Ids.lukesId,
      parentId: ben.id,
      name: "Luke",
      keyloggingEnabled: false,
      screenshotsEnabled: false,
    ))

    let device = try await db.create(IOSApp.Device(
      id: Ids.lukesDevice,
      childId: luke.id,
      modelIdentifier: "iPhone16,1",
      appVersion: "1.7.0",
      iosVersion: "26.2",
    ))

    try await db.create(IOSApp.Supervision(
      deviceId: device.id,
      claimCode: 123_456,
      claimCodeExpiresAt: Date() + .days(30),
      udid: "00008130-BE10000000BE001E",
      claimedAt: Date() - .days(7),
      supervisedAt: Date() - .days(7),
      profileInstalledAt: Date() - .days(7),
    ))

    let gifs = IOSApp.BlockGroup.Id(CreateBlockGroups.GroupIds().gifs)
    try await db.create([IOSApp.DeviceBlockGroup(deviceId: device.id, blockGroupId: gifs)])
  }
}
