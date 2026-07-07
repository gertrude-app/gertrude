import DuetSQL
import Foundation
import PairQL

func resolveClaimData<Output>(
  code: Int,
  intent: ClaimIntent,
  baseId: String,
  in context: ParentContext,
  onResume: (IOSDevice, Child) async throws -> Output,
  onUnclaimed: (IOSDevice, [Child]) async throws -> Output,
  onUnclaimedBound: ((Claim, IOSDevice, Child) async throws -> Output)? = nil,
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

  let device = try await claim.device(in: context.db)
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
    let msg = "This code has expired. Please generate a new one."
    throw context.error("\(baseId)-3", .badRequest, user: msg)
  }

  if let child = deviceChild, let onUnclaimedBound {
    return try await onUnclaimedBound(claim, device, child)
  }

  let children = try await context.parent.children(in: context.db)
  return try await onUnclaimed(device, children)
}
