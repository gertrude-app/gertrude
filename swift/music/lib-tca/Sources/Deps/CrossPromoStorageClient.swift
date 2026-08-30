import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct CrossPromoStorageClient: Sendable {
  var dismissedCampaignIDs: @Sendable () -> Set<String> = { [] }
  var insertDismissedCampaignID: @Sendable (_ campaignID: String) -> Void = { _ in }
  var lastShownAt: @Sendable () -> Date? = { nil }
  var saveLastShownAt: @Sendable (_ date: Date) -> Void = { _ in }
}

extension CrossPromoStorageClient: DependencyKey {
  static var liveValue: Self {
    .live(userDefaults: .standard)
  }

  static var testValue: Self {
    .init(
      dismissedCampaignIDs: { [] },
      insertDismissedCampaignID: { _ in },
      lastShownAt: { nil },
      saveLastShownAt: { _ in },
    )
  }
}

extension CrossPromoStorageClient {
  static func live(userDefaults: UserDefaults) -> Self {
    let storage = CrossPromoStorage(userDefaults: userDefaults)
    return Self(
      dismissedCampaignIDs: { storage.dismissedCampaignIDs() },
      insertDismissedCampaignID: { storage.insertDismissedCampaignID($0) },
      lastShownAt: { storage.lastShownAt() },
      saveLastShownAt: { storage.saveLastShownAt($0) },
    )
  }
}

private final class CrossPromoStorage: @unchecked Sendable {
  private static let dismissedCampaignIDsKey = "gertrude.music.cross-promo.dismissed-ids.v1"
  private static let lastShownAtKey = "gertrude.music.cross-promo.last-shown-at.v1"

  private let lock = NSLock()
  private let userDefaults: UserDefaults

  init(userDefaults: UserDefaults) {
    self.userDefaults = userDefaults
  }

  func dismissedCampaignIDs() -> Set<String> {
    self.lock.withLock {
      Set(self.userDefaults.stringArray(forKey: Self.dismissedCampaignIDsKey) ?? [])
    }
  }

  func insertDismissedCampaignID(_ campaignID: String) {
    self.lock.withLock {
      var campaignIDs = Set(
        self.userDefaults.stringArray(forKey: Self.dismissedCampaignIDsKey) ?? [],
      )
      campaignIDs.insert(campaignID)
      self.userDefaults.set(campaignIDs.sorted(), forKey: Self.dismissedCampaignIDsKey)
    }
  }

  func lastShownAt() -> Date? {
    self.lock.withLock {
      self.userDefaults.object(forKey: Self.lastShownAtKey) as? Date
    }
  }

  func saveLastShownAt(_ date: Date) {
    self.lock.withLock {
      self.userDefaults.set(date, forKey: Self.lastShownAtKey)
    }
  }
}

extension DependencyValues {
  var crossPromoStorage: CrossPromoStorageClient {
    get { self[CrossPromoStorageClient.self] }
    set { self[CrossPromoStorageClient.self] = newValue }
  }
}
