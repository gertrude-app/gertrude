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
  beforeFreshClaim: ((IOSDevice) async throws -> Void)? = nil,
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
      return try await onResume(device, child)
    } else {
      logIOSUnusual(
        "\(baseId)-2",
        "attempt to claim \(app.claimLogLabel) device from different parent",
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

  if let beforeFreshClaim {
    try await beforeFreshClaim(device)
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
