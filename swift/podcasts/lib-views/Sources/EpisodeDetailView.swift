import SwiftUI

public struct EpisodeDetailView: View {
  @Environment(\.colorScheme) var cs
  @Environment(\.lang) var lang

  public enum Event {
    case playPauseTapped
  }

  @dynamicMemberLookup
  public struct EpisodeDetail {
    public let data: EpisodeData
    public let websiteUrl: URL?
    public let sizeInBytes: Int
  }

  let episodeDetail: EpisodeDetail
  let show: ShowData
  let emit: @MainActor @Sendable (Event) -> Void

  public init(
    episode: EpisodeDetail,
    show: ShowData,
    emit: @MainActor @Sendable @escaping (Event) -> Void = { _ in },
  ) {
    self.episodeDetail = episode
    self.show = show
    self.emit = emit
  }

  public var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        VStack(spacing: 20) {
          ArtworkView(provider: self, size: 260, cornerRadius: 8)
            .padding(.bottom, 12)

          VStack(spacing: 4) {
            Text(self.show.name)
              .font(.system(size: 16, weight: .medium))
              .foregroundStyle(Color(self.cs, light: .violet700, dark: .violet300))
              .multilineTextAlignment(.center)

            Text(self.episode.title)
              .font(.system(size: 24, weight: .bold))
              .foregroundStyle(Color(self.cs, light: .violet950, dark: .violet100))
              .multilineTextAlignment(.center)
              .lineLimit(3)
              .padding(.horizontal, 24)

            HStack(spacing: 6) {
              Text(self.episode.pubDateRelative(lang: self.lang))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet400))
                .textCase(.uppercase)

              if let duration = self.episode.durationShortString(lang: self.lang) {
                Text("•")
                  .foregroundStyle(Color(self.cs, light: .violet400, dark: .violet500))
                Text(duration)
                  .font(.system(size: 12, weight: .medium))
                  .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet400))
                  .textCase(.uppercase)
              }
            }
          }
        }
        .padding(.top, 20)

        PlayPauseButton(
          text: self.episode.isPlaying
            ? lstr(.showPause)
            : (self.episode.progress >= 2.0 && !self.episode.isCompleted ? lstr(.showResume) : lstr(.showPlay)),
          isPlaying: self.episode.isPlaying,
          onTap: { self.emit(.playPauseTapped) }
        )

        if let description = self.episode.description {
          VStack(alignment: .leading, spacing: 8) {
            Text(lstr(.episodeDetailDescription))
              .font(.system(size: 18, weight: .semibold))
              .foregroundStyle(Color(self.cs, light: .violet950, dark: .violet100))

            Text(description)
              .font(.system(size: 15, weight: .regular))
              .foregroundStyle(Color(self.cs, light: .violet700, dark: .violet300))
              .multilineTextAlignment(.leading)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 24)
          .padding(.top, 16)
        }

        VStack(alignment: .leading, spacing: 12) {
          Text(lstr(.episodeDetailEpisodeInfo))
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(Color(self.cs, light: .violet950, dark: .violet100))
            .padding(.bottom, 4)

          self.infoRow(
            label: lstr(.episodeDetailPublished),
            value: self.formatPublishDate(self.episode.pubDate)
          )

          if let duration = self.episode.durationSeconds {
            self.infoRow(
              label: lstr(.episodeDetailDuration),
              value: formatPlayerTime(duration)
            )
          }

          self.infoRow(
            label: lstr(.episodeDetailSize),
            value: formatFileSize(self.episodeDetail.sizeInBytes)
          )

          self.infoRow(
            label: lstr(.settingsSubscriptionStatus),
            value: self.episode.downloadState == .downloaded ? lstr(.episodeDetailDownloaded) : lstr(.episodeDetailNotDownloaded)
          )

          if let websiteUrl = self.episodeDetail.websiteUrl {
            Link(destination: websiteUrl) {
              HStack(spacing: 8) {
                Text(lstr(.episodeDetailEpisodeWebsite))
                  .font(.system(size: 14, weight: .semibold))
                  .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet500))
                  .tracking(0.5)
                Spacer()
                HStack(spacing: 4) {
                  Text(lstr(.episodeDetailView))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color(self.cs, light: .violet800, dark: .violet200))
                  Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
                }
              }
            }
          }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 96)
      }
    }
    .background(
      Color(self.cs, light: .violet100, dark: .violet900)
        .ignoresSafeArea(.all)
    )
  }

  private func infoRow(label: String, value: String) -> some View {
    HStack(spacing: 8) {
      Text(label)
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet500))
        .textCase(.uppercase)
        .tracking(0.5)
      Spacer()
      Text(value)
        .font(.system(size: 15, weight: .medium))
        .foregroundStyle(Color(self.cs, light: .violet800, dark: .violet200))
    }
  }

  private func formatPublishDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }
}

