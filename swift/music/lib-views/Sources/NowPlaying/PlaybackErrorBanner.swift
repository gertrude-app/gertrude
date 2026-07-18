import SwiftUI

public struct PlaybackErrorBanner: View {
  private let title: String
  private let message: String
  private let systemImage: String
  private let actionTitle: String?
  private let onActionTap: @MainActor @Sendable () -> Void
  private let onDismissTap: @MainActor @Sendable () -> Void

  public init(
    title: String,
    message: String,
    systemImage: String = "exclamationmark.circle.fill",
    actionTitle: String? = nil,
    onActionTap: @MainActor @escaping @Sendable () -> Void = {},
    onDismissTap: @MainActor @escaping @Sendable () -> Void = {},
  ) {
    self.title = title
    self.message = message
    self.systemImage = systemImage
    self.actionTitle = actionTitle
    self.onActionTap = onActionTap
    self.onDismissTap = onDismissTap
  }

  public var body: some View {
    HStack(alignment: .top, spacing: 13) {
      Image(systemName: self.systemImage)
        .font(.system(size: 19, weight: .bold))
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(Color.gertrudeBrandAccent)
        .frame(width: 34, height: 34)
        .background(Color.gertrudeBrandAccent.opacity(0.13), in: Circle())
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 9) {
        VStack(alignment: .leading, spacing: 3) {
          Text(self.title)
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(.primary)
            .lineLimit(2)

          Text(self.message)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }

        if let actionTitle {
          Button(actionTitle, action: self.onActionTap)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .tint(.gertrudeBrandAccent)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      Button(action: self.onDismissTap) {
        Image(systemName: "xmark")
          .font(.system(size: 12, weight: .bold))
          .foregroundStyle(.secondary)
          .frame(width: 28, height: 28)
          .background(.primary.opacity(0.06), in: Circle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Dismiss")
    }
    .padding(.leading, 14)
    .padding(.trailing, 10)
    .padding(.vertical, 13)
    .background(.regularMaterial, in: .rect(cornerRadius: 22, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .strokeBorder(.primary.opacity(0.07), lineWidth: 1)
    }
    .shadow(color: .black.opacity(0.14), radius: 18, x: 0, y: 8)
    .accessibilityElement(children: .combine)
  }
}

#if DEBUG
  #Preview("Apple Music access") {
    VStack(spacing: 18) {
      PlaybackErrorBanner(
        title: "Apple Music access needed",
        message: "Allow Gertrude Music to use Apple Music so approved music can play.",
        systemImage: "music.note.list",
        actionTitle: "Open Settings",
      )

      PlaybackErrorBanner(
        title: "Song unavailable",
        message: "This song isn’t available from Apple Music right now. Try another approved track.",
        systemImage: "exclamationmark.triangle.fill",
      )
    }
    .padding(20)
    .background(.background)
  }

  #Preview("Over now playing") {
    ZStack(alignment: .top) {
      NowPlayingScreenView(
        title: PreviewMusicData.nowPlayingTitle,
        artist: PreviewMusicData.nowPlayingArtist,
        artworkURL: PreviewMusicData.nowPlayingArtworkURL,
        isPlaying: true,
        isLoading: false,
        progress: 0.38,
        duration: 214,
        onPlayPauseTap: {},
        onPreviousTap: {},
        onNextTap: {},
        onScrub: { _ in },
      )

      PlaybackErrorBanner(
        title: "Couldn’t start playback",
        message: "Check your connection and try again.",
        systemImage: "wifi.exclamationmark",
        actionTitle: "Try Again",
      )
      .padding(.horizontal, 18)
      .padding(.top, 18)
    }
  }

  #Preview("Over album detail") {
    NavigationStack {
      ZStack(alignment: .top) {
        AlbumDetailView(
          album: [AlbumData].previewAlbums[0],
          tracks: .previewTracks,
        )

        PlaybackErrorBanner(
          title: "Apple Music access needed",
          message: "Allow Gertrude Music to use Apple Music so approved music can play.",
          systemImage: "music.note.list",
          actionTitle: "Open Settings",
        )
        .padding(.horizontal, 18)
        .padding(.top, 12)
      }
    }
  }

  #Preview("Dark") {
    PlaybackErrorBanner(
      title: "Apple Music subscription required",
      message: "This device needs an active Apple Music subscription to play approved music.",
      systemImage: "person.crop.circle.badge.exclamationmark",
      actionTitle: "Learn More",
    )
    .padding(20)
    .background(Color.black)
    .preferredColorScheme(.dark)
  }
#endif
