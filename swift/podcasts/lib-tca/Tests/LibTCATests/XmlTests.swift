import Testing
import XCTest

@testable import LibTCA

@Test
func parsePodcastFeedBasic() throws {
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

  let result = try parsePodcastFeed(xmlString, source: "")

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
func parsePodcastFeedMinimal() throws {
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

  let result = try parsePodcastFeed(xmlString, source: "")

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
  #expect(episode.duration == nil)

  // Check pubDate
  let formatter = DateFormatter()
  formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
  formatter.locale = Locale(identifier: "en_US_POSIX")
  let expectedDate = formatter.date(from: "Mon, 01 Jan 2024 12:00:00 +0000")!
  #expect(episode.pubDate == expectedDate)
}

@Test
func parseDurationFormats() throws {
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

  let result = try parsePodcastFeed(xmlString, source: "")

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
func parseInvalidXML() {
  let invalidXml = "This is not XML"

  #expect(throws: XMLParseError.self) {
    try parsePodcastFeed(invalidXml, source: "")
  }
}

@Test
func parseEmptyFeed() {
  let emptyXml = """
  <?xml version="1.0" encoding="UTF-8"?>
  <rss version="2.0">
    <channel>
      <title>Empty Podcast</title>
    </channel>
  </rss>
  """

  #expect(throws: XMLParseError.missingRequiredData) {
    try parsePodcastFeed(emptyXml, source: "")
  }
}

@Test
func parseMissingGuid() {
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
    try parsePodcastFeed(xmlString, source: "")
  }
}

@Test
func parseAudioTypes() throws {
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

  let result = try parsePodcastFeed(xmlString, source: "")

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
func parseRealWorldFeed() throws {
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

  let result = try parsePodcastFeed(xmlString, source: "")

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
      "It is wisdom, and not legalism, to guard your heart, and to pay attention to what is filling your thoughts, your affections and your time.",
  )

  // Test pubDate
  let formatter = DateFormatter()
  formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
  formatter.locale = Locale(identifier: "en_US_POSIX")
  let expectedDate = formatter.date(from: "Mon, 01 Jan 2024 12:00:00 +0000")!
  #expect(episode.pubDate == expectedDate)
}

