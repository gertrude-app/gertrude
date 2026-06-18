import ComposableArchitecture
import GertieApp
import GertieTcaFeatures
import IOSRoute
import XCTest
import XExpect

@testable import LibApp

final class CrossPromoTests: XCTestCase {
  @MainActor
  func testPresentsHomeCampaignWhenRunning() async throws {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let savedAt = LockIsolated<Date?>(nil)
    let logged = LockIsolated<[String]>([])
    let promo = testCampaign()
    let store = TestStore(initialState: .init(screen: .running(state: .notConnected))) {
      IOSReducer()
    } withDependencies: {
      $0.date = .constant(now)
      $0.sharedStorage.loadDismissedCrossPromoIds = { @Sendable in nil }
      $0.sharedStorage.loadCrossPromoLastShownAt = { @Sendable in nil }
      $0.sharedStorage.saveCrossPromoLastShownAt = { @Sendable in savedAt.setValue($0) }
      $0.api.logEvent = { @Sendable _, detail in logged.withValue { $0.append(detail ?? "") } }
    }

    await store.send(.programmatic(.receivedCrossPromos(.init(promos: [promo])))) {
      $0.crossPromos = .init(promos: [promo]) // survives the hasGuaranteedExit filter
      $0.destination = .crossPromo(.init(campaign: promo))
    }
    await store.finish()

    expect(savedAt.value).toEqual(now) // throttle record written on impression
    XCTAssertEqual(logged.value.count, 1)
    XCTAssertTrue(logged.value.first?.contains("cross promo impression") == true)
  }

  @MainActor
  func testThrottleBlocksHomeReshowWithin72h() async throws {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let promo = testCampaign()
    let store = TestStore(initialState: .init(screen: .running(state: .notConnected))) {
      IOSReducer()
    } withDependencies: {
      $0.date = .constant(now)
      $0.sharedStorage.loadDismissedCrossPromoIds = { @Sendable in nil }
      $0.sharedStorage.loadCrossPromoLastShownAt = { @Sendable in now.addingTimeInterval(-3600) }
    }

    await store.send(.programmatic(.receivedCrossPromos(.init(promos: [promo])))) {
      $0.crossPromos = .init(promos: [promo]) // stored, but NOT presented (throttled)
    }
  }

  @MainActor
  func testDismissedCampaignIsNotPresented() async throws {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let promo = testCampaign()
    let store = TestStore(initialState: .init(screen: .running(state: .notConnected))) {
      IOSReducer()
    } withDependencies: {
      $0.date = .constant(now)
      $0.sharedStorage.loadDismissedCrossPromoIds = { @Sendable in [promo.campaignId] }
    }

    await store.send(.programmatic(.receivedCrossPromos(.init(promos: [promo])))) {
      $0.crossPromos = .init(promos: [promo]) // stored, but excluded by prior dismissal
    }
  }

  @MainActor
  func testDoesNotPresentWhenNotRunning() async throws {
    let promo = testCampaign()
    let store = TestStore(initialState: .init(screen: .onboarding(.happyPath(.hiThere)))) {
      IOSReducer()
    }

    await store.send(.programmatic(.receivedCrossPromos(.init(promos: [promo])))) {
      $0.crossPromos = .init(promos: [promo]) // stored for later, no present off the running screen
    }
  }

  @MainActor
  func testBurnsCampaignOnCtaTapped() async throws {
    let promo = testCampaign()
    let saved = LockIsolated<[String]>([])
    let logged = LockIsolated<[String]>([])
    var initial = IOSReducer.State(screen: .running(state: .notConnected))
    initial.destination = .crossPromo(.init(campaign: promo))
    let store = TestStore(initialState: initial) {
      IOSReducer()
    } withDependencies: {
      $0.sharedStorage.loadDismissedCrossPromoIds = { @Sendable in [] }
      $0.sharedStorage.saveDismissedCrossPromoIds = { @Sendable in saved.setValue($0) }
      $0.api.logEvent = { @Sendable _, detail in logged.withValue { $0.append(detail ?? "") } }
    }

    await store.send(.destination(.presented(.crossPromo(.delegate(.ctaTapped(.primary)))))) {
      $0.destination = nil
    }
    await store.finish()

    expect(saved.value).toEqual([promo.campaignId]) // burned so it won't re-show
    XCTAssertTrue(logged.value.first?.contains("cross promo cta") == true)
  }

  @MainActor
  func testBurnsCampaignOnSwipeDismiss() async throws {
    let promo = testCampaign()
    let saved = LockIsolated<[String]>([])
    let logged = LockIsolated<[String]>([])
    var initial = IOSReducer.State(screen: .running(state: .notConnected))
    initial.destination = .crossPromo(.init(campaign: promo))
    let store = TestStore(initialState: initial) {
      IOSReducer()
    } withDependencies: {
      $0.sharedStorage.loadDismissedCrossPromoIds = { @Sendable in [] }
      $0.sharedStorage.saveDismissedCrossPromoIds = { @Sendable in saved.setValue($0) }
      $0.api.logEvent = { @Sendable _, detail in logged.withValue { $0.append(detail ?? "") } }
    }

    await store.send(.destination(.dismiss)) {
      $0.destination = nil
    }
    await store.finish()

    expect(saved.value).toEqual([promo.campaignId])
    XCTAssertTrue(logged.value.first?.contains("cross promo dismiss") == true)
  }

  @MainActor
  func testDropsCampaignWithoutGuaranteedExit() async throws {
    let badPromo = testCampaign(id: "bad", style: .screen, dismissable: false) // no exit
    let logged = LockIsolated<[String]>([])
    let store = TestStore(initialState: .init(screen: .running(state: .notConnected))) {
      IOSReducer()
    } withDependencies: {
      $0.api.logEvent = { @Sendable _, detail in logged.withValue { $0.append(detail ?? "") } }
    }

    await store.send(.programmatic(.receivedCrossPromos(.init(promos: [badPromo]))))
    await store.finish()

    XCTAssertTrue(logged.value.contains { $0.contains("dropped: no guaranteed exit") })
  }
}

private func testCampaign(
  id: String = "promo-1",
  placement: String = "iosBlockerHome",
  style: CrossPromoStyle = .sheet,
  dismissable: Bool = true,
) -> CrossPromoCampaign {
  .init(
    campaignId: id,
    placement: placement,
    style: style,
    headline: "Check out Gertrude AM",
    body: "A podcast app the whole family will love.",
    primaryCta: .init(label: "Get it", action: .openUrl("https://gertrude.app")),
    dismissable: dismissable,
  )
}
