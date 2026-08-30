import Foundation
import LibViews

struct MusicLibrarySearch: Equatable, Sendable {
  private var documents: [Document]
  private var library: ApprovedMusicLibrary?

  init(library: ApprovedMusicLibrary? = nil) {
    self.documents = library.map(Self.documents) ?? []
    self.library = library
  }

  func artistDiscographyPlaybackItems(for artistID: ApprovedArtist.ID) -> [PlaybackItem] {
    self.library?.artistDiscographyPlaybackItems(for: artistID) ?? []
  }

  func artistTopSongsPlaybackItems(for artistID: ApprovedArtist.ID) -> [PlaybackItem] {
    self.library?.artistTopSongsPlaybackItems(for: artistID) ?? []
  }

  func result(id: MusicSearchResult.ID) -> MusicSearchResult? {
    self.documents.first(where: { $0.result.id == id })?.result
  }

  func results(query: String, limit: Int = 30) -> [MusicSearchResult] {
    let queryField = SearchField(query)
    guard !queryField.tokens.isEmpty, limit > 0 else { return [] }

    return self.documents
      .compactMap { document -> RankedResult? in
        guard document.matches(queryField.tokens) else { return nil }
        return RankedResult(
          result: document.result,
          tier: document.tier(for: queryField),
          exactTokenCount: document.exactTokenCount(for: queryField.tokens),
          normalizedTitle: document.primary.phrase,
        )
      }
      .sorted()
      .prefix(limit)
      .map(\.result)
  }

  private static func documents(_ library: ApprovedMusicLibrary) -> [Document] {
    var documents: [Document] = []
    var songIDs = Set<ApprovedTrack.ID>()

    for album in library.albums {
      documents.append(Document(
        result: .init(source: .album(album)),
        primary: album.title,
        secondary: album.artistName,
      ))

      for track in album.tracks where songIDs.insert(track.id).inserted {
        documents.append(Document(
          result: .init(source: .song(
            track: track,
            albumID: album.id,
            albumTitle: album.title,
            albumArtworkURL: AlbumData(album: album).artworkUrl,
          )),
          primary: track.title,
          secondary: [track.artistName, track.albumTitle, album.title]
            .compactMap(\.self)
            .joined(separator: " "),
        ))
      }
    }

    documents.append(contentsOf: library.artists.map { artist in
      Document(
        result: .init(source: .artist(artist)),
        primary: artist.name,
        secondary: "",
      )
    })

    documents.append(contentsOf: library.playlists.map { playlist in
      Document(
        result: .init(source: .playlist(playlist)),
        primary: playlist.name,
        secondary: "",
      )
    })

    return documents
  }
}

struct MusicSearchResult: Equatable, Identifiable, Sendable {
  enum ID: Equatable, Hashable, Sendable {
    case album(ApprovedAlbum.ID)
    case artist(ApprovedArtist.ID)
    case playlist(MusicPlaylist.ID)
    case song(ApprovedTrack.ID)

    init?(rawValue: String) {
      if rawValue.hasPrefix("album-") {
        self = .album(.init(rawValue: String(rawValue.dropFirst("album-".count))))
      } else if rawValue.hasPrefix("artist-") {
        self = .artist(.init(rawValue: String(rawValue.dropFirst("artist-".count))))
      } else if rawValue.hasPrefix("playlist-"),
                let uuid = UUID(uuidString: String(rawValue.dropFirst("playlist-".count))) {
        self = .playlist(.init(rawValue: uuid))
      } else if rawValue.hasPrefix("song-") {
        self = .song(.init(rawValue: String(rawValue.dropFirst("song-".count))))
      } else {
        return nil
      }
    }

    var rawValue: String {
      switch self {
      case .album(let id):
        "album-\(id.rawValue)"
      case .artist(let id):
        "artist-\(id.rawValue)"
      case .playlist(let id):
        "playlist-\(id.rawValue.uuidString)"
      case .song(let id):
        "song-\(id.rawValue)"
      }
    }

    var kindOrder: Int {
      switch self {
      case .song:
        0
      case .album:
        1
      case .artist:
        2
      case .playlist:
        3
      }
    }
  }

  enum Source: Equatable, Sendable {
    case album(ApprovedAlbum)
    case artist(ApprovedArtist)
    case playlist(MusicPlaylist)
    case song(
      track: ApprovedTrack,
      albumID: ApprovedAlbum.ID,
      albumTitle: String,
      albumArtworkURL: URL?,
    )
  }

  let source: Source

  var id: ID {
    switch self.source {
    case .album(let album):
      .album(album.id)
    case .artist(let artist):
      .artist(artist.id)
    case .playlist(let playlist):
      .playlist(playlist.id)
    case .song(let track, _, _, _):
      .song(track.id)
    }
  }

