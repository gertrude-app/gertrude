import SwiftUI

public struct ShowView: View {
  @Environment(\.colorScheme) var cs

  let show: ShowData
  let episodes: [EpisodeData]

  public init(show: ShowData, episodes: [EpisodeData] = []) {
    self.show = show
    self.episodes = episodes
  }

  public var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        self.showHeader

        if !self.episodes.isEmpty {
          self.episodesList
        }
      }
    }
    .background(
      Color(self.cs, light: .violet100, dark: .violet900)
        .ignoresSafeArea(.all)
    )
  }

  private var showHeader: some View {
    VStack(spacing: 16) {
      self.showArtwork

      VStack(spacing: 8) {
        Text(self.show.title)
          .font(.system(size: 24, weight: .bold))
          .foregroundStyle(Color(self.cs, light: .violet950, dark: .violet100))
          .multilineTextAlignment(.center)

        if let author = show.author {
          Text(author)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(Color(self.cs, light: .violet700, dark: .violet300))
            .multilineTextAlignment(.center)
        }

        if let description = show.description {
          Text(description)
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet400))
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .padding(.top, 8)
        }
      }
      .padding(.horizontal, 32)
    }
    .padding(.top, 30)
    .padding(.bottom, 24)
    .frame(maxWidth: .infinity)
  }

  private var showArtwork: some View {
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
    .frame(width: 200, height: 200)
    .cornerRadius(6)
    .clipped()
  }

  private var artworkPlaceholder: some View {
    Rectangle()
      .fill(Color(self.cs, light: .violet200, dark: .violet800))
      .overlay(
        Image(systemName: "mic")
          .font(.system(size: 60, weight: .medium))
          .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet500))
      )
  }

  private var episodesList: some View {
    LazyVStack(spacing: 1) {
      ForEach(self.episodes) { episode in
        EpisodeView(episode: episode)
          .background(Color(self.cs, light: .white, dark: .black))
      }
    }
    .padding(.top, 12)
  }
}

#Preview("Show View - Light") {
  ShowView(
    show: ShowData(
      id: 1,
      title: "The Ancient Path",
      author: "Jason Henderson",
      description: "A podcast about walking in the ancient paths of biblical wisdom and truth. Join us as we explore the timeless principles that guide us in righteousness.",
      artworkUrl: "https://is1-ssl.mzstatic.com/image/thumb/Podcasts116/v4/a2/94/d3/a294d3e7-bf02-377f-a531-7b0491a4cb81/mza_4607163774963783796.png/600x600bb.jpg"
    ),
    episodes: sampleEpisodes
  )
}

#Preview("Show View - Dark") {
  ShowView(
    show: ShowData(
      id: 1,
      title: "The Ancient Path",
      author: "Jason Henderson",
      description: "A podcast about walking in the ancient paths of biblical wisdom and truth. Join us as we explore the timeless principles that guide us in righteousness.",
      artworkUrl: "https://is1-ssl.mzstatic.com/image/thumb/Podcasts116/v4/a2/94/d3/a294d3e7-bf02-377f-a531-7b0491a4cb81/mza_4607163774963783796.png/600x600bb.jpg"
    ),
    episodes: sampleEpisodes
  )
  .preferredColorScheme(.dark)
}

#Preview("Show View - No Episodes") {
  ShowView(show: ShowData(
    id: 2,
    title: "Tech Talk Weekly",
    author: "Tech Media Network",
    description: "Weekly discussions about the latest in technology, programming, and digital innovation."
  ))
}

#Preview("Show View - No Artwork") {
  ShowView(
    show: ShowData(
      id: 3,
      title: "Swift Weekly Brief",
      author: "Jesse Squires",
      description: "A weekly podcast about Swift development, news, and community updates."
    ),
    episodes: sampleEpisodes
  )
}

private let sampleEpisodes = [
  EpisodeData(
    id: 1,
    title: "Walking in Truth",
    description: "How to discern truth from error in today's confusing world and walk confidently in biblical wisdom.",
    relativeTime: "3H AGO",
    duration: "45m"
  ),
  EpisodeData(
    id: 2,
    title: "The Narrow Path",
    description: "Jesus spoke of the narrow path that leads to life. What does this mean for believers today?",
    relativeTime: "1D AGO",
    duration: "52m",
    isDownloaded: true
  ),
  EpisodeData(
    id: 3,
    title: "Guarding Your Heart",
    description: "It is wisdom, and not legalism, to guard your heart, and to pay attention to what is filling your thoughts, your affections and your time.",
    relativeTime: "3D AGO",
    duration: "38m"
  ),
  EpisodeData(
    id: 4,
    title: "Swift 6.0 Release Notes",
    description: "A comprehensive overview of all the new features and improvements in Swift 6.0.",
    relativeTime: "JUST NOW",
    duration: "1h 15m",
    isDownloaded: true
  ),
  EpisodeData(
    id: 5,
    title: "Concurrency Best Practices",
    description: "Essential patterns and practices for writing safe, efficient concurrent code in Swift using async/await and actors.",
    relativeTime: "2H AGO",
    duration: "42m"
  ),
  EpisodeData(
    id: 6,
    title: "Performance Optimization Tips",
    description: "Learn how to optimize your Swift code for better performance and memory usage.",
    relativeTime: "4D AGO",
    duration: "47m"
  ),
]
