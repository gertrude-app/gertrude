import Gertie
import TaggedTime

enum AdminEvent: Equatable {
  case unlockRequestSubmitted(UnlockRequestSubmitted)
  case suspendFilterRequestSubmitted(SuspendFilterRequestSubmitted)
  case securityEvent(SecurityEventPayload)

  struct SecurityEventPayload: Equatable {
    var source: Source
    var detail: String?

    enum Source: Equatable {
      case macApp(childName: String, event: Gertie.SecurityEvent.MacApp)
      case dashboard(event: Gertie.SecurityEvent.Dashboard)
    }
  }

  struct UnlockRequestSubmitted: Equatable {
    var dashboardUrl: String
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
        deviceId: IOSApp.Device.Id,
        requestId: IOSApp.SuspendFilterRequest.Id,
      )
    }

    var dashboardUrl: String
    var childId: Child.Id
    var childName: String
    var duration: Seconds<Int>
    var requestComment: String?
    var context: Context
  }
}
