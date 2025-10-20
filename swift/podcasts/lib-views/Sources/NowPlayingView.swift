import SwiftUI

public struct NowPlayingView: View, EpisodeArtworkProvider {
  @Environment(\.colorScheme) var cs
  @State private var dragOffset: CGFloat = 0

  let episode: EpisodeData
  let show: ShowData
  let minimized: Bool
  let emit: @MainActor @Sendable (Event) -> Void

  public enum Event: Equatable {
    case playPauseTapped
    case skipBackwardTapped
    case skipForwardTapped
    case dismissed
    case miniPlayerTapped
    case scrubbed(to: Double)
  }

  public init(
    episode: EpisodeData,
    show: ShowData,
    minimized: Bool = true,
    emit: @MainActor @Sendable @escaping (Event) -> Void
  ) {
    self.episode = episode
    self.minimized = minimized
    self.show = show
    self.emit = emit
  }

  public var body: some View {
    ZStack {
      // Background only for expanded mode
      if !self.minimized {
        Color(self.cs, light: .violet100, dark: .violet900)
          .ignoresSafeArea(.all)
          .offset(y: self.minimized ? 300 : 0)
      }

      // Expanded player content (behind)
      self.expandedPlayerContent
        .opacity(self.minimized ? 0 : 1)
        .scaleEffect(self.minimized ? 0.9 : 1.0)
        .offset(y: self.minimized ? 300 : max(0, self.dragOffset))

      // Mini player (in front when minimized)
      if self.minimized {
        VStack {
          Spacer()
          self.miniPlayerContent
        }
        .opacity(self.minimized ? 1 : 0)
        .offset(y: self.minimized ? 0 : 20)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: self.minimized ? nil : .infinity)
    .animation(.nowPlayingSpring, value: self.minimized)
    .gesture(
      DragGesture()
        .onChanged { value in
          // Only respond to downward drags when expanded
          if !self.minimized, value.translation.height > 0 {
            self.dragOffset = value.translation.height
          }
        }
        .onEnded { value in
          // Dismiss if dragged down more than 100 points
          if !self.minimized, value.translation.height > 100 {
            self.emit(.dismissed)
          }
          // Reset drag offset with animation
          withAnimation(.nowPlayingSpring) {
            self.dragOffset = 0
          }
        }
    )
  }

  private var miniPlayerContent: some View {
    HStack(spacing: 12) {
      ArtworkView(provider: self, size: 44, cornerRadius: 4)

      // Episode info
      VStack(alignment: .leading, spacing: 2) {
        Text(self.episode.title)
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(Color(self.cs, light: .violet950, dark: .violet100))
          .lineLimit(1)

        if self.episode.downloadState == .downloading {
          Text("Downloading...")
            .font(.system(size: 12, weight: .regular))
            .italic()
            .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet400))
            .lineLimit(1)
        } else {
          Text(self.episode.pubDateRelative.uppercased())
            .font(.system(size: 12, weight: .regular))
            .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet400))
            .lineLimit(1)
        }
      }

      Spacer()

      // Play/pause or downloading button
      if self.episode.downloadState == .downloading {
        Image(systemName: "arrow.2.circlepath")
          .font(.system(size: 18, weight: .medium))
          .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
          .rotatingDownloadIcon()
          .padding(.trailing, 4)
      } else {
        Button(action: {
          self.emit(.playPauseTapped)
        }) {
          Image(systemName: self.episode.isPlaying ? "pause.fill" : "play.fill")
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
        }
        .padding(.trailing, 4)
      }
    }
    .padding(.leading, 8)
    .padding(.trailing, 12)
    .padding(.vertical, 8)
    .background(Color(self.cs, light: .white, dark: .black))
    .cornerRadius(8)
    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: -3)
    .padding(.horizontal, 16)
    .onTapGesture {
      self.emit(.miniPlayerTapped)
    }
  }

  private var expandedPlayerContent: some View {
    VStack(spacing: 0) {
      // Header
      HStack {
        Button(action: {
          self.emit(.dismissed)
        }) {
          Image(systemName: "chevron.down")
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
        }

        Spacer()

        VStack(spacing: 2) {
          Text("NOW PLAYING")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))

          Text(self.show.name)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color(self.cs, light: .violet700, dark: .violet300))
            .padding(.horizontal, 40)
            .lineLimit(1)
        }

        Spacer()

        Button(action: {
          // TODO: More actions
        }) {
          Image(systemName: "ellipsis")
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 20)
      .padding(.bottom, 40)

      Spacer()

      // Large artwork
      GeometryReader { geometry in
        let artworkSize = min(500, geometry.size.width * 0.9)
        ArtworkView(
          preferRemote: self.useEpisodeArtwork,
          artworkImage: self.show.artworkImage,
          artworkUrl: self.artworkUrl,
          size: artworkSize,
          cornerRadius: 8
        )
        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
      .aspectRatio(1, contentMode: .fit)
      .frame(maxWidth: 450, maxHeight: 450)

      Spacer()

      // Episode info
      VStack(spacing: 8) {
        Text(self.episode.title)
          .font(.system(size: 20, weight: .bold))
          .foregroundStyle(Color(self.cs, light: .violet950, dark: .violet100))
          .multilineTextAlignment(.center)
          .lineLimit(2)

        Text(self.show.author ?? self.show.name)
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet400))
          .lineLimit(1)
      }
      .padding(.horizontal, 40)
      .padding(.top, 24)
      .padding(.bottom, 20)

      Spacer()

      // Progress bar with draggable thumb
      VStack(spacing: 8) {
        GeometryReader { geometry in
          ZStack(alignment: .leading) {
            // Background track
            RoundedRectangle(cornerRadius: 2)
              .fill(Color(self.cs, light: .violet200, dark: .violet700))
              .frame(height: 4)

            // Progress fill
            let progressWidth = geometry.size.width * self.episode.progressRatio
            RoundedRectangle(cornerRadius: 2)
              .fill(Color(self.cs, light: .violet500, dark: .violet400))
              .frame(width: progressWidth, height: 4)

            // Draggable thumb
            Circle()
              .fill(Color(self.cs, light: .violet500, dark: .violet400))
              .frame(width: 12, height: 12)
              .offset(x: progressWidth - 6) // Center the thumb on progress position
              .gesture(
                DragGesture()
                  .onChanged { value in
                    guard let duration = self.episode.durationSeconds else { return }
                    let percentage = max(0, min(1, value.location.x / geometry.size.width))
                    let location = percentage * Double(duration)
                    self.emit(.scrubbed(to: location))
                  }
              )
          }
        }
        .frame(height: 12)

        HStack {
          Text(self.episode.currentPlayerTimeString)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet400))

          Spacer()

          Text(self.episode.remainingPlayerTimeString)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet400))
        }
      }
      .padding(.horizontal, 40)

      // Controls
      HStack(spacing: 32) {
        Button(action: {
          self.emit(.skipBackwardTapped)
        }) {
          Image(systemName: "gobackward.15")
            .font(.system(size: 36, weight: .medium))
            .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
        }

        Button(action: {
          self.emit(.playPauseTapped)
        }) {
          Image(systemName: self.episode.isPlaying ? "pause.circle.fill" : "play.circle.fill")
            .font(.system(size: 100, weight: .medium))
            .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
        }

        Button(action: {
          self.emit(.skipForwardTapped)
        }) {
          Image(systemName: "goforward.30")
            .font(.system(size: 36, weight: .medium))
            .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
        }
      }
      .padding(.top, 32)
      .padding(.bottom, 40)
    }
  }
}

