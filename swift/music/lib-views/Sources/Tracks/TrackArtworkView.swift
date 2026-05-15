import SwiftUI

public struct TrackArtworkView: View {
  private let artworkUrl: URL?
  private let showsArtwork: Bool
  private let size: CGFloat

  public init(
    artworkUrl: URL?,
    showsArtwork: Bool = true,
    size: CGFloat = 44,
  ) {
    self.artworkUrl = artworkUrl
    self.showsArtwork = showsArtwork
    self.size = size
  }

  public init(
    track: TrackData,
    size: CGFloat = 44,
  ) {
    self.init(
      artworkUrl: track.artworkUrl,
      showsArtwork: track.showsArtwork,
      size: size,
    )
  }

  public var body: some View {
    ArtworkImageView(
      artworkUrl: self.artworkUrl,
      showsArtwork: self.showsArtwork,
      size: self.size,
      cornerRadius: 10,
    )
  }
}

#Preview("Track artwork") {
  VStack(spacing: 24) {
    TrackArtworkView(track: [TrackData].previewTracks[0])
    TrackArtworkView(track: [TrackData].previewTracks[3])
    TrackArtworkView(
      track: TrackData(
        id: "missing-track-artwork",
        title: "Missing Artwork",
        artist: "Preview",
      ),
    )
  }
  .padding(24)
}
