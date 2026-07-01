import BlockerRoute
import Dependencies
import DuetSQL
import Gertie
import GertieBlocker

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
    ctx.telemetry.parentId = child.parentId
    let install = try await BlockerApp.Install.ensureExists(
      deviceId: .init(input.vendorId),
      modelIdentifier: input.modelIdentifier,
      iosVersion: input.iosVersion,
      appVersion: input.appVersion,
      in: ctx.db,
    )
    var device = try await install.device(in: ctx.db)
    try await device.bindChild(child, in: ctx.db)
    let token = try await ctx.db.findOrCreate(
      BlockerApp.Token(installId: install.id),
      conflictOn: [.installId],
    )

    let groups = try await BlockerApp.BlockGroup.query()
      .where(.optIn == false)
      .all(in: ctx.db)
    try await ctx.db.create(groups.map {
      BlockerApp.DeviceBlockGroup(deviceId: device.id, blockGroupId: $0.id)
    })

    ModelIdentifier.alertIfUnknown(input.modelIdentifier)

    let supervision = try await device.supervision(in: ctx.db)
    var supervised: ChildIOSDeviceData_v2.Supervised? = nil
    let superviseClaim = try await Claim.find(device.id, intent: .blockerSupervise, in: ctx.db)
    if supervision?.supervisedAt != nil, let claimCode = superviseClaim?.code {
      supervised = .byGertrude(claimCode: claimCode)
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
