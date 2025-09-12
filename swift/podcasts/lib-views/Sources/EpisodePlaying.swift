import SwiftUI

public struct EpisodePlaying: View {
  @Environment(\.colorScheme) var cs

  public enum DisplayMode {
    case mini
    case expanded
  }

  let episode: EpisodeData
  let show: ShowData
  let mode: DisplayMode
  let emit: @MainActor @Sendable (Event) -> Void

  public enum Event {
    case playPauseTapped
    case skipBackward
    case skipForward
    case dismissed
    case expandTapped
  }

  public init(
    episode: EpisodeData,
    show: ShowData,
    mode: DisplayMode = .mini,
    emit: @MainActor @Sendable @escaping (Event) -> Void = { _ in }
  ) {
    self.episode = episode
    self.show = show
    self.mode = mode
    self.emit = emit
  }

  public var body: some View {
    switch self.mode {
    case .mini:
      self.miniPlayer
        .transition(.move(edge: .bottom).combined(with: .opacity))
    case .expanded:
      self.expandedPlayer
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
  }

  private var miniPlayer: some View {
    HStack(spacing: 12) {
      Group {
        if let artworkUrl = show.artworkUrl, let url = URL(string: artworkUrl) {
          AsyncImage(url: url) { image in
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
          } placeholder: {
            self.artworkPlaceholder
          }
        } else {
          self.artworkPlaceholder
        }
      }
      .frame(width: 44, height: 44)
      .cornerRadius(4)
      .clipped()

      // Episode info
      VStack(alignment: .leading, spacing: 2) {
        Text(self.episode.title)
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(Color(self.cs, light: .violet950, dark: .violet100))
          .lineLimit(1)

        Text(self.episode.relativeTime)
          .font(.system(size: 12, weight: .regular))
          .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet400))
          .lineLimit(1)
      }

      Spacer()

      // Play/pause button
      Button(action: {
        self.emit(.playPauseTapped)
      }) {
        Image(systemName: self.episode.isPlaying ? "pause.fill" : "play.fill")
          .font(.system(size: 20, weight: .medium))
          .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
      }
    }
    .padding(.leading, 8)
    .padding(.trailing, 12)
    .padding(.vertical, 8)
    .background(Color(self.cs, light: .white, dark: .black))
    .cornerRadius(8)
    .onTapGesture {
      self.emit(.expandTapped)
    }
  }

  private var expandedPlayer: some View {
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

          Text(self.show.title)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color(self.cs, light: .violet700, dark: .violet300))
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
      Group {
        if let artworkUrl = show.artworkUrl, let url = URL(string: artworkUrl) {
          AsyncImage(url: url) { image in
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
          } placeholder: {
            self.artworkPlaceholder
          }
        } else {
          self.artworkPlaceholder
        }
      }
      .frame(width: 280, height: 280)
      .cornerRadius(8)
      .clipped()
      .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)

      Spacer()

      // Episode info
      VStack(spacing: 8) {
        Text(self.episode.title)
          .font(.system(size: 20, weight: .bold))
          .foregroundStyle(Color(self.cs, light: .violet950, dark: .violet100))
          .multilineTextAlignment(.center)
          .lineLimit(2)

        Text(self.show.author ?? "Unknown Author")
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet400))
          .lineLimit(1)
      }
      .padding(.horizontal, 40)
      .padding(.top, 40)

      Spacer()

      // Progress bar placeholder
      VStack(spacing: 8) {
        RoundedRectangle(cornerRadius: 2)
          .fill(Color(self.cs, light: .violet200, dark: .violet700))
          .frame(height: 4)
          .overlay(
            HStack {
              RoundedRectangle(cornerRadius: 2)
                .fill(Color(self.cs, light: .violet500, dark: .violet400))
                .frame(width: 80)
              Spacer()
            }
          )

        HStack {
          Text("2:34")
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet400))

          Spacer()

          Text(self.episode.duration)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet400))
        }
      }
      .padding(.horizontal, 40)

      // Controls
      HStack(spacing: 40) {
        Button(action: {
          self.emit(.skipBackward)
        }) {
          Image(systemName: "gobackward.15")
            .font(.system(size: 24, weight: .medium))
            .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
        }

        Button(action: {
          self.emit(.playPauseTapped)
        }) {
          Image(systemName: self.episode.isPlaying ? "pause.circle.fill" : "play.circle.fill")
            .font(.system(size: 64, weight: .medium))
            .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
        }

        Button(action: {
          self.emit(.skipForward)
        }) {
          Image(systemName: "goforward.30")
            .font(.system(size: 24, weight: .medium))
            .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
        }
      }
      .padding(.top, 32)
      .padding(.bottom, 40)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(self.cs, light: .violet100, dark: .violet900))
  }

  private var artworkPlaceholder: some View {
    Rectangle()
      .fill(Color(self.cs, light: .violet200, dark: .violet800))
      .overlay(
        Image(systemName: "mic")
          .font(.system(size: self.mode == .mini ? 20 : 80, weight: .medium))
          .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet500))
      )
  }
}

