@testable import Api

func resolvedArtist(
  id: Music.ArtistId,
  albums: [Music.ResolvedAlbum],
  topSongs: [Music.ResolvedTrack] = [],
) -> Music.ResolvedArtist {
  .init(id: id, name: "Artist", topSongs: topSongs, albums: albums)
}

func resolvedAlbum(
  id: Music.AlbumId,
  title: String = "Album",
  artworkUrl: String? = nil,
  trackCount: Int? = nil,
  tracks: [Music.ResolvedTrack]? = nil,
) -> Music.ResolvedAlbum {
  .init(
    id: id,
    title: title,
    artistName: "Artist",
    artistIds: ["artist-1"],
    artworkUrl: artworkUrl,
    trackCount: trackCount ?? tracks?.count ?? 1,
    releaseDate: "2026-01-02",
    releaseType: "Album",
    tracks: tracks ?? [resolvedTrack(id: "\(id.rawValue)-track", albumId: id)],
  )
}

func resolvedTrack(
  id: Music.TrackId,
  albumId: Music.AlbumId,
  title: String = "Track",
  artworkUrl: String? = nil,
  durationInMillis: Int? = 180_000,
  discNumber: Int? = nil,
  trackNumber: Int? = nil,
) -> Music.ResolvedTrack {
  .init(
    id: id,
    title: title,
    artistName: "Artist",
    artistIds: ["artist-1"],
    albumId: albumId,
    albumTitle: albumId == "album-1" ? "Direct" : "Album",
    artworkUrl: artworkUrl,
    durationInMillis: durationInMillis,
    discNumber: discNumber,
    trackNumber: trackNumber,
  )
}

func resolvedTrackGrant(
  id: Music.TrackId,
  preferredAlbumId: Music.AlbumId,
  albumTitle: String = "Album",
  albumTrackCount: Int = 1,
  albumArtworkUrl: String? = nil,
  trackTitle: String = "Track",
  trackArtworkUrl: String? = nil,
  durationInMillis: Int? = 180_000,
  discNumber: Int? = nil,
  trackNumber: Int? = nil,
  catalogPosition: Int = 0,
) -> Music.ResolvedTrackGrant {
  .init(
    track: .init(
      id: id,
      title: trackTitle,
      artistName: "Artist",
      artistIds: ["artist-1"],
      albumId: preferredAlbumId,
      albumTitle: albumTitle,
      artworkUrl: trackArtworkUrl,
      durationInMillis: durationInMillis,
      discNumber: discNumber,
      trackNumber: trackNumber,
    ),
    preferredAlbum: .init(
      id: preferredAlbumId,
      title: albumTitle,
      artistName: "Artist",
      artistIds: ["artist-1"],
      artworkUrl: albumArtworkUrl,
      trackCount: albumTrackCount,
      releaseDate: "2026-01-02",
      releaseType: "Album",
    ),
    catalogPosition: catalogPosition,
  )
}
