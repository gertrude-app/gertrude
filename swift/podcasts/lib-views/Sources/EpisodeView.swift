import SwiftUI

public struct EpisodeView: View {
  @Environment(\.colorScheme) var cs
  @State private var rotationAngle: Double = 0

  public enum Event {
    case playPauseTapped
    case downloadTapped
    case episodeTapped
    case removeDownloadTapped
    case toggleCompletedTapped
    case toggleArchivedTapped
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
        Text(self.episode.pubDateRelative.uppercased())
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
          .opacity(self.episode.isArchived ? 0.9 : 1.0)
      }

      if let description = episode.description {
        Text(description)
          .font(.system(size: 14, weight: .regular))
          .foregroundStyle(Color(self.cs, light: .violet700, dark: .violet300))
          .multilineTextAlignment(.leading)
          .lineLimit(self.episode.isArchived ? 1 : 3)
          .frame(maxWidth: .infinity, alignment: .leading)
      }

      HStack(alignment: .bottom) {
        if self.episode.isArchived {
          HStack(spacing: 6) {
            Image(systemName: "archivebox")
              .font(.system(size: 12, weight: .medium))
              .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet400))

            Text("ARCHIVED")
              .font(.system(size: 12, weight: .medium))
              .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet400))
          }
        } else {
          PlayBubble(episode: self.episode) {
            self.emit(.playPauseTapped)
          }
        }

        Spacer()

        HStack(alignment: .center, spacing: 9) {
          if !self.episode.isArchived {
            switch self.episode.downloadState {
            case .notDownloaded, .downloaded:
              Button {
                self.emit(.downloadTapped)
              } label: {
                Image(
                  systemName: self.episode
                    .downloadState == .downloaded ? "arrow.down.circle.fill" : "arrow.down.circle"
                )
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(self.cs, light: .violet400, dark: .violet400))
              }
            case .downloading:
              Image(systemName: "arrow.2.circlepath")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
                .rotationEffect(.degrees(self.rotationAngle))
                .onAppear {
                  withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    self.rotationAngle = 360
                  }
                }
            }
          }

          Menu {
            if !self.episode.isArchived {
              if self.episode.downloadState == .downloaded {
                Button(role: .destructive) {
                  self.emit(.removeDownloadTapped)
                } label: {
                  Label("Remove download", systemImage: "trash")
                }
                .tint(.red)
              } else {
                Button {
                  self.emit(.downloadTapped)
                } label: {
                  Label("Download episode", systemImage: "arrow.down.circle")
                }
                .tint(.primary)
              }

              Button {
                self.emit(.toggleCompletedTapped)
              } label: {
                Label(
                  self.episode.isCompleted ? "Mark as unplayed" : "Mark as played",
                  systemImage: self.episode
                    .isCompleted ? "arrow.counterclockwise" : "arrow.clockwise"
                )
              }
              .tint(.primary)
            }

            Button {
              self.emit(.toggleArchivedTapped)
            } label: {
              Label(
                self.episode.isArchived ? "Unarchive episode" : "Archive episode",
                systemImage: self.episode.isArchived ? "tray.and.arrow.up" : "archivebox"
              )
            }
            .tint(.primary)
          } label: {
            Image(systemName: "ellipsis")
              .font(.system(size: 14, weight: .heavy))
              .foregroundStyle(Color(self.cs, light: .violet400, dark: .violet400))
              .padding(12)
              .opacity(0.8)
          }
          .offset(x: -4)
          .buttonStyle(.plain)
        }
        .offset(x: 8, y: 5)
      }
      .padding(.top, 4)
      .offset(y: self.episode.isArchived ? -14 : 0)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 20)
    .padding(.top, 12)
    .padding(.bottom, self.episode.isArchived ? 4 : 20)
    .contentShape(Rectangle())
    .onTapGesture {
      self.emit(.episodeTapped)
    }
    .opacity(self.episode.isArchived ? 0.55 : 1.0)
  }
}
