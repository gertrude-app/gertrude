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
    // TODO: superios - must change when we do modelIdentifier -> marketing name
    // should become `deviceModelMarketingName` or similar, w/ `iPhone 16 Pro` etc
    let deviceType: String
    let iosVersion: String
    let code: Int
  }
}

// resolver

// this pair runs when a parent/accountability partner "claims" a pending ios supervision
// by having been redirected to a dashboard /login screen, and prompted to create an account
// and by means of query params, we detect that they are claiming a device and prompt them to
// either a) create a child by just entering a name (most common), or b) choose from an
// existing child if they already had a gertrude account
extension ClaimSupervisionCode: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    let pendingSupervision = try? await IOSApp.PendingSupervision.query()
      .where(.code == input.code)
      .first(in: context.db)

    guard var pendingSupervision else {
      logIOSUnusual("4083a77f", "pending supervision code not found")
      let msg = "Code not found. Double-check and try again."
      throw context.error("4083a77f", .notFound, user: msg)
    }

    if let claimedChildId = pendingSupervision.claimedChildId {
      if let child = try? await context.verifiedChild(from: claimedChildId) {
        guard let device = try? await IOSApp.Device.query()
          .where(.vendorId == pendingSupervision.vendorId)
          .first(in: context.db) else {
          logIOSUnusual("5dadafc9", "missing device in supervision re-claim")
          throw context.error("5dadafc9", .serverError, user: "Unexpected error, please try again")
        }

        return .init(
          childName: child.name,
          deviceType: ModelIdentifier.deviceType(from: device.modelIdentifier),
          iosVersion: device.iosVersion,
          code: input.code,
        )
      } else {
        logIOSUnusual("3ac80159", "attempt to claim device from different parent")
        let msg = "Code not found. Double-check and try again."
        throw context.error("3ac80159", .notFound, user: msg)
      }
    }

    guard pendingSupervision.expiresAt > get(dependency: \.date.now) else {
      logIOSUnusual("25bef9db", "pending supervision code not found")
      let msg = "This code has expired. Open the Gertrude app on the device to get a new one."
      throw context.error("25bef9db", .badRequest, user: msg)
    }

    // here we cover scenarios where the parent already claimed the device,
    // but never ran the supervision tool and completed, and tried later w/ new code
    if let prevDevice = try? await IOSApp.Device.query()
      .where(.vendorId == pendingSupervision.vendorId)
      .first(in: context.db) {
      let prevChild = try await context.db.find(prevDevice.childId)
      if prevChild.parentId != context.parent.id { // sanity check
        logIOSUnusual("4f6694ed", "attempt to claim prev device from different parent")
        let msg = "Code not found. Double-check and try again."
        throw context.error("4f6694ed", .notFound, user: msg)
      }
      pendingSupervision.claimedChildId = prevChild.id
      try await context.db.update(pendingSupervision)
      return .init(
        childName: prevChild.name,
        deviceType: ModelIdentifier.deviceType(from: prevDevice.modelIdentifier),
        iosVersion: prevDevice.iosVersion,
        code: input.code,
      )
    }

    let child = switch input.child {
    case .existingChild(id: let id):
      try await context.verifiedChild(from: id)
    case .newChild(name: let name):
      try await context.db.create(Child(parentId: context.parent.id, name: name))
    }

    let device = try await context.db.create(IOSApp.Device(
      childId: child.id,
      vendorId: .init(pendingSupervision.vendorId),
      modelIdentifier: pendingSupervision.modelIdentifier,
      appVersion: pendingSupervision.appVersion,
      iosVersion: pendingSupervision.iosVersion,
    ))

    // start with ALL block groups, parent controls from web ui
    let groups = try await IOSApp.BlockGroup.query().all(in: context.db)
    try await context.db.create(groups.map {
      IOSApp.DeviceBlockGroup(deviceId: device.id, blockGroupId: $0.id)
    })

    pendingSupervision.claimedChildId = child.id
    try await context.db.update(pendingSupervision)

    return .init(
      childName: child.name,
      deviceType: ModelIdentifier.deviceType(from: device.modelIdentifier),
      iosVersion: device.iosVersion,
      code: input.code,
    )
  }
}
