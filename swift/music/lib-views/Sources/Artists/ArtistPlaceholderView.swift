import SwiftUI

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
  #Preview("Artist placeholder") {
    NavigationStack {
      ArtistPlaceholderView(artist: [ArtistData].previewArtists[0])
    }
  }
#endif
