import SwiftUI

public struct PodcastsHomeView: View {
  @Environment(\.colorScheme) var cs

  public struct PodcastShow: Identifiable, Sendable {
    public let id: Int
    public let title: String
    public let artworkURL: String?

    public init(id: Int, title: String, artworkURL: String? = nil) {
      self.id = id
      self.title = title
      self.artworkURL = artworkURL
    }
  }

  let shows: [PodcastShow]
  let onAddShowTap: @MainActor @Sendable () -> Void
  let onShowTap: @MainActor @Sendable (PodcastShow) -> Void

  public init(
    shows: [PodcastShow],
    onAddShowTap: @MainActor @escaping @Sendable () -> Void,
    onShowTap: @MainActor @escaping @Sendable (PodcastShow) -> Void = { _ in }
  ) {
    self.shows = shows
    self.onAddShowTap = onAddShowTap
    self.onShowTap = onShowTap
  }

  // https://itunes.apple.com/search?term=ancient+path&media=podcast&limit=25

  public var body: some View {
    VStack(spacing: 0) {
      if self.shows.isEmpty {
        self.emptyState
      } else {
        self.showsList
      }

      Spacer()

      BigButton(
        "Add Show",
        type: .button(self.onAddShowTap),
        variant: .primary,
        icon: "plus"
      )
      .padding(.horizontal, 30)
      .padding(.bottom, 30)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(self.cs, light: .white, dark: .black))
  }

  private var emptyState: some View {
    VStack(spacing: 24) {
      Spacer()

      Image(systemName: "waveform.and.mic")
        .font(.system(size: 64, weight: .light))
        .foregroundStyle(Color(self.cs, light: .violet300, dark: .violet700))

      VStack(spacing: 12) {
        Text("No Shows Yet")
          .font(.system(size: 28, weight: .bold))
          .foregroundStyle(Color(self.cs, light: .violet950, dark: .violet100))

        Text("Add your first podcast show to get started listening to approved content.")
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet400))
          .multilineTextAlignment(.center)
          .padding(.horizontal, 40)
      }

      Spacer()
    }
  }

  private var showsList: some View {
    ScrollView {
      LazyVStack(spacing: 0) {
        ForEach(self.shows) { show in
          Button {
            self.onShowTap(show)
          } label: {
            self.showRow(show)
          }
          .buttonStyle(PlainButtonStyle())
        }
      }
      .padding(.top, 20)
    }
  }

  private func showRow(_ show: PodcastShow) -> some View {
    HStack(spacing: 16) {
      self.showArtwork(show)

      VStack(alignment: .leading, spacing: 4) {
        Text(show.title)
          .font(.system(size: 18, weight: .semibold))
          .foregroundStyle(Color(self.cs, light: .violet950, dark: .violet100))
          .multilineTextAlignment(.leading)
          .lineLimit(2)

        Text("Subscribed")
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
      }

      Spacer()

      Image(systemName: "chevron.right")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(Color(self.cs, light: .violet400, dark: .violet600))
    }
    .padding(.horizontal, 30)
    .padding(.vertical, 16)
    .background(
      Color(self.cs, light: .clear, dark: .clear)
        .contentShape(Rectangle())
    )
  }

  private var artworkPlaceholder: some View {
    Rectangle()
      .fill(Color(self.cs, light: .violet200, dark: .violet800))
      .overlay(
        Image(systemName: "mic")
          .font(.system(size: 20, weight: .medium))
          .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet500))
      )
  }

  private func showArtwork(_ show: PodcastShow) -> some View {
    Group {
      if let artworkURL = show.artworkURL, let url = URL(string: artworkURL) {
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
    .frame(width: 56, height: 56)
    .cornerRadius(12)
    .clipped()
  }
}

#Preview("With Shows") {
  PodcastsHomeView(
    shows: [
      PodcastsHomeView.PodcastShow(
        id: 1,
        title: "The Ancient Path",
        artworkURL: "https://is1-ssl.mzstatic.com/image/thumb/Podcasts116/v4/a2/94/d3/a294d3e7-bf02-377f-a531-7b0491a4cb81/mza_4607163774963783796.png/600x600bb.jpg",
      ),
      PodcastsHomeView.PodcastShow(
        id: 2,
        title: "The Secret Sombrero",
        artworkURL: "https://spanish-7cbc3de5.nyc3.digitaloceanspaces.com/sombrero.jpg"
      ),
      PodcastsHomeView.PodcastShow(
        id: 3,
        title: "This American Life"
      ),
    ],
    onAddShowTap: {}
  )
}

#Preview("Empty State") {
  PodcastsHomeView(
    shows: [],
    onAddShowTap: {}
  )
}

#Preview("With Shows (Dark)") {
  PodcastsHomeView(
    shows: [
      PodcastsHomeView.PodcastShow(
        id: 1,
        title: "The Ancient Path",
        artworkURL: "https://is1-ssl.mzstatic.com/image/thumb/Podcasts116/v4/a2/94/d3/a294d3e7-bf02-377f-a531-7b0491a4cb81/mza_4607163774963783796.png/600x600bb.jpg",
      ),
      PodcastsHomeView.PodcastShow(
        id: 2,
        title: "The Secret Sombrero",
        artworkURL: "https://spanish-7cbc3de5.nyc3.digitaloceanspaces.com/sombrero.jpg"
      ),
      PodcastsHomeView.PodcastShow(
        id: 3,
        title: "This American Life"
      ),
    ],
    onAddShowTap: {}
  )
  .preferredColorScheme(.dark)
}

#Preview("Empty State (Dark)") {
  PodcastsHomeView(
    shows: [],
    onAddShowTap: {}
  )
  .preferredColorScheme(.dark)
}
