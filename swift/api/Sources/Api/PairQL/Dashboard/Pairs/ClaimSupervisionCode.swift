import DuetSQL
import Foundation
import PairQL
import Vapor

struct ClaimSupervisionCode: Pair {
  static let auth: ClientAuth = .parent

  enum ChildAssignment: Codable, Equatable, Sendable {
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
extension ClaimSupervisionCode: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    let device = try? await IOSApp.Device.query()
      .where(.supervisionClaimCode == input.code)
      .first(in: context.db)

    guard var device else {
      logIOSUnusual("4083a77f", "supervision code not found")
      let msg = "Code not found. Double-check and try again."
      throw context.error("4083a77f", .notFound, user: msg)
    }

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

    if let expiresAt = device.claimCodeExpiresAt, expiresAt <= get(dependency: \.date.now) {
      logIOSUnusual("25bef9db", "supervision code expired")
      let deviceType = ModelIdentifier.deviceType(from: device.modelIdentifier)
      let msg = "This code has expired. Open the Gertrude app on the \(deviceType) to get a new one."
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

    // start with ALL block groups, parent controls from web ui
    let groups = try await IOSApp.BlockGroup.query().all(in: context.db)
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

    return .init(
      childName: child.name,
      modelName: device.modelName,
      iosVersion: device.iosVersion,
      code: input.code,
    )
  }
}
