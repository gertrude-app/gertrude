import SwiftUI

public struct TrackShelfView: View {
  private let title: String
  private let tracks: [TrackData]
  private let onTitleTap: @MainActor @Sendable () -> Void
  private let onTrackTap: @MainActor @Sendable (String) -> Void

  public init(
    title: String = "My tracks",
    tracks: [TrackData],
    onTitleTap: @MainActor @escaping @Sendable () -> Void = {},
    onTrackTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
  ) {
    self.title = title
    self.tracks = tracks.sorted { lhs, rhs in
      lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
    }
    self.onTitleTap = onTitleTap
    self.onTrackTap = onTrackTap
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      ShelfHeaderView(
        title: self.title,
        accessibilityLabel: "Show all tracks",
        onTap: self.onTitleTap,
      )

      if self.tracks.isEmpty {
        EmptyTrackShelfCard()
          .padding(.horizontal, 20)
      } else {
        ScrollView(.horizontal) {
          LazyHGrid(rows: self.rows, alignment: .top, spacing: 14) {
            ForEach(self.tracks) { track in
              TrackRowView(track: track) {
                self.onTrackTap(track.id)
              }
            }
          }
          .padding(.horizontal, 20)
          .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
      }
    }
  }

  private let rows: [GridItem] = Array(repeating: GridItem(.fixed(44), spacing: 8), count: 5)
}

#Preview("Track shelf") {
  ScrollView {
    TrackShelfView(tracks: .previewTracks)
      .padding(.vertical, 24)
  }
  .background(.background)
}

#Preview("Track shelf empty") {
  ScrollView {
    TrackShelfView(tracks: [])
      .padding(.vertical, 24)
  }
  .background(.background)
}
