import Dependencies
import DependenciesMacros
import Foundation

struct ReviewPromptProgress: Codable, Equatable, Sendable {
  static let requiredIntentionalPlayCount = 10

  var firstIntentionalPlayAt: Date?
  var hasPrompted = false
  var intentionalPlayCount = 0

  mutating func recordIntentionalPlay(at date: Date) {
    guard !self.hasPrompted else { return }
    self.firstIntentionalPlayAt = self.firstIntentionalPlayAt ?? date
    self.intentionalPlayCount = min(
      self.intentionalPlayCount + 1,
      Self.requiredIntentionalPlayCount,
    )
  }

  func isEligible(at date: Date, minimumAge: TimeInterval) -> Bool {
    guard !self.hasPrompted,
          self.intentionalPlayCount >= Self.requiredIntentionalPlayCount,
          let firstIntentionalPlayAt = self.firstIntentionalPlayAt else { return false }
    return date.timeIntervalSince(firstIntentionalPlayAt) >= minimumAge
  }
}

@DependencyClient
struct ReviewPromptStorageClient: Sendable {
  var load: @Sendable () -> ReviewPromptProgress = { .init() }
  var save: @Sendable (_ progress: ReviewPromptProgress) -> Void
}

extension ReviewPromptStorageClient: DependencyKey {
  static var liveValue: Self {
    .live(userDefaults: .standard)
  }

  static let testValue = Self(
    load: { .init(hasPrompted: true) },
    save: { _ in },
  )
}

extension ReviewPromptStorageClient {
  static func live(userDefaults: UserDefaults) -> Self {
    let storage = ReviewPromptStorage(userDefaults: userDefaults)
    return Self(
      load: { storage.load() },
      save: { storage.save($0) },
    )
  }
}

private final class ReviewPromptStorage: @unchecked Sendable {
  private static let key = "gertrude.music.review-prompt.v1"

  private let lock = NSLock()
  private let userDefaults: UserDefaults

  init(userDefaults: UserDefaults) {
    self.userDefaults = userDefaults
  }

  func load() -> ReviewPromptProgress {
    self.lock.withLock {
      guard let data = self.userDefaults.data(forKey: Self.key),
            let progress = try? JSONDecoder().decode(ReviewPromptProgress.self, from: data)
      else { return .init() }
      return progress
    }
  }

  func save(_ progress: ReviewPromptProgress) {
    self.lock.withLock {
      guard let data = try? JSONEncoder().encode(progress) else { return }
      self.userDefaults.set(data, forKey: Self.key)
    }
  }
}

extension DependencyValues {
  var reviewPromptStorage: ReviewPromptStorageClient {
    get { self[ReviewPromptStorageClient.self] }
    set { self[ReviewPromptStorageClient.self] = newValue }
  }
}
