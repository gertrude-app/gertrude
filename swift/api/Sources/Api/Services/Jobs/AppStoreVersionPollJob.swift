import Dependencies
import Queues
import Vapor

struct AppStoreVersionPollJob: AsyncScheduledJob {
  @Dependency(\.env) var env
  @Dependency(\.slack) var slack
  @Dependency(\.ephemeral) var ephemeral
  @Dependency(\.appStoreConnect) var appStoreConnect

  func run(context: QueueContext) async throws {
    guard self.env.mode == .prod else { return }
    await self.exec()
  }

  func exec() async {
    do {
      let version = try await self.appStoreConnect.fetchAppStoreVersion(.blocker)
      await self.ephemeral.setLatestIOSAppStoreVersion(version)
    } catch {
      await self.ephemeral.setLatestIOSAppStoreVersion(nil)
      await self.slack.error("Failed to poll iOS App Store version: \(error)")
    }
  }
}
