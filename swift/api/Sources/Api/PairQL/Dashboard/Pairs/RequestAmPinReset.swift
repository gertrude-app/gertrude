import DuetSQL
import Foundation
import PairQL

struct RequestAmPinReset: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let deviceId: IOSDevice.Id
  }

  struct Output: PairOutput {
    let code: Int
    let expiresAt: Date
  }
}

extension RequestAmPinReset: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    let device = try await context.db.find(input.deviceId)

    guard let childId = device.childId else {
      throw context.error("464a2a8d", .notFound, user: "Device not found.")
    }

    guard await (try? context.verifiedChild(from: childId)) != nil else {
      throw context.error("cbc3f164", .unauthorized, user: "You don't have access to this device.")
    }

    guard let install = try await device.podcastInstall(in: context.db) else {
      throw context.error(
        "efaeb74c",
        .notFound,
        user: "Gertrude Podcasts is not set up on this device.",
      )
    }

    let expiresAt = get(dependency: \.date.now) + .minutes(60)
    let code = await get(dependency: \.ephemeral)
      .createPinResetCode(forInstall: install.id, expiration: expiresAt)

    Task {
      let email = context.parent.email.rawValue
      await get(dependency: \.slack).internal(
        .podcasts,
        "*Podcasts PIN reset:* code generated for install `\(install.id)` by `\(email)`",
      )
    }

    return .init(code: code, expiresAt: expiresAt)
  }
}
