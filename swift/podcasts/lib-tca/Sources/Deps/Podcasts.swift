import Dependencies
import DependenciesMacros
import Foundation
import LibViews

@DependencyClient
struct PodcastClient: Sendable {
  var getFeed: @Sendable (_ feedUrl: String) async throws -> Feed
  var search: @Sendable (_ query: String) async throws -> [SearchResult]
  var download: @Sendable (_ episode: Episode) async -> Bool = { _ in false }
}

extension PodcastClient: DependencyKey {
  static var liveValue: PodcastClient {
    .init(
      getFeed: { feedUrl in
        try await getPodcastFeedLive(feedUrl: feedUrl)
      },
      search: { query in
        try await searchPodcastsLive(query: query)
      },
      download: { episode in
        await downloadEpisodeLive(episode: episode)
      }
    )
  }
}

extension DependencyValues {
  var podcasts: PodcastClient {
    get { self[PodcastClient.self] }
    set { self[PodcastClient.self] = newValue }
  }
}

@Sendable
func getPodcastFeedLive(feedUrl: String) async throws -> Feed {
  guard let url = URL(string: feedUrl) else {
    throw PodcastFeedError.invalidURL
  }

  let (data, response) = try await URLSession.shared.data(from: url)
  guard let httpResponse = response as? HTTPURLResponse,
        httpResponse.statusCode == 200 else {
    throw PodcastFeedError.networkError
  }

  guard let xmlString = String(data: data, encoding: .utf8) else {
    throw PodcastFeedError.invalidEncoding
  }

  do {
    return try parsePodcastFeed(xmlString)
  } catch let error as XMLParseError {
    throw PodcastFeedError.parseError(error)
  }
}

enum PodcastFeedError: Error, Sendable {
  case networkError
  case invalidURL
  case invalidEncoding
  case parseError(XMLParseError)
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

  do {
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
  } catch {
    throw SearchError.decodingError
  }
}

private struct ITunesSearchResponse: Codable {
  let results: [ITunesPodcast]
}

private struct ITunesPodcast: Codable {
  let trackId: Int
  let trackName: String
  let artistName: String
  let artworkUrl600: String?
  let feedUrl: String
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

enum SearchError: Error, Sendable {
  case invalidQuery
  case invalidURL
  case networkError
  case decodingError
}

@Sendable
func downloadEpisodeLive(episode: Episode) async -> Bool {
  guard let sourceUrl = URL(string: episode.audioUrl) else {
    return false
  }

  do {
    try FileManager.default.createDirectory(
      at: episode.localAudioUrl.deletingLastPathComponent(),
      withIntermediateDirectories: true,
      attributes: nil
    )

    let (data, response) = try await URLSession.shared.data(from: sourceUrl)
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
      return false
    }

    try data.write(to: episode.localAudioUrl)
    return true
  } catch {
    return false
  }
}
