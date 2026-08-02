import GertieUI
import SwiftUI

public struct SearchShowView: View {
  @Environment(\.colorScheme) var cs
  @FocusState private var isSearchFocused: Bool

  @Binding var searchText: String
  let isSearching: Bool
  let results: [SearchResult]
  let onResultTap: @MainActor @Sendable (SearchResult) -> Void
  let onSubmit: @MainActor @Sendable () -> Void

  public init(
    searchText: Binding<String>,
    isSearching: Bool = false,
    results: [SearchResult],
    onResultTap: @MainActor @escaping @Sendable (SearchResult) -> Void,
    onSubmit: @MainActor @escaping @Sendable () -> Void = {},
  ) {
    self._searchText = searchText
    self.isSearching = isSearching
    self.results = results
    self.onResultTap = onResultTap
    self.onSubmit = onSubmit
  }

  public var body: some View {
    Group {
      if #available(iOS 26.0, *) {
        self.nativeSearch
      } else {
        self.legacySearch
      }
    }
    .task {
      try? await Task.sleep(for: .milliseconds(250))
      self.isSearchFocused = true
    }
  }

  @available(iOS 26.0, *)
  private var nativeSearch: some View {
    self.stateContent
      .searchable(text: self.$searchText, prompt: Text(lstr(.searchPrompt)))
      .textInputAutocapitalization(.never)
      .autocorrectionDisabled(true)
      .searchFocused(self.$isSearchFocused)
      .onSubmit(of: .search) { self.onSubmit() }
  }

  private var legacySearch: some View {
    VStack(spacing: 0) {
      self.searchField
      self.stateContent
    }
  }

  @ViewBuilder
  private var stateContent: some View {
    VStack(spacing: 0) {
      if self.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        self.emptyState
      } else if self.isSearching {
        self.searchingState
      } else if self.results.isEmpty {
        self.noResultsState
      } else {
        self.resultsList
      }
    }
  }

  private var searchField: some View {
    HStack(spacing: 12) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))

      TextField(lstr(.searchPrompt), text: self.$searchText)
        .textInputAutocapitalization(.never)
        .disableAutocorrection(true)
        .submitLabel(.search)
        .focused(self.$isSearchFocused)
        .onSubmit { self.onSubmit() }
        .accessibilityIdentifier("podcast-search-field")
    }
    .font(.system(size: 18, weight: .medium))
    .padding(.horizontal, 18)
    .padding(.vertical, 14)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(self.cs, light: .white, dark: .black)),
    )
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(
          Color(self.cs, light: .violet200, dark: .violet800),
          lineWidth: 1,
        ),
    )
    .padding(.horizontal, 20)
    .padding(.top, 16)
    .padding(.bottom, 8)
  }

  private var emptyState: some View {
    VStack(spacing: 24) {
      Spacer()

      Image(systemName: "magnifyingglass")
        .font(.system(size: 64, weight: .light))
        .foregroundStyle(Color(self.cs, light: .violet300, dark: .violet700))

      Text(lstr(.searchEmptyMessage))
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet400))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)

      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var searchingState: some View {
    VStack(spacing: 24) {
      Spacer()

      ProgressView()
        .tint(Color(self.cs, light: .violet500, dark: .violet400))

      Text(lstr(.searching))
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet400))

      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var noResultsState: some View {
    VStack(spacing: 24) {
      Spacer()

      Image(systemName: "exclamationmark.magnifyingglass")
        .font(.system(size: 64, weight: .light))
        .foregroundStyle(Color(self.cs, light: .violet300, dark: .violet700))

      VStack(spacing: 12) {
        Text(lstr(.searchNoResultsTitle))
          .font(.system(size: 28, weight: .bold))
          .foregroundStyle(Color(self.cs, light: .violet950, dark: .violet100))

        Text(String(
          format: lstr(.searchNoResultsMessage),
          self.searchText.trimmingCharacters(in: .whitespacesAndNewlines),
        ))
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet400))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)
      }

      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
          .accessibilityIdentifier("podcast-search-result-\(result.id)")
        }
      }
      .padding(.top, 20)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .contentShape(Rectangle()),
    )
  }

  private func showArtwork(_ result: SearchResult) -> some View {
    ArtworkView(
      artworkUrl: result.artworkUrl,
      size: 64,
    )
  }
}

#Preview("Empty State") {
  NavigationView {
    SearchShowView(
      searchText: .constant(""),
      results: [],
      onResultTap: { _ in },
    )
  }
}

#Preview("No Results") {
  NavigationView {
    SearchShowView(
      searchText: .constant("nonexistent podcast"),
      results: [],
      onResultTap: { _ in },
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
          artworkURL: .ancientPath,
          feedUrl: "",
          episodeCount: 147,
          isExplicit: false,
        ),
        SearchResult(
          id: 2,
          title: "Explicit Tech News",
          artistName: "Uncensored Media",
          feedUrl: "",
          episodeCount: 89,
          isExplicit: true,
        ),
        SearchResult(
          id: 3,
          title: "StartupLife",
          artistName: "Entrepreneur Stories",
          feedUrl: "",
          episodeCount: 203,
        ),
      ],
      onResultTap: { result in
        print("Tapped: \(result.title)")
      },
    )
  }
}

#Preview("Empty State - Dark") {
  NavigationView {
    SearchShowView(
      searchText: .constant(""),
      results: [],
      onResultTap: { _ in },
    )
  }
  .preferredColorScheme(.dark)
}

#Preview("No Results - Dark") {
  NavigationView {
    SearchShowView(
      searchText: .constant("nonexistent podcast"),
      results: [],
      onResultTap: { _ in },
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
          artworkURL: .ancientPath,
          feedUrl: "",
          episodeCount: 147,
          isExplicit: false,
        ),
        SearchResult(
          id: 2,
          title: "Explicit Tech News",
          artistName: "Uncensored Media",
          feedUrl: "",
          episodeCount: 89,
          isExplicit: true,
        ),
        SearchResult(
          id: 3,
          title: "StartupLife",
          artistName: "Entrepreneur Stories",
          feedUrl: "",
          episodeCount: 203,
        ),
      ],
      onResultTap: { result in
        print("Tapped: \(result.title)")
      },
    )
  }
  .preferredColorScheme(.dark)
}
