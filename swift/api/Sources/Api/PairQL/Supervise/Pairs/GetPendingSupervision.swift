import DuetSQL
import PairQL

struct GetPendingSupervision: Pair {
  static let auth: ClientAuth = .none

  struct Input: PairInput {
    let code: Int
  }

  struct Output: PairOutput {
    let childName: String
    let modelIdentifier: String
    let modelName: String
    let iosVersion: String
  }
}

extension GetPendingSupervision: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let validated = try await SuperviseRoute.validatedSupervisionCode(
      code: input.code,
      baseId: "7863605f", // 7863605f-1, 7863605f-2, 7863605f-3, 7863605f-4
      in: context,
    )

    let child = try await context.db.find(validated.claimedChildId)
    return .init(
      childName: child.name,
      modelIdentifier: validated.device.modelIdentifier,
      modelName: validated.device.modelName,
      iosVersion: validated.device.iosVersion,
    )
  }
}

struct ValidatedSupervisionCode {
  let device: IOSApp.Device
  let claimedChildId: Child.Id
}

extension SuperviseRoute {
  static func validatedSupervisionCode(
    code: Int,
    baseId: String,
    in context: Context,
  ) async throws -> ValidatedSupervisionCode {
    let device = try? await IOSApp.Device.query()
      .where(.supervisionClaimCode == code)
      .first(in: context.db)

    let codeNotFound = "Code not found. Double-check and try again."
    guard let device else {
      logIOSUnusual("\(baseId)-1", "supervision code not found")
      throw context.error("\(baseId)-1", .notFound, user: codeNotFound)
    }

    guard let claimedChildId = device.childId else {
      logIOSUnexpected("\(baseId)-2", "supervision code not yet claimed")
      throw context.error("\(baseId)-2", .notFound, user: codeNotFound)
    }

    guard let expiresAt = device.claimCodeExpiresAt else {
      logIOSUnexpected("\(baseId)-3", "device has claim code but no expiration")
      throw context.error("\(baseId)-3", .notFound, user: codeNotFound)
    }

    if expiresAt < get(dependency: \.date.now) {
      logIOSUnusual("\(baseId)-4", "supervision code expired")
      let msg = "This code has expired. Open the Gertrude app on the \(device.deviceType) to get a new code."
      throw context.error("\(baseId)-4", .badRequest, user: msg)
    }

    return ValidatedSupervisionCode(device: device, claimedChildId: claimedChildId)
  }
}
