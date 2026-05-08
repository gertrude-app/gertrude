import DuetSQL
import PairQL

struct GetPendingSupervision: Pair {
  static let auth: ClientAuth = .none

  struct Input: PairInput {
    let code: Int
    let platform: String
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

    if validated.supervision.supervisedAt != nil {
      let msg = "Device already supervised. Open the Gertrude app on the \(validated.device.deviceType) to continue setup."
      throw context.error("1a01d2ae", .badRequest, user: msg)
    }

    try await context.db.create(IOSEvent(
      eventId: "3b8f1e2c",
      kind: .supervision,
      detail: "tool_code_entered: platform=\(input.platform)",
      deviceId: validated.device.id,
      modelIdentifier: validated.device.modelIdentifier,
      iosVersion: validated.device.iosVersion,
    ))

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
  let device: IOSDevice
  let supervision: BlockerApp.Supervision
  let claimedChildId: Child.Id
}

extension SuperviseRoute {
  static func validatedSupervisionCode(
    code: Int,
    baseId: String,
    in context: Context,
  ) async throws -> ValidatedSupervisionCode {
    let supervision = try? await BlockerApp.Supervision.query()
      .where(.claimCode == code)
      .first(in: context.db)

    let codeNotFound = "Code not found. Double-check and try again."
    guard let supervision else {
      logIOSUnusual("\(baseId)-1", "supervision code not found")
      throw context.error("\(baseId)-1", .notFound, user: codeNotFound)
    }

    let device = try await supervision.device(in: context.db)
    guard let claimedChildId = device.childId else {
      logIOSUnusual("\(baseId)-2", "supervision code not yet claimed")
      let msg = "This device hasn't been claimed yet. Complete the claim step in the Gertrude dashboard first."
      throw context.error("\(baseId)-2", .badRequest, user: msg)
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
