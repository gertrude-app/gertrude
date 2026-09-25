import Gertie
import TaggedTime

enum AdminEvent: Equatable {
  case unlockRequestSubmitted(UnlockRequestSubmitted)
  case suspendFilterRequestSubmitted(SuspendFilterRequestSubmitted)
  case securityEvent(SecurityEventPayload)

  struct SecurityEventPayload: Equatable {
    var source: Source
    var detail: String?
    var notificationDestination: NotificationDestination

    enum Source: Equatable {
      case macApp(childName: String, event: Gertie.SecurityEvent.MacApp)
      case dashboard(event: Gertie.SecurityEvent.Dashboard)
    }
  }

  enum NotificationDestination: Equatable {
    case legacyDashboard(baseUrl: String)
    case accountSite(baseUrl: String)

    var baseUrl: String {
      switch self {
      case .legacyDashboard(baseUrl: let baseUrl),
           .accountSite(baseUrl: let baseUrl):
        baseUrl
      }
    }
  }

  struct UnlockRequestSubmitted: Equatable {
    var notificationDestination: NotificationDestination
    var userId: Child.Id
    var userName: String
    var requestIds: [UnlockRequest.Id]
  }

  struct SuspendFilterRequestSubmitted: Equatable {
    enum Context: Equatable {
      case macapp(
        computerUserId: ComputerUser.Id,
        requestId: MacApp.SuspendFilterRequest.Id,
      )
      case iosapp(
        deviceId: IOSDevice.Id,
        requestId: BlockerApp.SuspendFilterRequest.Id,
      )
    }

    var notificationDestination: NotificationDestination
    var childId: Child.Id
    var childName: String
    var duration: Seconds<Int>
    var requestComment: String?
    var context: Context
  }
}

extension AdminEvent {
  func routingNotifications(toAccountSiteAt accountDashboardUrl: String) -> Self {
    switch self {
    case .unlockRequestSubmitted(var request):
      request.notificationDestination = .accountSite(baseUrl: accountDashboardUrl)
      return .unlockRequestSubmitted(request)
    case .suspendFilterRequestSubmitted(var request):
      guard case .macapp = request.context else {
        return self
      }
      request.notificationDestination = .accountSite(baseUrl: accountDashboardUrl)
      return .suspendFilterRequestSubmitted(request)
    case .securityEvent(var event):
      event.notificationDestination = .accountSite(baseUrl: accountDashboardUrl)
      return .securityEvent(event)
    }
  }
}
