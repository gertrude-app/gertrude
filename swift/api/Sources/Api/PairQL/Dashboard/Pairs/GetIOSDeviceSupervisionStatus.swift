import DuetSQL
import Foundation
import PairQL
import Vapor

struct GetIOSDeviceSupervisionStatus: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let code: Int
  }

  struct Output: PairOutput {
    let deviceId: IOSDevice.Id
    let childId: Child.Id
    let childName: String
    let modelName: String
    let deviceType: String
    let iosVersion: String
    let supervisionStatus: SupervisionStatus
    let requiresPayment: Bool
  }

  enum SupervisionStatus: String, Codable, Equatable, Sendable {
    case awaitingSupervision
    case supervised
  }
}

extension GetIOSDeviceSupervisionStatus: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    let supervision = try? await BlockerApp.Supervision.query()
      .where(.claimCode == input.code)
      .first(in: context.db)

    guard let supervision else {
      logIOSUnusual("d3f8a721", "supervision status: code not found")
      let msg = "Code not found. Double-check and try again."
      throw context.error("d3f8a721", .notFound, user: msg)
    }

    let device = try await supervision.device(in: context.db)
    guard let childId = device.childId else {
      logIOSUnusual("e5c2b198", "supervision status: device not yet claimed")
      let msg = "This device hasn't been claimed yet."
      throw context.error("e5c2b198", .badRequest, user: msg)
    }

    let child = try await context.verifiedChild(from: childId)
    let subscription = try await context.parent.subscription(in: context.db)
    let plan = Plan(subscription: subscription)
    return .init(
      deviceId: device.id,
      childId: child.id,
      childName: child.name,
      modelName: device.modelName,
      deviceType: device.deviceType,
      iosVersion: device.iosVersion,
      supervisionStatus: supervision.supervised ? .supervised : .awaitingSupervision,
      requiresPayment: !plan.allowsSupervision,
    )
  }
}
