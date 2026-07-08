import ComposableArchitecture
import GertieTcaFeatures
import LibClients
import XCTest
import XExpect

@testable import LibApp

final class IOSReducerTestsInstallFail: XCTestCase {
  func testInstallErrPermissionDeniedFlow() async throws {
    let cleanupInvocations = LockIsolated(0)
    let logged = LockIsolated<[String]>([])
    let store = await TestStore(
      initialState: IOSReducer.State(screen: .onboarding(.happyPath(.dontGetTrickedPreInstall))),
    ) {
      IOSReducer()
    } withDependencies: {
      $0.appEvent.record = { event in logged.withValue { $0.append(event.detail ?? "") } }
      $0.systemExtension.installFilter = {
        .failure(.configurationPermissionDenied)
      }
      $0.systemExtension.cleanupForRetry = {
        cleanupInvocations.withValue { $0 += 1 }
      }
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, "")))

    await store.receive(.programmatic(.installFailed(.configurationPermissionDenied))) {
      $0.screen = .onboarding(.installFail(.permissionDenied))
    }

    expect(logged.value.contains { $0.contains("configurationPermissionDenied") }).toEqual(true)
    expect(cleanupInvocations.value).toEqual(1)

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) { // <-- "try again"
      $0.screen = .onboarding(.happyPath(.explainInstallWithDevicePasscode))
    }
  }

  func testInstallOtherError() async throws {
    let logged = LockIsolated<[String]>([])
    let store = await TestStore(
      initialState: IOSReducer.State(screen: .onboarding(.happyPath(.dontGetTrickedPreInstall))),
    ) {
      IOSReducer()
    } withDependencies: {
      $0.appEvent.record = { event in logged.withValue { $0.append(event.detail ?? "") } }
      $0.systemExtension.installFilter = {
        .failure(.configurationInternalError)
      }
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, "")))

    await store.receive(.programmatic(.installFailed(.configurationInternalError))) {
      $0.screen = .onboarding(.installFail(.other(.configurationInternalError)))
    }

    expect(logged.value.contains { $0.contains("configurationInternalError") }).toEqual(true)
    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) { // <-- "try again"
      $0.screen = .onboarding(.happyPath(.explainInstallWithDevicePasscode))
    }
  }
}
