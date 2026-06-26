import DuetSQL
import Foundation
import PairQL
import PodcastRoute
import TSCodable
import Vapor

struct GetAmClaimData: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let code: Int
  }

  @TSCodable
  enum ResumeStep: Equatable, Sendable {
    case done(amSubscription: AmSubscriptionState, childName: String)
  }

  struct Output: PairOutput {
    let children: [GetIOSDeviceClaimData.ChildOption]
    let modelName: String
    let deviceType: String
    let iosVersion: String
    let resumeStep: ResumeStep?
  }
}

extension GetAmClaimData: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    try await resolveClaimData(
      code: input.code,
      intent: .podcasts,
      baseId: "50c00d4d", // 50c00d4d-1, 50c00d4d-2, 50c00d4d-3, 50c00d4d-4
      in: context,
      onResume: { device, child in
        guard let install = try await device.podcastInstall(in: context.db) else {
          logIOSUnusual("03eaf14e", "AM claim resume on device with no podcast install")
          let msg = "Code not found. Double-check and try again."
          throw context.error("03eaf14e", .notFound, user: msg)
        }
        let account = try await context.currentBillingAccount()
        return Output(
          children: [],
          modelName: device.modelName,
          deviceType: device.deviceType,
          iosVersion: device.iosVersion,
          resumeStep: .done(
            amSubscription: account.amSubscriptionState(forInstall: install),
            childName: child.name,
          ),
        )
      },
      onUnclaimed: { device, children in
        Output(
          children: children.map { GetIOSDeviceClaimData.ChildOption(id: $0.id, name: $0.name) },
          modelName: device.modelName,
          deviceType: device.deviceType,
          iosVersion: device.iosVersion,
          resumeStep: nil,
        )
      },
    )
  }
}
