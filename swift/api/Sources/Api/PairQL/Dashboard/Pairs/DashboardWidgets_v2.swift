import Foundation
import PairQL

/// @deprecated safe to remove 2026-07-07
struct DashboardWidgets_v2: Pair {
  static let auth: ClientAuth = .parent

  struct Announcement: PairNestable {
    var id: DashAnnouncement.Id
    var kind: DashAnnouncement.Kind
    var icon: String?
    var html: String
    var learnMoreUrl: String?
  }

  struct Output: PairOutput {
    var children: [DashboardWidgets_v3.Child]
    var childActivitySummaries: [DashboardWidgets_v3.ChildActivitySummary]
    var unlockRequests: [DashboardWidgets_v3.UnlockRequest]
    var recentScreenshots: [DashboardWidgets_v3.RecentScreenshot]
    var numParentNotifications: Int
    var announcement: Announcement?
    var pendingIOSDevices: [DashboardWidgets_v3.PendingIOSDevice]
  }
}

// resolver

extension DashboardWidgets_v2: NoInputResolver {
  static func resolve(in context: ParentContext) async throws -> Output {
    await context.db.logDeprecated("DashboardWidgets(v2)")
    let v3 = try await DashboardWidgets_v3.resolve(in: context)
    return Output(
      children: v3.children,
      childActivitySummaries: v3.childActivitySummaries,
      unlockRequests: v3.unlockRequests,
      recentScreenshots: v3.recentScreenshots,
      numParentNotifications: v3.numParentNotifications,
      announcement: v3.announcement.map { .init(
        id: $0.id,
        kind: $0.kind,
        icon: $0.icon,
        html: $0.html,
        learnMoreUrl: $0.action?.url,
      ) },
      pendingIOSDevices: v3.pendingIOSDevices,
    )
  }
}
