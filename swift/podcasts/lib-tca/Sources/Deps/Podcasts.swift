import Dependencies
import DependenciesMacros
import Foundation
import LibCore
import LibViews

@DependencyClient
struct PodcastClient: Sendable {
  var getFeed: @Sendable (_ feedUrl: String) async throws -> Feed
  var search: @Sendable (_ query: String) async throws -> [SearchResult]
  var downloadAudio: @Sendable (_ episode: Episode) async -> Bool = { _ in false }
  var downloadArtwork: @Sendable (_ show: Show) async -> Void = { _ in }
}

extension PodcastClient: DependencyKey {
  static var liveValue: PodcastClient {
    @Dependency(\.locale) var locale
    return .init(
      getFeed: { feedUrl in
        try await getPodcastFeedLive(feedUrl: feedUrl)
      },
      search: { query in
        try await searchPodcastsLive(query: query, locale: locale)
      },
      downloadAudio: { episode in
        await downloadEpisodeLive(episode: episode)
      },
      downloadArtwork: { show in
        await downloadArtworkLive(show: show)
      },
    )
  }
}

extension PodcastClient {
  func downloadAudio(for episode: Episode) async -> Bool {
    await self.downloadAudio(episode)
  }

  func downloadArtwork(for show: Show) async {
    await self._downloadArtwork(show)
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
    return try parsePodcastFeed(xmlString, source: feedUrl)
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
func searchPodcastsLive(query: String, locale: Locale) async throws -> [SearchResult] {
  guard !query.isEmpty else { return [] }

  guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
  else {
    throw SearchError.invalidQuery
  }

  let country = locale.region?.identifier ?? "US"
  let urlString =
    "https://itunes.apple.com/search?term=\(encodedQuery)&media=podcast&limit=25&country=\(country)"
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
        isExplicit: podcast.contentAdvisoryRating == "Explicit",
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
      attributes: nil,
    )

    let (data, response) = try await URLSession.shared.data(from: sourceUrl)
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200,
          !data.isEmpty else {
      return false
    }

    try data.write(to: episode.localAudioUrl)
    return true
  } catch {
    return false
  }
}

@Sendable
func downloadArtworkLive(show: Show) async {
  guard let artworkUrlString = show.artworkUrl else {
    return
  }

  guard let artworkUrl = URL(string: artworkUrlString) else {
    unexpected(id: "be3f7267", "URL: \(artworkUrlString)")
    return
  }

  do {
    try FileManager.default.createDirectory(
      at: .localFilesDir(showId: show.id),
      withIntermediateDirectories: true,
      attributes: nil,
    )

    let (data, response) = try await URLSession.shared.data(from: artworkUrl)
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
      return
    }

    try data.write(to: .localArtworkPath(showId: show.id))

    #if DEBUG
      if let img = UIImage(data: data),
         let jpegData = img.jpegData(compressionQuality: 1.0) {
        try jpegData
          .write(
            to: .localFilesDir(showId: show.id)
              .appending(component: "artwork-show-\(show.id).jpg"),
          )
      }
    #endif
  } catch {
    return
  }
}
