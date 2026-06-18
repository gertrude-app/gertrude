import DuetSQL
import Foundation
import PairQL

func resolveClaimData<Output>(
  code: Int,
  app: GertrudeIOSApp,
  baseId: String,
  in context: ParentContext,
  onResume: (IOSDevice, Child) async throws -> Output,
  onUnclaimed: (IOSDevice, [Child]) async throws -> Output,
) async throws -> Output {
  let found = try? await IOSDevice.query()
    .where(.claimCode == code)
    .first(in: context.db)

  guard let device = found else {
    logIOSUnusual("\(baseId)-1", "\(app.claimLogLabel) claim code not found")
    let msg = "Code not found. Double-check and try again."
    throw context.error("\(baseId)-1", .notFound, user: msg)
  }

  if let childId = device.childId {
    if let child = try? await context.verifiedChild(from: childId) {
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
      logIOSUnexpected(
        "\(baseId)-2",
        differentParentClaimLogDetail(app, code, context.parent, device, ownerChild, ownerParent),
      )
      let msg = "Code not found. Double-check and try again."
      throw context.error("\(baseId)-2", .notFound, user: msg)
    }
  }

  if let expiresAt = device.claimCodeExpiresAt,
     expiresAt < get(dependency: \.date.now) {
    logIOSUnusual("\(baseId)-3", "\(app.claimLogLabel) claim code expired")
    let msg = "This code has expired. Please generate a new one."
    throw context.error("\(baseId)-3", .badRequest, user: msg)
  }

  let children = try await context.parent.children(in: context.db)
  return try await onUnclaimed(device, children)
}
