import SwiftUI

public struct SearchShowView: View {
  @Environment(\.colorScheme) var cs

  @Binding var searchText: String
  let results: [SearchResult]
  let onResultTap: @MainActor @Sendable (SearchResult) -> Void

  public init(
    searchText: Binding<String>,
    results: [SearchResult],
    onResultTap: @MainActor @escaping @Sendable (SearchResult) -> Void
  ) {
    self._searchText = searchText
    self.results = results
    self.onResultTap = onResultTap
  }

  public var body: some View {
    VStack {
      if self.searchText.isEmpty, self.results.isEmpty {
        self.emptyState
      } else if !self.searchText.isEmpty, self.results.isEmpty {
        self.noResultsState
      } else {
        self.resultsList
      }
    }
    .searchable(text: self.$searchText, prompt: "Search for podcasts...")
  }

  private var emptyState: some View {
    VStack(spacing: 24) {
      Spacer()

      Image(systemName: "magnifyingglass")
        .font(.system(size: 64, weight: .light))
        .foregroundStyle(Color(self.cs, light: .violet300, dark: .violet700))

      Text("Enter a search term to find podcasts you'd like to add.")
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet400))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)

      Spacer()
    }
  }

  private var noResultsState: some View {
    VStack(spacing: 24) {
      Spacer()

      Image(systemName: "exclamationmark.magnifyingglass")
        .font(.system(size: 64, weight: .light))
        .foregroundStyle(Color(self.cs, light: .violet300, dark: .violet700))

      VStack(spacing: 12) {
        Text("No Results")
          .font(.system(size: 28, weight: .bold))
          .foregroundStyle(Color(self.cs, light: .violet950, dark: .violet100))

        Text("No podcasts found for \"\(self.searchText)\". Try a different search term.")
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet400))
          .multilineTextAlignment(.center)
          .padding(.horizontal, 40)
      }

      Spacer()
    }
  }

  private var resultsList: some View {
    ScrollView {
      LazyVStack(spacing: 0) {
        ForEach(self.results) { result in
          Button {
            self.onResultTap(result)
          } label: {
            self.resultRow(result)
          }
          .buttonStyle(PlainButtonStyle())
        }
      }
      .padding(.top, 20)
    }
  }

  private func resultRow(_ result: SearchResult) -> some View {
    HStack(spacing: 16) {
      self.showArtwork(result)

      VStack(alignment: .leading, spacing: 4) {
        HStack {
          Text(result.title)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(Color(self.cs, light: .violet950, dark: .violet100))
            .multilineTextAlignment(.leading)
            .lineLimit(2)

          if result.isExplicit {
            Text("E")
              .font(.system(size: 12, weight: .bold))
              .foregroundStyle(.white)
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(.red)
              .cornerRadius(4)
          }
        }

        Text(result.artistName)
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(Color(self.cs, light: .violet700, dark: .violet300))
          .multilineTextAlignment(.leading)
          .lineLimit(1)

        Text("\(result.episodeCount) episodes")
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
      }

      Spacer()

      Image(systemName: "plus.circle")
        .font(.system(size: 24, weight: .medium))
        .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 12)
    .background(
      Color(self.cs, light: .clear, dark: .clear)
        .contentShape(Rectangle())
    )
  }

  private func showArtwork(_ result: SearchResult) -> some View {
    ArtworkView(
      artworkUrl: result.artworkUrl,
      placeholderIconSize: 20
    )
    .frame(width: 64, height: 64)
    .cornerRadius(6)
    .clipped()
  }
}

#Preview("Empty State") {
  NavigationView {
    SearchShowView(
      searchText: .constant(""),
      results: [],
      onResultTap: { _ in }
    )
  }
}

#Preview("No Results") {
  NavigationView {
    SearchShowView(
      searchText: .constant("nonexistent podcast"),
      results: [],
      onResultTap: { _ in }
    )
  }
}

#Preview("With Results") {
  NavigationView {
    SearchShowView(
      searchText: .constant("tech"),
      results: [
        SearchResult(
          id: 1,
          title: "The Tech Talk Show",
          artistName: "Tech Media Network",
          artworkURL: "https://is1-ssl.mzstatic.com/image/thumb/Podcasts116/v4/a2/94/d3/a294d3e7-bf02-377f-a531-7b0491a4cb81/mza_4607163774963783796.png/600x600bb.jpg",
          feedUrl: "",
          episodeCount: 147,
          isExplicit: false
        ),
        SearchResult(
          id: 2,
          title: "Explicit Tech News",
          artistName: "Uncensored Media",
          feedUrl: "",
          episodeCount: 89,
          isExplicit: true
        ),
        SearchResult(
          id: 3,
          title: "StartupLife",
          artistName: "Entrepreneur Stories",
          feedUrl: "",
          episodeCount: 203
        ),
      ],
      onResultTap: { result in
        print("Tapped: \(result.title)")
      }
    )
  }
}

#Preview("Empty State - Dark") {
  NavigationView {
    SearchShowView(
      searchText: .constant(""),
      results: [],
      onResultTap: { _ in }
    )
  }
  .preferredColorScheme(.dark)
}

#Preview("No Results - Dark") {
  NavigationView {
    SearchShowView(
      searchText: .constant("nonexistent podcast"),
      results: [],
      onResultTap: { _ in }
    )
  }
  .preferredColorScheme(.dark)
}

#Preview("With Results - Dark") {
  NavigationView {
    SearchShowView(
      searchText: .constant("tech"),
      results: [
        SearchResult(
          id: 1,
          title: "The Tech Talk Show",
          artistName: "Tech Media Network",
          artworkURL: "https://is1-ssl.mzstatic.com/image/thumb/Podcasts116/v4/a2/94/d3/a294d3e7-bf02-377f-a531-7b0491a4cb81/mza_4607163774963783796.png/600x600bb.jpg",
          feedUrl: "",
          episodeCount: 147,
          isExplicit: false
        ),
        SearchResult(
          id: 2,
          title: "Explicit Tech News",
          artistName: "Uncensored Media",
          feedUrl: "",
          episodeCount: 89,
          isExplicit: true
        ),
        SearchResult(
          id: 3,
          title: "StartupLife",
          artistName: "Entrepreneur Stories",
          feedUrl: "",
          episodeCount: 203
        ),
      ],
      onResultTap: { result in
        print("Tapped: \(result.title)")
      }
    )
  }
  .preferredColorScheme(.dark)
}
