import DuetSQL
import Foundation
import PairQL
import TSCodable
import Vapor

struct ClaimIOSDevice: Pair {
  static let auth: ClientAuth = .parent

  @TSCodable
  enum ChildAssignment: Equatable, Sendable {
    case newChild(name: String)
    case existingChild(id: Child.Id)
  }

  struct Input: PairInput {
    let code: Int
    let child: ChildAssignment
  }

  struct Output: PairOutput {
    let childName: String
    let modelName: String
    let iosVersion: String
    let code: Int
  }
}

// resolver

// this pair runs when a parent/accountability partner "claims" a pending ios supervision
// by having been redirected to a dashboard /signup screen, and prompted to create an account
// and by means of query params, we detect that they are claiming a device and prompt them to
// either a) create a child by just entering a name (most common), or b) choose from an
// existing child if they already had a gertrude account
extension ClaimIOSDevice: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    try await claimDevice(
      for: .blocker,
      code: input.code,
      child: input.child,
      baseId: "f71dcb51", // f71dcb51-1, f71dcb51-2, f71dcb51-3
      in: context,
      onResume: { device, child in
        self.output(device: device, child: child, code: input.code)
      },
      onFresh: { device, child in
        // start with ALL non-opt-in block groups, parent controls from web ui
        try await device.ensureBlockerBlockGroups(in: context.db)

        try await context.db.create(IOSEvent(
          eventId: "f2c3863b",
          kind: .supervision,
          detail: "code_claimed: code=\(input.code)",
          deviceId: device.id,
          modelIdentifier: device.modelIdentifier,
          iosVersion: device.iosVersion,
        ))

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
    )
  }
}
