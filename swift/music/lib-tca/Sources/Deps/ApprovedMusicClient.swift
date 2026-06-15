import Dependencies
import DependenciesMacros
import Foundation
import MusicRoute

@DependencyClient
struct ApprovedMusicClient: Sendable {
  var loadApprovedLibrary: @Sendable () async throws -> ApprovedMusicLibrary
}

extension ApprovedMusicClient: DependencyKey {
  static var liveValue: Self {
    Self(loadApprovedLibrary: {
      @Dependency(\.api) var api
      @Dependency(\.keychain) var keychain
      guard let connection = keychain.loadConnection() else {
        throw ApprovedMusicClientError.missingConnection
      }
      let output = try await api.getApprovedMusicLibrary(connection.token)
      return await ApprovedMusicLibrary(remote: output)
    })
  }
}

extension DependencyValues {
  var approvedMusic: ApprovedMusicClient {
    get { self[ApprovedMusicClient.self] }
    set { self[ApprovedMusicClient.self] = newValue }
  }
}

extension ApprovedMusicClient {
  static let mock = Self(
    loadApprovedLibrary: { .mock },
  )

  static let empty = Self(
    loadApprovedLibrary: { .empty },
  )
}

private extension ApprovedMusicLibrary {
  init(remote output: GetApprovedMusicLibrary.Output) async {
    let albums = output.albums.map { remoteAlbum in
      ApprovedAlbum(
        id: .init(rawValue: remoteAlbum.id),
        title: remoteAlbum.title,
        artistName: remoteAlbum.artistName,
        artworkURL: remoteAlbum.artworkURL,
        showsArtwork: remoteAlbum.showsArtwork,
        trackIDs: remoteAlbum.trackIds.map { .init(rawValue: $0) },
      )
    }
    let tracks = output.tracks.map { remoteTrack in
      ApprovedTrack(
        id: .init(rawValue: remoteTrack.id),
        title: remoteTrack.title,
        artistName: remoteTrack.artistName,
        albumTitle: remoteTrack.albumTitle,
        albumID: .init(rawValue: remoteTrack.albumId),
        artistIDs: [],
        artworkURL: remoteTrack.artworkURL,
        showsArtwork: remoteTrack.showsArtwork,
      )
    }

    self.init(albums: albums, tracks: tracks)
  }
}

private extension GetApprovedMusicLibrary.Output.Album {
  var artworkURL: URL? {
    guard let artworkUrl else { return nil }
    return URL(string: artworkUrl)
  }
}

private extension GetApprovedMusicLibrary.Output.Track {
  var artworkURL: URL? {
    guard let artworkUrl else { return nil }
    return URL(string: artworkUrl)
  }
}

private enum ApprovedMusicClientError: Error {
  case missingConnection
}
