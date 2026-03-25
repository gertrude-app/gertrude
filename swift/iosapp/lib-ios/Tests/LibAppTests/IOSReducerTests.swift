@preconcurrency import Combine
import ComposableArchitecture
import GertieIOS
import IOSRoute
import LibCore
import XCTest
import XExpect

@testable import LibApp
@testable import LibClients

final class IOSReducerTests: XCTestCase {
  @MainActor
  func testHappyPath() async throws {
    let apiLoggedDetails = LockIsolated<[String]>([])
    let requestAuthInvocations = LockIsolated(0)
    let installInvocations = LockIsolated(0)
    let deleteCacheFillDirInvocations = LockIsolated(0)
    let batteryCheckInvocations = LockIsolated(0)
    let ratingRequestInvocations = LockIsolated(0)
    let defaultBlocksInvocations = LockIsolated(0)
    let fetchBlockRulesInvocations = LockIsolated(0)
    let storedDates = LockIsolated<[Date]>([])
    let savedProtectionModes = LockIsolated<[ProtectionMode]>([])
    let savedDisabledBlockGroups = LockIsolated<[[UUID]]>([])
    let savedAllBlockGroups = LockIsolated<[[GetBlockGroups.BlockGroupInfo]]>([])
    let cacheClearSubject = PassthroughSubject<DeviceClient.ClearCacheUpdate, Never>()
    let deviceId = UUID()
    let id1 = UUID()
    let id2 = UUID()

    let store = TestStore(initialState: IOSReducer.State()) {
      IOSReducer()
    } withDependencies: {
      $0.date = .constant(.reference)
      $0.mainQueue = .immediate
      $0.locale = Locale(identifier: "en_US")
      $0.api.logEvent = { @Sendable _, detail in
        apiLoggedDetails.withValue { $0.append(detail ?? "") }
      }
      $0.api.fetchDefaultBlockRules = { @Sendable _ in
        defaultBlocksInvocations.withValue { $0 += 1 }
        return [.urlContains(value: "default-rule")]
      }
      $0.api.fetchBlockRules = { @Sendable vid, disabled in
        expect(vid).toEqual(deviceId)
        expect(disabled).toEqual([id2])
        fetchBlockRulesInvocations.withValue { $0 += 1 }
        return [.urlContains(value: "GIFs")]
      }
      $0.api.fetchAllBlockGroups = { @Sendable _ in [
        .init(id: id1, name: "G1", shortDescription: "", longDescription: ""),
        .init(id: id2, name: "G2", shortDescription: "", longDescription: ""),
      ] }
      $0.api.connectAccountFeatureFlag = { @Sendable in
        .init(isEnabled: false)
      }
      $0.systemExtension.requestAuthorization = {
        requestAuthInvocations.withValue { $0 += 1 }
        return .success(())
      }
      $0.systemExtension.filterRunning = { false }
      $0.systemExtension.installFilter = {
        installInvocations.withValue { $0 += 1 }
        return .success(())
      }
      $0.device.deviceId = { deviceId }
      $0.device.deleteCacheFillDir = {
        deleteCacheFillDirInvocations.withValue { $0 += 1 }
      }
      $0.device.batteryLevel = {
        batteryCheckInvocations.withValue { $0 += 1 }
        return .level(0.2)
      }
      $0.sharedStorage.loadDisabledBlockGroupIds = { @Sendable in nil }
      $0.sharedStorage.loadAccountConnection = { @Sendable in nil }
      $0.sharedStorage.loadFirstLaunchDate = { @Sendable in nil }
      $0.sharedStorage.loadPendingSupervisionCode = { @Sendable in nil }
      $0.sharedStorage.loadAllBlockGroups = { @Sendable in nil }
      $0.sharedStorage.saveAllBlockGroups = { @Sendable value in
        savedAllBlockGroups.withValue { $0.append(value) }
      }
      $0.sharedStorage.saveFirstLaunchDate = { @Sendable value in
        storedDates.withValue { $0.append(value) }
      }
      $0.sharedStorage.saveProtectionMode = { @Sendable value in
        savedProtectionModes.withValue { $0.append(value) }
      }
      $0.device.clearCache = { _ in
        cacheClearSubject.eraseToAnyPublisher()
      }
      $0.device.availableDiskSpaceInBytes = { 1024 * 12 }
      $0.appStore.requestRating = {
        ratingRequestInvocations.withValue { $0 += 1 }
      }
    }

    await store.send(.programmatic(.appDidLaunch))

    await store.receive(.programmatic(.setFirstLaunch(.reference))) {
      $0.onboarding.firstLaunch = .reference
    }

    await store.receive(.programmatic(.setScreen(.onboarding(.happyPath(.hiThere))))) {
      $0.screen = .onboarding(.happyPath(.hiThere))
    }

    await store.receive(.programmatic(.receivedAllBlockGroups([
      .init(id: id1, name: "G1", shortDescription: "", longDescription: ""),
      .init(id: id2, name: "G2", shortDescription: "", longDescription: ""),
    ]))) {
      $0.allBlockGroups = [
        .init(id: id1, name: "G1", shortDescription: "", longDescription: ""),
        .init(id: id2, name: "G2", shortDescription: "", longDescription: ""),
      ]
    }

    await store.receive(.programmatic(.receivedConnectAccountFeatureFlag(.init(isEnabled: false))))

    await store.receive(.programmatic(.receivedAllBlockGroups([
      .init(id: id1, name: "G1", shortDescription: "", longDescription: ""),
      .init(id: id2, name: "G2", shortDescription: "", longDescription: ""),
    ])))

    expect(storedDates.value).toEqual([.reference])
    expect(apiLoggedDetails.value).toEqual(["[onboarding] first launch, region: `US`"])
    expect(deleteCacheFillDirInvocations.value).toEqual(1)
    expect(defaultBlocksInvocations.value).toEqual(1)
    expect(savedProtectionModes.value).toEqual([.onboarding([.urlContains(value: "default-rule")])])
    expect(savedAllBlockGroups.value).toEqual([
      [
        .init(id: id1, name: "G1", shortDescription: "", longDescription: ""),
        .init(id: id2, name: "G2", shortDescription: "", longDescription: ""),
      ],
      [
        .init(id: id1, name: "G1", shortDescription: "", longDescription: ""),
        .init(id: id2, name: "G2", shortDescription: "", longDescription: ""),
      ],
    ])

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.timeExpectation))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.confirmChildsDevice))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.explainPermissionDependsOnAge))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.confirmMinorDevice))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.confirmParentIsOnboarding))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.confirmInAppleFamily))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.explainTwoInstallSteps))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.explainAuthWithParentAppleAccount))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.dontGetTrickedPreAuth))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, "")))

    await store.receive(.programmatic(.authorizationSucceeded)) {
      $0.screen = .onboarding(.happyPath(.explainInstallWithDevicePasscode))
    }

    expect(requestAuthInvocations.value).toEqual(1)
    expect(apiLoggedDetails.value).toEqual([
      "[onboarding] first launch, region: `US`",
      "[onboarding] authorization succeeded",
    ])

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.dontGetTrickedPreInstall))
    }

    store.dependencies.sharedStorage.saveDisabledBlockGroupIds = { @Sendable value in
      savedDisabledBlockGroups.withValue { $0.append(value) }
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, "")))

    await store.receive(.programmatic(.installSucceeded)) {
      $0.screen = .onboarding(.happyPath(.optOutBlockGroups))
    }

    expect(savedProtectionModes.value.count).toEqual(1)
    expect(installInvocations.value).toEqual(1)
    expect(savedDisabledBlockGroups.value).toEqual([[]])
    expect(apiLoggedDetails.value).toEqual([
      "[onboarding] first launch, region: `US`",
      "[onboarding] authorization succeeded",
      "[onboarding] filter install success",
    ])

    await store.send(.interactive(.blockGroupToggled(id1))) {
      $0.disabledBlockGroupIds = [id1]
    }

    await store.send(.interactive(.blockGroupToggled(id1))) {
      $0.disabledBlockGroupIds = []
    }

    await store.send(.interactive(.blockGroupToggled(id2))) {
      $0.disabledBlockGroupIds = [id2]
    }

    expect(savedProtectionModes.value.count).toEqual(1)
    expect(savedDisabledBlockGroups.value.count).toEqual(1)

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) { // <-- "Done" from groups
      $0.screen = .onboarding(.happyPath(.promptClearCache))
    }

    expect(fetchBlockRulesInvocations.value).toEqual(1)
    expect(savedProtectionModes.value).toEqual([
      .onboarding([.urlContains(value: "default-rule")]),
      .normal([.urlContains(value: "GIFs")]),
    ])
    expect(savedDisabledBlockGroups.value).toEqual([
      [], // <-- on opt-out groups screen load, failsafe
      [id2], // <-- persist user choice after "Done"
    ])

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.onboarding.clearCache = .init(context: .onboarding, screen: .loading)
    }

    await store.send(.interactive(.onboardingClearCache(.onAppear)))

    await store.receive(.interactive(.onboardingClearCache(.receivedDeviceInfo(
      batteryLevel: .level(0.2),
      availableSpace: 1024 * 12,
    )))) {
      $0.onboarding.clearCache?.batteryLevel = .level(0.2)
      $0.onboarding.clearCache?.screen = .batteryWarning
      $0.onboarding.clearCache?.availableDiskSpaceInBytes = 1024 * 12
    }

    await store.send(.interactive(.onboardingClearCache(.batteryWarningContinueTapped))) {
      $0.onboarding.clearCache?.screen = .clearing
      $0.onboarding.clearCache?.startClearCache = .reference
    }

    cacheClearSubject.send(.bytesCleared(1024))
    await store.receive(.interactive(
      .onboardingClearCache(.receivedClearCacheUpdate(.bytesCleared(1024))),
    )) {
      $0.onboarding.clearCache?.bytesCleared = 1024
    }

    cacheClearSubject.send(.finished)
    await store.receive(.interactive(.onboardingClearCache(.receivedClearCacheUpdate(.finished)))) {
      $0.onboarding.clearCache?.screen = .cleared
    }

    await store.send(.interactive(.onboardingClearCache(.completeBtnTapped))) {
      $0.onboarding.clearCache = nil
      $0.screen = .onboarding(.happyPath(.requestAppStoreRating))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.doneQuit))
    }

    expect(ratingRequestInvocations.value).toEqual(1)
    await store.send(.programmatic(.appWillTerminate))
  }

  @MainActor
  func testConnectAccountFeatureFlagEnabled() async throws {
    var initialState = IOSReducer.State(
      screen: .onboarding(.happyPath(.dontGetTrickedPreInstall)),
      allBlockGroups: [.init(id: UUID(), name: "", shortDescription: "", longDescription: "")],
    )
    initialState.onboarding.connectFeature = .init(isEnabled: true)

    let store = TestStore(initialState: initialState) {
      IOSReducer()
    } withDependencies: {
      $0.api.logEvent = { @Sendable _, _ in }
      $0.systemExtension.installFilter = { .success(()) }
      $0.sharedStorage.saveDisabledBlockGroupIds = { @Sendable _ in }
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, "")))

    await store.receive(.programmatic(.installSucceeded)) {
      $0.screen = .onboarding(.happyPath(.offerAccountConnect))
    }

    await store.send(.interactive(.onboardingBtnTapped(.tertiary, ""))) {
      $0.screen = .onboarding(.happyPath(.explainAccountConnect))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.offerAccountConnect))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.optOutBlockGroups))
    }
  }

  @MainActor
  func testUpgradeFromV110() async throws {
    let defaultBlocksInvocations = LockIsolated(0)
    let userDefaults = UserDefaults.gertrude
    userDefaults.removePersistentDomain(forName: .gertrudeGroupId)
    userDefaults.set(Data([0x01]), forKey: "blockRules.v1") // <-- V1 data

    let store = TestStore(initialState: IOSReducer.State()) {
      IOSReducer()
    } withDependencies: {
      $0.device.deleteCacheFillDir = {}
      $0.api.logEvent = { @Sendable _, _ in }
      $0.api.fetchDefaultBlockRules = { @Sendable _ in
        defaultBlocksInvocations.withValue { $0 += 1 }
        return [.urlContains(value: "GIFs")]
      }
      $0.api.fetchAllBlockGroups = { @Sendable _ in [] }
      $0.sharedStorage = .liveValue
      $0.sharedStorage.saveFirstLaunchDate(.reference)
      $0.systemExtension.filterRunning = { true } // <-- filter running
    }

    await store.send(.programmatic(.appDidLaunch))

    await store.receive(.programmatic(.setFirstLaunch(.reference))) {
      $0.onboarding.firstLaunch = .reference
    }

    await store.receive(.programmatic(.setScreen(.running(state: .notConnected)))) {
      $0.screen = .running(state: .notConnected)
    }

    // they get opted out of new apple music group, as an upgrader
    await store.receive(.programmatic(.receivedDisabledBlockGroupIds([
      UUID(uuidString: "236c92c9-a06c-4f68-9f1a-74e76163ae07")!,
    ]))) {
      $0.disabledBlockGroupIds = [UUID(uuidString: "236c92c9-a06c-4f68-9f1a-74e76163ae07")!]
    }

    expect(defaultBlocksInvocations.value).toEqual(1)
    var data = userDefaults.data(forKey: "v1.5.0--protection-mode")!
    let protection = try JSONDecoder().decode(ProtectionMode.self, from: data)
    expect(protection).toEqual(.normal([.urlContains(value: "GIFs")]))

    data = userDefaults.data(forKey: "disabledBlockGroups.v1.3.0")!
    let disabled = try JSONDecoder().decode([BlockGroup].self, from: data)
    expect(disabled).toEqual([.spotifyImages])

    await store.send(.programmatic(.appWillTerminate))
  }

  @MainActor
  func testUpgradeFromV13x() async throws {
    let userDefaults = UserDefaults.gertrude
    userDefaults.removePersistentDomain(forName: .gertrudeGroupId)

    let legacyRules = ProtectionMode.Legacy.normal([.targetContains("v13-example.com")])
    let legacyData = try JSONEncoder().encode(legacyRules)
    userDefaults.set(legacyData, forKey: "ProtectionMode.v1.3.0")
    let disabledGroups = [BlockGroup.gifs, BlockGroup.ads]
    let disabledData = try JSONEncoder().encode(disabledGroups)
    userDefaults.set(disabledData, forKey: "disabledBlockGroups.v1.3.0")

    let store = TestStore(initialState: IOSReducer.State()) {
      IOSReducer()
    } withDependencies: {
      $0.device.deleteCacheFillDir = {}
      $0.api.logEvent = { @Sendable _, _ in }
      $0.api.fetchAllBlockGroups = { @Sendable _ in [] }
      $0.sharedStorage = .liveValue
      $0.sharedStorage.saveFirstLaunchDate(.reference)
      $0.systemExtension.filterRunning = { true }
    }

    await store.send(.programmatic(.appDidLaunch))

    await store.receive(.programmatic(.setFirstLaunch(.reference))) {
      $0.onboarding.firstLaunch = .reference
    }

    await store.receive(.programmatic(.setScreen(.running(state: .notConnected)))) {
      $0.screen = .running(state: .notConnected)
    }

    await store.receive(.programmatic(.receivedDisabledBlockGroupIds([
      BlockGroup.gifs.legacyUUID,
      BlockGroup.ads.legacyUUID,
      // they get opted out of new apple music group, as an upgrader
      UUID(uuidString: "236c92c9-a06c-4f68-9f1a-74e76163ae07")!,
    ]))) {
      $0.disabledBlockGroupIds = [
        BlockGroup.gifs.legacyUUID,
        BlockGroup.ads.legacyUUID,
        UUID(uuidString: "236c92c9-a06c-4f68-9f1a-74e76163ae07")!,
      ]
    }

    var data = userDefaults.data(forKey: "v1.5.0--protection-mode")!
    let protection = try JSONDecoder().decode(ProtectionMode.self, from: data)
    expect(protection).toEqual(.normal([.targetContains(value: "v13-example.com")]))

    data = userDefaults.data(forKey: "disabledBlockGroups.v1.3.0")!
    let disabled = try JSONDecoder().decode([BlockGroup].self, from: data)
    expect(disabled).toEqual(disabledGroups + [.spotifyImages])

    await store.send(.programmatic(.appWillTerminate))
  }

  @MainActor
  func testUsesHardcodedBlockRulesIfApiDefaultsReqFails() async throws {
    let savedProtectionModes = LockIsolated<[ProtectionMode]>([])

    let store = TestStore(initialState: IOSReducer.State()) {
      IOSReducer()
    } withDependencies: {
      $0.date = .constant(.reference)
      $0.locale = Locale(identifier: "en_US")
      $0.device.deleteCacheFillDir = {}
      $0.api.logEvent = { @Sendable _, _ in }
      $0.api.fetchAllBlockGroups = { @Sendable _ in [] }
      $0.api.fetchDefaultBlockRules = { @Sendable _ in
        struct TestError: Error {}
        throw TestError()
      }
      $0.api.connectAccountFeatureFlag = { @Sendable in
        .init(isEnabled: false)
      }
      $0.sharedStorage.loadFirstLaunchDate = { @Sendable in nil }
      $0.sharedStorage.loadDisabledBlockGroupIds = { @Sendable in nil }
      $0.sharedStorage.loadAccountConnection = { @Sendable in nil }
      $0.sharedStorage.saveProtectionMode = { @Sendable value in
        savedProtectionModes.withValue { $0.append(value) }
      }
    }

    store.exhaustivity = .off
    await store.send(.programmatic(.appDidLaunch))

    expect(savedProtectionModes.value)
      .toEqual([.onboarding(BlockRule.Legacy.defaults.map(\.current))])
  }

  @MainActor
  func testChooseWriteReview() async throws {
    let writeReviewInvocations = LockIsolated(0)
    let store = TestStore(
      initialState: IOSReducer.State(screen: .onboarding(.happyPath(.requestAppStoreRating))),
    ) {
      IOSReducer()
    } withDependencies: {
      $0.appStore.requestReview = {
        writeReviewInvocations.withValue { $0 += 1 }
      }
    }

    await store.send(.interactive(.onboardingBtnTapped(.secondary, ""))) {
      $0.screen = .onboarding(.happyPath(.doneQuit))
    }

    expect(writeReviewInvocations.value).toEqual(1)
  }

  @MainActor
  func testSkipReviewAndRating() async throws {
    let store = store(starting: .onboarding(.happyPath(.requestAppStoreRating)))
    await store.send(.interactive(.onboardingBtnTapped(.tertiary, ""))) {
      $0.screen = .onboarding(.happyPath(.doneQuit))
    }
  }

  @MainActor
  func testSkipsBatteryWarningWhenEnough() async throws {
    let clearCacheInvocations = LockIsolated(0)
    let store = TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.happyPath(.promptClearCache)),
    )) {
      IOSReducer()
    } withDependencies: {
      $0.mainQueue = .immediate
      $0.date = .constant(.reference)
      $0.api.logEvent = { @Sendable _, _ in }
      $0.device.batteryLevel = { .level(0.75) } // <-- enough battery
      $0.device.availableDiskSpaceInBytes = { 1024 * 1024 * 1024 * 5 } // <-- 5 GB space
      $0.device.clearCache = { _ in
        clearCacheInvocations.withValue { $0 += 1 }
        return AnyPublisher(Empty())
      }
    }
    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.onboarding.clearCache = .init(context: .onboarding)
    }
    await store.send(.interactive(.onboardingClearCache(.onAppear)))
    await store.receive(.interactive(.onboardingClearCache(.receivedDeviceInfo(
      batteryLevel: .level(0.75),
      availableSpace: 1024 * 1024 * 1024 * 5,
    )))) {
      $0.onboarding.clearCache?.batteryLevel = .level(0.75)
      $0.onboarding.clearCache?.screen = .clearing
      $0.onboarding.clearCache?.startClearCache = .reference
      $0.onboarding.clearCache?.availableDiskSpaceInBytes = 1024 * 1024 * 1024 * 5
    }
    expect(clearCacheInvocations.value).toEqual(1)
  }

  @MainActor
  func testShowsBatteryWarningWhenHugeDiskToClear() async throws {
    let clearCacheInvocations = LockIsolated(0)
    let store = TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.happyPath(.promptClearCache)),
    )) {
      IOSReducer()
    } withDependencies: {
      $0.mainQueue = .immediate
      $0.date = .constant(.reference)
      $0.api.logEvent = { @Sendable _, _ in }
      $0.device.batteryLevel = { .level(0.95) } // <-- logs of battery, but...
      $0.device.availableDiskSpaceInBytes = { 1024 * 1024 * 1024 * 65 } // ...65 GB to clear !!
      $0.device.clearCache = { _ in
        clearCacheInvocations.withValue { $0 += 1 }
        return AnyPublisher(Empty())
      }
    }
    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.onboarding.clearCache = .init(context: .onboarding, screen: .loading)
    }
    await store.send(.interactive(.onboardingClearCache(.onAppear)))
    await store.receive(.interactive(.onboardingClearCache(.receivedDeviceInfo(
      batteryLevel: .level(0.95),
      availableSpace: 1024 * 1024 * 1024 * 65,
    )))) {
      $0.onboarding.clearCache?.batteryLevel = .level(0.95)
      $0.onboarding.clearCache?.screen = .batteryWarning
      $0.onboarding.clearCache?.availableDiskSpaceInBytes = 1024 * 1024 * 1024 * 65
    }
    await store.send(.interactive(.onboardingClearCache(.batteryWarningContinueTapped))) {
      $0.onboarding.clearCache?.screen = .clearing
      $0.onboarding.clearCache?.startClearCache = .reference
    }
    expect(clearCacheInvocations.value).toEqual(1)
  }

  func testFirstLaunchWithStoredDate_ToRunning() async throws {
    let store = await TestStore(initialState: IOSReducer.State()) {
      IOSReducer()
    } withDependencies: {
      $0.device.deleteCacheFillDir = {}
      $0.api.fetchDefaultBlockRules = { @Sendable _ in [] }
      $0.api.fetchAllBlockGroups = { @Sendable _ in [] }
      $0.sharedStorage.loadProtectionMode = { @Sendable in
        .normal([.urlContains(value: "bad")])
      }
      $0.sharedStorage.loadDisabledBlockGroupIds = { @Sendable in [] }
      $0.sharedStorage.loadFirstLaunchDate = { @Sendable in .distantPast }
      $0.systemExtension.filterRunning = { true }
    }

    await store.send(.programmatic(.appDidLaunch))
    await store.receive(.programmatic(.setFirstLaunch(.distantPast))) {
      $0.onboarding.firstLaunch = .distantPast
    }
    await store.receive(.programmatic(.setScreen(.running(state: .notConnected)))) {
      $0.screen = .running(state: .notConnected)
    }
    await store.receive(.programmatic(.receivedDisabledBlockGroupIds([])))
    await store.send(.programmatic(.appWillTerminate))
  }

  func testFirstLaunchSupervisedSuccess() async throws {
    let groupId = UUID()
    let store = await TestStore(initialState: IOSReducer.State()) {
      IOSReducer()
    } withDependencies: {
      $0.date = .constant(.reference)
      $0.locale = Locale(identifier: "en_US")
      $0.device.deleteCacheFillDir = {}
      $0.api.fetchDefaultBlockRules = { @Sendable _ in [] }
      $0.api.logEvent = { @Sendable _, _ in }
      $0.api.connectAccountFeatureFlag = { @Sendable in .init(isEnabled: false) }
      // filter running...
      $0.systemExtension.filterRunning = { true }
      $0.api.fetchAllBlockGroups = { @Sendable _ in [] }
      // but no sign of onboarding...
      $0.sharedStorage.loadDisabledBlockGroupIds = { @Sendable in nil }
      $0.sharedStorage.loadAccountConnection = { @Sendable in nil }
      $0.sharedStorage.loadAllBlockGroups = { @Sendable in [
        .init(id: groupId, name: "", shortDescription: "", longDescription: ""),
      ] }
    }

    await store.send(.programmatic(.appDidLaunch))

    await store.receive(.programmatic(.setFirstLaunch(.reference))) {
      $0.onboarding.firstLaunch = .reference
    }

    // ...so we go straight to supervision first launch
    await store.receive(.programmatic(.setScreen(.supervisionSuccessFirstLaunch))) {
      $0.screen = .supervisionSuccessFirstLaunch
    }

    await store.receive(.programmatic(.receivedConnectAccountFeatureFlag(.init(isEnabled: false))))

    await store.receive(.programmatic(.receivedAllBlockGroups([
      .init(id: groupId, name: "", shortDescription: "", longDescription: ""),
    ]))) {
      $0.allBlockGroups = [.init(id: groupId, name: "", shortDescription: "", longDescription: "")]
    }

    // primary button goes to opt out groups
    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.optOutBlockGroups))
      $0.onboarding.deviceSupervised = true
    }

    await store.send(.programmatic(.appWillTerminate))
  }

  @MainActor
  func testParentDeviceFail() async throws {
    let store = store(starting: .onboarding(.happyPath(.confirmChildsDevice)))

    await store.send(.interactive(.onboardingBtnTapped(.secondary, ""))) {
      $0.screen = .onboarding(.onParentDeviceFail)
    }
  }

  @MainActor
  func testNoBlockGroupsFallback() async throws {
    let savedDisabledGroups = LockIsolated<[[UUID]]>([])
    let store = TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.happyPath(.dontGetTrickedPreInstall)),
      allBlockGroups: [], // <-- no groups fetched (e.g. api was down)
    )) {
      IOSReducer()
    } withDependencies: {
      $0.api.logEvent = { @Sendable _, _ in }
      $0.systemExtension.installFilter = { .success(()) }
      $0.sharedStorage.saveDisabledBlockGroupIds = { @Sendable value in
        savedDisabledGroups.withValue { $0.append(value) }
      }
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, "")))

    await store.receive(.programmatic(.installSucceeded)) {
      $0.screen = .onboarding(.happyPath(.promptClearCache))
    }

    expect(savedDisabledGroups.value).toEqual([[], []]) // empty saved twice (both safeguards)
  }

  @MainActor
  func testCantAdvanceWithZeroBlockGroups() async throws {
    let allIds = (0 ..< 9).map { _ in UUID() }
    let store = TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.happyPath(.optOutBlockGroups)),
      allBlockGroups: allIds.map {
        .init(id: $0, name: "", shortDescription: "", longDescription: "")
      },
      disabledBlockGroupIds: allIds,
    )) {
      IOSReducer()
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, "")))
    expect(store.state.screen).toEqual(.onboarding(.happyPath(.optOutBlockGroups)))
  }

  @MainActor
  func testConfirmParentIsOnboardingFail() async throws {
    let store = store(starting: .onboarding(.happyPath(.confirmParentIsOnboarding)))

    await store.send(.interactive(.onboardingBtnTapped(.secondary, ""))) {
      $0.screen = .onboarding(.childIsOnboardingFail)
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.hiThere))
    }
  }

  @MainActor
  func testSkipCacheClear() async throws {
    let store = store(starting: .onboarding(.happyPath(.promptClearCache)))

    await store.send(.interactive(.onboardingBtnTapped(.secondary, ""))) {
      $0.screen = .onboarding(.happyPath(.requestAppStoreRating))
    }
  }

  @MainActor
  func testAppStoreReviewBuild_routesToExplainer() async throws {
    var onboarding = IOSReducer.State.OnboardingState()
    onboarding.connectFeature = .init(isEnabled: false, releasedAppStoreVersion: "1.6.2")
    let store = TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.happyPath(.explainPermissionDependsOnAge)),
      onboarding: onboarding,
    )) {
      IOSReducer()
    } withDependencies: {
      $0.device.installedVersion = { "1.7.0" }
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.confirmMinorDevice))
    }

    await store
      .send(.interactive(.onboardingBtnTapped(.secondary, ""))) { // <-- over 18, build ahead
        $0.screen = .onboarding(.mdmSupervisionExplainer)
      }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.hiThere))
    }
  }

  @MainActor
  func testInfoBtnTappedLoadsInfoFeatureDestination() async throws {
    let vendorId = UUID()
    let store = TestStore(initialState: IOSReducer.State(screen: .running(state: .notConnected))) {
      IOSReducer()
    } withDependencies: {
      $0.sharedStorage.loadAccountConnection = { @Sendable in nil }
      $0.keychain._load = { @Sendable _ in vendorId.uuidString.data(using: .utf8) }
      $0.sharedStorage.loadProtectionMode = { @Sendable in
        .normal([.urlContains(value: "test")])
      }
      $0.sharedStorage.loadDisabledBlockGroupIds = { @Sendable in [UUID()] }
    }

    await store.send(.interactive(.infoBtnTapped)) {
      $0.destination = .info(InfoFeature.State(
        connection: nil,
        deviceId: vendorId,
        numRules: 1,
        numDisabledBlockGroups: 1,
      ))
    }
  }
}

@MainActor
func store(starting screen: IOSReducer.Screen) -> TestStore<IOSReducer.State, IOSReducer.Action> {
  TestStore(initialState: IOSReducer.State(screen: screen)) {
    IOSReducer()
  }
}

extension Date {
  static let epoch = Date(timeIntervalSince1970: 0)
  static let reference = Date(timeIntervalSinceReferenceDate: 0)
}
