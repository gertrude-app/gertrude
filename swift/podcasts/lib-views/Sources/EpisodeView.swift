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
          HStack(spacing: 8) {
            if self.episode.downloadState != .downloaded {
              Group {
                switch self.episode.downloadState {
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
                case .notDownloaded:
                  Image(systemName: "arrow.down.circle")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
                    .onTapGesture {
                      self.emit(.downloadTapped)
                    }
                case .downloaded:
                  EmptyView()
                }
              }
            }

            Text(self.episode.duration)
              .font(.system(size: 12, weight: .medium))
              .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
          }
          .padding(.top, 4)
          .padding(.trailing, 8)
        }
        Spacer()
      }

      VStack {
        Spacer()
        HStack {
          Spacer()
          Button(action: {
            self.emit(.playPauseTapped)
          }) {
            Image(systemName: self.episode.isPlaying ? "pause.circle.fill" : "play.circle")
              .font(.system(size: 28, weight: self.episode.isPlaying ? .medium : .thin))
              .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
          }
          .padding(.trailing, 4)
        }
        .padding(.bottom, 8)
      }
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
