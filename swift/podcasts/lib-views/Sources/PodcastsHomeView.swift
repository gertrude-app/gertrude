import SwiftUI

#if canImport(UIKit)
  import UIKit
#else
  import LibCore
#endif

public struct PodcastsHomeView: View {
  @Environment(\.colorScheme) var cs
  @Environment(\.miniNowPlayingVisible) var miniNowPlayingVisible
  @Environment(\.lang) var lang

  public enum SubscriptionStatus {
    case ok
    case trialEndingSoon
    case unpaid
  }

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
  let onSettingsTap: @MainActor @Sendable () -> Void
  let onDebugMenuTap: @MainActor @Sendable (DebugMenuAction) -> Void
  let subscriptionStatus: SubscriptionStatus

  public enum DebugMenuAction {
    case setTrialExpiringSoon
    case setUnpaid
    case setActive
  }

  public init(
    shows: [ShowDataWithStats],
    onAddShowTap: @MainActor @escaping @Sendable () -> Void = {},
    onShowTap: @MainActor @escaping @Sendable (Int) -> Void = { _ in },
    onDeleteShow: @MainActor @escaping @Sendable (Int) -> Void = { _ in },
    onSettingsTap: @MainActor @escaping @Sendable () -> Void = {},
    onDebugMenuTap: @MainActor @escaping @Sendable (DebugMenuAction) -> Void = { _ in },
    subscriptionStatus: SubscriptionStatus = .ok,
  ) {
    self.shows = shows
    self.onAddShowTap = onAddShowTap
    self.onShowTap = onShowTap
    self.onDeleteShow = onDeleteShow
    self.onSettingsTap = onSettingsTap
    self.onDebugMenuTap = onDebugMenuTap
    self.subscriptionStatus = subscriptionStatus
  }

  public var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text(lstr(.showsTitle))
          .font(.largeTitle)
          .fontWeight(.bold)
        Spacer()
        #if DEBUG
          if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
            Menu {
              Button("Set trial expiring soon") {
                self.onDebugMenuTap(.setTrialExpiringSoon)
              }
              Button("Set unpaid") {
                self.onDebugMenuTap(.setUnpaid)
              }
              Button("Set active") {
                self.onDebugMenuTap(.setActive)
              }
            } label: {
              Image(systemName: "flask")
                .font(.title3)
                .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet300))
            }
            .padding(.trailing, 8)
          }
        #endif
        Button {
          self.onAddShowTap()
        } label: {
          Image(systemName: "plus")
            .font(.title3)
            .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet300))
        }
        .padding(.trailing, 8)
        Button {
          self.onSettingsTap()
        } label: {
          ZStack(alignment: .topTrailing) {
            Image(systemName: "person.crop.circle")
              .font(.title3)
              .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet300))
            if self.subscriptionStatus != .ok {
              TimelineView(.animation) { context in
                let opacity = 0.65 + 0.35 * sin(context.date.timeIntervalSinceReferenceDate * .pi)
                Circle()
                  .fill(Color(red: 0.8, green: 0.0, blue: 0.0))
                  .frame(width: 9, height: 9)
                  .opacity(opacity)
                  .offset(x: 0, y: -1)
              }
            }
          }
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 8)
      .padding(.bottom, 8)

      if self.subscriptionStatus == .unpaid {
        self.unpaidBanner
      }

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
  }

  private var unpaidBanner: some View {
    Button {
      self.onSettingsTap()
    } label: {
      HStack(spacing: 12) {
        Image(systemName: "exclamationmark.triangle.fill")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(Color(self.cs, light: .violet700, dark: .violet300))
        Text(lstr(.showsSubscriptionRequired))
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(Color(self.cs, light: .violet950, dark: .violet100))
        Spacer()
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 24)
      .background(Color(self.cs, light: .violet100, dark: .violet950))
      .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
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
            Label(lstr(.showsDelete), systemImage: "trash")
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
            Text(lstr(.showsAddShow))
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
    .safeAreaInset(edge: .bottom) {
      if self.miniNowPlayingVisible {
        Color.clear.frame(height: 70)
      }
    }
  }

  private func showInfoText(_ show: ShowDataWithStats) -> String {
    var parts: [String] = []

    if let pubDate = show.mostRecentPubDate {
      parts.append(formatRelativeDate(pubDate, lang: self.lang))
    }

    if show.unplayedEpisodes > 0 {
      if show.unplayedEpisodes < 12 {
        let format = lstr(.showsNewCount)
        parts.append(String(format: format, show.unplayedEpisodes))
      } else {
        let format = lstr(.showsEpisodeCount)
        parts.append(String(format: format, show.totalEpisodes))
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
      artworkImage: show.showArtwork ? show.artworkImage : nil,
      artworkUrl: show.showArtwork ? show.artworkUrl : nil,
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
  )
  .preferredColorScheme(.dark)
}

#Preview("Trial Ending Soon") {
  PodcastsHomeView(
    shows: [
      showWithStats(id: 1) {
        $0.data.name = "The Ancient Path"
        $0.data.artworkUrl = .ancientPath
        $0.mostRecentPubDate = Date().addingTimeInterval(-TimeInterval.hours(8))
        $0.unplayedEpisodes = 3
        $0.totalEpisodes = 125
      },
    ],
    subscriptionStatus: .trialEndingSoon
  )
}

#Preview("Unpaid") {
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
    ],
    subscriptionStatus: .unpaid
  )
}