#Preview("Mini Player") {
  EpisodePlaying(
    episode: EpisodeData(
      id: 1,
      title: "Understanding SwiftUI State Management",
      description: "Deep dive into @State, @Binding, and @ObservableObject",
      relativeTime: "2H AGO",
      duration: "45m",
      downloadState: .downloaded,
      isPlaying: true
    ),
    show: ShowData(
      id: 1,
      title: "Swift Talk",
      author: "objc.io",
      description: "Weekly Swift discussions",
      artworkUrl: nil
    ),
    mode: .mini
  )
  .padding()
  .background(Color.gray.opacity(0.1))
}

#Preview("Expanded Player") {
  EpisodePlaying(
    episode: EpisodeData(
      id: 1,
      title: "Understanding SwiftUI State Management",
      description: "Deep dive into @State, @Binding, and @ObservableObject",
      relativeTime: "2H AGO",
      duration: "45m",
      downloadState: .downloaded,
      isPlaying: true
    ),
    show: ShowData(
      id: 1,
      title: "Swift Talk",
      author: "objc.io",
      description: "Weekly Swift discussions",
      artworkUrl: nil
    ),
    mode: .expanded
  )
}

#Preview("Mini Player - Playing") {
  EpisodePlaying(
    episode: EpisodeData(
      id: 1,
      title: "Advanced iOS Architecture Patterns That Scale",
      description: "MVVM, VIPER, TCA and more",
      relativeTime: "JUST NOW",
      duration: "1h 20m",
      downloadState: .downloaded,
      isPlaying: false
    ),
    show: ShowData(
      id: 2,
      title: "iOS Dev Weekly Podcast",
      author: "Dave Verwer",
      description: "Weekly iOS development discussions"
    ),
    mode: .mini
  )
  .padding()
  .background(Color.gray.opacity(0.1))
}

#Preview("Animated Transition") {
  struct AnimatedPreview: View {
    @State private var isExpanded = false

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

        // Mini player positioned at bottom
        if !isExpanded {
          VStack {
            Spacer()
            EpisodePlaying(
              episode: EpisodeData(
                id: 1,
                title: "SwiftUI Animation Masterclass",
                description: "Learn advanced animation techniques",
                relativeTime: "1H AGO",
                duration: "52m",
                downloadState: .downloaded,
                isPlaying: true
              ),
              show: ShowData(
                id: 1,
                title: "Swift Tutorials",
                author: "iOS Academy",
                description: "Advanced Swift programming",
                artworkUrl: "https://example.com/artwork.jpg"
              ),
              mode: .mini
            ) { event in
              if event == .expandTapped {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                  isExpanded = true
                }
              }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
          }
        }

        // Expanded player (full screen)
        if isExpanded {
          EpisodePlaying(
            episode: EpisodeData(
              id: 1,
              title: "SwiftUI Animation Masterclass",
              description: "Learn advanced animation techniques",
              relativeTime: "1H AGO",
              duration: "52m",
              downloadState: .downloaded,
              isPlaying: true
            ),
            show: ShowData(
              id: 1,
              title: "Swift Tutorials",
              author: "iOS Academy",
              description: "Advanced Swift programming",
              artworkUrl: "https://example.com/artwork.jpg"
            ),
            mode: .expanded
          ) { event in
            if event == .dismissed {
              withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isExpanded = false
              }
            }
          }
        }
      }
      .background(Color.gray.opacity(0.1))
    }
  }

  return AnimatedPreview()
}
