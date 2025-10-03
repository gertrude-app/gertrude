import SwiftUI

#if canImport(UIKit)
  import UIKit
#else
  import LibCore
#endif

public struct PodcastsHomeView: View {
  @Environment(\.colorScheme) var cs

  @dynamicMemberLookup
  public struct ShowDataWithStats {
    public var data: ShowData
    public var totalEpisodes: Int
    public var unplayedEpisodes: Int
    public var mostRecentPubDate: Date?
  }

  let shows: [ShowDataWithStats]
  let onAddShowTap: @MainActor @Sendable () -> Void
  let onShowTap: @MainActor @Sendable (Int) -> Void
  let onDeleteShow: @MainActor @Sendable (Int) -> Void

  public init(
    shows: [ShowDataWithStats],
    onAddShowTap: @MainActor @escaping @Sendable () -> Void,
    onShowTap: @MainActor @escaping @Sendable (Int) -> Void = { _ in },
    onDeleteShow: @MainActor @escaping @Sendable (Int) -> Void = { _ in }
  ) {
    self.shows = shows
    self.onAddShowTap = onAddShowTap
    self.onShowTap = onShowTap
    self.onDeleteShow = onDeleteShow
  }

  public var body: some View {
    ZStack {
      if self.shows.isEmpty {
        PodcastsEmptyState(onAddShowTap: self.onAddShowTap)
      } else {
        self.showsList
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(self.cs, light: .white, dark: .black))
  }

  private var showsList: some View {
    List {
      ForEach(self.shows, id: \.id) { show in
        Button {
          self.onShowTap(show.id)
        } label: {
          self.showRow(show)
        }
        .buttonStyle(PlainButtonStyle())
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
          Button(role: .destructive) {
            self.onDeleteShow(show.id)
          } label: {
            Label("Delete", systemImage: "trash")
          }
          .tint(.red)
        }
      }

      HStack {
        Spacer()
        Button {
          self.onAddShowTap()
        } label: {
          HStack(spacing: 6) {
            Image(systemName: "plus")
              .font(.system(size: 13, weight: .semibold))
            Text("Add Show")
              .font(.system(size: 15, weight: .medium))
          }
          .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet400))
        }
      }
      .listRowInsets(EdgeInsets(top: 12, leading: 30, bottom: 30, trailing: 30))
      .listRowSeparator(.hidden)
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
  }

  private func showInfoText(_ show: ShowDataWithStats) -> String {
    var parts: [String] = []

    if let pubDate = show.mostRecentPubDate {
      parts.append(formatRelativeDate(pubDate))
    }

    if show.unplayedEpisodes > 0 {
      if show.unplayedEpisodes < 12 {
        parts.append("\(show.unplayedEpisodes) new")
      } else {
        parts.append("\(show.totalEpisodes) episodes")
      }
    }

    return parts.joined(separator: " • ")
  }

  private func showRow(_ show: ShowDataWithStats) -> some View {
    HStack(spacing: 16) {
      self.showArtwork(show.data)

      VStack(alignment: .leading, spacing: 4) {
        Text(show.name)
          .font(.system(size: 18, weight: .semibold))
          .foregroundStyle(Color(self.cs, light: .violet950, dark: .violet100))
          .multilineTextAlignment(.leading)
          .lineLimit(2)

        Text(self.showInfoText(show))
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
          .lineLimit(1)
      }

      Spacer()

      Image(systemName: "chevron.right")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(Color(self.cs, light: .violet400, dark: .violet600))
    }
    .padding(.horizontal, 30)
    .padding(.vertical, 16)
    .background(
      Color(self.cs, light: .clear, dark: .clear)
        .contentShape(Rectangle())
    )
  }

  private func showArtwork(_ show: ShowData) -> some View {
    ArtworkView(
      artworkImage: show.artworkImage,
      artworkUrl: show.artworkUrl,
      size: 56
    )
  }
}

public extension PodcastsHomeView.ShowDataWithStats {
  init(
    show: ShowData,
    totalEpisodes: Int,
    unplayedEpisodes: Int,
    mostRecentPubDate: Date? = nil
  ) {
    self.data = show
    self.totalEpisodes = totalEpisodes
    self.unplayedEpisodes = unplayedEpisodes
    self.mostRecentPubDate = mostRecentPubDate
  }

  subscript<T>(dynamicMember keyPath: KeyPath<ShowData, T>) -> T {
    self.data[keyPath: keyPath]
  }
}

// previews

func showWithStats(
  id: Int = 1,
  _ modify: (inout PodcastsHomeView.ShowDataWithStats) -> Void = { _ in }
) -> PodcastsHomeView.ShowDataWithStats {
  var show = PodcastsHomeView.ShowDataWithStats(
    data: ShowData(id: id, name: "Test Show", showArtwork: true),
    totalEpisodes: 0,
    unplayedEpisodes: 0
  )
  modify(&show)
  return show
}

#Preview("With Shows") {
  PodcastsHomeView(
    shows: [
      showWithStats(id: 1) {
        $0.data.name = "The Ancient Path"
        $0.data.artworkUrl = .ancientPath
        $0.mostRecentPubDate = Date().addingTimeInterval(-TimeInterval.hours(8))
        $0.unplayedEpisodes = 3
        $0.totalEpisodes = 125
      },
      showWithStats(id: 2) {
        $0.data.name = "The Secret Sombrero"
        $0.data.artworkUrl = .sombrero
        $0.mostRecentPubDate = Date().addingTimeInterval(-TimeInterval.days(2))
        $0.unplayedEpisodes = 15
        $0.totalEpisodes = 87
      },
      showWithStats(id: 3) {
        $0.data.name = "This American Life"
        $0.mostRecentPubDate = Date().addingTimeInterval(-TimeInterval.days(5))
        $0.unplayedEpisodes = 0
        $0.totalEpisodes = 542
      },
    ],
    onAddShowTap: {}
  )
}

#Preview("With Shows (Dark)") {
  PodcastsHomeView(
    shows: [
      showWithStats(id: 1) {
        $0.data.name = "The Ancient Path"
        $0.data.artworkUrl = .ancientPath
        $0.mostRecentPubDate = Date().addingTimeInterval(-TimeInterval.hours(8))
        $0.unplayedEpisodes = 3
        $0.totalEpisodes = 125
      },
      showWithStats(id: 2) {
        $0.data.name = "The Secret Sombrero"
        $0.data.artworkUrl = .sombrero
        $0.mostRecentPubDate = Date().addingTimeInterval(-TimeInterval.days(2))
        $0.unplayedEpisodes = 15
        $0.totalEpisodes = 87
      },
      showWithStats(id: 3) {
        $0.data.name = "This American Life"
        $0.mostRecentPubDate = Date().addingTimeInterval(-TimeInterval.days(5))
        $0.unplayedEpisodes = 0
        $0.totalEpisodes = 542
      },
    ],
    onAddShowTap: {}
  )
  .preferredColorScheme(.dark)
}

extension String {
  static let ancientPath =
    "https://is1-ssl.mzstatic.com/image/thumb/Podcasts116/v4/a2/94/d3/a294d3e7-bf02-377f-a531-7b0491a4cb81/mza_4607163774963783796.png/600x600bb.jpg"
  static let sombrero = "https://spanish-7cbc3de5.nyc3.digitaloceanspaces.com/sombrero.jpg"
}
