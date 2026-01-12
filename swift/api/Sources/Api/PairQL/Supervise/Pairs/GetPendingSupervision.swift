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
      baseId: "7863605f", // 7863605f-1, 7863605f-2, 7863605f-3
      in: context,
    )

    let child = try await context.db.find(validated.claimedChildId)
    return .init(
      childName: child.name,
      modelIdentifier: validated.pendingSupervision.modelIdentifier,
      modelName: validated.pendingSupervision.modelName,
      iosVersion: validated.pendingSupervision.iosVersion,
    )
  }
}

struct ValidatedSupervisionCode {
  let pendingSupervision: IOSApp.PendingSupervision
  let claimedChildId: Child.Id
}

extension SuperviseRoute {
  static func validatedSupervisionCode(
    code: Int,
    baseId: String,
    in context: Context,
  ) async throws -> ValidatedSupervisionCode {
    let pending = try? await IOSApp.PendingSupervision.query()
      .where(.code == code)
      .first(in: context.db)

    let codeNotFound = "Code not found. Double-check and try again."
    guard let pending else {
      logIOSUnusual("\(baseId)-1", "pending supervision code not found")
      throw context.error("\(baseId)-1", .notFound, user: codeNotFound)
    }

    guard let claimedChildId = pending.claimedChildId else {
      logIOSUnexpected("\(baseId)-2", "supervision code not yet claimed")
      throw context.error("\(baseId)-2", .notFound, user: codeNotFound)
    }

    guard pending.expiresAt > get(dependency: \.date.now) else {
      logIOSUnusual("\(baseId)-3", "pending supervision code expired")
      let device = ModelIdentifier.deviceType(from: pending.modelIdentifier)
      let msg = "This code has expired. Open the Gertrude app on the \(device) to get a new code."
      throw context.error("\(baseId)-3", .badRequest, user: msg)
    }

    return ValidatedSupervisionCode(pendingSupervision: pending, claimedChildId: claimedChildId)
  }
}
