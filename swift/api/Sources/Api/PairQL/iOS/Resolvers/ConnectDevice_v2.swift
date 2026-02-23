import Dependencies
import DuetSQL
import Gertie
import GertieIOS
import IOSRoute

extension ConnectDevice_v2: Resolver {
  static func resolve(with input: Input, in ctx: Context) async throws -> Output {
    guard let childId = await with(dependency: \.ephemeral)
      .getPendingAppConnection(input.verificationCode) else {
      throw ctx.error(
        id: "79483727",
        type: .unauthorized,
        debugMessage: "verification code not found",
        userMessage: "Connection code expired, or not found. Please create a new code and try again.",
        appTag: .connectionCodeNotFound,
      )
    }

    let child = try await ctx.db.find(childId)
    var device = try await IOSApp.Device.ensureExists(
      id: .init(input.vendorId),
      modelIdentifier: input.modelIdentifier,
      iosVersion: input.iosVersion,
      appVersion: input.appVersion,
      in: ctx.db,
    )
    if device.childId != child.id {
      device.childId = child.id
      try await ctx.db.update(device)
    }
    let token = try await ctx.db.create(IOSApp.Token(deviceId: device.id))

    let groups = try await IOSApp.BlockGroup.query().all(in: ctx.db)
    try await ctx.db.create(groups.map {
      IOSApp.DeviceBlockGroup(deviceId: device.id, blockGroupId: $0.id)
    })

    ModelIdentifier.alertIfUnknown(input.modelIdentifier)

    let supervision = try await device.supervision(in: ctx.db)
    var supervised: ChildIOSDeviceData_v2.Supervised? = nil
    if let supervision {
      supervised = .byGertrude(claimCode: supervision.claimCode)
    } else if try await IOSEvent.query()
      .where(.deviceId == device.id)
      .where(.eventId == "bad8adcc")
      .exists(in: ctx.db) {
      supervised = .byOtherMethodUnconfirmed
    }

    if case .byGertrude = supervised {} else {
      let parentLink = AdminLink().slack(to: .parent(child.parentId), text: "parent")
      Task {
        await with(dependency: \.slack).internal(
          .info,
          "*iOS device connected* (non-supervised): child `\(child.name)`, \(parentLink)",
        )
      }
    }

    return .init(
      childId: child.id.rawValue,
      token: token.value.rawValue,
      deviceId: device.id.rawValue,
      childName: child.name,
      supervised: supervised,
    )
  }
}
