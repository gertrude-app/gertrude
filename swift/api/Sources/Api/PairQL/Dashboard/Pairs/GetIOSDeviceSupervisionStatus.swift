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
    let device = try? await IOSDevice.query()
      .where(.claimCode == input.code)
      .first(in: context.db)

    guard let device else {
      logIOSUnusual("d3f8a721", "supervision status: code not found")
      let msg = "Code not found. Double-check and try again."
      throw context.error("d3f8a721", .notFound, user: msg)
    }

    guard let childId = device.childId else {
      logIOSUnusual("e5c2b198", "supervision status: device not yet claimed")
      let msg = "This device hasn't been claimed yet."
      throw context.error("e5c2b198", .badRequest, user: msg)
    }

    let supervision = try await device.supervision(in: context.db)
    let child = try await context.verifiedChild(from: childId)
    let account = try await context.currentBillingAccount()
    return .init(
      deviceId: device.id,
      childId: child.id,
      childName: child.name,
      modelName: device.modelName,
      deviceType: device.deviceType,
      iosVersion: device.iosVersion,
      supervisionStatus: supervision?.supervised == true ? .supervised : .awaitingSupervision,
      requiresPayment: !account.can(.superviseIosDevice),
    )
  }
}
