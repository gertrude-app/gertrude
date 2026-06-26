#if DEBUG
  import Dependencies
  import DuetSQL
  import Gertie
  import GertieBlocker
  import Vapor
  import XCore

  enum AdminBen {
    enum Ids {
      static let ben = Parent.Id.from("BE100000-0000-0000-0000-000000000000")
      static let lukesId = Child.Id.from("00000000-BE10-BE10-0000-000000000000")
      static let lukesDevice = IOSDevice.Id.from("DD00BE10-0000-0000-0000-000000000000")
    }

    static func create() async throws {
      @Dependency(\.db) var db
      let ben = try await db.create(Parent(
        id: Ids.ben,
        email: "ben-ios-only" |> Reset.testEmail,
        password: Bcrypt.hash("ben123"),
        emailVerifiedAt: Date(),
      ))

      try await db.create(BillingIdentity(
        parentId: ben.id,
        stripeCustomerId: "cus_UVjrurAptk11E2",
        lastStripeSubscriptionId: "sub_1TWiOKGKRdhETuKABBZ0SiBS",
        lastPaidTier: .light,
      ))
      try await db.create(StripeSubscription(
        parentId: ben.id,
        tier: .light,
        stripeId: "sub_1TWiOKGKRdhETuKABBZ0SiBS",
        stripeStatus: .active,
        currentPeriodEnd: Date() + .days(365),
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

      let device = try await db.create(IOSDevice(
        id: Ids.lukesDevice,
        childId: luke.id,
        modelIdentifier: "iPhone16,1",
        iosVersion: "26.2",
      ))

      try await db.create(Claim(
        code: 123_456,
        intent: .blockerSupervise,
        deviceId: device.id,
        childId: luke.id,
        expiresAt: Date() + .days(30),
        claimedAt: Date() - .days(7),
      ))

      let install = try await db.create(BlockerApp.Install(
        deviceId: device.id,
        appVersion: "1.7.0",
      ))

      try await db.create(BlockerApp.Token(installId: install.id))

      try await db.create(BlockerApp.Supervision(
        deviceId: device.id,
        udid: "00008130-BE10000000BE001E",
        supervisedAt: Date() - .days(7),
        profileInstalledAt: Date() - .days(7),
      ))

      let gifs = BlockerApp.BlockGroup.Id(CreateBlockGroups.GroupIds().gifs)
      try await db.create([BlockerApp.DeviceBlockGroup(deviceId: device.id, blockGroupId: gifs)])
    }
  }
#endif
