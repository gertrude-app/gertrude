import DuetSQL
import Foundation
import PairQL
import Vapor

struct GetClaimDeviceData: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let code: Int
  }

  struct ChildOption: Codable, Equatable, Sendable {
    let id: Child.Id
    let name: String
  }

  struct Output: PairOutput {
    let children: [ChildOption]
    let modelName: String
    let deviceType: String
    let iosVersion: String
  }
}

extension GetClaimDeviceData: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    let supervision = try? await IOSApp.Supervision.query()
      .where(.claimCode == input.code)
      .first(in: context.db)

    guard let supervision else {
      logIOSUnusual("7e7fb536", "supervision code not found")
      let msg = "Code not found. Double-check and try again."
      throw context.error("7e7fb536", .notFound, user: msg)
    }

    let device = try await supervision.device(in: context.db)

    if supervision.claimCodeExpiresAt < get(dependency: \.date.now) {
      logIOSUnusual("87a02411", "supervision code expired")
      let msg = "This code has expired. Please generate a new one."
      throw context.error("87a02411", .badRequest, user: msg)
    }

    if let childId = device.childId {
      if let parentChild = try? await context.verifiedChild(from: childId) {
        logIOSUnusual("7cfaed29", "supervision code already claimed")
        // TODO: better would be to redirect them to next step
        let msg = "This code has already been connected to \(parentChild.name)."
        throw context.error("7cfaed29", .badRequest, user: msg)
      } else {
        logIOSUnexpected("b6bf7016", "attempt to claim device from different parent")
        let msg = "Code not found. Double-check and try again."
        throw context.error("b6bf7016", .notFound, user: msg)
      }
    }

    return try await .init(
      children: (context.parent.children(in: context.db)).map {
        .init(id: $0.id, name: $0.name)
      },
      modelName: device.modelName,
      deviceType: device.deviceType,
      iosVersion: device.iosVersion,
    )
  }
}
