import SwiftUI

public struct EpisodeView: View {
  @Environment(\.colorScheme) var cs
  @State private var rotationAngle: Double = 0

  let episode: EpisodeData
  let onTap: @MainActor @Sendable (EpisodeData) -> Void

  public init(
    episode: EpisodeData,
    onTap: @MainActor @Sendable @escaping (EpisodeData) -> Void = { _ in }
  ) {
    self.episode = episode
    self.onTap = onTap
  }

  public var body: some View {
    ZStack {
      HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
          Text(self.episode.relativeTime)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
            .opacity(0.8)

          Text(self.episode.title)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Color(self.cs, light: .violet950, dark: .violet100))
            .multilineTextAlignment(.leading)
            .lineLimit(2)

          if let description = episode.description {
            Text(description)
              .font(.system(size: 14, weight: .regular))
              .foregroundStyle(Color(self.cs, light: .violet700, dark: .violet300))
              .multilineTextAlignment(.leading)
              .lineLimit(3)
          }
        }

        Spacer(minLength: 60)
      }

      VStack {
        HStack {
          Spacer()
          Text(self.episode.duration)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
            .padding(.top, 4)
        }
        Spacer()
      }

      VStack {
        Spacer()
        HStack {
          Spacer()
          Group {
            switch self.episode.downloadState {
            case .downloaded:
              Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
            case .downloading:
              Image(systemName: "arrow.2.circlepath")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
                .rotationEffect(.degrees(self.rotationAngle))
                .onAppear {
                  withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    self.rotationAngle = 360
                  }
                }
            case .notDownloaded:
              Image(systemName: "arrow.down.circle")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
            }
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 20)
    .padding(.top, 12)
    .padding(.bottom, 20)
    .onTapGesture {
      self.onTap(self.episode)
    }
  }
}

#Preview("Episode - Basic") {
  EpisodeView(episode: EpisodeData(
    id: 1,
    title: "Introduction to SwiftUI",
    description: "Learn the basics of SwiftUI development and how to build beautiful user interfaces with declarative syntax.",
    relativeTime: "6H AGO",
    duration: "1h 5m"
  ))
}

#Preview("Episode - Downloaded") {
  EpisodeView(episode: EpisodeData(
    id: 2,
    title: "Advanced iOS Architecture Patterns",
    description: "Deep dive into MVVM, VIPER, and TCA architecture patterns for iOS applications.",
    relativeTime: "2D AGO",
    duration: "45m",
    downloadState: .downloaded
  ))
}

#Preview("Episode - No Description") {
  EpisodeView(episode: EpisodeData(
    id: 3,
    title: "Quick Tips for Better Code",
    relativeTime: "JUST NOW",
    duration: "15m"
  ))
}

#Preview("Episode - Long Title") {
  EpisodeView(episode: EpisodeData(
    id: 4,
    title: "This is a Very Long Episode Title That Should Wrap to Multiple Lines and Test Our Line Limit Implementation",
    description: "This episode has a really long title to test how our UI handles text wrapping and line limits in various scenarios.",
    relativeTime: "1D AGO",
    duration: "2h 15m"
  ))
}

#Preview("Episode - Dark Mode") {
  EpisodeView(episode: EpisodeData(
    id: 5,
    title: "Understanding Dark Mode Design",
    description: "Best practices for designing interfaces that work well in both light and dark modes.",
    relativeTime: "3H AGO",
    duration: "52m",
    downloadState: .downloaded
  ))
  .preferredColorScheme(.dark)
}

#Preview("Episode - Downloading") {
  EpisodeView(episode: EpisodeData(
    id: 6,
    title: "Swift Concurrency Deep Dive",
    description: "Learn about async/await, actors, and structured concurrency in Swift.",
    relativeTime: "JUST NOW",
    duration: "1h 20m",
    downloadState: .downloading
  ))
}
