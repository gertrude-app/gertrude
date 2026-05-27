import SwiftUI

public struct TrackShelfView: View {
  private let title: String
  private let tracks: [TrackData]
  private let isLoading: Bool
  private let transitionNamespace: Namespace.ID?
  private let onTitleTap: @MainActor @Sendable () -> Void
  private let onTrackTap: @MainActor @Sendable (String) -> Void

  public init(
    title: String = "My tracks",
    tracks: [TrackData],
    isLoading: Bool = false,
    transitionNamespace: Namespace.ID? = nil,
    onTitleTap: @MainActor @escaping @Sendable () -> Void = {},
    onTrackTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
  ) {
    self.title = title
    self.isLoading = isLoading
    self.transitionNamespace = transitionNamespace
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

      if self.isLoading {
        TrackShelfSkeletonView(rows: self.rows)
      } else if self.tracks.isEmpty {
        EmptyTrackShelfCard()
          .padding(.horizontal, 20)
      } else {
        ScrollView(.horizontal) {
          LazyHGrid(rows: self.rows, alignment: .top, spacing: 14) {
            ForEach(self.tracks) { track in
              TrackRowView(track: track, transitionNamespace: self.transitionNamespace) {
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

private struct TrackShelfSkeletonView: View {
  let rows: [GridItem]

  var body: some View {
    ScrollView(.horizontal) {
      LazyHGrid(rows: self.rows, alignment: .top, spacing: 14) {
        ForEach(0..<10, id: \.self) { index in
          TrackRowSkeletonView(titleWidth: index.isMultiple(of: 2) ? 178 : 132)
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 4)
    }
    .scrollIndicators(.hidden)
    .scrollClipDisabled()
    .accessibilityLabel("Loading tracks")
  }
}

private struct TrackRowSkeletonView: View {
  let titleWidth: CGFloat

  var body: some View {
    HStack(spacing: 10) {
      SkeletonBlock(width: 44, height: 44, cornerRadius: 10)

      VStack(alignment: .leading, spacing: 7) {
        SkeletonBlock(width: self.titleWidth, height: 13, cornerRadius: 6)
        SkeletonBlock(width: 96, height: 11, cornerRadius: 5)
      }

      Spacer(minLength: 0)
    }
    .frame(width: 270, alignment: .leading)
  }
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

#Preview("Track shelf loading") {
  ScrollView {
    TrackShelfView(tracks: [], isLoading: true)
      .padding(.vertical, 24)
  }
  .background(.background)
}
