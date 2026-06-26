import DuetSQL
import Foundation
import PairQL

struct ClaimBlockerDevice: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let code: Int
    let child: ClaimIOSDevice.ChildAssignment
  }

  struct Output: PairOutput {
    let childName: String
    let modelName: String
    let iosVersion: String
    let code: Int
    let childId: Child.Id
    let deviceId: IOSDevice.Id
  }
}

extension ClaimBlockerDevice: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    try await claimDevice(
      intent: .blockerConnect,
      code: input.code,
      child: input.child,
      baseId: "d4e7a9b6", // d4e7a9b6-1, d4e7a9b6-2, d4e7a9b6-3, d4e7a9b6-4
      in: context,
      onResume: { device, child in
        self.output(device: device, child: child, code: input.code)
      },
      onFresh: { device, child in
        try await device.ensureBlockerBlockGroups(in: context.db)
        return self.output(device: device, child: child, code: input.code)
      },
    )
  }

  static func output(device: IOSDevice, child: Child, code: Int) -> Output {
    .init(
      childName: child.name,
      modelName: device.modelName,
      iosVersion: device.iosVersion,
      code: code,
      childId: child.id,
      deviceId: device.id,
    )
  }
}
