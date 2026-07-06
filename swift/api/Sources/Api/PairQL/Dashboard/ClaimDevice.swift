import DuetSQL
import Foundation
import PairQL

func claimDevice<Output>(
  intent: ClaimIntent,
  code: Int,
  child childAssignment: ClaimIOSDevice.ChildAssignment,
  baseId: String,
  in context: ParentContext,
  onResume: (IOSDevice, Child) async throws -> Output,
  beforeClaim: ((IOSDevice) async throws -> Void)? = nil,
  onFresh: (IOSDevice, Child) async throws -> Output,
) async throws -> Output {
  guard let claim = try await Claim.find(code: code, in: context.db) else {
    logIOSUnusual("\(baseId)-1", "\(intent.claimLogLabel) claim code not found")
    let msg = "Code not found. Double-check and try again."
    throw context.error("\(baseId)-1", .notFound, user: msg)
  }

  if claim.intent != intent {
    logIOSUnusual("\(baseId)-4", "claim intent mismatch: code is \(claim.intent), funnel \(intent)")
    let msg = "That code is for \(claim.intent.app.marketingName), not \(intent.app.marketingName)."
    throw context.error("\(baseId)-4", .notFound, user: msg)
  }

  var device = try await claim.device(in: context.db)
  let deviceChild: Child?

  if let childId = device.childId {
    if let child = try? await context.verifiedChild(from: childId) {
      deviceChild = child
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
        differentParentClaimLogDetail(
          intent,
          code,
          context.parent,
          device,
          ownerChild,
          ownerParent,
        ),
      )
      let msg = "Code not found. Double-check and try again."
      throw context.error("\(baseId)-2", .notFound, user: msg)
    }
  } else {
    deviceChild = nil
  }

  if claim.claimedAt != nil, let child = deviceChild {
    return try await onResume(device, child)
  }

  if claim.expiresAt <= get(dependency: \.date.now) {
    logIOSUnusual("\(baseId)-3", "\(intent.claimLogLabel) claim code expired")
    let msg = "This code has expired. Open \(intent.app.marketingName) on the \(device.deviceType) to get a new one."
    throw context.error("\(baseId)-3", .badRequest, user: msg)
  }

  if let beforeClaim {
    try await beforeClaim(device)
  }

  let child = if let deviceChild {
    deviceChild
  } else {
    switch childAssignment {
    case .existingChild(id: let id):
      try await context.verifiedChild(from: id)
    case .newChild(name: let name):
      try await context.db.create(Child(parentId: context.parent.id, name: name))
    }
  }

  try await finalizeClaim(&device, claim: claim, for: child, in: context.db)

  Task { [email = context.parent.email.rawValue] in
    await get(dependency: \.slack)
      .internal(
        intent.app.slackChannel,
        "*\(intent.claimLogLabel):* code `\(code)` claimed by `\(email)`",
      )
  }

  return try await onFresh(device, child)
}

private func finalizeClaim(
  _ device: inout IOSDevice,
  claim: Claim,
  for child: Child,
  in db: any DuetSQL.Client,
) async throws {
  try await device.bindChild(child, in: db)
  try await completeClaim(claim, for: child, in: db)
}

func completeClaim(
  _ claim: Claim,
  for child: Child,
  in db: any DuetSQL.Client,
) async throws {
  var claim = claim
  try await claim.complete(childId: child.id, in: db)
}

func differentParentClaimLogDetail(
  _ intent: ClaimIntent,
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
    "attempt to claim \(intent.claimLogLabel) device from different parent",
    "code=\(code)",
    "requestingParent=\(parent.email.rawValue) id=\(parent.id)",
    "matchedDeviceId=\(device.id)",
    "ownerParent=\(ownerParentDetail)",
    "ownerChildId=\(ownerChildId.map { "\($0)" } ?? "unknown")",
  ].joined(separator: ", ")
}