#Preview("Mini Player") {
  NowPlayingView(
    episode: episode {
      $0.title = "Understanding SwiftUI State Management"
      $0.description = "Deep dive into @State, @Binding, and @ObservableObject"
      $0.durationSeconds = 2700
      $0.progress = 760
      $0.isPlaying = true
    },
    show: ShowData(
      id: 1,
      name: "Swift Talk",
      author: "objc.io",
      description: "Weekly Swift discussions",
      showArtwork: true,
      artworkUrl: nil
    ),
    minimized: true,
    emit: { _ in }
  )
  .padding()
  .background(Color.gray.opacity(0.1))
}

#Preview("Expanded Player") {
  NowPlayingView(
    episode: episode {
      $0.title = "Understanding SwiftUI State Management"
      $0.description = "Deep dive into @State, @Binding, and @ObservableObject"
      $0.durationSeconds = 2700
      $0.progress = 760
      $0.isPlaying = true
    },
    show: ShowData(
      id: 1,
      name: "Swift Talk",
      author: "objc.io",
      description: "Weekly Swift discussions",
      showArtwork: true,
      artworkUrl: nil
    ),
    minimized: false,
    emit: { _ in }
  )
}

#Preview("Mini Player - Playing") {
  NowPlayingView(
    episode: episode {
      $0.title = "Advanced iOS Architecture Patterns That Scale"
      $0.description = "MVVM, VIPER, TCA and more"
      $0.durationSeconds = 4800
      $0.progress = 1200
      $0.isPlaying = true
    },
    show: ShowData(
      id: 2,
      name: "iOS Dev Weekly Podcast",
      author: "Dave Verwer",
      description: "Weekly iOS development discussions",
      showArtwork: true
    ),
    minimized: true,
    emit: { _ in }
  )
  .padding()
  .background(Color.gray.opacity(0.1))
}

