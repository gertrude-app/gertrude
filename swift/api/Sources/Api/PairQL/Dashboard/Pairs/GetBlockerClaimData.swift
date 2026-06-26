import DuetSQL
import Foundation
import PairQL
import TSCodable

struct GetBlockerClaimData: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let code: Int
  }

  @TSCodable
  enum ResumeStep: Equatable, Sendable {
    case done(childName: String, childId: Child.Id, deviceId: IOSDevice.Id)
  }

  struct Output: PairOutput {
    let children: [GetIOSDeviceClaimData.ChildOption]
    let modelName: String
    let deviceType: String
    let iosVersion: String
    let resumeStep: ResumeStep?
  }
}

extension GetBlockerClaimData: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    try await resolveClaimData(
      code: input.code,
      intent: .blockerConnect,
      baseId: "b8a3f1c2", // b8a3f1c2-1, b8a3f1c2-2, b8a3f1c2-3, b8a3f1c2-4
      in: context,
      onResume: { device, child in
        Output(
          children: [],
          modelName: device.modelName,
          deviceType: device.deviceType,
          iosVersion: device.iosVersion,
          resumeStep: .done(childName: child.name, childId: child.id, deviceId: device.id),
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
