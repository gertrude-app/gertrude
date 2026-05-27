import SwiftUI

public enum LibraryViewState: Equatable, Sendable {
  case loading
  case loaded(albums: [AlbumData], artists: [ArtistData], tracks: [TrackData])
  case empty
  case failed
}

public struct LibraryView: View {
  private let state: LibraryViewState
  private let transitionNamespace: Namespace.ID?
  private let onRetryTap: @MainActor @Sendable () -> Void
  private let onAlbumsTitleTap: @MainActor @Sendable () -> Void
  private let onAlbumTap: @MainActor @Sendable (String) -> Void
  private let onArtistsTitleTap: @MainActor @Sendable () -> Void
  private let onArtistTap: @MainActor @Sendable (String) -> Void
  private let onTracksTitleTap: @MainActor @Sendable () -> Void
  private let onTrackTap: @MainActor @Sendable (String) -> Void

  public init(
    state: LibraryViewState,
    transitionNamespace: Namespace.ID? = nil,
    onRetryTap: @MainActor @escaping @Sendable () -> Void = {},
    onAlbumsTitleTap: @MainActor @escaping @Sendable () -> Void = {},
    onAlbumTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onArtistsTitleTap: @MainActor @escaping @Sendable () -> Void = {},
    onArtistTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onTracksTitleTap: @MainActor @escaping @Sendable () -> Void = {},
    onTrackTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
  ) {
    self.state = state
    self.transitionNamespace = transitionNamespace
    self.onRetryTap = onRetryTap
    self.onAlbumsTitleTap = onAlbumsTitleTap
    self.onAlbumTap = onAlbumTap
    self.onArtistsTitleTap = onArtistsTitleTap
    self.onArtistTap = onArtistTap
    self.onTracksTitleTap = onTracksTitleTap
    self.onTrackTap = onTrackTap
  }

  public var body: some View {
    ScrollView {
      self.content
        .padding(.vertical, 24)
    }
    .background(.background)
    .navigationTitle("My Music")
  }

  @ViewBuilder private var content: some View {
    switch self.state {
    case .loading:
      VStack(alignment: .leading, spacing: 34) {
        AlbumShelfView(albums: [], isLoading: true)
        ArtistShelfView(artists: [], isLoading: true)
        TrackShelfView(tracks: [], isLoading: true)
      }

    case .loaded(let albums, let artists, let tracks):
      VStack(alignment: .leading, spacing: 34) {
        AlbumShelfView(
          albums: albums,
          transitionNamespace: self.transitionNamespace,
          onTitleTap: self.onAlbumsTitleTap,
          onAlbumTap: self.onAlbumTap,
        )

        ArtistShelfView(
          artists: artists,
          transitionNamespace: self.transitionNamespace,
          onTitleTap: self.onArtistsTitleTap,
          onArtistTap: self.onArtistTap,
        )

        TrackShelfView(
          tracks: tracks,
          transitionNamespace: self.transitionNamespace,
          onTitleTap: self.onTracksTitleTap,
          onTrackTap: self.onTrackTap,
        )
      }

    case .empty:
      LibraryMessageCard(
        title: "No music yet",
        message: "Approved songs, albums, and artists will appear here after a parent adds them in Gertrude.",
        systemImage: "music.note.house",
        buttonTitle: "Check again",
        onButtonTap: self.onRetryTap,
      )
      .padding(.horizontal, 20)
      .padding(.top, 48)

    case .failed:
      LibraryMessageCard(
        title: "Couldn’t load music",
        message: "Check your connection and try again.",
        systemImage: "wifi.exclamationmark",
        buttonTitle: "Try again",
        onButtonTap: self.onRetryTap,
      )
      .padding(.horizontal, 20)
      .padding(.top, 48)
    }
  }
}

private struct LibraryMessageCard: View {
  let title: String
  let message: String
  let systemImage: String
  var buttonTitle: String?
  var onButtonTap: @MainActor @Sendable () -> Void = {}

  var body: some View {
    VStack(spacing: 16) {
      ZStack {
        Circle()
          .fill(.primary.opacity(0.06))
          .frame(width: 76, height: 76)

        Image(systemName: self.systemImage)
          .font(.system(size: 30, weight: .semibold))
          .foregroundStyle(.secondary)
      }

      VStack(spacing: 6) {
        Text(self.title)
          .font(.system(size: 22, weight: .bold, design: .rounded))
          .foregroundStyle(.primary)

        Text(self.message)
          .font(.system(size: 15, weight: .medium))
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
      }

      if let buttonTitle {
        Button(buttonTitle, action: self.onButtonTap)
          .buttonStyle(.borderedProminent)
          .padding(.top, 4)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(28)
    .background(.primary.opacity(0.05), in: .rect(cornerRadius: 28, style: .continuous))
  }
}

#Preview("Loaded") {
  NavigationStack {
    LibraryView(
      state: .loaded(
        albums: .previewAlbums,
        artists: .previewArtists,
        tracks: .previewTracks,
      ),
    )
  }
}

#Preview("Loading") {
  NavigationStack {
    LibraryView(state: .loading)
  }
}

#Preview("Empty") {
  NavigationStack {
    LibraryView(state: .empty)
  }
}

#Preview("Failed") {
  NavigationStack {
    LibraryView(state: .failed)
  }
}
