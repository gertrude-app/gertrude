import SwiftUI

public struct EpisodeView: View {
  @Environment(\.colorScheme) var cs
  @State private var rotationAngle: Double = 0

  public enum Event {
    case playPauseTapped
    case downloadTapped
    case episodeTapped
  }

  let episode: EpisodeData
  let emit: @MainActor @Sendable (Event) -> Void

  public init(
    episode: EpisodeData,
    emit: @MainActor @Sendable @escaping (Event) -> Void = { _ in }
  ) {
    self.episode = episode
    self.emit = emit
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      VStack(alignment: .leading, spacing: 2) {
        Text(self.episode.pubDateRelative)
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
          .opacity(0.8)
          .padding(.top, 2)

        Text(self.episode.title)
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(Color(self.cs, light: .violet950, dark: .violet100))
          .multilineTextAlignment(.leading)
          .lineLimit(2)
          .frame(maxWidth: .infinity, alignment: .leading)
      }

      if let description = episode.description {
        Text(description)
          .font(.system(size: 14, weight: .regular))
          .foregroundStyle(Color(self.cs, light: .violet700, dark: .violet300))
          .multilineTextAlignment(.leading)
          .lineLimit(3)
          .frame(maxWidth: .infinity, alignment: .leading)
      }

      HStack(alignment: .bottom) {
        PlayBubble(episode: self.episode) {
          self.emit(.playPauseTapped)
        }

        Spacer()

        switch self.episode.downloadState {
        case .notDownloaded, .downloaded:
          Image(
            systemName: self.episode
              .downloadState == .downloaded ? "arrow.down.circle.fill" : "arrow.down.circle"
          )
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(Color(self.cs, light: .violet400, dark: .violet400))
          .onTapGesture {
            self.emit(.downloadTapped)
          }
          .padding(.bottom, 2)
        case .downloading:
          Image(systemName: "arrow.2.circlepath")
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
            .rotationEffect(.degrees(self.rotationAngle))
            .onAppear {
              withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                self.rotationAngle = 360
              }
            }
            .padding(.bottom, 2)
        }
      }
      .padding(.top, 4)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 20)
    .padding(.top, 12)
    .padding(.bottom, 20)
    .onTapGesture {
      self.emit(.episodeTapped)
    }
  }
}
