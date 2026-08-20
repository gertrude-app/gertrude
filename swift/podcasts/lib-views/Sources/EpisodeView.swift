import GertieUI
import SwiftUI

public struct EpisodeView: View {
  @Environment(\.colorScheme) var cs
  @Environment(\.lang) var lang

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
    emit: @MainActor @Sendable @escaping (Event) -> Void = { _ in },
  ) {
    self.episode = episode
    self.emit = emit
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      VStack(alignment: .leading, spacing: 2) {
        Text(self.episode.pubDateRelative(lang: self.lang).uppercased())
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
          .opacity(self.episode.isArchived ? 0.8 : 1.0)
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
        if self.episode.isArchived {
          HStack(spacing: 6) {
            Image(systemName: "archivebox")
              .font(.system(size: 12, weight: .medium))
              .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet400))

            Text("ARCHIVED")
              .font(.system(size: 12, weight: .medium))
              .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet400))
          }
          .padding(.top, 21)
          .padding(.bottom, 4)
        } else {
          PlayBubble(episode: self.episode) {
            self.emit(.playPauseTapped)
          }
          .transaction { $0.animation = nil }
        }

        Spacer()

        HStack(alignment: .center, spacing: 10) {
          if !self.episode.isArchived {
            switch self.episode.downloadState {
            case .notDownloaded, .downloaded:
              Button {
                self.emit(.downloadTapped)
              } label: {
                Image(
                  systemName: self.episode
                    .downloadState == .downloaded ? "arrow.down.circle.fill" : "arrow.down.circle",
                )
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(self.cs, light: .violet400, dark: .violet400))
              }
              .buttonStyle(.plain)
              .padding(12)
              .contentShape(Rectangle())
              .offset(x: 12)
            case .downloading:
              Image(systemName: "arrow.2.circlepath")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
                .rotatingDownloadIcon()
                .padding(12)
                .offset(x: 12)
            }
          }

          Menu {
            if !self.episode.isArchived {
              if self.episode.downloadState == .downloaded {
                Button(role: .destructive) {
                  self.emit(.removeDownloadTapped)
                } label: {
                  Label(lstr(.episodeRemoveDownload), systemImage: "trash")
                }
                .tint(.red)
                .transaction { $0.animation = nil }
              } else {
                Button {
                  self.emit(.downloadTapped)
                } label: {
                  Label(lstr(.episodeDownloadEpisode), systemImage: "arrow.down.circle")
                }
                .tint(.primary)
                .transaction { $0.animation = nil }
              }

              Button {
                self.emit(.toggleCompletedTapped)
              } label: {
                Label(
                  self.episode.isCompleted
                    ? lstr(.episodeMarkAsUnplayed)
                    : lstr(.episodeMarkAsPlayed),
                  systemImage: self.episode
                    .isCompleted ? "arrow.counterclockwise" : "arrow.clockwise",
                )
              }
              .tint(.primary)
              .transaction { $0.animation = nil }
            }

            Button {
              self.emit(.toggleArchivedTapped)
            } label: {
              Label(
                self.episode.isArchived
                  ? lstr(.episodeUnarchiveEpisode)
                  : lstr(.episodeArchiveEpisode),
                systemImage: self.episode.isArchived ? "tray.and.arrow.up" : "archivebox",
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
          .transaction { $0.animation = nil }
        }
        .offset(x: 11, y: 7)
      }
      .padding(.top, 4)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 20)
    .padding(.top, 12)
    .padding(.bottom, 16)
    .contentShape(Rectangle())
    .onTapGesture {
      self.emit(.episodeTapped)
    }
    .opacity(self.episode.isArchived ? 0.55 : 1.0)
  }
}