  var playbackItems: [PlaybackItem] {
    switch self.source {
    case .album(let album):
      album.tracks.map {
        PlaybackItem(
          track: $0,
          artworkURL: album.artworkURL,
          albumID: album.id,
        )
      }
    case .artist(let artist):
      (artist.topSongs ?? []).map {
        PlaybackItem(track: $0, artworkURL: $0.artworkURL)
      }
    case .playlist(let playlist):
      PlaylistDetailFeature.State(playlist: playlist).playbackItems
    case .song(let track, let albumID, _, let albumArtworkURL):
      [PlaybackItem(
        track: track,
        artworkURL: track.artworkURL ?? albumArtworkURL,
        albumID: albumID,
      )]
    }
  }

  var viewData: MusicSearchResultData {
    switch self.source {
    case .album(let album):
      let albumData = AlbumData(album: album)
      return MusicSearchResultData(
        id: self.id.rawValue,
        kind: .album,
        collectionID: album.id.rawValue,
        title: album.title,
        detail: album.artistName,
        artworkURL: albumData.artworkUrl,
      )

    case .artist(let artist):
      let artistData = ArtistData(artist: artist)
      return MusicSearchResultData(
        id: self.id.rawValue,
        kind: .artist,
        collectionID: artist.id.rawValue,
        title: artist.name,
        artworkURL: artistData.artworkUrl,
      )

    case .playlist(let playlist):
      let playlistData = PlaylistData(playlist: playlist)
      let songLabel = playlist.entries.count == 1 ? "1 song" : "\(playlist.entries.count) songs"
      return MusicSearchResultData(
        id: self.id.rawValue,
        kind: .playlist,
        collectionID: playlist.id.rawValue.uuidString,
        title: playlist.name,
        detail: songLabel,
        playlistArtworkURLs: playlistData.artworkUrls,
      )

    case .song(let track, _, let albumTitle, let albumArtworkURL):
      return MusicSearchResultData(
        id: self.id.rawValue,
        kind: .song,
        collectionID: track.id.rawValue,
        title: track.title,
        detail: [track.artistName, track.albumTitle ?? albumTitle]
          .filter { !$0.isEmpty }
          .joined(separator: " · "),
        artworkURL: track.artworkURL ?? albumArtworkURL,
      )
    }
  }
}

private struct Document: Equatable, Sendable {
  let result: MusicSearchResult
  let primary: SearchField
  let secondary: SearchField

  init(
    result: MusicSearchResult,
    primary: String,
    secondary: String,
  ) {
    self.result = result
    self.primary = SearchField(primary)
    self.secondary = SearchField(secondary)
  }

  func matches(_ queryTokens: [String]) -> Bool {
    let candidateTokens = self.primary.matchingTokens + self.secondary.matchingTokens
    return queryTokens.allSatisfy { queryToken in
      candidateTokens.contains(where: { $0.hasPrefix(queryToken) })
    }
  }

  func tier(for query: SearchField) -> Int {
    if self.primary.phrase == query.phrase {
      return 0
    }
    if Self.matches(query.tokens, in: self.primary.matchingTokens) {
      return 1
    }
    if query.tokens.contains(where: { queryToken in
      self.primary.matchingTokens.contains(where: { $0.hasPrefix(queryToken) })
    }) {
      return 2
    }
    return 3
  }

  func exactTokenCount(for queryTokens: [String]) -> Int {
    let candidateTokens = self.primary.matchingTokens + self.secondary.matchingTokens
    return queryTokens.count(where: candidateTokens.contains)
  }

  private static func matches(
    _ queryTokens: [String],
    in candidateTokens: [String],
  ) -> Bool {
    queryTokens.allSatisfy { queryToken in
      candidateTokens.contains(where: { $0.hasPrefix(queryToken) })
    }
  }
}

private struct SearchField: Equatable, Sendable {
  let matchingTokens: [String]
  let phrase: String
  let tokens: [String]

  init(_ value: String) {
    let folded = value.folding(
      options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
      locale: Locale(identifier: "en_US_POSIX"),
    )
    let normalized = folded.unicodeScalars.map { scalar in
      CharacterSet.alphanumerics.contains(scalar) ? String(scalar) : " "
    }
    .joined()
    self.tokens = normalized.split(whereSeparator: \.isWhitespace).map(String.init)
    self.phrase = self.tokens.joined(separator: " ")
    let compact = self.tokens.joined()
    self.matchingTokens = compact.isEmpty || self.tokens.contains(compact)
      ? self.tokens
      : self.tokens + [compact]
  }
}

private struct RankedResult: Comparable {
  let result: MusicSearchResult
  let tier: Int
  let exactTokenCount: Int
  let normalizedTitle: String

  static func < (lhs: Self, rhs: Self) -> Bool {
    if lhs.tier != rhs.tier {
      return lhs.tier < rhs.tier
    }
    if lhs.exactTokenCount != rhs.exactTokenCount {
      return lhs.exactTokenCount > rhs.exactTokenCount
    }
    if lhs.normalizedTitle != rhs.normalizedTitle {
      return lhs.normalizedTitle < rhs.normalizedTitle
    }
    if lhs.result.id.kindOrder != rhs.result.id.kindOrder {
      return lhs.result.id.kindOrder < rhs.result.id.kindOrder
    }
    return lhs.result.id.rawValue < rhs.result.id.rawValue
  }
}
