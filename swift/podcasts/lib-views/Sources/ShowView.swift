import SwiftUI

#if !canImport(UIKit)
  import LibCore
#endif

public struct ShowView: View {
  @Environment(\.colorScheme) var cs
  @Environment(\.lang) var lang
  @Environment(\.miniNowPlayingVisible) var miniNowPlayingVisible

  public enum Event: Equatable, Sendable {
    case sortOldestToNewest
    case sortNewestToOldest
    case toggleShowArchivedTapped
    case unarchiveAllTapped
    case headerPlayButtonTapped
  }

  public enum HeaderPlayButtonState: Equatable {
    case resume(episodeTitle: String, isPlaying: Bool)
    case playLatest(isPlaying: Bool)
    case none
  }

  let show: ShowData
  let episodes: [EpisodeData]
  let showArchivedEpisodes: Bool
  let sortNewestToOldest: Bool
  let headerPlayButtonState: HeaderPlayButtonState
  let onEpisodeEvent: @MainActor @Sendable (Int, EpisodeView.Event) -> Void
  let onEvent: @MainActor @Sendable (Event) -> Void

  public init(
    show: ShowData,
    episodes: [EpisodeData] = [],
    showArchivedEpisodes: Bool = false,
    sortNewestToOldest: Bool = true,
    headerPlayButtonState: HeaderPlayButtonState = .none,
    onEpisodeEvent: @MainActor @Sendable @escaping (Int, EpisodeView.Event) -> Void = { _, _ in },
    onEvent: @MainActor @Sendable @escaping (Event) -> Void = { _ in },
  ) {
    self.show = show
    self.episodes = episodes
    self.showArchivedEpisodes = showArchivedEpisodes
    self.sortNewestToOldest = sortNewestToOldest
    self.headerPlayButtonState = headerPlayButtonState
    self.onEpisodeEvent = onEpisodeEvent
    self.onEvent = onEvent
  }

  public var body: some View {
    List {
      self.showHeader
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)

      ForEach(self.episodes.filter { !$0.isArchived || self.showArchivedEpisodes }) { episode in
        EpisodeView(episode: episode) { event in
          self.onEpisodeEvent(episode.id, event)
        }
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.visible)
        .listRowSeparatorTint(Color(self.cs, light: .violet200, dark: .violet800))
        .listRowBackground(Color(self.cs, light: .white, dark: .black))
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
          Button {
            self.onEpisodeEvent(episode.id, .toggleArchivedTapped)
          } label: {
            VStack(spacing: 4) {
              Image(systemName: "archivebox")
                .font(.system(size: 14))
              Text(lstr(episode.isArchived ? .showUnarchive : .showArchive))
                .font(.system(size: 10))
            }
          }
          .tint(.blue)

          if !episode.isArchived {
            if episode.downloadState == .downloaded {
              Button {
                self.onEpisodeEvent(episode.id, .removeDownloadTapped)
              } label: {
                VStack(spacing: 4) {
                  Image(systemName: "trash")
                    .font(.system(size: 14))
                  Text(lstr(.showRemoveDownload))
                    .font(.system(size: 10, weight: .thin))
                    .multilineTextAlignment(.center)
                }
              }
              .tint(.red)
            } else if episode.downloadState == .notDownloaded {
              Button {
                self.onEpisodeEvent(episode.id, .downloadTapped)
              } label: {
                VStack(spacing: 4) {
                  Image(systemName: "arrow.down")
                    .font(.system(size: 14))
                  Text(lstr(.showDownload))
                    .font(.system(size: 10))
                }
              }
              .tint(Color(self.cs, light: .violet600, dark: .violet400))
            }
          }
        }
      }
    }
    .listStyle(.plain)
    .background(
      Color(self.cs, light: .violet100, dark: .violet900)
        .ignoresSafeArea(.all),
    )
    .scrollContentBackground(.hidden)
    .safeAreaInset(edge: .bottom) {
      if self.miniNowPlayingVisible {
        Color.clear.frame(height: 75)
      }
    }
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Menu {
          Picker("Sort Order", selection: Binding(
            get: { self.sortNewestToOldest },
            set: { newValue in self.onEvent(newValue ? .sortNewestToOldest : .sortOldestToNewest) },
          )) {
            Label(lstr(.showSortNewestFirst), systemImage: "arrow.up").tag(true)
            Label(lstr(.showSortOldestFirst), systemImage: "arrow.down").tag(false)
          }
          .pickerStyle(.inline)

          if self.episodes.contains(where: \.isArchived) {
            Divider()
            Toggle(isOn: Binding(
              get: { self.showArchivedEpisodes },
              set: { _ in self.onEvent(.toggleShowArchivedTapped) },
            )) {
              Label(
                String(format: lstr(.showShowArchived), self.archivedCount),
                systemImage: "archivebox",
              )
            }

            Button {
              self.onEvent(.unarchiveAllTapped)
            } label: {
              Label(
                lstr(.showUnarchiveAll),
                systemImage: "arrow.2.circlepath",
              )
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

        self.headerPlayButton
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
      size: 200,
    )
  }

  @ViewBuilder
  private var headerPlayButton: some View {
    switch self.headerPlayButtonState {
    case .resume(let episodeTitle, let isPlaying):
      VStack(spacing: 8) {
        PlayPauseButton(
          text: isPlaying ? lstr(.showPause) : lstr(.showResume),
          isPlaying: isPlaying,
          onTap: { self.onEvent(.headerPlayButtonTapped) },
        )

        Text(episodeTitle)
          .padding(.horizontal, 24)
          .font(.system(size: 12, weight: .regular))
          .foregroundStyle(Color(self.cs, light: .violet700, dark: .violet300))
          .lineLimit(1)
      }
      .padding(.top, 16)

    case .playLatest(let isPlaying):
      VStack(spacing: 8) {
        PlayPauseButton(
          text: isPlaying ? lstr(.showPause) : lstr(.showPlayLatest),
          isPlaying: isPlaying,
          onTap: { self.onEvent(.headerPlayButtonTapped) },
        )
      }
      .padding(.top, 16)
      .padding(.bottom, 16)

    case .none:
      EmptyView()
    }
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
        artworkUrl: .ancientPath,
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
        artworkUrl: .ancientPath,
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
    episodes: sampleEpisodes,
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
    $0.downloadState = .notDownloaded
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
