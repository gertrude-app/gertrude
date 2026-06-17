import Dependencies
import DependenciesMacros
import Foundation
import MusicRoute
import PairQL

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
      do {
        let output = try await api.getApprovedMusicLibrary(connection.token)
        return ApprovedMusicLibrary(remote: output)
      } catch let error as PqlError where error.type == .paymentRequired {
        throw ApprovedMusicClientError.subscriptionRequired
      }
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
  init(remote output: GetApprovedMusicLibrary.Output) {
    self.init(albums: output.albums.map(ApprovedAlbum.init))
  }
}

private extension ApprovedAlbum {
  init(remote album: GetApprovedMusicLibrary.Output.Album) {
    self.init(
      id: .init(rawValue: album.id),
      title: album.title,
      artistName: album.artistName,
      artworkURL: album.artworkURL,
      showsArtwork: album.showsArtwork,
      tracks: album.tracks.map(ApprovedTrack.init),
    )
  }
}

private extension ApprovedTrack {
  init(remote track: GetApprovedMusicLibrary.Output.Track) {
    self.init(
      id: .init(rawValue: track.id),
      title: track.title,
      artistName: track.artistName,
      artworkURL: track.artworkURL,
    )
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

enum ApprovedMusicClientError: Error {
  case missingConnection
  case subscriptionRequired
}