@Test
func parseSpanishPodcastFeed() throws {
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

  let result = try parsePodcastFeed(xmlString, source: "")

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
      "https://traffic.libsyn.com/secure/dfa45e84-e725-48d9-855e-11a263a101d3/1756505423974_148_148__Right_in_Spanish__Correcto_derecha_derecho.mp3?dest-id=3943362",
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
      "How do you say \"right\" in Spanish? Is it \"derecha\", \"derecho\", or \"correcto\"? Today we'll explore a bunch of important adjectives in Spanish, and we'll get lots of practice choosing the right one. Practice all of today's Spanish for free at LCSPodcast.com/148",
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

@Test
func stripsHtmlTags() throws {
  let xmlString = """
  <?xml version="1.0" encoding="UTF-8"?>
  <rss version="2.0" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd">
    <channel>
      <title>Test Podcast</title>
      <description><![CDATA[%INPUT%]]></description>
      <author>Test Author</author>
      <link>https://example.com</link>
      <image>
        <url>https://example.com/artwork.jpg</url>
      </image>
      <item>
        <title>Episode 1</title>
        <description><![CDATA[%INPUT%]]></description>
        <link>https://example.com/episode1</link>
        <guid>episode-1</guid>
        <pubDate>Mon, 01 Jan 2024 12:00:00 +0000</pubDate>
        <itunes:duration>1:23:45</itunes:duration>
        <itunes:image href="https://example.com/episode1-artwork.jpg"/>
        <enclosure url="https://example.com/episode1.mp3" type="audio/mpeg" length="50000000"/>
      </item>
    </channel>
  </rss>
  """

  let cases = [
    ("<p>Description</p>", "Description"),
    ("<p>Desc <a href=\"\">Link</a></p>", "Desc Link"),
    ("<p>First</p><p>Second</p>", "First Second"),
    (
      "<p>Send email to <a href=\"mailto:a@b.com\"><strong>a.b.com</strong></a>, or call us.</p>",
      "Send email to a.b.com, or call us."
    ),
    ("<p>Description\nwith\n\nnewline\n\n\nmore</p>", "Description with newline more"),
    ("<p>Line1</p>\n<p>Line2</p>", "Line1 Line2"),
  ]

  for (input, expected) in cases {
    let testXml = xmlString.replacingOccurrences(of: "%INPUT%", with: input)
    let feed = try parsePodcastFeed(testXml, source: "")
    #expect(feed.show.description == expected)
    #expect(feed.episodes[0].description == expected)
  }
}

@Test
func parseTALFeed() throws {
  let xmlString = """
  <?xml version="1.0" encoding="utf-8"?>
  <rss version="2.0" xml:base="https://www.thisamericanlife.org/podcast/rss.xml"  xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd" xmlns:media="http://search.yahoo.com/mrss/">
  <channel>
   <title>This American Life</title>
   <link>https://www.thisamericanlife.org/podcast/rss.xml</link>
   <description>Each week we choose a theme. Then anything can happen. This American Life is true stories that unfold like little movies for radio. Personal stories with funny moments, big feelings, and surprising plot twists. Newsy stories that try to capture what it’s like to be alive right now. It’s the most popular weekly podcast in the world, and winner of the first ever Pulitzer Prize for a radio show or podcast. Hosted by Ira Glass and produced in collaboration with WBEZ Chicago.</description>
   <language>en</language>
   <itunes:new-feed-url>https://www.thisamericanlife.org/podcast/rss.xml</itunes:new-feed-url>
   <atom:link href="https://www.thisamericanlife.org/podcast/rss.xml" rel="self" type="application/rss+xml" />
   <copyright>Copyright 1995-2025 This American Life</copyright>
   <itunes:author>This American Life</itunes:author>
   <itunes:subtitle>Each week we choose a theme. Then anything can happen. This American Life is true stories that unfold like little movies for radio. Personal stories with funny moments, big feelings, and surprising plot twists. Newsy stories that try to capture what it’s like to be alive right now. It’s the most popular weekly podcast in the world, and winner of the first ever Pulitzer Prize for a radio show or podcast. Hosted by Ira Glass and produced in collaboration with WBEZ Chicago.</itunes:subtitle>
   <itunes:explicit>false</itunes:explicit>
   <itunes:owner> <itunes:email>web@thislife.org</itunes:email>
  </itunes:owner>
   <itunes:category text="Society &amp; Culture" />
   <itunes:category text="Arts" />
   <itunes:category text="News"> <itunes:category text="Politics" />
  </itunes:category>
   <itunes:image href="https://thisamericanlife.org/sites/all/themes/thislife/img/tal-logo-3000x3000.png" />
  <item>
   <title>867: College Disorientation</title>
   <link>https://www.thisamericanlife.org/867/college-disorientation</link>
   <description>&lt;p&gt;Things are different on college campuses this year. We see inside the drama, with students and staff.

  &lt;/p&gt;&lt;p&gt;Visit &lt;a href=&quot;https://thisamericanlife.supercast.com?utm_source=rss&amp;utm_medium=shownotes&amp;utm_id=lifepartners&quot;&gt;thisamericanlife.org/lifepartners&lt;/a&gt; to sign up for our premium subscription.&lt;/p&gt;&lt;ul&gt;&lt;li&gt;Prologue: We go to orientation at Arizona State University and meet international students who are trying to make friends. (6 minutes)&lt;/li&gt;&lt;li&gt;Act One: The president of the Black Student Union at the University of Utah fights to keep the B in BSU. (30 minutes)&lt;/li&gt;&lt;li&gt;Act Two: A definition of antisemitism, canceled classes, and angry professors at Columbia University. (16 minutes)&lt;/li&gt;&lt;/ul&gt;&lt;p&gt;Transcripts are available at &lt;a href=&quot;https://www.thisamericanlife.org/867/transcript&quot;&gt;thisamericanlife.org&lt;/a&gt;&lt;/p&gt;&lt;p&gt;&lt;a href=&#039;https://www.thisamericanlife.org/page/privacy-policy&#039;&gt;This American Life privacy policy.&lt;/a&gt;&lt;br /&gt;&lt;a href=&#039;https://podcastchoices.com/adchoices&#039;&gt;Learn more about sponsor message choices.&lt;/a&gt;&lt;/p&gt;</description>
   <pubDate>Sun, 14 Sep 2025 18:00:00 -0400</pubDate>
   <guid isPermaLink="false">45952 at https://www.thisamericanlife.org</guid>
   <itunes:episodeType>full</itunes:episodeType>
   <itunes:episode>867</itunes:episode>
   <itunes:title>College Disorientation</itunes:title>
   <itunes:author>This American Life</itunes:author>
   <itunes:explicit>false</itunes:explicit>
   <itunes:image href="https://www.thisamericanlife.org/sites/default/files/styles/rss_image/public/images/rss/tal-867-welcomeback-sq.jpg?itok=0yOLJPiF" />
   <enclosure url="https://pfx.vpixl.com/6qj4J/dts.podtrac.com/redirect.mp3/chrt.fm/track/138C95/pdst.fm/e/prefix.up.audio/s/traffic.megaphone.fm/NPR2581159385.mp3" type="audio/mpeg" />
   <itunes:duration>00:57:33</itunes:duration>
   <itunes:subtitle>Things are different on college campuses this year. We see inside the drama, with students and staff.
  </itunes:subtitle>
   <itunes:summary>Things are different on college campuses this year. We see inside the drama, with students and staff.



  Prologue: We go to orientation at Arizona State University and meet international students who are trying to make friends. (6 minutes)

  Act One: The president of the Black Student Union at the University of Utah fights to keep the B in BSU. (30 minutes)

  Act Two: A definition of antisemitism, canceled classes, and angry professors at Columbia University. (16 minutes)</itunes:summary>
  </item>
  <item>
   <title>866: Watch Out for That Tree</title>
   <link>https://www.thisamericanlife.org/866/watch-out-for-that-tree</link>
   <description>&lt;p&gt;Small human plans that run into much larger obstacles.

  &lt;/p&gt;&lt;p&gt;Visit &lt;a href=&quot;https://thisamericanlife.supercast.com?utm_source=rss&amp;utm_medium=shownotes&amp;utm_id=lifepartners&quot;&gt;thisamericanlife.org/lifepartners&lt;/a&gt; to sign up for our premium subscription.&lt;/p&gt;&lt;ul&gt;&lt;li&gt;Prologue: Angela&#039;s dad, an accountant, made a spreadsheet to prepare for their family trip to a national park. But there are things you never think to put in a spreadsheet. (7 minutes)&lt;/li&gt;&lt;li&gt;Act One: A young couple, excited to start a new chapter in their lives, is suddenly put on a very different trajectory. (30 minutes)&lt;/li&gt;&lt;li&gt;Act Two: A sixteen-year-old plans out a prank, and a complete stranger from Honduras ends up in a million-dollar deal. What could go wrong? (25 minutes)&lt;/li&gt;&lt;/ul&gt;&lt;p&gt;Transcripts are available at &lt;a href=&quot;https://www.thisamericanlife.org/866/transcript&quot;&gt;thisamericanlife.org&lt;/a&gt;&lt;/p&gt;&lt;p&gt;&lt;a href=&#039;https://www.thisamericanlife.org/page/privacy-policy&#039;&gt;This American Life privacy policy.&lt;/a&gt;&lt;br /&gt;&lt;a href=&#039;https://podcastchoices.com/adchoices&#039;&gt;Learn more about sponsor message choices.&lt;/a&gt;&lt;/p&gt;</description>
   <pubDate>Sun, 07 Sep 2025 18:00:00 -0400</pubDate>
   <guid isPermaLink="false">45941 at https://www.thisamericanlife.org</guid>
   <itunes:episodeType>full</itunes:episodeType>
   <itunes:episode>866</itunes:episode>
   <itunes:title>Watch Out for That Tree</itunes:title>
   <itunes:author>This American Life</itunes:author>
   <itunes:explicit>false</itunes:explicit>
   <itunes:image href="https://www.thisamericanlife.org/sites/default/files/styles/rss_image/public/images/rss/tal-866-sq.jpg?itok=JenMuC-y" />
   <enclosure url="https://pfx.vpixl.com/6qj4J/dts.podtrac.com/redirect.mp3/chrt.fm/track/138C95/pdst.fm/e/prefix.up.audio/s/traffic.megaphone.fm/NPR5310093493.mp3" type="audio/mpeg" />
   <itunes:duration>01:07:30</itunes:duration>
   <itunes:subtitle>Small human plans that run into much larger obstacles.
  </itunes:subtitle>
   <itunes:summary>Small human plans that run into much larger obstacles.



  Prologue: Angela&#039;s dad, an accountant, made a spreadsheet to prepare for their family trip to a national park. But there are things you never think to put in a spreadsheet. (7 minutes)

  Act One: A young couple, excited to start a new chapter in their lives, is suddenly put on a very different trajectory. (30 minutes)

  Act Two: A sixteen-year-old plans out a prank, and a complete stranger from Honduras ends up in a million-dollar deal. What could go wrong? (25 minutes)</itunes:summary>
  </item>
  <item>
   <title>233: Starting From Scratch</title>
   <link>https://www.thisamericanlife.org/233/starting-from-scratch</link>
   <description>&lt;p&gt;People starting over—sometimes because they want to, other times because they have to.

  &lt;/p&gt;&lt;p&gt;Visit &lt;a href=&quot;https://thisamericanlife.supercast.com&quot;&gt;thisamericanlife.org/lifepartners&lt;/a&gt; to sign up for our premium subscription.&lt;/p&gt;&lt;ul&gt;&lt;li&gt;Prologue: Host Ira Glass talks to Jorge Just, who thought he&#039;d started over successfully. He&#039;d moved to New York, found an apartment that everyone told him was a great deal, things were looking good. Then a reality television show visited his building. (8 minutes)&lt;/li&gt;&lt;li&gt;Act One: Molly FitzSimons tells the story of her father starting over. After 25 years in the same zip code, as an executive in the same company, he moved to Los Angeles and tried to start over in a new life with a new venture: A cable channel, with no people, no talking, no plots, but lots and lots of puppies. (15 minutes)&lt;/li&gt;&lt;li&gt;Act Two: Mary Beth Kirchner documents one day in the life of a hustler named Joe, who wakes up every morning broke, hustles as much as $10,000 during the day and then loses most of it by the time he goes to bed. What it&#039;s like to start from scratch every day of your life. (18 minutes)&lt;/li&gt;&lt;li&gt;Act Three: Jonathan Goldstein reads a story about the first people to ever start from scratch, a couple named Adam and Eve. (14 minutes)&lt;/li&gt;&lt;/ul&gt;&lt;p&gt;Transcripts are available at &lt;a href=&quot;https://www.thisamericanlife.org/233/transcript&quot;&gt;thisamericanlife.org&lt;/a&gt;&lt;/p&gt;&lt;p&gt;&lt;a href=&#039;https://www.thisamericanlife.org/page/privacy-policy&#039;&gt;This American Life privacy policy.&lt;/a&gt;&lt;br /&gt;&lt;a href=&#039;https://podcastchoices.com/adchoices&#039;&gt;Learn more about sponsor message choices.&lt;/a&gt;&lt;/p&gt;</description>
   <pubDate>Sun, 31 Aug 2025 18:00:00 -0400</pubDate>
   <guid isPermaLink="false">37440 at https://www.thisamericanlife.org</guid>
   <itunes:episodeType>full</itunes:episodeType>
   <itunes:episode>233</itunes:episode>
   <itunes:title>Starting From Scratch</itunes:title>
   <itunes:author>This American Life</itunes:author>
   <itunes:explicit>false</itunes:explicit>
   <itunes:image href="https://www.thisamericanlife.org/sites/default/files/styles/rss_image/public/images/rss/istock-151622920-sq.jpg?itok=cRpnlcXV" />
   <enclosure url="https://pfx.vpixl.com/6qj4J/dts.podtrac.com/redirect.mp3/chrt.fm/track/138C95/pdst.fm/e/prefix.up.audio/s/traffic.megaphone.fm/NPR4591929511.mp3" type="audio/mpeg" />
   <itunes:duration>01:00:31</itunes:duration>
   <itunes:subtitle>A man in retirement tries to start over in a new life with a new venture: a cable channel, with lots of puppies.
  </itunes:subtitle>
   <itunes:summary>People starting over—sometimes because they want to, other times because they have to.



  Prologue: Host Ira Glass talks to Jorge Just, who thought he&#039;d started over successfully. He&#039;d moved to New York, found an apartment that everyone told him was a great deal, things were looking good. Then a reality television show visited his building. (8 minutes)

  Act One: Molly FitzSimons tells the story of her father starting over. After 25 years in the same zip code, as an executive in the same company, he moved to Los Angeles and tried to start over in a new life with a new venture: A cable channel, with no people, no talking, no plots, but lots and lots of puppies. (15 minutes)

  Act Two: Mary Beth Kirchner documents one day in the life of a hustler named Joe, who wakes up every morning broke, hustles as much as $10,000 during the day and then loses most of it by the time he goes to bed. What it&#039;s like to start from scratch every day of your life. (18 minutes)

  Act Three: Jonathan Goldstein reads a story about the first people to ever start from scratch, a couple named Adam and Eve. (14 minutes)</itunes:summary>
  </item>
  <item>
   <title>865: The Other Territory</title>
   <link>https://www.thisamericanlife.org/865/the-other-territory</link>
   <description>&lt;p&gt;Since October 7th, while the world has focused its attention on Gaza, the Israeli government has tightened the screws on the three million Palestinians in the West Bank in all sorts of dramatic ways. We travel to the West Bank to see these changes in person.

  &lt;/p&gt;&lt;p&gt;Visit &lt;a href=&quot;https://thisamericanlife.supercast.com&quot;&gt;thisamericanlife.org/lifepartners&lt;/a&gt; to sign up for our premium subscription.&lt;/p&gt;&lt;ul&gt;&lt;li&gt;Prologue: Ira joins Hamed on his Monday commute. He has to navigate a constantly changing series of checkpoints and roadblocks to get to work each day. Hamed works for Comet-ME, which sets up solar panels, water systems, and security cameras in small villages all over the West Bank. (13 minutes)&lt;/li&gt;&lt;li&gt;Act One: Settler violence has worsened significantly in the West Bank since October 7, 2023. Yael Even Or travels to a tiny village called Tuba, surrounded by Israeli settlements, to meet the 27-year-old resident trying to protect it. (26 minutes)&lt;/li&gt;&lt;li&gt;Act 2: Two quick snapshots of life in the West Bank since October 7th. (6 minutes)&lt;/li&gt;&lt;li&gt;Act Two: After October 7th, Israeli Minister of Security Itamar Ben-Gvir increased restrictions on Palestinian prisoners in Israeli security prisons. Prisoners started dying. Dana Chivvis looks into one of those deaths. (25 minutes)&lt;/li&gt;&lt;/ul&gt;&lt;p&gt;Transcripts are available at &lt;a href=&quot;https://www.thisamericanlife.org/865/transcript&quot;&gt;thisamericanlife.org&lt;/a&gt;&lt;/p&gt;&lt;p&gt;&lt;a href=&#039;https://www.thisamericanlife.org/page/privacy-policy&#039;&gt;This American Life privacy policy.&lt;/a&gt;&lt;br /&gt;&lt;a href=&#039;https://podcastchoices.com/adchoices&#039;&gt;Learn more about sponsor message choices.&lt;/a&gt;&lt;/p&gt;</description>
   <pubDate>Sun, 24 Aug 2025 18:00:00 -0400</pubDate>
   <guid isPermaLink="false">45940 at https://www.thisamericanlife.org</guid>
   <itunes:episodeType>full</itunes:episodeType>
   <itunes:episode>865</itunes:episode>
   <itunes:title>The Other Territory</itunes:title>
   <itunes:author>This American Life</itunes:author>
   <itunes:explicit>false</itunes:explicit>
   <itunes:image href="https://www.thisamericanlife.org/sites/default/files/styles/rss_image/public/images/rss/tal-865-theotherterritory-sakirkhader-mg1278411-sq_0.jpg?itok=y9poChwD" />
   <enclosure url="https://pfx.vpixl.com/6qj4J/dts.podtrac.com/redirect.mp3/chrt.fm/track/138C95/pdst.fm/e/prefix.up.audio/s/traffic.megaphone.fm/NPR3210182538.mp3" type="audio/mpeg" />
   <itunes:duration>01:14:50</itunes:duration>
   <itunes:subtitle>Since October 7, Israel has intensified restrictions on West Bank Palestinians while global attention focused on Gaza. We travel to the West Bank to see these changes in person.
  </itunes:subtitle>
   <itunes:summary>Since October 7th, while the world has focused its attention on Gaza, the Israeli government has tightened the screws on the three million Palestinians in the West Bank in all sorts of dramatic ways. We travel to the West Bank to see these changes in person.



  Prologue: Ira joins Hamed on his Monday commute. He has to navigate a constantly changing series of checkpoints and roadblocks to get to work each day. Hamed works for Comet-ME, which sets up solar panels, water systems, and security cameras in small villages all over the West Bank. (13 minutes)

  Act One: Settler violence has worsened significantly in the West Bank since October 7, 2023. Yael Even Or travels to a tiny village called Tuba, surrounded by Israeli settlements, to meet the 27-year-old resident trying to protect it. (26 minutes)

  Act 2: Two quick snapshots of life in the West Bank since October 7th. (6 minutes)

  Act Two: After October 7th, Israeli Minister of Security Itamar Ben-Gvir increased restrictions on Palestinian prisoners in Israeli security prisons. Prisoners started dying. Dana Chivvis looks into one of those deaths. (25 minutes)</itunes:summary>
  </item>
  <item>
   <title>864: Chicago Hope</title>
   <link>https://www.thisamericanlife.org/864/chicago-hope</link>
   <description>&lt;p&gt;The story of the most commonly performed surgery, and what goes wrong with it – terribly wrong – 100,000 times a year in the United States. We’re excited to bring you the first episode of The Retrievals, Season 2, the new show from longtime This American Life producer and editor Susan Burton. It’s from Serial Productions and The New York Times.

  &lt;/p&gt;&lt;p&gt;Visit &lt;a href=&quot;https://thisamericanlife.supercast.com?utm_source=rss&amp;utm_medium=shownotes&amp;utm_id=lifepartners&quot;&gt;thisamericanlife.org/lifepartners&lt;/a&gt; to sign up for our premium subscription.&lt;/p&gt;&lt;ul&gt;&lt;li&gt;Prologue: Ira Glass introduces the first episode of an inventive new podcast from longtime This American Life producer and editor Susan Burton.&lt;/li&gt;&lt;li&gt;Act One: Susan Burton introduces Mindy, a labor and delivery nurse at UI Health at the University of Illinois at Chicago. (5 minutes)&lt;/li&gt;&lt;li&gt;Act Two: Another labor and delivery nurse at UI Health, Clara, gets ready to deliver twins at her own hospital and receives an epidural. (19 minutes)&lt;/li&gt;&lt;li&gt;Act Three: Clara’s anesthesia is not working. She is now in the middle of major abdominal surgery, and she can feel that surgery. (21 minutes)&lt;/li&gt;&lt;li&gt;Act Four: Heather, the head of obstetric anesthesia at UI Health, gets up onstage and asks a ballroom full of hundreds of anesthesiologists to wrestle with the question of why patients are feeling pain during C-sections, and what they can do to solve it. (8 minutes)&lt;/li&gt;&lt;/ul&gt;&lt;p&gt;Transcripts are available at &lt;a href=&quot;https://www.thisamericanlife.org/864/transcript&quot;&gt;thisamericanlife.org&lt;/a&gt;&lt;/p&gt;&lt;p&gt;&lt;a href=&#039;https://www.thisamericanlife.org/page/privacy-policy&#039;&gt;This American Life privacy policy.&lt;/a&gt;&lt;br /&gt;&lt;a href=&#039;https://podcastchoices.com/adchoices&#039;&gt;Learn more about sponsor message choices.&lt;/a&gt;&lt;/p&gt;</description>
   <pubDate>Sun, 20 Jul 2025 18:00:00 -0400</pubDate>
   <guid isPermaLink="false">45931 at https://www.thisamericanlife.org</guid>
   <itunes:episodeType>full</itunes:episodeType>
   <itunes:episode>864</itunes:episode>
   <itunes:title>Chicago Hope</itunes:title>
   <itunes:author>This American Life</itunes:author>
   <itunes:explicit>false</itunes:explicit>
   <itunes:image href="https://www.thisamericanlife.org/sites/default/files/styles/rss_image/public/images/rss/tal-864-retrievals-sq.jpg?itok=gA3HBjk4" />
   <enclosure url="https://pfx.vpixl.com/6qj4J/dts.podtrac.com/redirect.mp3/chrt.fm/track/138C95/pdst.fm/e/prefix.up.audio/s/traffic.megaphone.fm/NPR3974539898.mp3" type="audio/mpeg" />
   <itunes:duration>00:59:25</itunes:duration>
   <itunes:subtitle>The story of the most commonly performed surgery, and what goes terribly wrong with it.
  </itunes:subtitle>
   <itunes:summary>The story of the most commonly performed surgery, and what goes wrong with it – terribly wrong – 100,000 times a year in the United States. We’re excited to bring you the first episode of The Retrievals, Season 2, the new show from longtime This American Life producer and editor Susan Burton. It’s from Serial Productions and The New York Times.



  Prologue: Ira Glass introduces the first episode of an inventive new podcast from longtime This American Life producer and editor Susan Burton.

  Act One: Susan Burton introduces Mindy, a labor and delivery nurse at UI Health at the University of Illinois at Chicago. (5 minutes)

  Act Two: Another labor and delivery nurse at UI Health, Clara, gets ready to deliver twins at her own hospital and receives an epidural. (19 minutes)

  Act Three: Clara’s anesthesia is not working. She is now in the middle of major abdominal surgery, and she can feel that surgery. (21 minutes)

  Act Four: Heather, the head of obstetric anesthesia at UI Health, gets up onstage and asks a ballroom full of hundreds of anesthesiologists to wrestle with the question of why patients are feeling pain during C-sections, and what they can do to solve it. (8 minutes)</itunes:summary>
  </item>
  <item>
    <title>Bonus: Nancy's Deep Cuts</title>
    <description>&lt;p&gt;Ira Glass talks with longtime producer Nancy Updike about the most personal stories they have put on the radio. This is a sample of the bonus episodes we regularly release to our This American Life Partners.&lt;/p&gt;

  &lt;p&gt;To gain access to all the bonus episodes AND help us keep making This American Life, join at &lt;a href=&quot;https://thisamericanlife.supercast.com?utm_source=rss&amp;amp;utm_medium=shownotes&amp;amp;utm_campaign=bonus-content-promo&amp;amp;utm_id=lifepartners&amp;amp;utm_content=20250718-nancydeepcuts&quot;&gt;thisamericanlife.org/lifepartners&lt;/a&gt;.&lt;/p&gt;</description>
    <pubDate>Thu, 17 Jul 2025 00:00:00 -0400</pubDate>
    <guid isPermaLink="false">45933 at https://www.thisamericanlife.org</guid>
    <enclosure url="https://www.thisamericanlife.org/sites/default/files/audio/upload/extra/nancy_deep_cuts_part_1_public_feed_07_18_2026_v3.mp3" type="audio/mpeg" />
    <itunes:image href="https://www.thisamericanlife.org/sites/default/files/styles/rss_image/public/images/rss/this_american_life_partners_-_teal.jpg?itok=mZBuUS4l" />
    <media:thumbnail url="https://www.thisamericanlife.org/sites/default/files/youtube/this_american_life_partners_teal_yt.jpg" height="720" width="1280" />
    <itunes:author>This American Life</itunes:author>
    <itunes:duration>00:26:44</itunes:duration>
    <link>https://www.thisamericanlife.org</link>
    <itunes:subtitle>Ira Glass talks with Nancy Updike about the most personal stories they have put on the radio.</itunes:subtitle>
    <itunes:summary>Ira Glass talks with Nancy Updike about the most personal stories they have put on the radio.</itunes:summary>
  </item>
  <item>
   <title>863: Championship Window</title>
   <link>https://www.thisamericanlife.org/863/championship-window</link>
   <description>&lt;p&gt;People on a mission to achieve their goals before their window of opportunity closes.

  &lt;/p&gt;&lt;p&gt;Visit &lt;a href=&quot;https://thisamericanlife.supercast.com?utm_source=rss&amp;utm_medium=shownotes&amp;utm_id=lifepartners&quot;&gt;thisamericanlife.org/lifepartners&lt;/a&gt; to sign up for our premium subscription.&lt;/p&gt;&lt;ul&gt;&lt;li&gt;Prologue: Guest host Emmanuel Dzotsi goes to a packed sports bar in Brooklyn for his favorite soccer team’s biggest game in years. (6 minutes)&lt;/li&gt;&lt;li&gt;Act One: Connie Wang tells the story of a championship window she didn&#039;t realize she was in — until it was too late. (14 minutes)&lt;/li&gt;&lt;li&gt;Act Two: Seth Lind, our Operations Director, isn’t a crier. But he wants to connect with his emotions, so guest host Emmanuel Dzotsi sets up an unconventional experiment. (14 minutes)&lt;/li&gt;&lt;li&gt;Act Three: Two college baseball teams with horrible losing streaks — a combined 141 games — are scheduled to play each other. One of them must finally win. (14 minutes)&lt;/li&gt;&lt;/ul&gt;&lt;p&gt;Transcripts are available at &lt;a href=&quot;https://www.thisamericanlife.org/863/transcript&quot;&gt;thisamericanlife.org&lt;/a&gt;&lt;/p&gt;&lt;p&gt;&lt;a href=&#039;https://www.thisamericanlife.org/page/privacy-policy&#039;&gt;This American Life privacy policy.&lt;/a&gt;&lt;br /&gt;&lt;a href=&#039;https://podcastchoices.com/adchoices&#039;&gt;Learn more about sponsor message choices.&lt;/a&gt;&lt;/p&gt;</description>
   <pubDate>Sun, 29 Jun 2025 18:00:00 -0400</pubDate>
   <guid isPermaLink="false">45913 at https://www.thisamericanlife.org</guid>
   <itunes:episodeType>full</itunes:episodeType>
   <itunes:episode>863</itunes:episode>
   <itunes:title>Championship Window</itunes:title>
   <itunes:author>This American Life</itunes:author>
   <itunes:explicit>false</itunes:explicit>
   <itunes:image href="https://www.thisamericanlife.org/sites/default/files/styles/rss_image/public/images/rss/tal-863-championshipwindow-sq.jpg?itok=IqJSuqm3" />
   <enclosure url="https://pfx.vpixl.com/6qj4J/dts.podtrac.com/redirect.mp3/chrt.fm/track/138C95/pdst.fm/e/prefix.up.audio/s/traffic.megaphone.fm/NPR9271186174.mp3" type="audio/mpeg" />
   <itunes:duration>00:58:00</itunes:duration>
   <itunes:subtitle>People on a mission to achieve their goals before their window of opportunity closes.
  </itunes:subtitle>
   <itunes:summary>People on a mission to achieve their goals before their window of opportunity closes.



  Prologue: Guest host Emmanuel Dzotsi goes to a packed sports bar in Brooklyn for his favorite soccer team’s biggest game in years. (6 minutes)

  Act One: Connie Wang tells the story of a championship window she didn&#039;t realize she was in — until it was too late. (14 minutes)

  Act Two: Seth Lind, our Operations Director, isn’t a crier. But he wants to connect with his emotions, so guest host Emmanuel Dzotsi sets up an unconventional experiment. (14 minutes)

  Act Three: Two college baseball teams with horrible losing streaks — a combined 141 games — are scheduled to play each other. One of them must finally win. (14 minutes)</itunes:summary>
  </item>
  <item>
   <title>862: Some Things We Don&#039;t Do Anymore</title>
   <link>https://www.thisamericanlife.org/862/some-things-we-dont-do-anymore</link>
   <description>&lt;p&gt;On his first day in office, President Trump decided to freeze all U.S. foreign aid. Soon after, his administration effectively dissolved USAID—the federal agency that delivers billions in food, medicine, and other aid worldwide. Many of its programs have been canceled. Now, as USAID officially winds down, we try to assess its impact. What was good? What was not so good? We meet people around the world wrestling with these questions and trying to navigate this chaotic moment.

  &lt;/p&gt;&lt;p&gt;Visit &lt;a href=&quot;https://thisamericanlife.supercast.com?utm_source=rss&amp;utm_medium=shownotes&amp;utm_id=lifepartners&quot;&gt;thisamericanlife.org/lifepartners&lt;/a&gt; to sign up for our premium subscription.&lt;/p&gt;&lt;ul&gt;&lt;li&gt;Prologue: Just one box of a specially enriched peanut butter paste can save the life of a severely malnourished child. So why have 500,000 of those boxes been stuck in warehouses in Rhode Island? (13 minutes)&lt;/li&gt;&lt;li&gt;Act One: USAID was founded in 1961. Since then, it has spent hundreds of billions of dollars all over the world. What did that get us? Producer David Kestenbaum talked with Joshua Craze and John Norris about that. (12 minutes)&lt;/li&gt;&lt;li&gt;Act Two: Two Americans moved to Eswatini when that country was the epicenter of the AIDS epidemic. With support from USAID, they built a clinic and started serving HIV+ patients. Now that US support for their clinic has ended, they are wondering if what they did was entirely a good thing. (27 minutes)&lt;/li&gt;&lt;li&gt;Act Three: When USAID suddenly stopped all foreign assistance without warning or a transition plan, it sent people all over the world scrambling. Especially those relying on daily medicine provided by USAID. Producer Ike Sriskandarajah spoke to two families in Kenya who were trying to figure it out. (8 minutes)&lt;/li&gt;&lt;/ul&gt;&lt;p&gt;Transcripts are available at &lt;a href=&quot;https://www.thisamericanlife.org/862/transcript&quot;&gt;thisamericanlife.org&lt;/a&gt;&lt;/p&gt;&lt;p&gt;&lt;a href=&#039;https://www.thisamericanlife.org/page/privacy-policy&#039;&gt;This American Life privacy policy.&lt;/a&gt;&lt;br /&gt;&lt;a href=&#039;https://podcastchoices.com/adchoices&#039;&gt;Learn more about sponsor message choices.&lt;/a&gt;&lt;/p&gt;</description>
   <pubDate>Sun, 22 Jun 2025 18:00:00 -0400</pubDate>
   <guid isPermaLink="false">45909 at https://www.thisamericanlife.org</guid>
   <itunes:episodeType>full</itunes:episodeType>
   <itunes:episode>862</itunes:episode>
   <itunes:title>Some Things We Don&#039;t Do Anymore</itunes:title>
   <itunes:author>This American Life</itunes:author>
   <itunes:explicit>false</itunes:explicit>
   <itunes:image href="https://www.thisamericanlife.org/sites/default/files/styles/rss_image/public/images/rss/tal-862-somethingswedontdoanymore-sq.jpg?itok=wJ5Ce_hO" />
   <enclosure url="https://pfx.vpixl.com/6qj4J/dts.podtrac.com/redirect.mp3/chrt.fm/track/138C95/pdst.fm/e/prefix.up.audio/s/traffic.megaphone.fm/NPR9826036922.mp3" type="audio/mpeg" />
   <itunes:duration>01:06:29</itunes:duration>
   <itunes:subtitle>Trump froze U.S. foreign aid and dismantled USAID. We examine the agency’s impact and hear from people trying to navigate this chaotic moment.
  </itunes:subtitle>
   <itunes:summary>On his first day in office, President Trump decided to freeze all U.S. foreign aid. Soon after, his administration effectively dissolved USAID—the federal agency that delivers billions in food, medicine, and other aid worldwide. Many of its programs have been canceled. Now, as USAID officially winds down, we try to assess its impact. What was good? What was not so good? We meet people around the world wrestling with these questions and trying to navigate this chaotic moment.



  Prologue: Just one box of a specially enriched peanut butter paste can save the life of a severely malnourished child. So why have 500,000 of those boxes been stuck in warehouses in Rhode Island? (13 minutes)

  Act One: USAID was founded in 1961. Since then, it has spent hundreds of billions of dollars all over the world. What did that get us? Producer David Kestenbaum talked with Joshua Craze and John Norris about that. (12 minutes)

  Act Two: Two Americans moved to Eswatini when that country was the epicenter of the AIDS epidemic. With support from USAID, they built a clinic and started serving HIV+ patients. Now that US support for their clinic has ended, they are wondering if what they did was entirely a good thing. (27 minutes)

  Act Three: When USAID suddenly stopped all foreign assistance without warning or a transition plan, it sent people all over the world scrambling. Especially those relying on daily medicine provided by USAID. Producer Ike Sriskandarajah spoke to two families in Kenya who were trying to figure it out. (8 minutes)</itunes:summary>
  </item>
  <item>
   <title>861: Group Chat</title>
   <link>https://www.thisamericanlife.org/861/group-chat</link>
   <description>&lt;p&gt;Conversations across a divide: People who are outside a war zone check in with family, friends, and strangers inside.

  &lt;/p&gt;&lt;p&gt;Visit &lt;a href=&quot;https://thisamericanlife.supercast.com?utm_source=rss&amp;utm_medium=shownotes&amp;utm_id=lifepartners&quot;&gt;thisamericanlife.org/lifepartners&lt;/a&gt; to sign up for our premium subscription.&lt;/p&gt;&lt;ul&gt;&lt;li&gt;Prologue: The Hammash family’s group chat unfolds over texts, starting before the war. (8 minutes)&lt;/li&gt;&lt;li&gt;Act One: When Yousef Hammash left Gaza a year ago, his sisters decided to stay behind. We hear about the toll that separation has taken on Yousef and the sister he’s closest to, Aseel. (30 minutes)&lt;/li&gt;&lt;li&gt;Act Two: Mohammed Mhawish, a reporter who left Gaza a year ago with his family, talks to a young woman in Gaza about how she manages her hunger. Israel blockaded all food from Gaza for more than two months. (15 minutes)&lt;/li&gt;&lt;li&gt;Coda: Chana gives a short update about Banias, a 9-year-old girl in Gaza she&#039;s been speaking with for months. (4 minutes)&lt;/li&gt;&lt;/ul&gt;&lt;p&gt;Transcripts are available at &lt;a href=&quot;https://www.thisamericanlife.org/861/transcript&quot;&gt;thisamericanlife.org&lt;/a&gt;&lt;/p&gt;&lt;p&gt;&lt;a href=&#039;https://www.thisamericanlife.org/page/privacy-policy&#039;&gt;This American Life privacy policy.&lt;/a&gt;&lt;br /&gt;&lt;a href=&#039;https://podcastchoices.com/adchoices&#039;&gt;Learn more about sponsor message choices.&lt;/a&gt;&lt;/p&gt;</description>
   <pubDate>Sun, 01 Jun 2025 18:00:00 -0400</pubDate>
   <guid isPermaLink="false">45896 at https://www.thisamericanlife.org</guid>
   <itunes:episodeType>full</itunes:episodeType>
   <itunes:episode>861</itunes:episode>
   <itunes:title>Group Chat</itunes:title>
   <itunes:author>This American Life</itunes:author>
   <itunes:explicit>false</itunes:explicit>
   <itunes:image href="https://www.thisamericanlife.org/sites/default/files/styles/rss_image/public/images/rss/tal-861-groupchat-sq_0.jpg?itok=FDTfGF_w" />
   <enclosure url="https://pfx.vpixl.com/6qj4J/dts.podtrac.com/redirect.mp3/chrt.fm/track/138C95/pdst.fm/e/prefix.up.audio/s/traffic.megaphone.fm/NPR4038782354.mp3" type="audio/mpeg" />
   <itunes:duration>01:01:22</itunes:duration>
   <itunes:subtitle>Conversations across a divide: People who are outside a war zone check in with family, friends, and strangers inside.
  </itunes:subtitle>
   <itunes:summary>Conversations across a divide: People who are outside a war zone check in with family, friends, and strangers inside.



  Prologue: The Hammash family’s group chat unfolds over texts, starting before the war. (8 minutes)

  Act One: When Yousef Hammash left Gaza a year ago, his sisters decided to stay behind. We hear about the toll that separation has taken on Yousef and the sister he’s closest to, Aseel. (30 minutes)

  Act Two: Mohammed Mhawish, a reporter who left Gaza a year ago with his family, talks to a young woman in Gaza about how she manages her hunger. Israel blockaded all food from Gaza for more than two months. (15 minutes)

  Coda: Chana gives a short update about Banias, a 9-year-old girl in Gaza she&#039;s been speaking with for months. (4 minutes)</itunes:summary>
  </item>
  <item>
   <title>860: Suddenly: A Mirror!</title>
   <link>https://www.thisamericanlife.org/860/suddenly-a-mirror</link>
   <description>&lt;p&gt;A show about people who are suddenly confronted with who they are.

  &lt;/p&gt;&lt;p&gt;Visit &lt;a href=&quot;https://thisamericanlife.supercast.com?utm_source=rss&amp;utm_medium=shownotes&amp;utm_id=lifepartners&quot;&gt;thisamericanlife.org/lifepartners&lt;/a&gt; to sign up for our premium subscription.
  &lt;/p&gt;&lt;ul&gt;&lt;li&gt;Prologue: Guest host Aviva DeKornfeld tells Ira Glass about breaking into a community pool as a kid, and the split-second decision that has haunted her ever since. (4 minutes)&lt;/li&gt;&lt;li&gt;Act One: Some people are great in a crisis. Others, not so much. Does that mean anything about who we really are? Tobin Low investigates. (10 minutes)&lt;/li&gt;&lt;li&gt;Act Two: Aviva DeKornfeld has the story of Leisha Hailey, who was certain she had the next million-dollar idea. (11 minutes)&lt;/li&gt;&lt;li&gt;Act Three: Comedian Mike Birbiglia talks about the questions his daughter asks him and how trying to answer them showed him surprising reflections of himself.  (15 minutes)&lt;/li&gt;&lt;li&gt;Act Four: David Kestenbaum tells the story of the suspicious disappearance of multiple shoes and a woman determined to explain it. (8 minutes)&lt;/li&gt;&lt;/ul&gt;&lt;p&gt;Transcripts are available at &lt;a href=&quot;https://www.thisamericanlife.org/860/transcript&quot;&gt;thisamericanlife.org&lt;/a&gt;&lt;/p&gt;&lt;p&gt;&lt;a href=&#039;https://www.thisamericanlife.org/page/privacy-policy&#039;&gt;This American Life privacy policy.&lt;/a&gt;&lt;br /&gt;&lt;a href=&#039;https://podcastchoices.com/adchoices&#039;&gt;Learn more about sponsor message choices.&lt;/a&gt;&lt;/p&gt;</description>
   <pubDate>Sun, 25 May 2025 18:00:00 -0400</pubDate>
   <guid isPermaLink="false">45888 at https://www.thisamericanlife.org</guid>
   <itunes:episodeType>full</itunes:episodeType>
   <itunes:episode>860</itunes:episode>
   <itunes:title>Suddenly: A Mirror!</itunes:title>
   <itunes:author>This American Life</itunes:author>
   <itunes:explicit>false</itunes:explicit>
   <itunes:image href="https://www.thisamericanlife.org/sites/default/files/styles/rss_image/public/images/rss/tal-860-suddenlyamirror-kellymalka-sq.jpg?itok=YXbk6Mxh" />
   <enclosure url="https://pfx.vpixl.com/6qj4J/dts.podtrac.com/redirect.mp3/chrt.fm/track/138C95/pdst.fm/e/prefix.up.audio/s/traffic.megaphone.fm/NPR7502652376.mp3" type="audio/mpeg" />
   <itunes:duration>00:59:53</itunes:duration>
   <itunes:subtitle>A show about people who are suddenly confronted with who they are.
  </itunes:subtitle>
   <itunes:summary>A show about people who are suddenly confronted with who they are.



  Prologue: Guest host Aviva DeKornfeld tells Ira Glass about breaking into a community pool as a kid, and the split-second decision that has haunted her ever since. (4 minutes)

  Act One: Some people are great in a crisis. Others, not so much. Does that mean anything about who we really are? Tobin Low investigates. (10 minutes)

  Act Two: Aviva DeKornfeld has the story of Leisha Hailey, who was certain she had the next million-dollar idea. (11 minutes)

  Act Three: Comedian Mike Birbiglia talks about the questions his daughter asks him and how trying to answer them showed him surprising reflections of himself.  (15 minutes)

  Act Four: David Kestenbaum tells the story of the suspicious disappearance of multiple shoes and a woman determined to explain it. (8 minutes)</itunes:summary>
  </item>
  <item>
   <title>859: Chaos Graph</title>
   <link>https://www.thisamericanlife.org/859/chaos-graph</link>
   <description>&lt;p&gt;People immersed in chaos try to solve for what it all adds up to.

  &lt;/p&gt;&lt;p&gt;Visit &lt;a href=&quot;https://thisamericanlife.supercast.com?utm_source=rss&amp;utm_medium=shownotes&amp;utm_id=lifepartners&quot;&gt;thisamericanlife.org/lifepartners&lt;/a&gt; to sign up for our premium subscription.&lt;/p&gt;&lt;ul&gt;&lt;li&gt;Prologue: A scientist who is used to organizing data starts tracking scientific meetings that seem to exist only on paper—meetings that might decide the fate of years of research. The NIH website shows one reality; the empty conference rooms tell another story. She graphs the chaos. (9 minutes)&lt;/li&gt;&lt;li&gt;Act One: American doctors returning from Gaza compare notes and start to see a pattern. (28 minutes)&lt;/li&gt;&lt;li&gt;Act Two: A woman watches her partner get taken in handcuffs with no explanation. Days later, she spots him in the most unexpected place. The coordinates of her life suddenly don&#039;t make sense as she navigates the bewildering map of the US immigration system. (23 minutes)&lt;/li&gt;&lt;/ul&gt;&lt;p&gt;Transcripts are available at &lt;a href=&quot;https://www.thisamericanlife.org/859/transcript&quot;&gt;thisamericanlife.org&lt;/a&gt;&lt;/p&gt;&lt;p&gt;&lt;a href=&#039;https://www.thisamericanlife.org/page/privacy-policy&#039;&gt;This American Life privacy policy.&lt;/a&gt;&lt;br /&gt;&lt;a href=&#039;https://podcastchoices.com/adchoices&#039;&gt;Learn more about sponsor message choices.&lt;/a&gt;&lt;/p&gt;</description>
   <pubDate>Sun, 27 Apr 2025 18:00:00 -0400</pubDate>
   <guid isPermaLink="false">45882 at https://www.thisamericanlife.org</guid>
   <itunes:episodeType>full</itunes:episodeType>
   <itunes:episode>859</itunes:episode>
   <itunes:title>Chaos Graph</itunes:title>
   <itunes:author>This American Life</itunes:author>
   <itunes:explicit>false</itunes:explicit>
   <itunes:image href="https://www.thisamericanlife.org/sites/default/files/styles/rss_image/public/images/rss/tal-859-chaosgraph-luisajung-sq.jpg?itok=uFuZTAtM" />
   <enclosure url="https://pfx.vpixl.com/6qj4J/dts.podtrac.com/redirect.mp3/chrt.fm/track/138C95/pdst.fm/e/prefix.up.audio/s/traffic.megaphone.fm/NPR8121348044.mp3" type="audio/mpeg" />
   <itunes:duration>01:07:29</itunes:duration>
   <itunes:subtitle>People immersed in chaos try to solve for what it all adds up to.
  </itunes:subtitle>
   <itunes:summary>People immersed in chaos try to solve for what it all adds up to.



  Prologue: A scientist who is used to organizing data starts tracking scientific meetings that seem to exist only on paper—meetings that might decide the fate of years of research. The NIH website shows one reality; the empty conference rooms tell another story. She graphs the chaos. (9 minutes)

  Act One: American doctors returning from Gaza compare notes and start to see a pattern. (28 minutes)

  Act Two: A woman watches her partner get taken in handcuffs with no explanation. Days later, she spots him in the most unexpected place. The coordinates of her life suddenly don&#039;t make sense as she navigates the bewildering map of the US immigration system. (23 minutes)</itunes:summary>
  </item>
  <item>
    <title>A Big Announcement</title>
    <description>&lt;p&gt;Ira Glass has news to share about some things happening here at This American Life.&lt;/p&gt;

  &lt;p&gt;To sign up as a Life Partner, visit &lt;a href=&quot;https://www.thisamericanlife.org/lifepartners&quot;&gt;thisamericanlife.org/lifepartners&lt;/a&gt;.&lt;/p&gt;</description>
    <pubDate>Wed, 16 Oct 2024 00:00:00 -0400</pubDate>
    <guid isPermaLink="false">45786 at https://www.thisamericanlife.org</guid>
    <enclosure url="https://www.thisamericanlife.org/sites/default/files/audio/upload/extra/life_partners_promo_102524_update.mp3" type="audio/mpeg" />
    <itunes:image href="https://www.thisamericanlife.org/sites/default/files/styles/rss_image/public/images/rss/channel_cover-this_american_life_partners_-_no_alpha.png?itok=bOrHWUOu" />
    <media:thumbnail url="https://www.thisamericanlife.org/sites/default/files/youtube/tal-life_partners-16x9.jpg" height="720" width="1280" />
    <itunes:author>This American Life</itunes:author>
    <itunes:duration>00:04:56</itunes:duration>
    <itunes:subtitle>Ira Glass has news to share about some things happening here at This American Life.</itunes:subtitle>
    <itunes:summary>Ira Glass has news to share about some things happening here at This American Life.</itunes:summary>
    <link>https://www.thisamericanlife.org</link>
  </item>
  </channel>
  </rss>
  """

  let feed = try parsePodcastFeed(xmlString, source: "")

  // Test show properties
  #expect(feed.show.name == "This American Life")
  #expect(feed.show.author == "This American Life")
  #expect(feed.show.websiteUrl == "https://www.thisamericanlife.org/podcast/rss.xml")
  #expect(
    feed.show
      .artworkUrl ==
      "https://thisamericanlife.org/sites/all/themes/thislife/img/tal-logo-3000x3000.png",
  )

  // Test episodes count (should be 12 based on actual parsing)
  #expect(feed.episodes.count == 12)

  // Test first episode (College Disorientation) - itunes:duration is 00:57:33
  let episode1 = feed.episodes[0]
  #expect(episode1.title == "867: College Disorientation")
  #expect(episode1.episodeNumber == 867)
  #expect(
    episode1
      .audioUrl ==
      "https://pfx.vpixl.com/6qj4J/dts.podtrac.com/redirect.mp3/chrt.fm/track/138C95/pdst.fm/e/prefix.up.audio/s/traffic.megaphone.fm/NPR2581159385.mp3",
  )
  #expect(episode1.audioType == .mp3)
  #expect(
    episode1
      .artworkUrl ==
      "https://www.thisamericanlife.org/sites/default/files/styles/rss_image/public/images/rss/tal-867-welcomeback-sq.jpg?itok=0yOLJPiF",
  )
  #expect(episode1.guid == "45952 at https://www.thisamericanlife.org")
  #expect(episode1.websiteUrl == "https://www.thisamericanlife.org/867/college-disorientation")
  #expect(episode1.duration == 3453) // 00:57:33 = 57*60 + 33 = 3453 seconds
  #expect(episode1.sizeInBytes == 0) // No length attribute in this feed

  // Test episode description HTML stripping
  let expectedDescription =
    "Things are different on college campuses this year. We see inside the drama, with students and staff. Visit thisamericanlife.org/lifepartners to sign up for our premium subscription. Prologue: We go to orientation at Arizona State University and meet international students who are trying to make friends. (6 minutes) Act One: The president of the Black Student Union at the University of Utah fights to keep the B in BSU. (30 minutes) Act Two: A definition of antisemitism, canceled classes, and angry professors at Columbia University. (16 minutes) Transcripts are available at thisamericanlife.org This American Life privacy policy. Learn more about sponsor message choices."
  #expect(episode1.description == expectedDescription)

  // Test episode pubDate - Sun, 14 Sep 2025 18:00:00 -0400
  let formatter = DateFormatter()
  formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
  formatter.locale = Locale(identifier: "en_US_POSIX")
  let expectedDate1 = formatter.date(from: "Sun, 14 Sep 2025 18:00:00 -0400")!
  #expect(episode1.pubDate == expectedDate1)

  // Test second episode (Watch Out for That Tree) - itunes:duration is 01:07:30
  let episode2 = feed.episodes[1]
  #expect(episode2.title == "866: Watch Out for That Tree")
  #expect(episode2.episodeNumber == 866)
  #expect(episode2.duration == 4050) // 01:07:30 = 1*3600 + 7*60 + 30 = 4050 seconds

  // Test third episode (Starting From Scratch) - itunes:duration is 01:00:31
  let episode3 = feed.episodes[2]
  #expect(episode3.title == "233: Starting From Scratch")
  #expect(episode3.episodeNumber == 233)
  #expect(episode3.duration == 3631) // 01:00:31 = 1*3600 + 0*60 + 31 = 3631 seconds
  #expect(
    episode3.description?
      .contains("Jorge Just, who thought he'd started over successfully") == true,
  )
  #expect(episode3.description?.contains("He'd moved to New York") == true)

  // Test fourth episode (The Other Territory) - itunes:duration is 01:14:50
  let episode4 = feed.episodes[3]
  #expect(episode4.title == "865: The Other Territory")
  #expect(episode4.episodeNumber == 865)
  #expect(episode4.duration == 4490) // 01:14:50 = 1*3600 + 14*60 + 50 = 4490 seconds

  // Test fifth episode (Chicago Hope) - itunes:duration is 00:59:25
  let episode5 = feed.episodes[4]
  #expect(episode5.title == "864: Chicago Hope")
  #expect(episode5.episodeNumber == 864)
  #expect(episode5.duration == 3565) // 00:59:25 = 0*3600 + 59*60 + 25 = 3565 seconds

  // Test sixth episode (Bonus: Nancy's Deep Cuts) - itunes:duration is 00:26:44
  let episode6 = feed.episodes[5]
  #expect(episode6.title == "Bonus: Nancy's Deep Cuts")
  #expect(episode6.episodeNumber == nil)
  #expect(episode6.duration == 1604) // 00:26:44 = 0*3600 + 26*60 + 44 = 1604 seconds
  #expect(
    episode6
      .artworkUrl ==
      "https://www.thisamericanlife.org/sites/default/files/styles/rss_image/public/images/rss/this_american_life_partners_-_teal.jpg?itok=mZBuUS4l",
  )

  // Test seventh episode (Championship Window) - itunes:duration is 00:58:00
  let episode7 = feed.episodes[6]
  #expect(episode7.title == "863: Championship Window")
  #expect(episode7.episodeNumber == 863)
  #expect(episode7.duration == 3480) // 00:58:00 = 0*3600 + 58*60 + 0 = 3480 seconds

  // Test eighth episode (Some Things We Don't Do Anymore) - itunes:duration is 01:06:29
  let episode8 = feed.episodes[7]
  #expect(episode8.title == "862: Some Things We Don't Do Anymore")
  #expect(episode8.episodeNumber == 862)
  #expect(episode8.duration == 3989) // 01:06:29 = 1*3600 + 6*60 + 29 = 3989 seconds
  #expect(
    episode8.description?
      .contains(
        "On his first day in office, President Trump decided to freeze all U.S. foreign aid",
      ) ==
      true,
  )

  // Test ninth episode (Group Chat) - itunes:duration is 01:01:22
  let episode9 = feed.episodes[8]
  #expect(episode9.title == "861: Group Chat")
  #expect(episode9.episodeNumber == 861)
  #expect(episode9.duration == 3682) // 01:01:22 = 1*3600 + 1*60 + 22 = 3682 seconds

  // Test tenth episode (Suddenly: A Mirror!) - itunes:duration is 00:59:53
  let episode10 = feed.episodes[9]
  #expect(episode10.title == "860: Suddenly: A Mirror!")
  #expect(episode10.episodeNumber == 860)
  #expect(episode10.duration == 3593) // 00:59:53 = 0*3600 + 59*60 + 53 = 3593 seconds

  // Test eleventh episode (Chaos Graph) - itunes:duration is 01:07:29
  let episode11 = feed.episodes[10]
  #expect(episode11.title == "859: Chaos Graph")
  #expect(episode11.episodeNumber == 859)
  #expect(episode11.duration == 4049) // 01:07:29 = 1*3600 + 7*60 + 29 = 4049 seconds

  // Test last episode (A Big Announcement) - itunes:duration is 00:04:56
  let lastEpisode = feed.episodes[11]
  #expect(lastEpisode.title == "A Big Announcement")
  #expect(lastEpisode.episodeNumber == nil)
  #expect(lastEpisode.duration == 296) // 00:04:56 = 0*3600 + 4*60 + 56 = 296 seconds
}

