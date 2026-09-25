import Dependencies
import DuetSQL
import Gertie

func dashSecurityEvent(
  _ event: Gertie.SecurityEvent.Dashboard,
  _ detail: String? = nil,
  parent parentId: Parent.Id,
  in context: Context,
) {
  Task {
    await recordDashSecurityEvent(
      event,
      parentId,
      context.ipAddress,
      detail,
      .legacyDashboard(baseUrl: context.env.dashboardUrl),
      with: context.db,
    )
  }
}

func dashSecurityEvent(
  _ event: Gertie.SecurityEvent.Dashboard,
  _ detail: String? = nil,
  in context: ParentContext,
) {
  Task {
    await recordDashSecurityEvent(
      event,
      context.parent.id,
      context.ipAddress,
      detail,
      .legacyDashboard(baseUrl: context.env.dashboardUrl),
      with: context.db,
    )
  }
}

func recordDashSecurityEvent(
  _ event: Gertie.SecurityEvent.Dashboard,
  _ detail: String? = nil,
  in context: AccountOwnerContext,
) async {
  await recordDashSecurityEvent(
    event,
    context.accountOwner.id,
    context.ipAddress,
    detail,
    .legacyDashboard(baseUrl: context.env.dashboardUrl),
    with: context.db,
  )
}

private func recordDashSecurityEvent(
  _ event: Gertie.SecurityEvent.Dashboard,
  _ parentId: Parent.Id,
  _ ipAddress: String? = nil,
  _ detail: String? = nil,
  _ notificationDestination: AdminEvent.NotificationDestination,
  with db: any DuetSQL.Client,
) async {
  _ = try? await db.create(Api.SecurityEvent(
    // opt out of using the controlled uuid dependency because this helper is also called
    // from unstructured tasks, which otherwise causes test flakiness
    id: .init(UUID()),
    parentId: parentId,
    event: event.rawValue,
    detail: detail,
    ipAddress: ipAddress,
  ))

  await with(dependency: \.adminNotifier).notify(
    parentId,
    .securityEvent(.init(
      source: .dashboard(event: event),
      detail: detail,
      notificationDestination: notificationDestination,
    )),
  )
}
