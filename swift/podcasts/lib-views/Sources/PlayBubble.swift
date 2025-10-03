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
      ? self.episode.remainingDurationShortString
      : self.episode.durationShortString
  }

  public var body: some View {
    Button(action: self.onTap) {
      HStack(spacing: 6) {
        Image(
          systemName: self.showsReplayArrow
            ? "arrow.counterclockwise"
            : (self.episode.isPlaying ? "pause.fill" : "play.fill")
        )
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet400))

        if self.hasProgress {
          ProgressView(value: self.progressRatio)
            .progressViewStyle(LinearProgressViewStyle(
              tint: Color(self.cs, light: .violet600, dark: .violet400)
            ))
            .background(Color(
              self.cs,
              light: .violet300.opacity(0.3),
              dark: .violet500.opacity(0.2)
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
      .padding(.horizontal, 11)
      .padding(.vertical, 6)
      .background(
        Color(self.cs, light: .violet100, dark: .violet900.opacity(0.3))
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
    isPlaying: false
  )
  modify(&episode)
  return episode
}

func show(id: Int = 1, _ modify: (inout ShowData) -> Void = { _ in }) -> ShowData {
  var show = ShowData(id: id, name: "Test Show", showArtwork: true)
  modify(&show)
  return show
}

#Preview("All States") {
  VStack(spacing: 16) {
    HStack {
      Text("Unlistened:")
      Spacer()
      PlayBubble(episode: episode())
    }

    HStack {
      Text("Partial (25%):")
      Spacer()
      PlayBubble(episode: episode {
        $0.progress = 495.0
      })
    }

    HStack {
      Text("Partial (85%):")
      Spacer()
      PlayBubble(episode: episode {
        $0.durationSeconds = 3600
        $0.progress = 3060.0
      })
    }

    HStack {
      Text("Complete:")
      Spacer()
      PlayBubble(episode: episode {
        $0.progress = 1980.0
      })
    }

    HStack {
      Text("No duration:")
      Spacer()
      PlayBubble(episode: episode {
        $0.durationSeconds = nil
      })
    }

    HStack {
      Text("Playing:")
      Spacer()
      PlayBubble(episode: episode {
        $0.durationSeconds = 2700
        $0.progress = 1080.0
        $0.isPlaying = true
      })
    }
  }
  .padding(20)
}

#Preview("All States (Dark)") {
  VStack(spacing: 16) {
    HStack {
      Text("Unlistened:")
      Spacer()
      PlayBubble(episode: episode())
    }

    HStack {
      Text("Partial (25%):")
      Spacer()
      PlayBubble(episode: episode {
        $0.progress = 495.0
      })
    }

    HStack {
      Text("Partial (85%):")
      Spacer()
      PlayBubble(episode: episode {
        $0.durationSeconds = 3600
        $0.progress = 3060.0
      })
    }

    HStack {
      Text("Complete:")
      Spacer()
      PlayBubble(episode: episode {
        $0.progress = 1980.0
      })
    }

    HStack {
      Text("No duration:")
      Spacer()
      PlayBubble(episode: episode {
        $0.durationSeconds = nil
      })
    }

    HStack {
      Text("Playing:")
      Spacer()
      PlayBubble(episode: episode {
        $0.durationSeconds = 2700
        $0.progress = 1080.0
        $0.isPlaying = true
      })
    }
  }
  .padding(20)
  .preferredColorScheme(.dark)
}
