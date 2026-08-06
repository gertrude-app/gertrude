import SwiftUI

struct TrackRowView: View {
  let number: String?
  let track: TrackData
  let showsArtwork: Bool
  let isCurrent: Bool
  let isPlaying: Bool
  let palette: ArtworkPalette?
  let retainsPreviousArtwork: Bool
  let onTap: (@MainActor @Sendable () -> Void)?

  init(
    number: String?,
    track: TrackData,
    showsArtwork: Bool,
    isCurrent: Bool,
    isPlaying: Bool,
    palette: ArtworkPalette?,
    retainsPreviousArtwork: Bool = false,
    onTap: (@MainActor @Sendable () -> Void)? = nil,
  ) {
    self.number = number
    self.track = track
    self.showsArtwork = showsArtwork
    self.isCurrent = isCurrent
    self.isPlaying = isPlaying
    self.palette = palette
    self.retainsPreviousArtwork = retainsPreviousArtwork
    self.onTap = onTap
  }

  var body: some View {
    if let onTap {
      Button(action: onTap) {
        self.rowContent
      }
      .buttonStyle(.plain)
      .accessibilityLabel(self.accessibilityLabel)
    } else {
      self.rowContent
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(self.accessibilityLabel)
    }
  }

  private var rowContent: some View {
    TrackRowContent(
      number: self.number,
      track: self.track,
      showsArtwork: self.showsArtwork,
      isCurrent: self.isCurrent,
      isPlaying: self.isPlaying,
      palette: self.palette,
      retainsPreviousArtwork: self.retainsPreviousArtwork,
    )
  }

  private var accessibilityLabel: String {
    let number = self.number.map { "\($0). " } ?? ""
    let duration = self.track.duration?.nonEmpty.map { ", \($0)" } ?? ""
    return "\(self.accessibilityPlaybackPrefix)\(number)\(self.track.title), \(self.track.artist)\(duration)"
  }

  private var accessibilityPlaybackPrefix: String {
    if self.isPlaying { return "Playing, " }
    if self.isCurrent { return "Paused, " }
    return ""
  }
}

private struct TrackRowContent: View {
  @Environment(\.self) private var environment

  let number: String?
  let track: TrackData
  let showsArtwork: Bool
  let isCurrent: Bool
  let isPlaying: Bool
  let palette: ArtworkPalette?
  let retainsPreviousArtwork: Bool

  var body: some View {
    let currentTrackStyle = self.currentTrackStyle

    HStack(spacing: 12) {
      Group {
        if self.isCurrent {
          TrackRowWaveformView(
            isPlaying: self.isPlaying,
            color: currentTrackStyle.text,
          )
        } else if let number {
          Text(number)
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

      if self.showsArtwork {
        TrackRowArtworkView(
          url: self.track.artworkUrl,
          retainsPreviousImage: self.retainsPreviousArtwork,
        )
      }

      VStack(alignment: .leading, spacing: 3) {
        Text(self.track.title)
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(
            self.isCurrent ? currentTrackStyle.text : .primary,
          )
          .lineLimit(2)

        Text(self.track.artist)
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(
            self.isCurrent ? currentTrackStyle.secondaryText : .secondary,
          )
          .lineLimit(1)
      }

      Spacer(minLength: 8)

      if let duration = self.track.duration?.nonEmpty {
        Text(duration)
          .font(.caption.monospacedDigit().weight(.medium))
          .foregroundStyle(
            self.isCurrent ? currentTrackStyle.secondaryText : .secondary,
          )
          .lineLimit(1)
      }
    }
    .padding(.leading, 20)
    .padding(.trailing, 24)
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

  private var currentTrackStyle: TrackRowCurrentStyle {
    guard let paletteColors = self.palette?.orderedColors(in: self.environment) else {
      return TrackRowCurrentStyle(
        background: Color.gertrudeBrandAccent.opacity(0.10),
        text: .gertrudeBrandAccent,
        secondaryText: Color.gertrudeBrandAccent.opacity(0.65),
      )
    }

    let highlightColor = self.environment.colorScheme == .dark
      ? paletteColors.darker : paletteColors.lighter
    let foregroundColor = self.environment.colorScheme == .dark
      ? paletteColors.lighter : paletteColors.darker

    return TrackRowCurrentStyle(
      background: highlightColor.opacity(0.5),
      text: foregroundColor,
      secondaryText: foregroundColor.opacity(0.65),
    )
  }
}

private struct TrackRowCurrentStyle {
  let background: Color
  let text: Color
  let secondaryText: Color
}

private struct TrackRowWaveformView: View {
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

private struct TrackRowArtworkView: View {
  let url: URL?
  let retainsPreviousImage: Bool

  var body: some View {
    CachedArtworkImageView(
      url: self.url,
      retainsPreviousImage: self.retainsPreviousImage,
    ) { image in
      image
        .resizable()
        .scaledToFill()
        .frame(width: 44, height: 44)
        .clipShape(.rect(cornerRadius: 8, style: .continuous))
    } placeholder: {
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(Color.gertrudeBrandAccent.opacity(0.14))
        .frame(width: 44, height: 44)
        .overlay {
          Image(systemName: "music.note")
            .foregroundStyle(Color.gertrudeBrandAccent)
        }
    }
    .accessibilityHidden(true)
    .transaction { transaction in
      if self.retainsPreviousImage {
        transaction.animation = nil
      }
    }
  }
}
