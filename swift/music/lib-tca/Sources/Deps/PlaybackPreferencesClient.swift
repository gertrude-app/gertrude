import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct PlaybackPreferencesClient: Sendable {
  var load: @Sendable () async -> PlaybackPreferences = { .init() }
  var save: @Sendable (_ preferences: PlaybackPreferences) async -> Void
}

extension PlaybackPreferencesClient: DependencyKey {
  static var liveValue: Self {
    .live(userDefaults: .standard)
  }

  static var testValue: Self {
    .noop
  }
}

extension DependencyValues {
  var playbackPreferences: PlaybackPreferencesClient {
    get { self[PlaybackPreferencesClient.self] }
    set { self[PlaybackPreferencesClient.self] = newValue }
  }
}

extension PlaybackPreferencesClient {
  static func live(userDefaults: UserDefaults) -> Self {
    let storage = PlaybackPreferencesStorage(userDefaults: userDefaults)
    return Self(
      load: {
        storage.load()
      },
      save: { preferences in
        storage.save(preferences)
      },
    )
  }

  static let noop = Self(
    load: { .init() },
    save: { _ in },
  )
}

private final class PlaybackPreferencesStorage: @unchecked Sendable {
  private static let key = "gertrude.music.playback-preferences.v1"

  private let lock = NSLock()
  private let userDefaults: UserDefaults

  init(userDefaults: UserDefaults) {
    self.userDefaults = userDefaults
  }

  func load() -> PlaybackPreferences {
    self.lock.withLock {
      guard let data = self.userDefaults.data(forKey: Self.key),
            let preferences = try? JSONDecoder().decode(PlaybackPreferences.self, from: data)
      else { return .init() }
      return preferences
    }
  }

  func save(_ preferences: PlaybackPreferences) {
    self.lock.withLock {
      guard let data = try? JSONEncoder().encode(preferences) else { return }
      self.userDefaults.set(data, forKey: Self.key)
    }
  }
}
