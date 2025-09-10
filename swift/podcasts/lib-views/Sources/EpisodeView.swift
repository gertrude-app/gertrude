import SwiftUI

public struct EpisodeView: View {
  @Environment(\.colorScheme) var cs

  let episode: EpisodeData

  public init(episode: EpisodeData) {
    self.episode = episode
  }

  public var body: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 6) {
        HStack {
          Text(self.episode.relativeTime)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))

          Spacer()

          Text(self.episode.duration)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
        }

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

      VStack {
        Spacer()

        Image(
          systemName: self.episode
            .isDownloaded ? "arrow.down.circle.fill" : "arrow.down.circle"
        )
        .font(.system(size: 20, weight: .medium))
        .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
      }
    }
    .padding(.horizontal, 20)
    .padding(.top, 12)
    .padding(.bottom, 16)
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
    isDownloaded: true
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
    isDownloaded: true
  ))
  .preferredColorScheme(.dark)
}
