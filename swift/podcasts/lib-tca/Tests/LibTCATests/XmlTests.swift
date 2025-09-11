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
  #expect(episode1.sizeInBytes == 50_000_000)
  #expect(episode1.episodeNumber == nil)

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
  #expect(episode2.sizeInBytes == 30_000_000)
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

@Test
func testParseRealWorldFeed() throws {
  let xmlString = """
  <?xml version="1.0" encoding="UTF-8"?>
  <rss version="2.0" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd">
    <channel>
      <title>Test Real World Podcast</title>
      <description>A real-world test podcast</description>
      <link>https://example.com</link>
      <itunes:image href="https://example.com/show-artwork.jpg"/>

      <item>
        <title>Guarding Your Heart</title>
        <pubDate>Mon, 01 Jan 2024 12:00:00 +0000</pubDate>
        <guid>real-world-1</guid>
        <enclosure url="https://example.com/episode.mp3" length="36828271" type="audio/mpeg" />
        <itunes:author>Jason Henderson</itunes:author>
        <itunes:image href="https://example.com/episode-artwork.jpg"/>
        <itunes:subtitle><![CDATA[It is wisdom, and not legalism, to guard your heart, and to pay attention to what is filling your thoughts, your affections and your time.]]></itunes:subtitle>
        <itunes:summary><![CDATA[It is wisdom, and not legalism, to guard your heart, and to pay attention to what is filling your thoughts, your affections and your time. And it is absurd to say that the so-called "little things" of life are not important to God, when, from the creation of man, there has never been anything MORE important to God than what man's heart is loving and following.]]></itunes:summary>
        <description><![CDATA[It is wisdom, and not legalism, to guard your heart, and to pay attention to what is filling your thoughts, your affections and your time.]]></description>
      </item>
    </channel>
  </rss>
  """

  let result = try parsePodcastFeed(xmlString)

  // Test show artwork from itunes:image
  #expect(result.show.name == "Test Real World Podcast")
  #expect(result.show.artworkUrl == "https://example.com/show-artwork.jpg")
  #expect(result.show.description == "A real-world test podcast")

  // Test episode
  #expect(result.episodes.count == 1)
  let episode = result.episodes[0]
  #expect(episode.title == "Guarding Your Heart")
  #expect(episode.audioUrl == "https://example.com/episode.mp3")
  #expect(episode.audioType == .mp3)
  #expect(episode.artworkUrl == "https://example.com/episode-artwork.jpg")
  #expect(episode.guid == "real-world-1")
  #expect(episode.sizeInBytes == 36_828_271)

  // Test CDATA description parsing
  #expect(
    episode
      .description ==
      "It is wisdom, and not legalism, to guard your heart, and to pay attention to what is filling your thoughts, your affections and your time."
  )

  // Test pubDate
  let formatter = DateFormatter()
  formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
  formatter.locale = Locale(identifier: "en_US_POSIX")
  let expectedDate = formatter.date(from: "Mon, 01 Jan 2024 12:00:00 +0000")!
  #expect(episode.pubDate == expectedDate)
}

