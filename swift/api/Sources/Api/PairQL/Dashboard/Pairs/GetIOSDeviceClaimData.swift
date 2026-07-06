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
    try await resolveClaimData(
      code: input.code,
      intent: .blockerSupervise,
      baseId: "7321ce12", // 7321ce12-1, 7321ce12-2, 7321ce12-3, 7321ce12-4
      in: context,
      onResume: { device, _ in
        try await claimedOutput(for: device, in: context)
      },
      onUnclaimed: { device, children in
        Output(
          children: children.map { ChildOption(id: $0.id, name: $0.name) },
          modelName: device.modelName,
          deviceType: device.deviceType,
          iosVersion: device.iosVersion,
          resumeStep: nil,
        )
      },
      onUnclaimedBound: { claim, device, child in
        try await completeClaim(claim, for: child, in: context.db)
        return try await claimedOutput(for: device, in: context)
      },
    )
  }
}

private func claimedOutput(
  for device: IOSDevice,
  in context: ParentContext,
) async throws -> GetIOSDeviceClaimData.Output {
  try await device.ensureBlockerBlockGroups(in: context.db)
  let supervision = try await device.supervision(in: context.db)
  let step = try await resumeStep(supervision: supervision, in: context)
  return GetIOSDeviceClaimData.Output(
    children: [],
    modelName: device.modelName,
    deviceType: device.deviceType,
    iosVersion: device.iosVersion,
    resumeStep: step,
  )
}

private func resumeStep(
  supervision: BlockerApp.Supervision?,
  in context: ParentContext,
) async throws -> GetIOSDeviceClaimData.ResumeStep {
  if supervision?.supervisedAt != nil {
    return .done
  }
  let account = try await context.currentBillingAccount()
  if account.paymentActionForMissingLightPlanCapability(.superviseIosDevice) != nil {
    return .payment
  }
  return .downloadHelper
}
