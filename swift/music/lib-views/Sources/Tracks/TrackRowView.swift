import SwiftUI

public struct TrackRowView: View {
  @Environment(\.colorScheme) var cs

  private let track: TrackData
  private let artworkSize: CGFloat
  private let width: CGFloat
  private let onTap: @MainActor @Sendable () -> Void

  public init(
    track: TrackData,
    artworkSize: CGFloat = 44,
    width: CGFloat = 270,
    onTap: @MainActor @escaping @Sendable () -> Void = {},
  ) {
    self.track = track
    self.artworkSize = artworkSize
    self.width = width
    self.onTap = onTap
  }

  public var body: some View {
    Button(action: self.onTap) {
      HStack(spacing: 10) {
        TrackArtworkView(track: self.track, size: self.artworkSize)

        VStack(alignment: .leading, spacing: 2) {
          Text(self.track.title)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Color(self.cs, light: .black, dark: .white))
            .lineLimit(1)

          Text(self.track.artist)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color(
              self.cs,
              light: .black.opacity(0.72),
              dark: .white.opacity(0.64),
            ))
            .lineLimit(1)
        }

        Spacer(minLength: 0)
      }
      .frame(width: self.width, alignment: .leading)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("\(self.track.title), \(self.track.artist)")
  }
}

#Preview("Track rows") {
  VStack(alignment: .leading, spacing: 12) {
    TrackRowView(track: [TrackData].previewTracks[0])
    TrackRowView(track: [TrackData].previewTracks[1])
    TrackRowView(track: [TrackData].previewTracks[2])
  }
  .padding(24)
}
