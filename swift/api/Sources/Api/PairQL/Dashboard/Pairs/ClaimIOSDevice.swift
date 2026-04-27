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
    let supervision = try? await IOSApp.Supervision.query()
      .where(.claimCode == input.code)
      .first(in: context.db)

    guard var supervision else {
      logIOSUnusual("4083a77f", "supervision code not found")
      let msg = "Code not found. Double-check and try again."
      throw context.error("4083a77f", .notFound, user: msg)
    }

    var device = try await supervision.device(in: context.db)
    if let childId = device.childId {
      if let child = try? await context.verifiedChild(from: childId) {
        return .init(
          childName: child.name,
          modelName: device.modelName,
          iosVersion: device.iosVersion,
          code: input.code,
        )
      } else {
        logIOSUnusual("3ac80159", "attempt to claim device from different parent")
        let msg = "Code not found. Double-check and try again."
        throw context.error("3ac80159", .notFound, user: msg)
      }
    }

    if supervision.claimCodeExpiresAt <= get(dependency: \.date.now) {
      logIOSUnusual("25bef9db", "supervision code expired")
      let msg = "This code has expired. Open the Gertrude app on the \(device.deviceType) to get a new one."
      throw context.error("25bef9db", .badRequest, user: msg)
    }

    let child = switch input.child {
    case .existingChild(id: let id):
      try await context.verifiedChild(from: id)
    case .newChild(name: let name):
      try await context.db.create(Child(parentId: context.parent.id, name: name))
    }

    device.childId = child.id
    try await context.db.update(device)
    supervision.claimedAt = get(dependency: \.date.now)
    try await context.db.update(supervision)

    // start with ALL non-opt-in block groups, parent controls from web ui
    let groups = try await IOSApp.BlockGroup.query()
      .where(.optIn == false)
      .all(in: context.db)
    try await context.db.create(groups.map {
      IOSApp.DeviceBlockGroup(deviceId: device.id, blockGroupId: $0.id)
    })

    try await context.db.create(IOSEvent(
      eventId: "f2c3863b",
      kind: .supervision,
      detail: "code_claimed: code=\(input.code)",
      deviceId: device.id,
      modelIdentifier: device.modelIdentifier,
      iosVersion: device.iosVersion,
    ))

    Task {
      let email = context.parent.email.rawValue
      await get(dependency: \.slack)
        .internal(.info, "*iOS supervision:* code `\(input.code)` claimed by `\(email)`")
    }

    return .init(
      childName: child.name,
      modelName: device.modelName,
      iosVersion: device.iosVersion,
      code: input.code,
    )
  }
}
