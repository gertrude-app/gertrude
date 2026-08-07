import DuetSQL
import Gertie
import PairQL
import XCTest
import XExpect

@testable import Api

final class SaveMacappMonitoringResolverTests: ApiTestCase, @unchecked Sendable {
  func testEnforcesMinimumScreenshotFrequency() async throws {
    let child = try await self.child()

    let output = try await SaveMacappMonitoring.resolve(
      with: SaveMacappMonitoring.Input(
        id: child.id,
        keyloggingEnabled: false,
        screenshotsEnabled: false,
        screenshotsResolution: 333,
        screenshotsFrequency: 1, // <-- below minimum of 10
        showSuspensionActivity: true,
      ),
      in: child.parent.context,
    )

    let retrieved = try await self.db.find(child.id)
    expect(output).toEqual(.success)
    expect(retrieved.screenshotsFrequency).toEqual(10)
  }

  func testRejectsScreenshotsDisabledWhenFilteringDisabled() async throws {
    let child = try await self.child(with: \.filteringDisabled, of: true)
    var threw = false
    do {
      _ = try await SaveMacappMonitoring.resolve(
        with: SaveMacappMonitoring.Input(
          id: child.id,
          keyloggingEnabled: true,
          screenshotsEnabled: false,
          screenshotsResolution: 1000,
          screenshotsFrequency: 180,
          showSuspensionActivity: true,
        ),
        in: child.parent.context,
      )
    } catch {
      threw = true
    }
    expect(threw).toEqual(true)
  }

  func testUpdatesMonitoringFields() async throws {
    let child = try await self.child()

    let output = try await SaveMacappMonitoring.resolve(
      with: SaveMacappMonitoring.Input(
        id: child.id,
        keyloggingEnabled: false,
        screenshotsEnabled: false,
        screenshotsResolution: 333,
        screenshotsFrequency: 444,
        showSuspensionActivity: true,
      ),
      in: child.parent.context,
    )

    let retrieved = try await self.db.find(child.id)
    expect(output).toEqual(.success)
    expect(retrieved.keyloggingEnabled).toEqual(false)
    expect(retrieved.screenshotsEnabled).toEqual(false)
    expect(retrieved.screenshotsResolution).toEqual(333)
    expect(retrieved.screenshotsFrequency).toEqual(444)
    expect(retrieved.showSuspensionActivity).toEqual(true)
    expect(sent.websocketMessages).toEqual([.init(.userUpdated, to: .user(child.id))])
  }
}
