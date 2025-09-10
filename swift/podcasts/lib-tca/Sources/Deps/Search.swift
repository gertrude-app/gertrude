import Dependencies
import DependenciesMacros
import Foundation
import LibCore

@DependencyClient
struct SearchClient: Sendable {
  var search: @Sendable (_ query: String) async throws -> [SearchResult]
}

extension SearchClient: DependencyKey {
  static var liveValue: SearchClient {
    .init(search: { query in
      try await searchPodcastsLive(query: query)
    })
  }
}

extension DependencyValues {
  var search: SearchClient {
    get { self[SearchClient.self] }
    set { self[SearchClient.self] = newValue }
  }
}

// structs for decoding

private struct ITunesSearchResponse: Codable {
  let results: [ITunesPodcast]
}

private struct ITunesPodcast: Codable {
  let trackId: Int
  let trackName: String
  let artistName: String
  let artworkUrl600: String?
  let feedUrl: String?
  let trackCount: Int
  let contentAdvisoryRating: String?

  enum CodingKeys: String, CodingKey {
    case trackId
    case trackName
    case artistName
    case artworkUrl600
    case feedUrl
    case trackCount
    case contentAdvisoryRating
  }
}

@Sendable
func searchPodcastsLive(query: String) async throws -> [SearchResult] {
  guard !query.isEmpty else { return [] }

  guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
  else {
    throw SearchError.invalidQuery
  }

  let urlString = "https://itunes.apple.com/search?term=\(encodedQuery)&media=podcast&limit=25"
  guard let url = URL(string: urlString) else {
    throw SearchError.invalidURL
  }

  let (data, response) = try await URLSession.shared.data(from: url)
  guard let httpResponse = response as? HTTPURLResponse,
        httpResponse.statusCode == 200 else {
    throw SearchError.networkError
  }

  let decoder = JSONDecoder()
  let searchResponse = try decoder.decode(ITunesSearchResponse.self, from: data)

  return searchResponse.results.map { podcast in
    SearchResult(
      id: podcast.trackId,
      title: podcast.trackName,
      artistName: podcast.artistName,
      artworkURL: podcast.artworkUrl600,
      feedUrl: podcast.feedUrl,
      episodeCount: podcast.trackCount,
      isExplicit: podcast.contentAdvisoryRating == "Explicit"
    )
  }
}

public enum SearchError: Error, Sendable {
  case invalidQuery
  case invalidURL
  case networkError
  case decodingError
}
