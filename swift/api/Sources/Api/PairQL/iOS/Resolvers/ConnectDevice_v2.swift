import Dependencies
import DuetSQL
import Gertie
import GertieIOS
import IOSRoute
import Vapor

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
    let device = try await ctx.db.create(IOSApp.Device(
      id: .init(input.vendorId),
      childId: childId,
      modelIdentifier: input.modelIdentifier,
      appVersion: input.appVersion,
      iosVersion: input.iosVersion,
    ))
    let token = try await ctx.db.create(IOSApp.Token(deviceId: device.id))

    let groups = try await IOSApp.BlockGroup.query().all(in: ctx.db)
    try await ctx.db.create(groups.map {
      IOSApp.DeviceBlockGroup(deviceId: device.id, blockGroupId: $0.id)
    })

    ModelIdentifier.alertIfUnknown(input.modelIdentifier)

    var supervised: ChildIOSDeviceData_v2.Supervised? = nil
    if device.isSupervised {
      guard let claimCode = device.supervisionClaimCode else {
        // NB: going away w/ supervision join table, remove vapor import
        logIOSUnexpected("979dd459", "deviceId=\(device.id)")
        throw Abort(.internalServerError)
      }
      supervised = .byGertrude(claimCode: claimCode)
    } else if try await IOSEvent.query()
      .where(.deviceId == device.id)
      .where(.eventId == "bad8adcc")
      .exists(in: ctx.db) {
      supervised = .byOtherMethodUnconfirmed
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
