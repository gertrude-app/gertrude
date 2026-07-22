import SwiftUI
import Testing

@testable import LibViews

@Test
func playlistArtworkURLsAreDeduplicatedInEntryOrder() {
  let first = URL(string: "https://example.com/first.jpg")!
  let second = URL(string: "https://example.com/second.jpg")!
  let playlist = PlaylistData(
    id: "playlist",
    name: "Playlist",
    entries: [first, first, second, first].enumerated().map { index, url in
      PlaylistEntryData(
        id: "entry-\(index)",
        track: TrackData(
          id: "track-\(index)",
          title: "Track \(index)",
          artist: "Artist",
          artworkUrl: url,
        ),
      )
    },
  )

  #expect(playlist.artworkUrls == [first, second])
}

@MainActor
@Test
func packageLoads() {
  _ = GertrudeMusicView()
}

@Test
func onboardingBlurbFallsBackWhenNilOrBlank() {
  let fallback = "hardcoded copy"
  #expect(musicOnboardingBlurb(override: nil, device: "x", fallback: fallback) == fallback)
  #expect(musicOnboardingBlurb(override: "", device: "x", fallback: fallback) == fallback)
  #expect(musicOnboardingBlurb(override: "   \n ", device: "x", fallback: fallback) == fallback)
}

@Test
func onboardingBlurbInterpolatesDevicePlaceholder() {
  let out = musicOnboardingBlurb(
    override: "This is {{device}}. Open this link:",
    device: "Billy’s iPhone",
    fallback: "hardcoded copy",
  )
  #expect(out == "This is Billy’s iPhone. Open this link:")
}

@Test
func onboardingBlurbUsesPlainOverrideWithNoPlaceholder() {
  let out = musicOnboardingBlurb(
    override: "Just $5 a month.",
    device: "iPhone",
    fallback: "hardcoded copy",
  )
  #expect(out == "Just $5 a month.")
}

@Test
func onboardingBlurbFallsBackOnResidualMustache() {
  let fallback = "hardcoded copy"
  // unknown/misspelled placeholder the client can't fill
  #expect(musicOnboardingBlurb(
    override: "Hi {{childName}}, open this:",
    device: "iPhone",
    fallback: fallback,
  ) == fallback)
  // malformed / unbalanced delimiters
  #expect(musicOnboardingBlurb(
    override: "This is {{device}. Open:",
    device: "iPhone",
    fallback: fallback,
  ) == fallback)
}

@MainActor
@Test
func comparesResolvedColorLuminance() {
  let environment = EnvironmentValues()

  #expect(Color.black.isDarker(than: .white, in: environment))
  #expect(!Color.white.isDarker(than: .black, in: environment))
}
