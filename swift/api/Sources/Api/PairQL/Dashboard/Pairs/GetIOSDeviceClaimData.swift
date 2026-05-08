import DuetSQL
import Foundation
import PairQL
import Vapor

struct GetIOSDeviceClaimData: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let code: Int
  }

  struct ChildOption: Codable, Equatable, Sendable {
    let id: Child.Id
    let name: String
  }

  enum ResumeStep: String, Codable, Equatable, Sendable {
    case payment
    case downloadHelper
    case done
  }

  struct Output: PairOutput {
    let children: [ChildOption]
    let modelName: String
    let deviceType: String
    let iosVersion: String
    let resumeStep: ResumeStep?
  }
}

extension GetIOSDeviceClaimData: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    let device = try? await IOSDevice.query()
      .where(.claimCode == input.code)
      .first(in: context.db)

    guard let device else {
      logIOSUnusual("7e7fb536", "supervision code not found")
      let msg = "Code not found. Double-check and try again."
      throw context.error("7e7fb536", .notFound, user: msg)
    }

    if let childId = device.childId {
      if await (try? context.verifiedChild(from: childId)) != nil {
        let supervision = try await device.supervision(in: context.db)
        let step = try await resumeStep(supervision: supervision, in: context)
        return .init(
          children: [],
          modelName: device.modelName,
          deviceType: device.deviceType,
          iosVersion: device.iosVersion,
          resumeStep: step,
        )
      } else {
        logIOSUnexpected("b6bf7016", "attempt to claim device from different parent")
        let msg = "Code not found. Double-check and try again."
        throw context.error("b6bf7016", .notFound, user: msg)
      }
    }

    if let expiresAt = device.claimCodeExpiresAt,
       expiresAt < get(dependency: \.date.now) {
      logIOSUnusual("87a02411", "supervision code expired")
      let msg = "This code has expired. Please generate a new one."
      throw context.error("87a02411", .badRequest, user: msg)
    }

    return try await .init(
      children: (context.parent.children(in: context.db)).map {
        .init(id: $0.id, name: $0.name)
      },
      modelName: device.modelName,
      deviceType: device.deviceType,
      iosVersion: device.iosVersion,
      resumeStep: nil,
    )
  }
}

private func resumeStep(
  supervision: BlockerApp.Supervision?,
  in context: ParentContext,
) async throws -> GetIOSDeviceClaimData.ResumeStep {
  if supervision?.supervisedAt != nil {
    return .done
  }
  let plan = try await context.parent.plan(in: context.db)
  if !plan.allowsSupervision {
    return .payment
  }
  return .downloadHelper
}