extension EpisodeDetailView: EpisodeArtworkProvider {
  var episode: EpisodeData { self.episodeDetail.data }
}

extension EpisodeDetailView.EpisodeDetail {
  subscript<T>(dynamicMember keyPath: KeyPath<EpisodeData, T>) -> T {
    self.data[keyPath: keyPath]
  }

  public init(episode: EpisodeData, websiteUrl: URL?, sizeInBytes: Int) {
    self.data = episode
    self.websiteUrl = websiteUrl
    self.sizeInBytes = sizeInBytes
  }
}

#Preview("Episode Detail - Light") {
  EpisodeDetailView(
    episode: .init(
      episode: episode(id: 1) {
        $0.title = "Walking in Truth"
        $0.description =
          "How to discern truth from error in today's confusing world and walk confidently in biblical wisdom. This episode explores the importance of grounding ourselves in God's word and being able to recognize deception."
        $0.durationSeconds = 3120
        $0.progress = 1200
        $0.downloadState = .downloaded
        $0.pubDate = .now - .days(2)
      },
      websiteUrl: URL(string: "https://example.com/episode/1"),
      sizeInBytes: 50_000_000
    ),
    show: show {
      $0.name = "The Ancient Path"
      $0.author = "Jason Henderson"
      $0.artworkUrl = .ancientPath
    }
  )
}

#Preview("Episode Detail - Dark") {
  EpisodeDetailView(
    episode: .init(
      episode: episode(id: 2) {
        $0.title = "The Narrow Path"
        $0.description =
          "Jesus spoke of the narrow path that leads to life. What does this mean for believers today? Join us as we explore the radical call to follow Christ and walk in obedience to His commands."
        $0.durationSeconds = 2820
        $0.downloadState = .notDownloaded
        $0.pubDate = .now - .days(5)
      },
      websiteUrl: nil,
      sizeInBytes: 35_000_000
    ),
    show: show {
      $0.name = "The Ancient Path"
      $0.author = "Jason Henderson"
      $0.artworkUrl = .ancientPath
    }
  )
  .preferredColorScheme(.dark)
}

#Preview("Episode Detail - Playing") {
  EpisodeDetailView(
    episode: .init(
      episode: episode(id: 3) {
        $0.title = "Guarding Your Heart"
        $0.description =
          "It is wisdom, and not legalism, to guard your heart, and to pay attention to what is filling your thoughts, your affections and your time."
        $0.durationSeconds = 2280
        $0.progress = 1000
        $0.downloadState = .downloaded
        $0.pubDate = .now - .hours(1)
        $0.isPlaying = true
      },
      websiteUrl: URL(string: "https://example.com/episode/3"),
      sizeInBytes: 28_500_000
    ),
    show: show {
      $0.name = "The Ancient Path"
      $0.author = "Jason Henderson"
      $0.artworkUrl = .ancientPath
    }
  )
}

#Preview("Episode Detail - Resume") {
  EpisodeDetailView(
    episode: .init(
      episode: episode(id: 4) {
        $0.title = "Walking in Wisdom"
        $0.description = "How to apply biblical wisdom to our daily decisions and relationships."
        $0.durationSeconds = 2400
        $0.progress = 800
        $0.downloadState = .downloaded
        $0.pubDate = .now - .days(3)
      },
      websiteUrl: URL(string: "https://example.com/episode/4"),
      sizeInBytes: 32_000_000
    ),
    show: show {
      $0.name = "The Ancient Path"
      $0.author = "Jason Henderson"
      $0.artworkUrl = .ancientPath
    }
  )
}
