import Dependencies
import Foundation
import MacAppRoute
import Vapor

extension MacApp {
  struct ChildContext: ResolverContext {
    let requestId: String
    let dashboardUrl: String
    let child: Child
    let token: MacAppToken

    @Dependency(\.uuid) var uuid
    @Dependency(\.env) var env
    @Dependency(\.db) var db

    func computerUser() async throws -> ComputerUser {
      try await self.token.computerUser(in: self.db)
    }
  }
}

extension AuthedUserRoute: RouteResponder {
  static func respond(
    to route: Self,
    in context: MacApp.ChildContext,
  ) async throws -> Response {
    switch route {
    case .checkIn(let input):
      let output = try await CheckIn.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .checkIn_v2(let input):
      let output = try await CheckIn_v2.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .disableFilterForChild:
      let output = try await DisableFilterForChild.resolve(in: context)
      return try await self.respond(with: output)
    case .createSignedScreenshotUpload(let input):
      let output = try await CreateSignedScreenshotUpload.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .createSignedScreenshotUpload_v2(let input):
      let output = try await CreateSignedScreenshotUpload_v2.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .logFilterEvents(let input):
      let output = try await LogFilterEvents.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .logSecurityEvent(let input):
      let output = try await LogSecurityEvent.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .createKeystrokeLines(let input):
      let output = try await CreateKeystrokeLines.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .createOnboardingAppKeys(let input):
      let output = try await CreateOnboardingAppKeys.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .createOnboardingBlockedApps(let input):
      let output = try await CreateOnboardingBlockedApps.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .createOnboardingKeychain(let input):
      let output = try await CreateOnboardingKeychain.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .createSuspendFilterRequest_v2(let input):
      let output = try await CreateSuspendFilterRequest_v2.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .createUnlockRequests_v3(let input):
      let output = try await CreateUnlockRequests_v3.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .reportBrowsers(let input):
      let output = try await ReportBrowsers.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .uploadAppIcon(let input):
      let output = try await UploadAppIcon.resolve(with: input, in: context)
      return try await self.respond(with: output)
    }
  }
}

extension MacApp.ChildContext {
  func verifyOnboardingToken(_ pairName: String, _ eventId: String) async throws {
    @Dependency(\.date.now) var now
    let tokenAge = now.timeIntervalSince(self.token.createdAt)
    guard tokenAge > .minutes(90) else { return }
    let parent = try await self.child.parent(in: self.db)
    await get(dependency: \.slack).internal(
      .info,
      "Rejected \(pairName) for *\(self.child.name)* (\(parent.adminSiteLink(.slack))), token too old `\(eventId)`",
    )
    try await self.db.create(InterestingEvent(
      eventId: eventId,
      kind: "event",
      context: "macapp",
      computerUserId: self.computerUser().id,
      parentId: parent.id,
      detail: "suspicious \(pairName), token age: \(Int(tokenAge))s",
    ))
    throw self.error(
      id: "e-\(eventId)",
      type: .unauthorized,
      debugMessage: "token too old for \(pairName)",
    )
  }
}
