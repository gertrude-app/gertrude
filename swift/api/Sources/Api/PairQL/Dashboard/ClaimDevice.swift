import DuetSQL
import Foundation
import PairQL

func claimDevice<Output>(
  for app: GertrudeIOSApp,
  code: Int,
  child childAssignment: ClaimIOSDevice.ChildAssignment,
  baseId: String,
  in context: ParentContext,
  onResume: (IOSDevice, Child) async throws -> Output,
  beforeClaim: ((IOSDevice) async throws -> Void)? = nil,
  onFresh: (IOSDevice, Child) async throws -> Output,
) async throws -> Output {
  let found = try? await IOSDevice.query()
    .where(.claimCode == code)
    .first(in: context.db)

  guard var device = found else {
    logIOSUnusual("\(baseId)-1", "\(app.claimLogLabel) claim code not found")
    let msg = "Code not found. Double-check and try again."
    throw context.error("\(baseId)-1", .notFound, user: msg)
  }

  if let childId = device.childId {
    if let child = try? await context.verifiedChild(from: childId) {
      if device.claimedAt == nil {
        if let beforeClaim {
          try await beforeClaim(device)
        }
        try await device.claim(for: child, in: context.db)
      }
      return try await onResume(device, child)
    } else {
      let ownerChild = try? await Child.query()
        .where(.id == childId)
        .first(in: context.db)
      let ownerParent: Parent? = if let ownerChild {
        try? await ownerChild.parent(in: context.db)
      } else {
        nil
      }
      logIOSUnusual(
        "\(baseId)-2",
        differentParentClaimLogDetail(app, code, context.parent, device, ownerChild, ownerParent),
      )
      let msg = "Code not found. Double-check and try again."
      throw context.error("\(baseId)-2", .notFound, user: msg)
    }
  }

  if let expiresAt = device.claimCodeExpiresAt,
     expiresAt <= get(dependency: \.date.now) {
    logIOSUnusual("\(baseId)-3", "\(app.claimLogLabel) claim code expired")
    let msg = "This code has expired. Open \(app.marketingName) on the \(device.deviceType) to get a new one."
    throw context.error("\(baseId)-3", .badRequest, user: msg)
  }

  if let beforeClaim {
    try await beforeClaim(device)
  }

  let child = switch childAssignment {
  case .existingChild(id: let id):
    try await context.verifiedChild(from: id)
  case .newChild(name: let name):
    try await context.db.create(Child(parentId: context.parent.id, name: name))
  }

  try await device.claim(for: child, in: context.db)

  Task { [email = context.parent.email.rawValue] in
    await get(dependency: \.slack)
      .internal(app.slackChannel, "*\(app.claimLogLabel):* code `\(code)` claimed by `\(email)`")
  }

  return try await onFresh(device, child)
}

func differentParentClaimLogDetail(
  _ app: GertrudeIOSApp,
  _ code: Int,
  _ parent: Parent,
  _ device: IOSDevice,
  _ ownerChild: Child?,
  _ ownerParent: Parent?,
) -> String {
  let ownerParentDetail = if let ownerParent {
    "\(ownerParent.email.rawValue) id=\(ownerParent.id)"
  } else if let ownerChild {
    "unknown id=\(ownerChild.parentId)"
  } else {
    "unknown"
  }

  let ownerChildId = ownerChild?.id ?? device.childId
  return [
    "attempt to claim \(app.claimLogLabel) device from different parent",
    "code=\(code)",
    "requestingParent=\(parent.email.rawValue) id=\(parent.id)",
    "matchedDeviceId=\(device.id)",
    "ownerParent=\(ownerParentDetail)",
    "ownerChildId=\(ownerChildId.map { "\($0)" } ?? "unknown")",
  ].joined(separator: ", ")
}
