import SwiftUI

public struct PlayBubble: View {
  @Environment(\.colorScheme) var cs

  let episode: EpisodeData
  let onTap: @MainActor @Sendable () -> Void

  public init(
    episode: EpisodeData,
    onTap: @MainActor @Sendable @escaping () -> Void = {}
  ) {
    self.episode = episode
    self.onTap = onTap
  }

  private var isFullyListened: Bool {
    self.episode.progress >= 0.99
  }

  private var hasProgress: Bool {
    self.episode.progress > 0.01 && !self.isFullyListened
  }

  public var body: some View {
    Button(action: self.onTap) {
      HStack(spacing: 8) {
        Image(
          systemName: self
            .isFullyListened ? "arrow.counterclockwise" :
            (self.episode.isPlaying ? "pause.fill" : "play.fill")
        )
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet400))

        if self.hasProgress {
          ProgressView(value: self.episode.progress)
            .progressViewStyle(LinearProgressViewStyle(
              tint: Color(self.cs, light: .violet600, dark: .violet400)
            ))
            .background(Color(
              self.cs,
              light: .violet300.opacity(0.3),
              dark: .violet500.opacity(0.2)
            ))
            .frame(width: 20, height: 2)
            .scaleEffect(y: 2.0)
            .clipShape(Capsule())
        }

        if let duration = episode.duration {
          Text(duration)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet400))
        }
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .background(
        Color(self.cs, light: .violet100, dark: .violet900.opacity(0.3))
      )
      .cornerRadius(20)
    }
    .buttonStyle(PlainButtonStyle())
  }
}

#Preview("All States") {
  VStack(spacing: 16) {
    HStack {
      Text("Unlistened:")
      Spacer()
      PlayBubble(
        episode: EpisodeData(
          id: 1,
          title: "Test Episode",
          relativeTime: "2 hours ago",
          duration: "33m",
          durationSeconds: 1980,
          progress: 0.0,
          currentTimeString: "0:00",
          remainingTimeString: "33:00",
          downloadState: .downloaded,
          isPlaying: false
        )
      )
    }

    HStack {
      Text("Partial (25%):")
      Spacer()
      PlayBubble(
        episode: EpisodeData(
          id: 2,
          title: "Test Episode",
          relativeTime: "2 hours ago",
          duration: "33m",
          durationSeconds: 1980,
          progress: 0.25,
          currentTimeString: "8:15",
          remainingTimeString: "24:45",
          downloadState: .downloaded,
          isPlaying: false
        )
      )
    }

    HStack {
      Text("Partial (85%):")
      Spacer()
      PlayBubble(
        episode: EpisodeData(
          id: 3,
          title: "Almost Done",
          relativeTime: "3 days ago",
          duration: "60m",
          durationSeconds: 3600,
          progress: 0.85,
          currentTimeString: "51:00",
          remainingTimeString: "9:00",
          downloadState: .downloaded,
          isPlaying: false
        )
      )
    }

    HStack {
      Text("Complete:")
      Spacer()
      PlayBubble(
        episode: EpisodeData(
          id: 4,
          title: "Complete Episode",
          relativeTime: "2 hours ago",
          duration: "33m",
          durationSeconds: 1980,
          progress: 1.0,
          currentTimeString: "33:00",
          remainingTimeString: "0:00",
          downloadState: .downloaded,
          isPlaying: false
        )
      )
    }

    HStack {
      Text("No duration:")
      Spacer()
      PlayBubble(
        episode: EpisodeData(
          id: 5,
          title: "Unknown Duration",
          relativeTime: "2 hours ago",
          duration: nil,
          durationSeconds: nil,
          progress: 0.0,
          currentTimeString: "0:00",
          remainingTimeString: "unknown",
          downloadState: .downloaded,
          isPlaying: false
        )
      )
    }

    HStack {
      Text("Playing:")
      Spacer()
      PlayBubble(
        episode: EpisodeData(
          id: 6,
          title: "Currently Playing",
          relativeTime: "now",
          duration: "45m",
          durationSeconds: 2700,
          progress: 0.4,
          currentTimeString: "18:00",
          remainingTimeString: "27:00",
          downloadState: .downloaded,
          isPlaying: true
        )
      )
    }
  }
  .padding(20)
}

#Preview("All States (Dark)") {
  VStack(spacing: 16) {
    HStack {
      Text("Unlistened:")
      Spacer()
      PlayBubble(
        episode: EpisodeData(
          id: 1,
          title: "Test Episode",
          relativeTime: "2 hours ago",
          duration: "33m",
          durationSeconds: 1980,
          progress: 0.0,
          currentTimeString: "0:00",
          remainingTimeString: "33:00",
          downloadState: .downloaded,
          isPlaying: false
        )
      )
    }

    HStack {
      Text("Partial (25%):")
      Spacer()
      PlayBubble(
        episode: EpisodeData(
          id: 2,
          title: "Test Episode",
          relativeTime: "2 hours ago",
          duration: "33m",
          durationSeconds: 1980,
          progress: 0.25,
          currentTimeString: "8:15",
          remainingTimeString: "24:45",
          downloadState: .downloaded,
          isPlaying: false
        )
      )
    }

    HStack {
      Text("Partial (85%):")
      Spacer()
      PlayBubble(
        episode: EpisodeData(
          id: 3,
          title: "Almost Done",
          relativeTime: "3 days ago",
          duration: "60m",
          durationSeconds: 3600,
          progress: 0.85,
          currentTimeString: "51:00",
          remainingTimeString: "9:00",
          downloadState: .downloaded,
          isPlaying: false
        )
      )
    }

    HStack {
      Text("Complete:")
      Spacer()
      PlayBubble(
        episode: EpisodeData(
          id: 4,
          title: "Complete Episode",
          relativeTime: "2 hours ago",
          duration: "33m",
          durationSeconds: 1980,
          progress: 1.0,
          currentTimeString: "33:00",
          remainingTimeString: "0:00",
          downloadState: .downloaded,
          isPlaying: false
        )
      )
    }

    HStack {
      Text("No duration:")
      Spacer()
      PlayBubble(
        episode: EpisodeData(
          id: 5,
          title: "Unknown Duration",
          relativeTime: "2 hours ago",
          duration: nil,
          durationSeconds: nil,
          progress: 0.0,
          currentTimeString: "0:00",
          remainingTimeString: "unknown",
          downloadState: .downloaded,
          isPlaying: false
        )
      )
    }

    HStack {
      Text("Playing:")
      Spacer()
      PlayBubble(
        episode: EpisodeData(
          id: 6,
          title: "Currently Playing",
          relativeTime: "now",
          duration: "45m",
          durationSeconds: 2700,
          progress: 0.4,
          currentTimeString: "18:00",
          remainingTimeString: "27:00",
          downloadState: .downloaded,
          isPlaying: true
        )
      )
    }
  }
  .padding(20)
  .preferredColorScheme(.dark)
}
