import SwiftUI

struct AlbumDetailTrackRow: Identifiable, Equatable {
  let number: Int
  let track: TrackData

  var id: String { self.track.id }
}

struct AlbumDetailTrackRowView: View {
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
              self.isCurrent ? currentTrackStyle.text : .primary,
            )
            .lineLimit(2)

          Text(self.row.track.artist)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(
              self.isCurrent ? currentTrackStyle.secondaryText : .secondary,
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
    PlaybackWaveformView(
      isPlaying: self.isPlaying,
      color: self.color,
      barCount: 4,
      barWidth: 3,
      barSpacing: 2,
      minimumBarHeight: 4,
      maximumBarHeight: 16,
      containerWidth: 24,
      containerHeight: 24,
      alignment: .center,
      phaseStep: 0.85,
      minimumInterval: nil,
    )
  }
}

struct AlbumDetailEmptyTracksView: View {
  var body: some View {
    Text("No tracks yet")
      .font(.system(size: 15, weight: .semibold))
      .foregroundStyle(.secondary)
      .frame(maxWidth: .infinity)
      .padding(24)
      .background(
        .primary.opacity(0.05),
        in: .rect(cornerRadius: 24, style: .continuous),
      )
  }
}
