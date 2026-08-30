import Dependencies
import DependenciesMacros
import Foundation
import GertieApp
import MusicRoute
import PairQL
import PairQLClient

@DependencyClient
struct ApiClient: Sendable {
  var addToMusicPlaylist:
    @Sendable (_ token: UUID, _ input: AddToMusicPlaylist.Input) async throws
    -> AddToMusicPlaylist.Output
  var addMusicBatchToPlaylist:
    @Sendable (_ token: UUID, _ input: AddMusicBatchToPlaylist.Input) async throws
    -> AddMusicBatchToPlaylist.Output
  var createMusicPlaylist:
    @Sendable (_ token: UUID, _ input: CreateMusicPlaylist.Input) async throws
    -> CreateMusicPlaylist.Output
  var crossPromos: @Sendable () async throws -> CrossPromos.Output = { .init(promos: []) }
  var deleteMusicPlaylist:
    @Sendable (_ token: UUID, _ input: DeleteMusicPlaylist.Input) async throws
    -> DeleteMusicPlaylist.Output
  var getApprovedMusicLibrary:
    @Sendable (_ token: UUID, _ knownRevision: Int64?, _ storefront: String?) async throws
    -> GetApprovedMusicLibrary_v2.Output
  var getMusicAppStatus: @Sendable () async throws -> GetMusicAppStatus_v2.Output
  var removeMusicPlaylistEntry:
    @Sendable (_ token: UUID, _ input: RemoveMusicPlaylistEntry.Input) async throws
    -> RemoveMusicPlaylistEntry.Output
  var renameMusicPlaylist:
    @Sendable (_ token: UUID, _ input: RenameMusicPlaylist.Input) async throws
    -> RenameMusicPlaylist.Output
  var reorderMusicPlaylistEntries:
    @Sendable (_ token: UUID, _ input: ReorderMusicPlaylistEntries.Input) async throws
    -> ReorderMusicPlaylistEntries.Output
}

extension ApiClient: DependencyKey {
  static var liveValue: ApiClient {
    .init(
      addToMusicPlaylist: { token, input in
        try await pairql.call(
          AddToMusicPlaylist.self,
          authed: .addToMusicPlaylist(input),
          token: token,
        )
      },
      addMusicBatchToPlaylist: { token, input in
        try await pairql.call(
          AddMusicBatchToPlaylist.self,
          authed: .addMusicBatchToPlaylist(input),
          token: token,
        )
      },
      createMusicPlaylist: { token, input in
        try await pairql.call(
          CreateMusicPlaylist.self,
          authed: .createMusicPlaylist(input),
          token: token,
        )
      },
      crossPromos: {
        @Dependency(\.device) var device
        @Dependency(\.locale) var locale
        let (deviceId, iosVersion, modelIdentifier, appVersion) = await device.data()
        guard let deviceId else { return .init(promos: []) }
        return try await pairql.call(
          CrossPromos.self,
          unauthed: .crossPromos(.init(
            deviceId: deviceId,
            appVersion: appVersion,
            modelIdentifier: modelIdentifier,
            iosVersion: iosVersion,
            locale: locale.identifier,
          )),
        )
      },
      deleteMusicPlaylist: { token, input in
        try await pairql.call(
          DeleteMusicPlaylist.self,
          authed: .deleteMusicPlaylist(input),
          token: token,
        )
      },
      getApprovedMusicLibrary: { token, knownRevision, storefront in
        let input = GetApprovedMusicLibrary_v2.Input(
          knownRevision: knownRevision,
          storefront: storefront,
        )
        return try await pairql.call(
          GetApprovedMusicLibrary_v2.self,
          authed: .getApprovedMusicLibrary_v2(input),
          token: token,
        )
      },
      getMusicAppStatus: {
        @Dependency(\.device) var device
        let (deviceId, iosVersion, modelIdentifier, appVersion) = await device.data()
        guard let deviceId else {
          throw ApiClient.ApiError.noDeviceId
        }
        return try await pairql.call(
          GetMusicAppStatus_v2.self,
          unauthed: .getMusicAppStatus_v2(.init(
            deviceId: deviceId,
            modelIdentifier: modelIdentifier,
            iosVersion: iosVersion,
            appVersion: appVersion,
          )),
        )
      },
      removeMusicPlaylistEntry: { token, input in
        try await pairql.call(
          RemoveMusicPlaylistEntry.self,
          authed: .removeMusicPlaylistEntry(input),
          token: token,
        )
      },
      renameMusicPlaylist: { token, input in
        try await pairql.call(
          RenameMusicPlaylist.self,
          authed: .renameMusicPlaylist(input),
          token: token,
        )
      },
      reorderMusicPlaylistEntries: { token, input in
        try await pairql.call(
          ReorderMusicPlaylistEntries.self,
          authed: .reorderMusicPlaylistEntries(input),
          token: token,
        )
      },
    )
  }
}

private let pairql = PairQLClient<MusicRoute>(
  endpoint: { GertrudeIOSApp.apiBaseURL() },
  timeout: 10,
)

extension ApiClient {
  enum ApiError: Error {
    case noDeviceId
    case unexpectedError(statusCode: Int)
  }
}

extension DependencyValues {
  var api: ApiClient {
    get { self[ApiClient.self] }
    set { self[ApiClient.self] = newValue }
  }
}
