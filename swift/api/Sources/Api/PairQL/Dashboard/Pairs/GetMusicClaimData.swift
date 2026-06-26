import DuetSQL
import Foundation
import PairQL
import TSCodable
import Vapor

struct GetMusicClaimData: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let code: Int
  }

  @TSCodable
  enum ResumeStep: Equatable, Sendable {
    case done(childName: String)
  }

  struct Output: PairOutput {
    let children: [GetIOSDeviceClaimData.ChildOption]
    let modelName: String
    let deviceType: String
    let iosVersion: String
    let resumeStep: ResumeStep?
    let paymentAction: GetSubscriptionPanel_v2.Action?
  }
}

extension GetMusicClaimData: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    let account = try await context.currentBillingAccount()
    let paymentAction = account.paymentActionForMissingLightPlanCapability(.useGertrudeMusic)

    return try await resolveClaimData(
      code: input.code,
      intent: .music,
      baseId: "5052a8c5", // 5052a8c5-1, 5052a8c5-2, 5052a8c5-3, 5052a8c5-4
      in: context,
      onResume: { device, child in
        guard try await device.musicInstall(in: context.db) != nil else {
          logIOSUnusual("b903b698", "Music claim resume on device with no music install")
          let msg = "Code not found. Double-check and try again."
          throw context.error("b903b698", .notFound, user: msg)
        }
        return Output(
          children: [],
          modelName: device.modelName,
          deviceType: device.deviceType,
          iosVersion: device.iosVersion,
          resumeStep: paymentAction == nil ? .done(childName: child.name) : nil,
          paymentAction: paymentAction,
        )
      },
      onUnclaimed: { device, children in
        guard try await device.musicInstall(in: context.db) != nil else {
          logIOSUnusual("4e4b135e", "Music claim data on device with no music install")
          let msg = "Code not found. Double-check and try again."
          throw context.error("4e4b135e", .notFound, user: msg)
        }
        return Output(
          children: paymentAction == nil
            ? children.map { GetIOSDeviceClaimData.ChildOption(id: $0.id, name: $0.name) }
            : [],
          modelName: device.modelName,
          deviceType: device.deviceType,
          iosVersion: device.iosVersion,
          resumeStep: nil,
          paymentAction: paymentAction,
        )
      },
    )
  }
}
