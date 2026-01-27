import DuetSQL
import PairQL

struct GetPendingSupervision: Pair {
  static let auth: ClientAuth = .none

  struct Input: PairInput {
    let code: Int
  }

  struct Output: PairOutput {
    let childName: String
    let deviceType: String
    let modelIdentifier: String
    let modelName: String
    let iosVersion: String
  }
}

extension GetPendingSupervision: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let validated = try await SuperviseRoute.validatedSupervisionCode(
      code: input.code,
      baseId: "7863605f", // 7863605f-1, 7863605f-2, 7863605f-3
      in: context,
    )

    let child = try await context.db.find(validated.claimedChildId)
    return .init(
      childName: child.name,
      deviceType: validated.device.deviceType,
      modelIdentifier: validated.device.modelIdentifier,
      modelName: validated.device.modelName,
      iosVersion: validated.device.iosVersion,
    )
  }
}

struct ValidatedSupervisionCode {
  let device: IOSApp.Device
  let supervision: IOSApp.Supervision
  let claimedChildId: Child.Id
}

extension SuperviseRoute {
  static func validatedSupervisionCode(
    code: Int,
    baseId: String,
    in context: Context,
  ) async throws -> ValidatedSupervisionCode {
    let supervision = try? await IOSApp.Supervision.query()
      .where(.claimCode == code)
      .first(in: context.db)

    let codeNotFound = "Code not found. Double-check and try again."
    guard let supervision else {
      logIOSUnusual("\(baseId)-1", "supervision code not found")
      throw context.error("\(baseId)-1", .notFound, user: codeNotFound)
    }

    let device = try await supervision.device(in: context.db)
    guard let claimedChildId = device.childId else {
      logIOSUnexpected("\(baseId)-2", "supervision code not yet claimed")
      throw context.error("\(baseId)-2", .notFound, user: codeNotFound)
    }

    if supervision.claimCodeExpiresAt < get(dependency: \.date.now) {
      logIOSUnusual("\(baseId)-3", "supervision code expired")
      let msg = "This code has expired. Open the Gertrude app on the \(device.deviceType) to get a new code."
      throw context.error("\(baseId)-3", .badRequest, user: msg)
    }

    return ValidatedSupervisionCode(
      device: device,
      supervision: supervision,
      claimedChildId: claimedChildId,
    )
  }
}
