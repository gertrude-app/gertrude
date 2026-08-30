import Dependencies
import MusicRoute
import Vapor

extension MusicApp {
  struct InstallContext: ResolverContext {
    let requestId: String
    let dashboardUrl: String
    let install: MusicApp.Install
    let device: IOSDevice
    let child: Child
    let telemetry: TelemetryBag

    @Dependency(\.db) var db
    @Dependency(\.env) var env
  }
}

func requireMusicAccess(in ctx: MusicApp.InstallContext) async throws {
  let parent = try await ctx.child.parent(in: ctx.db)
  let account = try await parent.billingAccountSnapshot(
    in: ctx.db,
    at: get(dependency: \.date.now),
  )
  try requireGertrudeMusicAccess(in: ctx, billing: account)
}

extension AuthedRoute: RouteResponder {
  static func respond(to route: Self, in ctx: MusicApp.InstallContext) async throws -> Response {
    switch route {
    case .getApprovedMusicLibrary:
      let output = try await GetApprovedMusicLibrary.resolve(in: ctx)
      return try await self.respond(with: output)
    case .getApprovedMusicLibrary_v2(let input):
      let output = try await GetApprovedMusicLibrary_v2.resolve(with: input, in: ctx)
      return try await self.respond(with: output)
    case .createMusicPlaylist(let input):
      let output = try await CreateMusicPlaylist.resolve(with: input, in: ctx)
      return try await self.respond(with: output)
    case .renameMusicPlaylist(let input):
      let output = try await RenameMusicPlaylist.resolve(with: input, in: ctx)
      return try await self.respond(with: output)
    case .deleteMusicPlaylist(let input):
      let output = try await DeleteMusicPlaylist.resolve(with: input, in: ctx)
      return try await self.respond(with: output)
    case .addToMusicPlaylist(let input):
      let output = try await AddToMusicPlaylist.resolve(with: input, in: ctx)
      return try await self.respond(with: output)
    case .addMusicBatchToPlaylist(let input):
      let output = try await AddMusicBatchToPlaylist.resolve(with: input, in: ctx)
      return try await self.respond(with: output)
    case .removeMusicPlaylistEntry(let input):
      let output = try await RemoveMusicPlaylistEntry.resolve(with: input, in: ctx)
      return try await self.respond(with: output)
    case .reorderMusicPlaylistEntries(let input):
      let output = try await ReorderMusicPlaylistEntries.resolve(with: input, in: ctx)
      return try await self.respond(with: output)
    }
  }
}