#Preview("Mini Player - Dark") {
  NowPlayingView(
    episode: episode {
      $0.title = "Understanding SwiftUI State Management"
      $0.description = "Deep dive into @State, @Binding, and @ObservableObject"
      $0.durationSeconds = 2700
      $0.progress = 760
      $0.isPlaying = true
    },
    show: ShowData(
      id: 1,
      name: "Swift Talk",
      author: "objc.io",
      description: "Weekly Swift discussions",
      showArtwork: true,
      artworkUrl: nil
    ),
    minimized: true,
    emit: { _ in }
  )
  .padding()
  .background(Color.gray.opacity(0.1))
  .preferredColorScheme(.dark)
}

#Preview("Expanded Player - Dark") {
  NowPlayingView(
    episode: episode {
      $0.title = "Understanding SwiftUI State Management"
      $0.description = "Deep dive into @State, @Binding, and @ObservableObject"
      $0.durationSeconds = 2700
      $0.progress = 760
      $0.isPlaying = true
    },
    show: ShowData(
      id: 1,
      name: "Swift Talk",
      author: "objc.io",
      description: "Weekly Swift discussions",
      showArtwork: true,
      artworkUrl: nil
    ),
    minimized: false,
    emit: { _ in }
  )
  .preferredColorScheme(.dark)
}

#Preview("Mini Player - Downloading") {
  NowPlayingView(
    episode: episode {
      $0.title = "Understanding SwiftUI State Management"
      $0.description = "Deep dive into @State, @Binding, and @ObservableObject"
      $0.durationSeconds = 2700
      $0.progress = 0
      $0.downloadState = .downloading
      $0.isPlaying = false
    },
    show: ShowData(
      id: 1,
      name: "Swift Talk",
      author: "objc.io",
      description: "Weekly Swift discussions",
      showArtwork: true,
      artworkUrl: nil
    ),
    minimized: true,
    emit: { _ in }
  )
  .padding()
  .background(Color.gray.opacity(0.1))
}

#Preview("Mini Player - Downloading (Dark)") {
  NowPlayingView(
    episode: episode {
      $0.title = "Understanding SwiftUI State Management"
      $0.description = "Deep dive into @State, @Binding, and @ObservableObject"
      $0.durationSeconds = 2700
      $0.progress = 0
      $0.downloadState = .downloading
      $0.isPlaying = false
    },
    show: ShowData(
      id: 1,
      name: "Swift Talk",
      author: "objc.io",
      description: "Weekly Swift discussions",
      showArtwork: true,
      artworkUrl: nil
    ),
    minimized: true,
    emit: { _ in }
  )
  .padding()
  .background(Color.gray.opacity(0.1))
  .preferredColorScheme(.dark)
}

#Preview("Animated Transition") {
  struct AnimatedPreview: View {
    @State private var isMinimized = true

    var body: some View {
      ZStack {
        // Background content
        VStack {
          Text("Main Content Area")
            .font(.title)
            .foregroundColor(.secondary)

          Rectangle()
            .fill(Color.blue.opacity(0.2))
            .frame(height: 200)
            .overlay(
              Text("Your app content here")
                .foregroundColor(.secondary)
            )

          Spacer()

          // Space for mini player
          Rectangle()
            .fill(Color.clear)
            .frame(height: 80)
        }
        .padding()
        .opacity(isMinimized ? 1 : 0.3)

        // Single NowPlayingView that handles its own transitions
        NowPlayingView(
          episode: episode {
            $0.title = "SwiftUI Animation Masterclass"
            $0.description = "Learn advanced animation techniques"
            $0.durationSeconds = 3120
            $0.progress = 1560
            $0.isPlaying = true
          },
          show: ShowData(
            id: 1,
            name: "Swift Tutorials",
            author: "iOS Academy",
            description: "Advanced Swift programming",
            showArtwork: true,
            artworkUrl: "https://example.com/artwork.jpg"
          ),
          minimized: isMinimized,
          emit: { event in
            if event == .miniPlayerTapped {
              isMinimized = false
            } else if event == .dismissed {
              isMinimized = true
            }
          }
        )
      }
      .background(Color.gray.opacity(0.1))
    }
  }

  return AnimatedPreview()
}