#Preview("Unpaid (Dark)") {
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
    ],
    subscriptionStatus: .unpaid
  )
  .preferredColorScheme(.dark)
}

#Preview("Empty State") {
  PodcastsHomeView(shows: [])
}

#Preview("Many Shows") {
  PodcastsHomeView(
    shows: [
      showWithStats(id: 1) {
        $0.data.name = "The Ancient Path"
        $0.data.artworkUrl = .ancientPath
        $0.mostRecentPubDate = Date().addingTimeInterval(-TimeInterval.hours(2))
        $0.unplayedEpisodes = 5
        $0.totalEpisodes = 145
      },
      showWithStats(id: 2) {
        $0.data.name = "The Secret Sombrero"
        $0.data.artworkUrl = .sombrero
        $0.mostRecentPubDate = Date().addingTimeInterval(-TimeInterval.days(1))
        $0.unplayedEpisodes = 12
        $0.totalEpisodes = 87
      },
      showWithStats(id: 3) {
        $0.data.name = "This American Life"
        $0.mostRecentPubDate = Date().addingTimeInterval(-TimeInterval.days(3))
        $0.unplayedEpisodes = 2
        $0.totalEpisodes = 542
      },
      showWithStats(id: 4) {
        $0.data.name = "Swift Talk"
        $0.data.artworkUrl = .ancientPath
        $0.mostRecentPubDate = Date().addingTimeInterval(-TimeInterval.days(5))
        $0.unplayedEpisodes = 0
        $0.totalEpisodes = 234
      },
      showWithStats(id: 5) {
        $0.data.name = "Tech Weekly"
        $0.mostRecentPubDate = Date().addingTimeInterval(-TimeInterval.days(7))
        $0.unplayedEpisodes = 8
        $0.totalEpisodes = 156
      },
      showWithStats(id: 6) {
        $0.data.name = "History Podcast"
        $0.data.artworkUrl = .sombrero
        $0.mostRecentPubDate = Date().addingTimeInterval(-TimeInterval.days(8))
        $0.unplayedEpisodes = 3
        $0.totalEpisodes = 89
      },
      showWithStats(id: 7) {
        $0.data.name = "Developer Life"
        $0.mostRecentPubDate = Date().addingTimeInterval(-TimeInterval.days(10))
        $0.unplayedEpisodes = 0
        $0.totalEpisodes = 67
      },
      showWithStats(id: 8) {
        $0.data.name = "Science Today"
        $0.data.artworkUrl = .ancientPath
        $0.mostRecentPubDate = Date().addingTimeInterval(-TimeInterval.days(12))
        $0.unplayedEpisodes = 6
        $0.totalEpisodes = 201
      },
    ],
  )
}

public struct NowPlayingVisibleKey: EnvironmentKey {
  public static let defaultValue: Bool = false
}

public extension EnvironmentValues {
  var miniNowPlayingVisible: Bool {
    get { self[NowPlayingVisibleKey.self] }
    set { self[NowPlayingVisibleKey.self] = newValue }
  }
}

extension String {
  static let ancientPath =
    "https://is1-ssl.mzstatic.com/image/thumb/Podcasts116/v4/a2/94/d3/a294d3e7-bf02-377f-a531-7b0491a4cb81/mza_4607163774963783796.png/600x600bb.jpg"
  static let sombrero = "https://spanish-7cbc3de5.nyc3.digitaloceanspaces.com/sombrero.jpg"
}
