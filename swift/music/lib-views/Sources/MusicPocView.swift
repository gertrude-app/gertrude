import SwiftUI

public enum MusicPocViewState: Equatable {
  case needsAuthorization
  case authorizing
  case readyToPlay
  case playing
  case denied
  case failed(String)
}

public struct MusicPocView: View {
  private let state: MusicPocViewState
  private let onAuthorizeTap: () -> Void
  private let onPlayTap: () -> Void

  public init(
    state: MusicPocViewState,
    onAuthorizeTap: @escaping () -> Void,
    onPlayTap: @escaping () -> Void,
  ) {
    self.state = state
    self.onAuthorizeTap = onAuthorizeTap
    self.onPlayTap = onPlayTap
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

    case .readyToPlay:
      Button("Play Test Song", action: self.onPlayTap)
        .buttonStyle(.borderedProminent)

    case .playing:
      VStack(spacing: 12) {
        Image(systemName: "music.note")
          .font(.largeTitle)
        Text("Playing test song")
          .font(.headline)
      }

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

#Preview("Needs authorization") {
  MusicPocView(
    state: .needsAuthorization,
    onAuthorizeTap: {},
    onPlayTap: {},
  )
}

#Preview("Authorizing") {
  MusicPocView(
    state: .authorizing,
    onAuthorizeTap: {},
    onPlayTap: {},
  )
}

#Preview("Ready to play") {
  MusicPocView(
    state: .readyToPlay,
    onAuthorizeTap: {},
    onPlayTap: {},
  )
}

#Preview("Playing") {
  MusicPocView(
    state: .playing,
    onAuthorizeTap: {},
    onPlayTap: {},
  )
}

#Preview("Denied") {
  MusicPocView(
    state: .denied,
    onAuthorizeTap: {},
    onPlayTap: {},
  )
}

#Preview("Failed") {
  MusicPocView(
    state: .failed("Unable to start playback."),
    onAuthorizeTap: {},
    onPlayTap: {},
  )
}