@Test
func testParseSpanishPodcastFeed() throws {
  let xmlString = """
  <?xml version="1.0" encoding="UTF-8"?>
  <rss version="2.0" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd" xmlns:content="http://purl.org/rss/1.0/modules/content/">
    <channel>
      <title>Spanish Learning Podcast</title>
      <description>Learn Spanish with real examples</description>
      <link>https://lcspodcast.com</link>

      <item>
        <title>148: Right in Spanish: Correcto, derecha, derecho</title>
        <itunes:title>148: Right in Spanish: Correcto, derecha, derecho</itunes:title>
        <pubDate>Wed, 10 Sep 2025 06:00:00 +0000</pubDate>
        <guid isPermaLink="false"><![CDATA[446c5533-344f-4d28-a8c0-a61cc15b8a29]]></guid>
        <link><![CDATA[https://lcspodcast.com/148]]></link>
        <description><![CDATA[<p dir="ltr">How do you say "right" in Spanish? Is it "derecha", "derecho", or "correcto"? Today we'll explore a bunch of important adjectives in Spanish, and we'll get lots of practice choosing the right one.</p> <p>Practice all of today's Spanish for free at <a href= "https://lcspodcast.com/148">LCSPodcast.com/148</a></p>]]></description>
        <content:encoded><![CDATA[<p dir="ltr">How do you say "right" in Spanish? Is it "derecha", "derecho", or "correcto"? Today we'll explore a bunch of important adjectives in Spanish, and we'll get lots of practice choosing the right one.</p> <p>Practice all of today's Spanish for free at <a href= "https://lcspodcast.com/148">LCSPodcast.com/148</a></p>]]></content:encoded>
        <enclosure length="78625008" type="audio/mpeg" url="https://traffic.libsyn.com/secure/dfa45e84-e725-48d9-855e-11a263a101d3/1756505423974_148_148__Right_in_Spanish__Correcto_derecha_derecho.mp3?dest-id=3943362" />
        <itunes:duration>31:59</itunes:duration>
        <itunes:explicit>false</itunes:explicit>
        <itunes:keywords />
        <itunes:subtitle><![CDATA[How do you say "right" in Spanish? Is it "derecha", "derecho", or "correcto"? Today we'll explore a bunch of important adjectives in Spanish, and we'll get lots of practice choosing the right one. Practice all of today's Spanish...]]></itunes:subtitle>
        <itunes:episode>148</itunes:episode>
        <itunes:episodeType>full</itunes:episodeType>
        <itunes:author>Timothy Moser, Founder, LearnCraft Spanish</itunes:author>
      </item>

      <item>
        <title>12: What Is “Is” in Spanish?</title>
        <itunes:title>12: What Is “Is” in Spanish?</itunes:title>
        <pubDate>Tue, 04 Mar 2025 08:00:00 +0000</pubDate>
        <guid isPermaLink="false"><![CDATA[a178574c-5450-4dd1-966e-f0d18629806e]]></guid>
        <link><![CDATA[https://lcspodcast.com/11]]></link>
        <itunes:image href="https://static.libsyn.com/p/assets/3/4/9/2/3492a4c3453b43e316c3140a3186d450/podcast_artwork_2025-20250411-ngp2171nbs.png" />
        <description><![CDATA[<p dir="ltr">How do you say “is” in Spanish? It MIGHT be the word “es”... and it might not! Let’s learn our first conjugation of Ser, and we’ll explore when you might use this word. This is the most common verb in Spanish, and the most common conjugation (by far). Today we’ll get some practice with “es” in a lot of sentence contexts.</p> <p>Practice all of today’s Spanish for free at <a href= "https://lcspodcast.com/12">LCSPodcast.com/12</a></p>]]></description>
        <content:encoded><![CDATA[<p dir="ltr">How do you say “is” in Spanish? It MIGHT be the word “es”... and it might not! Let’s learn our first conjugation of Ser, and we’ll explore when you might use this word. This is the most common verb in Spanish, and the most common conjugation (by far). Today we’ll get some practice with “es” in a lot of sentence contexts.</p> <p>Practice all of today’s Spanish for free at <a href= "https://lcspodcast.com/12">LCSPodcast.com/12</a></p>]]></content:encoded>
        <enclosure length="50337176" type="audio/mpeg" url="https://traffic.libsyn.com/secure/dfa45e84-e725-48d9-855e-11a263a101d3/012__What_Is__Is__in_Spanish_.mp3?dest-id=3943362" />
        <itunes:duration>20:11</itunes:duration>
        <itunes:explicit>false</itunes:explicit>
        <itunes:keywords />
        <itunes:subtitle><![CDATA[How do you say “is” in Spanish? It MIGHT be the word “es”... and it might not! Let’s learn our first conjugation of Ser, and we’ll explore when you might use this word. This is the most common verb in Spanish, and the most common...]]></itunes:subtitle>
        <itunes:episode>11</itunes:episode>
        <itunes:episodeType>full</itunes:episodeType>
        <itunes:author>Timothy Moser, Founder, LearnCraft Spanish</itunes:author>
      </item>
    </channel>
  </rss>
  """

  let result = try parsePodcastFeed(xmlString)

  // Test show
  #expect(result.show.name == "Spanish Learning Podcast")
  #expect(result.show.description == "Learn Spanish with real examples")

  // Test episodes
  #expect(result.episodes.count == 2)
  let episode = result.episodes[0]
  #expect(episode.title == "148: Right in Spanish: Correcto, derecha, derecho")
  #expect(
    episode
      .audioUrl ==
      "https://traffic.libsyn.com/secure/dfa45e84-e725-48d9-855e-11a263a101d3/1756505423974_148_148__Right_in_Spanish__Correcto_derecha_derecho.mp3?dest-id=3943362"
  )
  #expect(episode.audioType == .mp3)
  #expect(episode.guid == "446c5533-344f-4d28-a8c0-a61cc15b8a29")
  #expect(episode.websiteUrl == "https://lcspodcast.com/148")
  #expect(episode.duration == 1919) // 31:59 in seconds
  #expect(episode.episodeNumber == 148)

  // Test HTML tag removal from description
  #expect(
    episode
      .description ==
      "How do you say \"right\" in Spanish? Is it \"derecha\", \"derecho\", or \"correcto\"? Today we'll explore a bunch of important adjectives in Spanish, and we'll get lots of practice choosing the right one. Practice all of today's Spanish for free at LCSPodcast.com/148"
  )

  // Test pubDate - this is a future date: Wed, 10 Sep 2025
  let formatter = DateFormatter()
  formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
  formatter.locale = Locale(identifier: "en_US_POSIX")
  let expectedDate = formatter.date(from: "Wed, 10 Sep 2025 06:00:00 +0000")!
  #expect(episode.pubDate == expectedDate)

  let episode2 = result.episodes[1]
  #expect(episode2.title == "12: What Is “Is” in Spanish?")
  #expect(episode2.episodeNumber == 11)
}
