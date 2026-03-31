import Dependencies
import XCTest
import XExpect

@testable import Api

final class AppStoreVersionPollJobTests: ApiTestCase, @unchecked Sendable {
  func testPollStoresVersionInEphemeral() async throws {
    let ephemeral = Ephemeral()
    let version = await ephemeral.getLatestIOSAppStoreVersion()
    expect(version).toBeNil()

    try await withDependencies {
      $0.db = self.db
      $0.env = .testValue
      $0.slack = .mock
      $0.ephemeral = ephemeral
      $0.appStoreConnect.fetchAppStoreVersion = { _ in "1.8.0" }
    } operation: {
      await AppStoreVersionPollJob().exec()
    }

    let stored = await ephemeral.getLatestIOSAppStoreVersion()
    expect(stored).toEqual("1.8.0")
  }

  func testPollErrorClearsPreviouslyStoredVersion() async throws {
    let ephemeral = Ephemeral()
    await ephemeral.setLatestIOSAppStoreVersion("1.7.0")
    let before = await ephemeral.getLatestIOSAppStoreVersion()
    expect(before).toEqual("1.7.0")

    await withDependencies {
      $0.db = self.db
      $0.env = .testValue
      $0.slack = .mock
      $0.ephemeral = ephemeral
      $0.appStoreConnect.fetchAppStoreVersion = { _ in
        throw AppStoreConnectError.noResults
      }
    } operation: {
      await AppStoreVersionPollJob().exec()
    }

    let stored = await ephemeral.getLatestIOSAppStoreVersion()
    expect(stored).toBeNil()
  }
}
