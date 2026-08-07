import Foundation

func parsePodcastFeed(_ xmlString: String, source: String) throws -> Feed {
  guard let xmlData = sanitizeFeedXML(xmlString).data(using: .utf8) else {
    throw XMLParseError.invalidUtf8
  }

  let parser = XMLParser(data: xmlData)
  let delegate = PodcastFeedParser(source: source)
  parser.delegate = delegate

  guard parser.parse() else {
    throw XMLParseError.parseFailed
  }

  if let parseError = delegate.parseError {
    throw parseError
  }

  guard let show = delegate.show, !delegate.episodes.isEmpty else {
    throw XMLParseError.missingRequiredData
  }

  return Feed(show: show, episodes: delegate.episodes)
}

enum XMLParseError: Error, Sendable {
  case invalidUtf8
  case parseFailed
  case missingRequiredData
  case invalidDate
  case invalidDuration
  case invalidAudioType
  case missingEpisodeSize
}

private func sanitizeFeedXML(_ xml: String) -> String {
  let clean = xml.replacingOccurrences(
    of: "[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F]",
    with: "",
    options: .regularExpression,
  ).trimmingCharacters(in: .whitespacesAndNewlines)
  let parts = clean.components(separatedBy: "<![CDATA[")
  guard parts.count > 1 else {
    return escapeBareFeedAmpersands(clean)
  }
  var result = escapeBareFeedAmpersands(parts[0])
  for part in parts.dropFirst() {
    if let cdataEnd = part.range(of: "]]>") {
      result += "<![CDATA[" + part[..<cdataEnd.upperBound]
      result += escapeBareFeedAmpersands(String(part[cdataEnd.upperBound...]))
    } else {
      result += "<![CDATA[" + part
    }
  }
  return result
}

private func urlWithoutQueryOrFragment(_ urlString: String) -> String {
  guard var components = URLComponents(string: urlString) else {
    return urlString
  }
  components.query = nil
  components.fragment = nil
  return components.string ?? urlString
}

private func escapeBareFeedAmpersands(_ text: String) -> String {
  text.replacingOccurrences(
    of: "&(?!amp;|lt;|gt;|quot;|apos;|#\\d+;|#x[0-9a-fA-F]+;)",
    with: "&amp;",
    options: .regularExpression,
  )
}

private class PodcastFeedParser: NSObject, XMLParserDelegate {
  var source: String
  var show: Show.FeedData?
  var episodes: [Episode.FeedData] = []
  var parseError: XMLParseError?

  // Current parsing state
  private var currentElement = ""
  private var currentText = ""
  private var parentElement = ""

  // Show properties
  private var showTitle = ""
  private var showAuthor: String?
  private var showDescription: String?
  private var showWebsiteUrl: String?
  private var showArtworkUrl: String?
  private var iTunesId: Int?

  // Episode properties
  private var episodeTitle = ""
  private var episodeDescription: String?
  private var episodeWebsiteUrl: String?
  private var episodeAudioUrl = ""
  private var episodeArtworkUrl: String?
  private var episodeDuration: Int?
  private var episodeSize = 0
  private var episodeAudioType = AudioType.mp3
  private var episodeGuid = ""
  private var episodePubDate = Date()
  private var episodeNumber: Int?

  private var isInItem = false
  private var itemElementCount = 0

  init(source: String) {
    self.source = source
  }

  func parser(
    _ parser: XMLParser,
    didStartElement elementName: String,
    namespaceURI: String?,
    qualifiedName qName: String?,
    attributes attributeDict: [String: String] = [:],
  ) {
    self.parentElement = self.currentElement
    self.currentElement = elementName
    self.currentText = ""

    if elementName == "item" {
      self.isInItem = true
      self.itemElementCount += 1
      // Reset episode properties
      self.resetEpisodeProperties()
    }

    // Handle attributes
    if elementName == "enclosure", self.isInItem {
      self.episodeAudioUrl = upgradeToHttps(attributeDict["url"] ?? "")
      let typeString = attributeDict["type"] ?? ""
      self.episodeAudioType = AudioType(rawValue: typeString) ?? .mp3
      let lengthString = attributeDict["length"] ?? "0"
      self.episodeSize = Int(lengthString) ?? 0
    }

    if elementName == "itunes:image", !self.isInItem {
      self.showArtworkUrl = attributeDict["href"].map(upgradeToHttps)
    }

    if elementName == "image", self.isInItem {
      self.episodeArtworkUrl = attributeDict["href"].map(upgradeToHttps)
    }

    if elementName == "itunes:image", self.isInItem {
      self.episodeArtworkUrl = attributeDict["href"].map(upgradeToHttps)
    }
  }

  func parser(_ parser: XMLParser, foundCharacters string: String) {
    self.currentText += string
  }

