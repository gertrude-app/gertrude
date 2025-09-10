import Testing
import XCTest

@testable import LibTCA

@Test
func testParsePodcastFeedBasic() throws {
  let xmlString = """
  <?xml version="1.0" encoding="UTF-8"?>
  <rss version="2.0" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd">
    <channel>
      <title>Test Podcast</title>
      <description>A test podcast for XML parsing</description>
      <author>Test Author</author>
      <link>https://example.com</link>
      <image>
        <url>https://example.com/artwork.jpg</url>
      </image>

      <item>
        <title>Episode 1</title>
        <description>First test episode</description>
        <link>https://example.com/episode1</link>
        <guid>episode-1</guid>
        <pubDate>Mon, 01 Jan 2024 12:00:00 +0000</pubDate>
        <itunes:duration>1:23:45</itunes:duration>
        <itunes:image href="https://example.com/episode1-artwork.jpg"/>
        <enclosure url="https://example.com/episode1.mp3" type="audio/mpeg" length="50000000"/>
      </item>

      <item>
        <title>Episode 2</title>
        <description>Second test episode</description>
        <guid>episode-2</guid>
        <pubDate>Mon, 08 Jan 2024 12:00:00 +0000</pubDate>
        <itunes:duration>45:30</itunes:duration>
        <itunes:image href="https://example.com/episode2-artwork.jpg"/>
        <enclosure url="https://example.com/episode2.m4a" type="audio/x-m4a" length="30000000"/>
      </item>
    </channel>
  </rss>
  """

  let result = try parsePodcastFeed(xmlString)

  // show
  #expect(result.show.name == "Test Podcast")
  #expect(result.show.author == "Test Author")
  #expect(result.show.description == "A test podcast for XML parsing")
  #expect(result.show.websiteUrl == "https://example.com")
  #expect(result.show.artworkUrl == "https://example.com/artwork.jpg")

  // episodes
  #expect(result.episodes.count == 2)
  let episode1 = result.episodes[0]
  let episode2 = result.episodes[1]
  #expect(episode1.title == "Episode 1")
  #expect(episode1.description == "First test episode")
  #expect(episode1.websiteUrl == "https://example.com/episode1")
  #expect(episode1.audioUrl == "https://example.com/episode1.mp3")
  #expect(episode1.audioType == .mp3)
  #expect(episode1.artworkUrl == "https://example.com/episode1-artwork.jpg")
  #expect(episode1.guid == "episode-1")
  #expect(episode1.duration == 5025)
  
  // Check pubDates
  let formatter = DateFormatter()
  formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
  formatter.locale = Locale(identifier: "en_US_POSIX")
  let expectedDate1 = formatter.date(from: "Mon, 01 Jan 2024 12:00:00 +0000")!
  let expectedDate2 = formatter.date(from: "Mon, 08 Jan 2024 12:00:00 +0000")!
  #expect(episode1.pubDate == expectedDate1)
  #expect(episode2.pubDate == expectedDate2)
  
  #expect(episode2.title == "Episode 2")
  #expect(episode2.audioType == .m4a)
  #expect(episode2.artworkUrl == "https://example.com/episode2-artwork.jpg")
  #expect(episode2.duration == 2730)
}

@Test
func testParsePodcastFeedMinimal() throws {
  let xmlString = """
  <?xml version="1.0" encoding="UTF-8"?>
  <rss version="2.0">
    <channel>
      <title>Minimal Podcast</title>

      <item>
        <title>Simple Episode</title>
        <guid>simple-1</guid>
        <pubDate>Mon, 01 Jan 2024 12:00:00 +0000</pubDate>
        <enclosure url="https://example.com/simple.mp3" type="audio/mpeg" length="1000000"/>
      </item>
    </channel>
  </rss>
  """

  let result = try parsePodcastFeed(xmlString)

  #expect(result.show.name == "Minimal Podcast")
  #expect(result.show.author == nil)
  #expect(result.show.description == nil)
  #expect(result.show.websiteUrl == nil)
  #expect(result.show.artworkUrl == nil)

  #expect(result.episodes.count == 1)
  let episode = result.episodes[0]
  #expect(episode.title == "Simple Episode")
  #expect(episode.description == nil)
  #expect(episode.websiteUrl == nil)
  #expect(episode.audioUrl == "https://example.com/simple.mp3")
  #expect(episode.duration == 0)
  
  // Check pubDate
  let formatter = DateFormatter()
  formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
  formatter.locale = Locale(identifier: "en_US_POSIX")
  let expectedDate = formatter.date(from: "Mon, 01 Jan 2024 12:00:00 +0000")!
  #expect(episode.pubDate == expectedDate)
}

