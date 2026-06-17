import PairQL

func verifiedChildWithConnectedMusicApp(
  from childId: Child.Id,
  in context: ParentContext,
) async throws -> Child {
  let child = try await context.verifiedChild(from: childId)
  let account = try await context.currentBillingAccount()
  try requireGertrudeMusicAccess(in: context, billing: account)

  let devices = try await child.iosDevices(in: context.db)
  let connectedDeviceIds = try await MusicApp.Token.connectedDeviceIds(
    among: devices.map(\.id),
    in: context.db,
  )
  guard !connectedDeviceIds.isEmpty else {
    throw context.error(
      "1fa9493f",
      .badRequest,
      user: "Connect Gertrude Music for this child before managing music.",
    )
  }
  return child
}