@Test
func skipsInvalidEpisodes() throws {
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
        <itunes:image href="https://example.com/episode1-artwork.jpg"/>
        <enclosure url="https://example.com/episode1.mp3" type="audio/mpeg" />
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

  let feed = try parsePodcastFeed(xmlString, source: "")
  #expect(feed.episodes.count == 1) // one episode should be dropped, no length
}

@Test
func failsOnNoValidEpisodes() throws {
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
        <itunes:image href="https://example.com/episode1-artwork.jpg"/>
        <enclosure url="https://example.com/episode1.mp3" type="audio/mpeg" />
      </item>
    </channel>
  </rss>
  """

  #expect(throws: (any Error).self) {
    _ = try parsePodcastFeed(xmlString, source: "")
  }
}

@Test
func hoyHablamosArtwork() throws {
  // Test with real feed content that has both itunes:image and image/url
  let xmlString = """
  <?xml version="1.0" encoding="UTF-8"?>
  <rss version="2.0" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd">
    <channel>
      <title>Test Podcast</title>
      <description>A test podcast</description>
      <author>Test Author</author>
      <link>https://example.com</link>
      <itunes:image href="https://www.hoyhablamos.com/wp-content/uploads/2024/03/logo-rrss-hoyhablamos-basico.jpg" />
      <image>
        <title>Hoy Hablamos Básico</title>
        <url>https://www.hoyhablamos.com/wp-content/uploads/2024/03/logo-rrss-hoyhablamos-basico.jpg</url>
        <link>https://www.hoyhablamos.com/basico/</link>
      </image>

      <item>
        <title>Episode 1</title>
        <description>First test episode</description>
        <link>https://example.com/episode1</link>
        <guid>episode-1</guid>
        <pubDate>Mon, 01 Jan 2024 12:00:00 +0000</pubDate>
        <itunes:duration>10:00</itunes:duration>
        <enclosure url="https://example.com/episode1.mp3" type="audio/mpeg" length="1000000"/>
      </item>
    </channel>
  </rss>
  """

  let feed = try parsePodcastFeed(xmlString, source: "")

  // This should have the artwork URL from either itunes:image or image/url
  #expect(
    feed.show
      .artworkUrl ==
      "https://www.hoyhablamos.com/wp-content/uploads/2024/03/logo-rrss-hoyhablamos-basico.jpg",
  )
}

@Test
func episodeWithoutDurationIsNil() throws {
  let xmlString = """
  <?xml version="1.0" encoding="UTF-8"?>
  <rss version="2.0">
    <channel>
      <title>Test Podcast</title>
      <item>
        <title>Episode Without Duration</title>
        <guid>episode-without-duration</guid>
        <pubDate>Wed, 11 Sep 2024 06:00:00 +0000</pubDate>
        <enclosure url="https://example.com/episode.mp3" length="5242880" type="audio/mpeg" />
      </item>
    </channel>
  </rss>
  """

  let feed = try parsePodcastFeed(xmlString, source: "")
  #expect(feed.episodes[0].duration == nil)
}
