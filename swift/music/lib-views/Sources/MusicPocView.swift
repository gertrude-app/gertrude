import SwiftUI

public struct MusicPocTrackViewState: Equatable, Sendable {
  public let id: String
  public let title: String
  public let artist: String
  public let artworkURL: URL?
  public let blocksArtwork: Bool
  public let isPlaying: Bool
  public let isStarting: Bool

  public init(
    id: String,
    title: String,
    artist: String,
    artworkURL: URL?,
    blocksArtwork: Bool,
    isPlaying: Bool,
    isStarting: Bool,
  ) {
    self.id = id
    self.title = title
    self.artist = artist
    self.artworkURL = artworkURL
    self.blocksArtwork = blocksArtwork
    self.isPlaying = isPlaying
    self.isStarting = isStarting
  }
}

public enum MusicPocViewState: Equatable {
  case needsAuthorization
  case authorizing
  case readyToPlay(MusicPocTrackViewState)
  case denied
  case failed(String)
}

public struct MusicPocView: View {
  private let state: MusicPocViewState
  private let onAuthorizeTap: () -> Void
  private let onPlayPauseTap: () -> Void
  private let onArtworkBlockingChanged: (Bool) -> Void

  public init(
    state: MusicPocViewState,
    onAuthorizeTap: @escaping () -> Void,
    onPlayPauseTap: @escaping () -> Void,
    onArtworkBlockingChanged: @escaping (Bool) -> Void,
  ) {
    self.state = state
    self.onAuthorizeTap = onAuthorizeTap
    self.onPlayPauseTap = onPlayPauseTap
    self.onArtworkBlockingChanged = onArtworkBlockingChanged
  }

  public var body: some View {
    VStack(spacing: 24) {
      VStack(spacing: 8) {
        Text("Gertrude FM")
          .font(.largeTitle.bold())

        Text("Apple Music playback proof of concept")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      self.controls
    }
    .multilineTextAlignment(.center)
    .padding(32)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  @ViewBuilder private var controls: some View {
    switch self.state {
    case .needsAuthorization:
      Button("Authorize Apple Music", action: self.onAuthorizeTap)
        .buttonStyle(.borderedProminent)

    case .authorizing:
      ProgressView("Requesting Apple Music access…")

    case .readyToPlay(let track):
      TrackCard(
        track: track,
        onPlayPauseTap: self.onPlayPauseTap,
        onArtworkBlockingChanged: self.onArtworkBlockingChanged,
      )

    case .denied:
      Text("Apple Music access was denied.")
        .font(.headline)
        .foregroundStyle(.red)

    case .failed(let message):
      VStack(spacing: 8) {
        Text("Something went wrong.")
          .font(.headline)
        Text(message)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
  }
}

private struct TrackCard: View {
  let track: MusicPocTrackViewState
  let onPlayPauseTap: () -> Void
  let onArtworkBlockingChanged: (Bool) -> Void

  var body: some View {
    VStack(spacing: 18) {
      self.artwork

      VStack(spacing: 5) {
        Text(self.track.title)
          .font(.title3.bold())
          .lineLimit(2)

        Text(self.track.artist)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      Toggle(
        "Block album art",
        isOn: Binding(
          get: { self.track.blocksArtwork },
          set: { value in self.onArtworkBlockingChanged(value) },
        ),
      )
      .toggleStyle(.switch)
      .font(.subheadline)
      .padding(.horizontal, 4)

      Button(action: self.onPlayPauseTap) {
        HStack(spacing: 8) {
          if self.track.isStarting {
            ProgressView()
              .controlSize(.small)
          } else {
            Image(systemName: self.track.isPlaying ? "pause.fill" : "play.fill")
          }
          Text(self.track.isPlaying ? "Pause" : "Play")
        }
        .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .disabled(self.track.isStarting)
    }
    .padding(20)
    .frame(maxWidth: 280)
    .background(.thinMaterial, in: .rect(cornerRadius: 28))
  }

  @ViewBuilder private var artwork: some View {
    if self.track.blocksArtwork {
      FallbackArtwork()
    } else if let artworkURL = self.track.artworkURL {
      AsyncImage(url: artworkURL) { phase in
        switch phase {
        case .success(let image):
          image
            .resizable()
            .scaledToFill()
        case .failure, .empty:
          FallbackArtwork()
        @unknown default:
          FallbackArtwork()
        }
      }
      .frame(width: 176, height: 176)
      .clipShape(.rect(cornerRadius: 28))
    } else {
      FallbackArtwork()
    }
  }
}

private struct FallbackArtwork: View {
  var body: some View {
    ZStack {
      LinearGradient(
        colors: [.gray.opacity(0.35), .gray.opacity(0.12)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing,
      )

      Image(systemName: "music.note")
        .font(.system(size: 46, weight: .semibold))
        .foregroundStyle(.secondary)
    }
    .frame(width: 176, height: 176)
    .clipShape(.rect(cornerRadius: 28))
  }
}

private let previewTrack = MusicPocTrackViewState(
  id: "1758369112",
  title: "See You Again",
  artist: "The Gray Havens",
  artworkURL: URL(string: "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/75/1d/a6/751da645-a25f-3545-9871-93c94cc3d658/12453.jpg/600x600bb.jpg"),
  blocksArtwork: false,
  isPlaying: false,
  isStarting: false,
)

#Preview("Needs authorization") {
  MusicPocView(
    state: .needsAuthorization,
    onAuthorizeTap: {},
    onPlayPauseTap: {},
    onArtworkBlockingChanged: { _ in },
  )
}

#Preview("Authorizing") {
  MusicPocView(
    state: .authorizing,
    onAuthorizeTap: {},
    onPlayPauseTap: {},
    onArtworkBlockingChanged: { _ in },
  )
}

#Preview("Ready to play") {
  MusicPocView(
    state: .readyToPlay(previewTrack),
    onAuthorizeTap: {},
    onPlayPauseTap: {},
    onArtworkBlockingChanged: { _ in },
  )
}

#Preview("Blocked") {
  MusicPocView(
    state: .readyToPlay(
      MusicPocTrackViewState(
        id: previewTrack.id,
        title: previewTrack.title,
        artist: previewTrack.artist,
        artworkURL: previewTrack.artworkURL,
        blocksArtwork: true,
        isPlaying: true,
        isStarting: false,
      ),
    ),
    onAuthorizeTap: {},
    onPlayPauseTap: {},
    onArtworkBlockingChanged: { _ in },
  )
}

#Preview("Denied") {
  MusicPocView(
    state: .denied,
    onAuthorizeTap: {},
    onPlayPauseTap: {},
    onArtworkBlockingChanged: { _ in },
  )
}

#Preview("Failed") {
  MusicPocView(
    state: .failed("Unable to start playback."),
    onAuthorizeTap: {},
    onPlayPauseTap: {},
    onArtworkBlockingChanged: { _ in },
  )
}
