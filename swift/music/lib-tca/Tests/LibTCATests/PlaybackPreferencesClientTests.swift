import CustomDump
import Foundation
import Testing

@testable import LibTCA

struct PlaybackPreferencesClientTests {
  @Test
  func liveClientDefaultsAndRoundTrips() async throws {
    let suiteName = "PlaybackPreferencesClientTests.liveClientDefaultsAndRoundTrips"
    let userDefaults = try #require(UserDefaults(suiteName: suiteName))
    userDefaults.removePersistentDomain(forName: suiteName)
    defer { userDefaults.removePersistentDomain(forName: suiteName) }
    let client = PlaybackPreferencesClient.live(userDefaults: userDefaults)

    let initialPreferences = await client.load()
    expectNoDifference(initialPreferences, .init())

    let preferences = PlaybackPreferences(
      endBehavior: .loopTrack,
      isShuffleEnabled: true,
    )
    await client.save(preferences)

    let restoredPreferences = await client.load()
    expectNoDifference(restoredPreferences, preferences)
  }
}