  func parser(
    _ parser: XMLParser,
    didEndElement elementName: String,
    namespaceURI: String?,
    qualifiedName qName: String?,
  ) {
    let trimmedText = self.currentText.trimmingCharacters(in: .whitespacesAndNewlines)

    if elementName == "item" {
      // Finished parsing an episode
      guard !self.episodeAudioUrl.isEmpty else {
        self.isInItem = false
        return
      }

      if self.episodeGuid.isEmpty {
        self.episodeGuid = urlWithoutQueryOrFragment(self.episodeAudioUrl)
      }

      let episode = Episode.FeedData(
        title: self.episodeTitle,
        description: self.episodeDescription?.isEmpty == false ? self
          .stripHTML(self.episodeDescription ?? "") : nil,
        websiteUrl: self.episodeWebsiteUrl?.isEmpty == false ? self.episodeWebsiteUrl : nil,
        audioUrl: self.episodeAudioUrl,
        artworkUrl: self.episodeArtworkUrl?.isEmpty == false ? self.episodeArtworkUrl : nil,
        duration: self.episodeDuration,
        sizeInBytes: self.episodeSize,
        audioType: self.episodeAudioType,
        guid: self.episodeGuid,
        pubDate: self.episodePubDate,
        episodeNumber: self.episodeNumber,
      )
      self.episodes.append(episode)
      self.isInItem = false
      return
    }

    // Show-level elements
    if !self.isInItem {
      switch elementName {
      case "title":
        self.showTitle = trimmedText
      case "description":
        self.showDescription = trimmedText
      case "author", "managingEditor", "itunes:author":
        self.showAuthor = trimmedText
      case "link":
        self.showWebsiteUrl = trimmedText
      case "url" where self.parentElement == "image" && !self.isInItem:
        self.showArtworkUrl = upgradeToHttps(trimmedText)
      case "itunes:image":
        // iTunes image is handled in attributes
        break
      default:
        break
      }
    }
    // Episode-level elements
    else {
      switch elementName {
      case "title":
        self.episodeTitle = trimmedText
      case "description":
        self.episodeDescription = trimmedText
      case "link":
        self.episodeWebsiteUrl = trimmedText
      case "guid":
        self.episodeGuid = trimmedText
      case "pubDate":
        self.episodePubDate = self.parseDate(trimmedText) ?? Date()
      case "itunes:duration":
        self.episodeDuration = self.parseDuration(trimmedText)
      case "itunes:episode":
        self.episodeNumber = Int(trimmedText)
      case "url" where self.parentElement == "image" && self.isInItem:
        self.episodeArtworkUrl = upgradeToHttps(trimmedText)
      default:
        break
      }
    }

    // Create show object when we finish parsing the channel
    if elementName == "channel", self.show == nil {
      self.show = Show.FeedData(
        sourceUrl: self.source,
        name: self.showTitle,
        author: self.showAuthor,
        description: self.showDescription?.isEmpty == false ? self
          .stripHTML(self.showDescription ?? "") : nil,
        websiteUrl: self.showWebsiteUrl,
        artworkUrl: self.showArtworkUrl,
        iTunesId: self.iTunesId,
      )
    }
  }

  private func resetEpisodeProperties() {
    self.episodeTitle = ""
    self.episodeDescription = nil
    self.episodeWebsiteUrl = nil
    self.episodeAudioUrl = ""
    self.episodeArtworkUrl = nil
    self.episodeDuration = nil
    self.episodeSize = 0
    self.episodeAudioType = .mp3
    self.episodeGuid = ""
    self.episodePubDate = Date()
    self.episodeNumber = nil
  }

  private func parseDate(_ dateString: String) -> Date? {
    let formatters = [
      // RFC 2822 format (most common in RSS)
      "EEE, dd MMM yyyy HH:mm:ss Z",
      "EEE, dd MMM yyyy HH:mm:ss zzz",
      // ISO 8601 format
      "yyyy-MM-dd'T'HH:mm:ssZ",
      "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
      // Additional common formats
      "dd MMM yyyy HH:mm:ss Z",
      "yyyy-MM-dd HH:mm:ss Z",
      // Simple date-only format (non-spec but sometimes seen)
      "yyyy-MM-dd",
    ]

    for formatString in formatters {
      let formatter = DateFormatter()
      formatter.dateFormat = formatString
      formatter.locale = Locale(identifier: "en_US_POSIX")
      if let date = formatter.date(from: dateString) {
        return date
      }
    }

    return nil
  }

  private func parseDuration(_ durationString: String) -> Int? {
    // Handle formats like "1:23:45" or "3600" (seconds)
    let seconds: Int?
    if durationString.contains(":") {
      let components = durationString.split(separator: ":").compactMap { Int($0) }
      switch components.count {
      case 3: // HH:MM:SS
        seconds = components[0] * 3600 + components[1] * 60 + components[2]
      case 2: // MM:SS
        seconds = components[0] * 60 + components[1]
      case 1: // SS
        seconds = components[0]
      default:
        seconds = nil
      }
    } else {
      seconds = Int(durationString)
    }
    guard let seconds, seconds > 0 else { return nil }
    return seconds
  }

  private func stripHTML(_ html: String) -> String {
    // Remove HTML tags using regex, replacing with space to preserve word separation
    let regex = try! NSRegularExpression(pattern: "<[^>]+>", options: [])
    let range = NSRange(location: 0, length: html.utf16.count)
    let stripped = regex.stringByReplacingMatches(
      in: html,
      options: [],
      range: range,
      withTemplate: " ",
    )

    // Clean up extra whitespace and decode HTML entities
    let cleaned = stripped
      .replacingOccurrences(of: "&amp;", with: "&")
      .replacingOccurrences(of: "&lt;", with: "<")
      .replacingOccurrences(of: "&gt;", with: ">")
      .replacingOccurrences(of: "&quot;", with: "\"")
      .replacingOccurrences(of: "&#39;", with: "'")
      .replacingOccurrences(of: "&nbsp;", with: " ")
      .trimmingCharacters(in: .whitespacesAndNewlines)

    // Remove multiple spaces and clean up
    let withoutExtraSpaces = cleaned.replacingOccurrences(
      of: "\\s+",
      with: " ",
      options: .regularExpression,
    )

    // Remove spaces before punctuation
    let finalCleaned = withoutExtraSpaces.replacingOccurrences(
      of: "\\s+([.,;:!?])",
      with: "$1",
      options: .regularExpression,
    )

    return finalCleaned
  }
}