@Test
func testParseDurationFormats() throws {
  let xmlString = """
  <?xml version="1.0" encoding="UTF-8"?>
  <rss version="2.0">
    <channel>
      <title>Duration Test</title>

      <item>
        <title>Episode with HH:MM:SS</title>
        <guid>duration-1</guid>
        <pubDate>Mon, 01 Jan 2024 12:00:00 +0000</pubDate>
        <itunes:duration>2:15:30</itunes:duration>
        <enclosure url="https://example.com/ep1.mp3" type="audio/mpeg" length="1000000"/>
      </item>

      <item>
        <title>Episode with MM:SS</title>
        <guid>duration-2</guid>
        <pubDate>Mon, 01 Jan 2024 12:00:00 +0000</pubDate>
        <itunes:duration>42:15</itunes:duration>
        <enclosure url="https://example.com/ep2.mp3" type="audio/mpeg" length="1000000"/>
      </item>

      <item>
        <title>Episode with seconds</title>
        <guid>duration-3</guid>
        <pubDate>Mon, 01 Jan 2024 12:00:00 +0000</pubDate>
        <itunes:duration>3600</itunes:duration>
        <enclosure url="https://example.com/ep3.mp3" type="audio/mpeg" length="1000000"/>
      </item>
    </channel>
  </rss>
  """

  let result = try parsePodcastFeed(xmlString)

  #expect(result.episodes.count == 3)
  #expect(result.episodes[0].duration == 8130)
  #expect(result.episodes[1].duration == 2535)
  #expect(result.episodes[2].duration == 3600)
  
  // All episodes have the same pubDate in this test
  let formatter = DateFormatter()
  formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
  formatter.locale = Locale(identifier: "en_US_POSIX")
  let expectedDate = formatter.date(from: "Mon, 01 Jan 2024 12:00:00 +0000")!
  #expect(result.episodes[0].pubDate == expectedDate)
  #expect(result.episodes[1].pubDate == expectedDate)
  #expect(result.episodes[2].pubDate == expectedDate)
}

@Test
func testParseInvalidXML() {
  let invalidXml = "This is not XML"

  #expect(throws: XMLParseError.self) {
    try parsePodcastFeed(invalidXml)
  }
}

@Test
func testParseEmptyFeed() {
  let emptyXml = """
  <?xml version="1.0" encoding="UTF-8"?>
  <rss version="2.0">
    <channel>
      <title>Empty Podcast</title>
    </channel>
  </rss>
  """

  #expect(throws: XMLParseError.missingRequiredData) {
    try parsePodcastFeed(emptyXml)
  }
}

@Test
func testParseMissingGuid() {
  let xmlString = """
  <?xml version="1.0" encoding="UTF-8"?>
  <rss version="2.0">
    <channel>
      <title>Test Podcast</title>

      <item>
        <title>Episode without GUID</title>
        <pubDate>Mon, 01 Jan 2024 12:00:00 +0000</pubDate>
        <enclosure url="https://example.com/ep1.mp3" type="audio/mpeg" length="1000000"/>
      </item>
    </channel>
  </rss>
  """

  #expect(throws: XMLParseError.missingRequiredData) {
    try parsePodcastFeed(xmlString)
  }
}

@Test
func testParseAudioTypes() throws {
  let xmlString = """
  <?xml version="1.0" encoding="UTF-8"?>
  <rss version="2.0">
    <channel>
      <title>Audio Type Test</title>

      <item>
        <title>MP3 Episode</title>
        <guid>audio-1</guid>
        <pubDate>Mon, 01 Jan 2024 12:00:00 +0000</pubDate>
        <itunes:image href="https://example.com/mp3-artwork.jpg"/>
        <enclosure url="https://example.com/ep1.mp3" type="audio/mpeg" length="1000000"/>
      </item>

      <item>
        <title>M4A Episode</title>
        <guid>audio-2</guid>
        <pubDate>Mon, 01 Jan 2024 12:00:00 +0000</pubDate>
        <itunes:image href="https://example.com/m4a-artwork.jpg"/>
        <enclosure url="https://example.com/ep2.m4a" type="audio/x-m4a" length="1000000"/>
      </item>

      <item>
        <title>Unknown Type Episode</title>
        <guid>audio-3</guid>
        <pubDate>Mon, 01 Jan 2024 12:00:00 +0000</pubDate>
        <enclosure url="https://example.com/ep3.wav" type="audio/wav" length="1000000"/>
      </item>
    </channel>
  </rss>
  """

  let result = try parsePodcastFeed(xmlString)

  #expect(result.episodes.count == 3)
  #expect(result.episodes[0].audioType == .mp3)
  #expect(result.episodes[0].artworkUrl == "https://example.com/mp3-artwork.jpg")
  #expect(result.episodes[1].audioType == .m4a)
  #expect(result.episodes[1].artworkUrl == "https://example.com/m4a-artwork.jpg")
  #expect(result.episodes[2].audioType == .mp3)
  #expect(result.episodes[2].artworkUrl == nil)
  
  // All episodes have the same pubDate in this test
  let formatter = DateFormatter()
  formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
  formatter.locale = Locale(identifier: "en_US_POSIX")
  let expectedDate = formatter.date(from: "Mon, 01 Jan 2024 12:00:00 +0000")!
  #expect(result.episodes[0].pubDate == expectedDate)
  #expect(result.episodes[1].pubDate == expectedDate)
  #expect(result.episodes[2].pubDate == expectedDate)
}
