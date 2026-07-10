import SwiftUI

public struct AlbumDetailView: View {
  private let album: AlbumData
  private let rows: [AlbumDetailTrackRow]
  private let transitionSourceID: String?
  private let isPlaying: Bool
  private let isLoading: Bool
  private let isLoadingTracks: Bool
  private let currentTrackID: String?
  private let onPlayTap: @MainActor @Sendable () -> Void
  private let onTrackTap: @MainActor @Sendable (String) -> Void

  public init(
    album: AlbumData,
    tracks: [TrackData],
    transitionSourceID: String? = nil,
    isPlaying: Bool = false,
    isLoading: Bool = false,
    isLoadingTracks: Bool = false,
    currentTrackID: String? = nil,
    onPlayTap: @MainActor @escaping @Sendable () -> Void = {},
    onTrackTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
  ) {
    self.album = album
    self.transitionSourceID = transitionSourceID
    self.isPlaying = isPlaying
    self.isLoading = isLoading
    self.isLoadingTracks = isLoadingTracks
    self.currentTrackID = currentTrackID
    self.onPlayTap = onPlayTap
    self.onTrackTap = onTrackTap
    self.rows = tracks.enumerated().map { index, track in
      AlbumDetailTrackRow(number: index + 1, track: track)
    }
  }

  public var body: some View {
    GeometryReader { proxy in
      ScrollView {
        VStack(spacing: 30) {
          VStack(spacing: 16) {
            ZoomableAlbumArtworkView(
              album: self.album,
              size: self.artworkSize(for: proxy.size.width),
              cornerRadius: 16,
              transitionID: self.artworkTransitionID,
              role: .destination,
            )

            VStack(spacing: 5) {
              Text(self.album.title)
                .font(
                  .system(
                    size: 26,
                    weight: .bold,
                    design: .rounded,
                  ),
                )
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(3)

              Text(self.album.artist)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            }
            .padding(.horizontal, 28)

            AlbumDetailPlayButton(
              isPlaying: self.isPlaying,
              isLoading: self.isLoading,
              palette: self.album.artworkPalette,
              onTap: self.onPlayTap,
            )
            .padding(.horizontal, 20)
            .padding(.top, 4)
          }
          .frame(maxWidth: .infinity)
          .padding(.top, proxy.frame(in: .global).minY + 18)
          .padding(.bottom, 24)
          .background {
            if let backgroundColor = self.album.artworkPalette?
              .backgroundColor {
              LinearGradient(
                colors: [
                  .clear,
                  backgroundColor.opacity(0.3),
                ],
                startPoint: .top,
                endPoint: .bottom,
              )
              .ignoresSafeArea(edges: .top)
            }
          }

          if self.rows.isEmpty {
            AlbumDetailEmptyTracksView(
              isLoading: self.isLoadingTracks,
            )
            .padding(.horizontal, 20)
          } else {
            VStack(spacing: 0) {
              ForEach(self.rows) { row in
                AlbumDetailTrackRowView(
                  row: row,
                  isCurrent: row.track.id
                    == self.currentTrackID,
                  isPlaying: self.isPlaying
                    && row.track.id == self.currentTrackID,
                  palette: self.album.artworkPalette,
                ) {
                  self.onTrackTap(row.track.id)
                }
              }
            }
          }
        }
        .padding(.bottom, 112)
      }
      .background(.background)
      .ignoresSafeArea(edges: .top)
    }
    .navigationTitle("")
    .albumDetailNavigationBarBackground()
  }

  private func artworkSize(for containerWidth: CGFloat) -> CGFloat {
    min(320, max(220, containerWidth - 96))
  }

  private var artworkTransitionID: String {
    albumArtworkZoomTransitionID(
      for: self.transitionSourceID ?? self.album.id,
    )
  }
}

private extension View {
  @ViewBuilder
  func albumDetailNavigationBarBackground() -> some View {
    #if os(iOS)
      self.toolbarBackground(.hidden, for: .navigationBar)
    #else
      self
    #endif
  }
}

private struct AlbumDetailPlayButton: View {
  @Environment(\.self) private var environment

  let isPlaying: Bool
  let isLoading: Bool
  let palette: ArtworkPalette?
  let onTap: @MainActor @Sendable () -> Void

  var body: some View {
    let colors = self.colors

    Button(action: self.onTap) {
      HStack(spacing: 8) {
        if self.isLoading {
          ProgressView()
            .controlSize(.small)
            .tint(colors.foreground)
        } else {
          Image(
            systemName: self.isPlaying
              ? "pause.fill" : "play.fill",
          )
        }

        Text(self.title)
      }
      .font(.system(size: 17, weight: .bold, design: .rounded))
      .frame(maxWidth: .infinity)
      .frame(height: 52)
      .foregroundStyle(colors.foreground)
      .background(colors.background, in: Capsule())
      .contentShape(Capsule())
    }
    .buttonStyle(.plain)
    .disabled(self.isLoading)
  }

  private var colors: AlbumDetailPlayButtonColors {
    guard let paletteColors = self.palette?.orderedColors(in: self.environment) else {
      return self.environment.colorScheme == .dark
        ? AlbumDetailPlayButtonColors(background: .white, foreground: .black)
        : AlbumDetailPlayButtonColors(background: .black, foreground: .white)
    }

    if self.environment.colorScheme == .dark {
      return AlbumDetailPlayButtonColors(
        background: paletteColors.lighter,
        foreground: paletteColors.darker,
      )
    }

    return AlbumDetailPlayButtonColors(
      background: paletteColors.darker,
      foreground: paletteColors.lighter,
    )
  }

