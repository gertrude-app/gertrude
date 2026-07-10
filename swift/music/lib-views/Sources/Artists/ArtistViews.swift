import Foundation
import SwiftUI

public struct ArtistData: Identifiable, Equatable, Hashable, Sendable {
  public let id: String
  public let name: String
  public let artworkUrl: URL?
  public let artworkPalette: ArtworkPalette?
  public let subtitle: String?
  public let editorialNotes: String?
  public let releaseAlbumIds: [String]
  public let topSongs: [ArtistTopSongData]

  public init(
    id: String,
    name: String,
    artworkUrl: URL? = nil,
    artworkPalette: ArtworkPalette? = nil,
    subtitle: String? = nil,
    editorialNotes: String? = nil,
    releaseAlbumIds: [String] = [],
    topSongs: [ArtistTopSongData] = [],
  ) {
    self.id = id
    self.name = name
    self.artworkUrl = artworkUrl
    self.artworkPalette = artworkPalette
    self.subtitle = subtitle
    self.editorialNotes = editorialNotes
    self.releaseAlbumIds = releaseAlbumIds
    self.topSongs = topSongs
  }
}

public struct ArtistCardView: View {
  @Environment(\.colorScheme) private var colorScheme

  private let artist: ArtistData
  private let artworkSize: CGFloat

  public init(
    artist: ArtistData,
    artworkSize: CGFloat = 148,
  ) {
    self.artist = artist
    self.artworkSize = artworkSize
  }

  public var body: some View {
    VStack(alignment: .center, spacing: 10) {
      ZoomableArtistArtworkView(
        artworkUrl: self.artist.artworkUrl,
        size: self.artworkSize,
        transitionID: self.artworkTransitionID,
        role: .source,
      )

      Text(self.artist.name)
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(Color(self.colorScheme, light: .black, dark: .white))
        .lineLimit(2)
        .multilineTextAlignment(.center)
    }
    .frame(width: self.artworkSize, alignment: .center)
    .contentShape(Rectangle())
    .accessibilityLabel("\(self.artist.name), artist")
  }

  private var artworkTransitionID: String {
    artistArtworkZoomTransitionID(for: self.artist.id)
  }
}

public struct ArtistArtworkView: View {
  @Environment(\.colorScheme) private var colorScheme

  private let artworkUrl: URL?
  private let size: CGFloat

  public init(
    artworkUrl: URL?,
    size: CGFloat = 148,
  ) {
    self.artworkUrl = artworkUrl
    self.size = size
  }

  public init(
    artist: ArtistData,
    size: CGFloat = 148,
  ) {
    self.init(
      artworkUrl: artist.artworkUrl,
      size: size,
    )
  }

  public var body: some View {
    CachedArtworkImageView(url: self.artworkUrl) { image in
      self.artwork(image)
    } placeholder: {
      self.placeholderArtwork
    }
  }

  private func artwork(_ image: Image) -> some View {
    ZStack {
      image
        .resizable()
        .scaledToFill()
        .frame(width: self.size, height: self.size)
        .clipShape(Circle())
        .blur(radius: self.glowBlurRadius)
        .opacity(0.32)
        .scaleEffect(1.04)
        .offset(y: self.glowOffset)

      image
        .resizable()
        .scaledToFill()
        .frame(width: self.size, height: self.size)
        .clipShape(Circle())
        .overlay {
          Circle()
            .stroke(
              Gradient(colors: [
                Color(self.colorScheme, light: .white.opacity(0.5), dark: .white.opacity(0.2)),
                .clear,
                .black.opacity(0.1),
              ]),
              lineWidth: 1.5,
            )
            .frame(width: self.size - 0.75, height: self.size - 0.75)
        }
    }
    .frame(width: self.size, height: self.size)
  }

  private var placeholderArtwork: some View {
    Circle()
      .fill(self.placeholderColor)
      .frame(width: self.size, height: self.size)
      .overlay {
        Image(systemName: "person.fill")
          .font(.system(size: self.placeholderIconSize, weight: .semibold))
          .foregroundStyle(Color(
            self.colorScheme,
            light: .black.opacity(0.32),
            dark: .white.opacity(0.42),
          ))
      }
  }

  private var placeholderColor: Color {
    Color(
      self.colorScheme,
      light: Color(red: 0.90, green: 0.90, blue: 0.92),
      dark: Color(red: 0.14, green: 0.14, blue: 0.16),
    )
  }

  private var placeholderIconSize: CGFloat {
    max(24, self.size * 0.24)
  }

  private var glowBlurRadius: CGFloat {
    min(12, max(6, self.size * 0.08))
  }

  private var glowOffset: CGFloat {
    min(2, self.size * 0.015)
  }
}

public struct ArtistPlaceholderView: View {
  private let artist: ArtistData

  public init(artist: ArtistData) {
    self.artist = artist
  }

  public var body: some View {
    #if os(iOS)
      self.content
        .navigationTitle(self.artist.name)
        .navigationBarTitleDisplayMode(.inline)
    #else
      self.content
        .navigationTitle(self.artist.name)
    #endif
  }

  private var content: some View {
    ScrollView {
      VStack(spacing: 18) {
        ArtistArtworkView(artist: self.artist, size: 168)

        VStack(spacing: 6) {
          Text(self.artist.name)
            .font(.system(size: 30, weight: .bold, design: .rounded))
            .multilineTextAlignment(.center)

          if let subtitle = self.artist.subtitle {
            Text(subtitle)
              .font(.system(size: 15, weight: .medium))
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)
          }

          Text("Artist page coming soon")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.top, 6)
        }
      }
      .frame(maxWidth: .infinity)
      .padding(.horizontal, 28)
      .padding(.top, 48)
      .padding(.bottom, 96)
    }
    .background(.background)
  }
}

#if DEBUG
  #Preview("Artist card") {
    HStack(alignment: .top, spacing: 16) {
      ArtistCardView(artist: [ArtistData].previewArtists[0])
      ArtistCardView(artist: [ArtistData].previewArtists[1])
    }
    .padding(24)
  }

  #Preview("Artist placeholder") {
    NavigationStack {
      ArtistPlaceholderView(artist: [ArtistData].previewArtists[0])
    }
  }
#endif
