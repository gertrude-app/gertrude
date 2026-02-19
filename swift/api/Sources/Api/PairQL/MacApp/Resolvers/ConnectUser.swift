import Dependencies
import DuetSQL
import Gertie
import MacAppRoute
import Vapor

extension ConnectUser: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    guard let childId = await with(dependency: \.ephemeral)
      .getPendingAppConnection(input.verificationCode) else {
      throw context.error(
        id: "6e7fc234",
        type: .unauthorized,
        debugMessage: "verification code not found",
        userMessage: "Connection code expired, or not found. Please create a new code and try again.",
        appTag: .connectionCodeNotFound,
      )
    }

    let computerUser: ComputerUser
    let child = try await context.db.find(childId)

    let parent = try await ParentWithSubscription.find(child.parentId, in: context.db)
    switch parent.plan {
    case .full(.complimentary), .full(.trialing), .full(.paid):
      break
    default:
      unexpected("9cf4e745", parent.model.id, "mac app connection, no .full plan")
      throw context.error(
        id: "ba2d1e75",
        type: .unauthorized,
        debugMessage: "account does not permit mac app connection",
        userMessage: "This Gertrude account does not currently support connecting a Mac app. Please upgrade or start a free trial and try again.",
      )
    }

    var computer = try? await Computer.query()
      .where(.serialNumber == input.serialNumber)
      .first(in: context.db)

    // there should only ever be a single gertrude user
    // per computer + macOS user (represented by os user numeric id)
    var existingComputerUser: ComputerUser?
    if let computer {
      existingComputerUser = try? await ComputerUser.query()
        .where(.computerId == computer.id)
        .where(.numericId == input.numericId)
        .first(in: context.db)
    }

    if var existingComputerUser {
      // we get in here if the gertrude app was already installed for this macOS user
      // at some point in the past, so we will update the ComputerUser to be attached to this
      // user, after double-checking below that the user belongs to the same admin acct

      // sanity check - we only "transfer" a device, if the admin accounts match
      let existingUser = try await existingComputerUser.child(in: context.db)
      if existingUser.parentId != child.parentId {
        throw context.error(
          id: "41a43089",
          type: .unauthorized,
          debugMessage: "invalid connect transfer attempt",
          userMessage: "This user is associated with another Gertrude parent account.",
        )
      }

      let oldUserId = existingComputerUser.childId
      existingComputerUser.username = input.username
      existingComputerUser.fullUsername = input.fullUsername
      existingComputerUser.childId = child.id
      existingComputerUser.isAdmin = input.isAdmin

      // update the device to be attached to the user issuing this request
      computerUser = try await context.db.update(existingComputerUser)

      let oldTokens = try await MacAppToken.query()
        .where(.computerUserId == computerUser.id)
        .where(.childId == oldUserId)
        .all(in: context.db)

      @Dependency(\.date.now) var now
      for var token in oldTokens {
        // wait 14 days, so buffered security events can be resent
        token.deletedAt = now + .days(14)
        try await context.db.update(token)
      }

    } else {
      if computer == nil {
        // create new admin device if we don't have one
        computer = try await context.db.create(Computer(
          parentId: child.parentId,
          osVersion: input.osVersion.flatMap(Semver.init),
          modelIdentifier: input.modelIdentifier,
          serialNumber: input.serialNumber,
        ))
      }

      // ...and create the user device
      computerUser = try await context.db.create(ComputerUser(
        childId: child.id,
        computerId: computer?.id ?? .init(),
        isAdmin: input.isAdmin,
        appVersion: input.appVersion,
        username: input.username,
        fullUsername: input.fullUsername,
        numericId: input.numericId,
      ))
    }

    let token = try await context.db.create(MacAppToken(
      childId: child.id,
      computerUserId: computerUser.id,
    ))

    await notifyAdConversion(child: child, db: context.db)

    return Output(
      id: child.id.rawValue,
      token: token.value.rawValue,
      deviceId: computerUser.id.rawValue,
      name: child.name,
      keyloggingEnabled: child.keyloggingEnabled,
      screenshotsEnabled: child.screenshotsEnabled,
      screenshotFrequency: child.screenshotsFrequency,
      screenshotSize: child.screenshotsResolution,
    )
  }
}

// helpers

private func notifyAdConversion(child: Child, db: any DuetSQL.Client) async {
  guard let parent = try? await db.find(child.parentId),
        let gclid = parent.gclid else {
    return
  }

  let alreadyRecorded = try? await InterestingEvent.query()
    .where(.eventId == "g-ad-conversion")
    .where(.parentId == parent.id)
    .exists(in: db)

  if alreadyRecorded == true {
    with(dependency: \.postmark).toSuperAdmin(
      "google ad conversion",
      "gclid: <code>\(gclid)</code><br/>time: <code>\(Date())</code>",
    )
    _ = try? await db.create(InterestingEvent(
      eventId: "g-ad-conversion",
      kind: "event",
      context: "reporting",
      parentId: parent.id,
    ))
  }
}
