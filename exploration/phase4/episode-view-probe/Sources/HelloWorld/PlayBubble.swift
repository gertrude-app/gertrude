import SwiftUI

public struct PlayBubble: View {
  @Environment(\.colorScheme) var cs
  @Environment(\.lang) var lang

  let episode: EpisodeData
  let onTap: @MainActor @Sendable () -> Void

  public init(
    episode: EpisodeData,
    onTap: @MainActor @Sendable @escaping () -> Void = {},
  ) {
    self.episode = episode
    self.onTap = onTap
  }

  var hasProgress: Bool {
    self.episode.progress > 3.0 && (self.episode.isPlaying || !self.episode.isCompleted)
  }

  var showsReplayArrow: Bool {
    self.episode.isCompleted && !self.episode.isPlaying
  }

  var progressRatio: Double {
    guard let durationSeconds = episode.durationSeconds, durationSeconds > 0 else {
      return 0.0
    }
    return min(self.episode.progress / Double(durationSeconds), 1.0)
  }

  var timeText: String? {
    self.hasProgress
      ? self.episode.remainingDurationShortString(lang: self.lang)
      : self.episode.durationShortString(lang: self.lang)
  }

  public var body: some View {
    Button(action: self.onTap) {
      HStack(spacing: 6) {
        if self.episode.downloadState == .downloading {
          Text(lstr(.episodeDownloading))
            .font(.system(size: 12, weight: .medium))
            .italic()
            .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet400))
        } else {
          Image(
            systemName: self.showsReplayArrow
              ? "arrow.counterclockwise"
              : (self.episode.isPlaying ? "pause.fill" : "play.fill"),
          )
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet400))

          if self.hasProgress {
            ProgressView(value: self.progressRatio)
              .progressViewStyle(LinearProgressViewStyle(
                tint: Color(self.cs, light: .violet600, dark: .violet400),
              ))
              .background(Color(
                self.cs,
                light: .violet300.opacity(0.3),
                dark: .violet500.opacity(0.2),
              ))
              .frame(width: 24, height: 4)
              .clipShape(Capsule())
          }

          if let time = self.timeText {
            Text(time)
              .font(.system(size: 12, weight: .medium))
              .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet400))
          }
        }
      }
      .padding(.horizontal, 11)
      .padding(.vertical, 6)
      .background(
        Color(self.cs, light: .violet100, dark: .violet900.opacity(0.5)),
      )
      .cornerRadius(16)
    }
    .buttonStyle(PlainButtonStyle())
  }
}

func episode(id: Int = 1, _ modify: (inout EpisodeData) -> Void = { _ in }) -> EpisodeData {
  var episode = EpisodeData(
    id: id,
    title: "Test Episode",
    durationSeconds: 1980,
    progress: 0.0,
    downloadState: .downloaded,
    pubDate: Date(),
    isPlaying: false,
    isArchived: false,
  )
  modify(&episode)
  return episode
}
