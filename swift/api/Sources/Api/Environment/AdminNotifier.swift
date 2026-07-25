import Dependencies
import Gertie

struct AdminNotifier: Sendable {
  var notify: @Sendable (Parent.Id, AdminEvent) async -> Void
}

// dependency

extension DependencyValues {
  var adminNotifier: AdminNotifier {
    get { self[AdminNotifier.self] }
    set { self[AdminNotifier.self] = newValue }
  }
}

extension AdminNotifier: DependencyKey {
  static var liveValue: AdminNotifier {
    .init { parentId, event in
      @Dependency(\.db) var db
      @Dependency(\.env) var env
      @Dependency(\.slack) var slack
      do {
        let parent = try await db.find(parentId)
        let event = parent.accountSiteBetaEnabled
          ? event.routingMacSuspensionRequest(toAccountSiteAt: env.accountDashboardUrl)
          : event
        let notifications = try await parent.notifications(in: db)

        // happy path: they have at least one notification for this event
        if !notifications.isEmpty {
          for notification in notifications {
            do {
              switch (notification.trigger, event) {
              case (.suspendFilterRequestSubmitted, .suspendFilterRequestSubmitted(let event)):
                let method = try await notification.method(in: db)
                try await event.send(with: method.config, parentId: parentId)
              case (.unlockRequestSubmitted, .unlockRequestSubmitted(let event)):
                let method = try await notification.method(in: db)
                try await event.send(with: method.config, parentId: parentId)
              case (.securityEventsAll, .securityEvent(let event)):
                let method = try await notification.method(in: db)
                try await event.send(with: method.config, parentId: parentId)
              case (.securityEventsMedium, .securityEvent(let event)):
                if event.severity >= .medium {
                  let method = try await notification.method(in: db)
                  try await event.send(with: method.config, parentId: parentId)
                }
              case (.securityEventsRecommended, .securityEvent(let event)):
                if event.severity >= .recommended {
                  let method = try await notification.method(in: db)
                  try await event.send(with: method.config, parentId: parentId)
                }
              default:
                break
              }
            } catch {
              await slack
                .error("failed to notify admin \(parentId) of event \(event): \(error)")
            }
          }

          // no notifications: send fallback email unless it's a security event
        } else {
          do {
            switch event {
            case .suspendFilterRequestSubmitted(let event):
              try await event.sendEmail(to: parent.email.rawValue, isFallback: true)
            case .unlockRequestSubmitted(let event):
              try await event.sendEmail(to: parent.email.rawValue, isFallback: true)
            case .securityEvent:
              break
            }
          } catch {
            await slack
              .error("failed to fallback email admin \(parentId) of event \(event): \(error)")
          }
        }

      } catch {
        await slack
          .error("failed to find admin \(parentId) data for event \(event): \(error)")
      }
    }
  }
}

#if DEBUG
  extension AdminNotifier: TestDependencyKey {
    static var testValue: AdminNotifier {
      .init(notify: unimplemented("AdminNotifier.notify(adminId:event:)"))
    }
  }
#endif