  private var title: String {
    if self.isLoading { return "Loading" }
    return self.isPlaying ? "Playing" : "Play"
  }
}

private struct AlbumDetailPlayButtonColors {
  let background: Color
  let foreground: Color
}

private struct AlbumDetailTrackRow: Identifiable, Equatable {
  let number: Int
  let track: TrackData

  var id: String { self.track.id }
}

private struct AlbumDetailTrackRowView: View {
  @Environment(\.self) private var environment

  let row: AlbumDetailTrackRow
  let isCurrent: Bool
  let isPlaying: Bool
  let palette: ArtworkPalette?
  let onTap: @MainActor @Sendable () -> Void

  var body: some View {
    let currentTrackStyle = self.currentTrackStyle

    Button(action: self.onTap) {
      HStack(spacing: 12) {
        Group {
          if self.isCurrent {
            AlbumDetailWaveformView(
              isPlaying: self.isPlaying,
              color: currentTrackStyle.text,
            )
          } else {
            Text(self.row.number, format: .number)
              .font(
                .system(
                  size: 14,
                  weight: .semibold,
                  design: .rounded,
                ),
              )
              .monospacedDigit()
              .foregroundStyle(.secondary)
          }
        }
        .frame(width: 24, alignment: .trailing)

        VStack(alignment: .leading, spacing: 3) {
          Text(self.row.track.title)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(
              self.isCurrent
                ? currentTrackStyle.text : .primary,
            )
            .lineLimit(2)

          Text(self.row.track.artist)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(
              self.isCurrent
                ? currentTrackStyle.secondaryText : .secondary,
            )
            .lineLimit(1)
        }

        Spacer(minLength: 0)
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 12)
      .background {
        if self.isCurrent {
          RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(currentTrackStyle.background)
            .padding(.horizontal, 10)
        }
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(
      "\(self.accessibilityPlaybackPrefix)\(self.row.number). \(self.row.track.title), \(self.row.track.artist)",
    )
  }

  private var currentTrackStyle: AlbumDetailCurrentTrackStyle {
    guard let paletteColors = self.palette?.orderedColors(in: self.environment) else {
      return AlbumDetailCurrentTrackStyle(
        background: Color.gertrudeBrandAccent.opacity(0.10),
        text: .gertrudeBrandAccent,
        secondaryText: .secondary,
      )
    }

    let highlightColor = self.environment.colorScheme == .dark
      ? paletteColors.darker : paletteColors.lighter
    let foregroundColor = self.environment.colorScheme == .dark
      ? paletteColors.lighter : paletteColors.darker

    return AlbumDetailCurrentTrackStyle(
      background: highlightColor.opacity(0.5),
      text: foregroundColor,
      secondaryText: foregroundColor.opacity(0.65),
    )
  }

  private var accessibilityPlaybackPrefix: String {
    if self.isPlaying { return "Playing, " }
    if self.isCurrent { return "Paused, " }
    return ""
  }
}

private struct AlbumDetailCurrentTrackStyle {
  let background: Color
  let text: Color
  let secondaryText: Color
}

private struct AlbumDetailWaveformView: View {
  let isPlaying: Bool
  let color: Color

  var body: some View {
    if self.isPlaying {
      TimelineView(.animation) { timeline in
        self.bars(date: timeline.date)
      }
    } else {
      self.bars(date: nil)
    }
  }

  private func bars(date: Date?) -> some View {
    HStack(alignment: .center, spacing: 2) {
      ForEach(0 ..< 4, id: \.self) { index in
        RoundedRectangle(cornerRadius: 1.5, style: .continuous)
          .fill(self.color)
          .frame(
            width: 3,
            height: self.barHeight(index: index, date: date),
          )
      }
    }
    .frame(width: 24, height: 24)
  }

  private func barHeight(index: Int, date: Date?) -> CGFloat {
    guard let date else { return 4 }
    let phase =
      date.timeIntervalSinceReferenceDate * 5.5 + Double(index) * 0.85
    let progress = (sin(phase) + 1) / 2
    return 6 + CGFloat(progress) * 10
  }
}

private struct AlbumDetailEmptyTracksView: View {
  let isLoading: Bool

  var body: some View {
    VStack(spacing: 10) {
      if self.isLoading {
        ProgressView()
      }

      Text(self.isLoading ? "Loading tracks" : "No tracks yet")
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(24)
    .background(
      .primary.opacity(0.05),
      in: .rect(cornerRadius: 24, style: .continuous),
    )
  }
}

#if DEBUG
  #Preview("Album detail") {
    NavigationStack {
      AlbumDetailView(
        album: [AlbumData].previewAlbums[0],
        tracks: .previewTracks,
      )
    }
  }

  #Preview("Album detail playing") {
    NavigationStack {
      AlbumDetailView(
        album: [AlbumData].previewAlbums[0],
        tracks: .previewTracks,
        isPlaying: true,
        currentTrackID: [TrackData].previewTracks[2].id,
      )
    }
  }

  #Preview("Album detail loading tracks") {
    NavigationStack {
      AlbumDetailView(
        album: [AlbumData].previewAlbums[0],
        tracks: [],
        isLoading: true,
        isLoadingTracks: true,
      )
    }
  }
#endif
