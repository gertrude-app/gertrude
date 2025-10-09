import SwiftUI

#if !canImport(UIKit)
  import LibCore
#endif

public struct ShowView: View {
  @Environment(\.colorScheme) var cs

  public enum Event: Equatable, Sendable {
    case sortOldestToNewest
    case sortNewestToOldest
    case toggleShowArchivedTapped
    case unarchiveAllTapped
  }

  let show: ShowData
  let episodes: [EpisodeData]
  let showArchivedEpisodes: Bool
  let sortNewestToOldest: Bool
  let onEpisodeEvent: @MainActor @Sendable (Int, EpisodeView.Event) -> Void
  let onEvent: @MainActor @Sendable (Event) -> Void

  public init(
    show: ShowData,
    episodes: [EpisodeData] = [],
    showArchivedEpisodes: Bool = false,
    sortNewestToOldest: Bool = true,
    onEpisodeEvent: @MainActor @Sendable @escaping (Int, EpisodeView.Event) -> Void = { _, _ in },
    onEvent: @MainActor @Sendable @escaping (Event) -> Void = { _ in }
  ) {
    self.show = show
    self.episodes = episodes
    self.showArchivedEpisodes = showArchivedEpisodes
    self.sortNewestToOldest = sortNewestToOldest
    self.onEpisodeEvent = onEpisodeEvent
    self.onEvent = onEvent
  }

  var newestFirstLabel: String {
    self.sortNewestToOldest ? "✓  Sort newest first" : "     Sort newest first"
  }

  var oldestFirstLabel: String {
    self.sortNewestToOldest ? "     Sort oldest first" : "✓  Sort oldest first"
  }

  public var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        self.showHeader

        if !self.episodes.isEmpty {
          self.episodesList
        }
      }
    }
    .background(
      Color(self.cs, light: .violet100, dark: .violet900)
        .ignoresSafeArea(.all)
    )
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Menu {
          Button {
            self.onEvent(.sortNewestToOldest)
          } label: {
            Label(self.newestFirstLabel, systemImage: "arrow.up")
          }
          Button {
            self.onEvent(.sortOldestToNewest)
          } label: {
            Label(self.oldestFirstLabel, systemImage: "arrow.down")
          }
          if self.episodes.contains(where: \.isArchived) {
            Divider()
            Button {
              self.onEvent(.toggleShowArchivedTapped)
            } label: {
              Label(self.archivedButtonTitle, systemImage: "archivebox")
            }
            Button {
              self.onEvent(.unarchiveAllTapped)
            } label: {
              Label("     Unarchive all", systemImage: "arrow.2.circlepath")
            }
          }
        } label: {
          Text("•••")
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(Color(self.cs, light: .violet700, dark: .violet400))
            .padding(.trailing, 4)
            .opacity(0.9)
        }
      }
    }
  }

  private var archivedCount: Int {
    self.episodes.filter(\.isArchived).count
  }

  private var archivedButtonTitle: String {
    "\(self.showArchivedEpisodes ? "✓" : " ")    Show archived (\(self.archivedCount))"
  }

  private var showHeader: some View {
    VStack(spacing: 16) {
      self.showArtwork

      VStack(spacing: 8) {
        Text(self.show.name)
          .font(.system(size: 24, weight: .bold))
          .foregroundStyle(Color(self.cs, light: .violet950, dark: .violet100))
          .multilineTextAlignment(.center)
          .lineLimit(2)

        if let author = show.author {
          Text(author)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(Color(self.cs, light: .violet700, dark: .violet300))
            .multilineTextAlignment(.center)
        }

        if let description = show.description {
          Text(description)
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet400))
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .padding(.top, 8)
        }
      }
      .padding(.horizontal, 32)
    }
    .padding(.top, 30)
    .padding(.bottom, 24)
    .frame(maxWidth: .infinity)
  }

  private var showArtwork: some View {
    ArtworkView(
      artworkImage: self.show.artworkImage,
      artworkUrl: self.show.artworkUrl,
      size: 200
    )
  }

  private var episodesList: some View {
    LazyVStack(spacing: 1) {
      ForEach(self.episodes.filter { !$0.isArchived || self.showArchivedEpisodes }) { episode in
        EpisodeView(episode: episode) { event in
          self.onEpisodeEvent(episode.id, event)
        }
        .background(Color(self.cs, light: .white, dark: .black))
      }
    }
    .padding(.top, 12)
  }
}

#Preview("Show View - Light") {
  NavigationView {
    ShowView(
      show: ShowData(
        id: 1,
        name: "The Ancient Path",
        author: "Jason Henderson",
        description: "A podcast about walking in the ancient paths of biblical wisdom and truth. Join us as we explore the timeless principles that guide us in righteousness.",
        showArtwork: true,
        artworkUrl: .ancientPath
      ),
      episodes: sampleEpisodes,
      showArchivedEpisodes: true,
    )
  }
}

#Preview("Show View - Dark") {
  NavigationView {
    ShowView(
      show: ShowData(
        id: 1,
        name: "The Ancient Path",
        author: "Jason Henderson",
        description: "A podcast about walking in the ancient paths of biblical wisdom and truth. Join us as we explore the timeless principles that guide us in righteousness.",
        showArtwork: true,
        artworkUrl: .ancientPath
      ),
      episodes: sampleEpisodes,
      showArchivedEpisodes: true,
    )
    .preferredColorScheme(.dark)
  }
}

#Preview("Show View - No Episodes") {
  ShowView(show: ShowData(
    id: 2,
    name: "Tech Talk Weekly",
    author: "Tech Media Network",
    description: "Weekly discussions about the latest in technology, programming, and digital innovation.",
    showArtwork: true,
  ))
}

#Preview("Show View - No Artwork") {
  ShowView(
    show: ShowData(
      id: 3,
      name: "Swift Weekly Brief",
      author: "Jesse Squires",
      description: "A weekly podcast about Swift development, news, and community updates.",
      showArtwork: true,
    ),
    episodes: sampleEpisodes
  )
}

private let sampleEpisodes = [
  episode(id: 1) {
    $0.title = "Walking in Truth"
    $0
      .description =
      "How to discern truth from error in today's confusing world and walk confidently in biblical wisdom."
    $0.downloadState = .downloading
    $0.isPlaying = true
  },
  episode(id: 2) {
    $0.title = "The Narrow Path"
    $0
      .description =
      "Jesus spoke of the narrow path that leads to life. What does this mean for believers today?"
    $0.durationSeconds = 3120
    $0.downloadState = .downloaded
  },
  episode(id: 3) {
    $0.title = "Guarding Your Heart"
    $0
      .description =
      "It is wisdom, and not legalism, to guard your heart, and to pay attention to what is filling your thoughts, your affections and your time."
    $0.durationSeconds = 2280
    $0.isArchived = true
  },
  episode(id: 4) {
    $0.title = "Swift 6.0 Release Notes"
    $0
      .description =
      "A comprehensive overview of all the new features and improvements in Swift 6.0."
    $0.durationSeconds = 4500
    $0.downloadState = .downloaded
  },
  episode(id: 5) {
    $0.title = "Concurrency Best Practices"
    $0
      .description =
      "Essential patterns and practices for writing safe, efficient concurrent code in Swift using async/await and actors."
    $0.durationSeconds = 2520
  },
  episode(id: 6) {
    $0.title = "Performance Optimization Tips"
    $0
      .description =
      "Learn how to optimize your Swift code for better performance and memory usage."
    $0.durationSeconds = 2820
  },
]
