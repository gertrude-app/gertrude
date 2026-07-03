import Dependencies
import DependenciesMacros
import Foundation

public enum RecorderEvent: String, Sendable, Equatable, Codable, CaseIterable {
  case broadcastStarted = "com.netrivet.gertrude-ios.app.broadcastStarted"
  case broadcastPaused = "com.netrivet.gertrude-ios.app.broadcastPaused"
  case broadcastResumed = "com.netrivet.gertrude-ios.app.broadcastResumed"
  case broadcastFinished = "com.netrivet.gertrude-ios.app.broadcastFinished"
}

@DependencyClient
public struct RecorderEventsClient: Sendable {
  public var events: @Sendable () -> AsyncStream<RecorderEvent> = { AsyncStream { _ in } }
  public var emit: @Sendable (RecorderEvent) -> Void
}

extension RecorderEventsClient: DependencyKey {
  public static var liveValue: RecorderEventsClient {
    .init(
      events: {
        AsyncStream<RecorderEvent> { continuation in
          notifier.withValue { notifier in
            for event in RecorderEvent.allCases {
              notifier.startObserving(name: event.rawValue) {
                continuation.yield(event)
              }
            }
          }
        }
      },
      emit: { event in
        notifier.withValue { $0.postNotification(name: event.rawValue) }
      },
    )
  }
}

extension RecorderEventsClient: TestDependencyKey {
  public static let testValue = RecorderEventsClient()
}

public extension DependencyValues {
  var recorderEvents: RecorderEventsClient {
    get { self[RecorderEventsClient.self] }
    set { self[RecorderEventsClient.self] = newValue }
  }
}

// @see https://ohmyswift.com/blog/2024/08/27/send-data-between-ios-apps-and-extensions-using-darwin-notifications/
private final class DarwinNotificationManager {
  private var callbacks: [String: () -> Void] = [:]

  init() {}

  func postNotification(name: String) {
    let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
    CFNotificationCenterPostNotification(
      notificationCenter,
      CFNotificationName(name as CFString),
      nil,
      nil,
      true,
    )
  }

  func startObserving(name: String, callback: @escaping () -> Void) {
    self.callbacks[name] = callback
    let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
    CFNotificationCenterAddObserver(
      notificationCenter,
      Unmanaged.passUnretained(self).toOpaque(),
      DarwinNotificationManager.notificationCallback,
      name as CFString,
      nil,
      .deliverImmediately,
    )
  }

  func stopObserving(name: String) {
    let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
    CFNotificationCenterRemoveObserver(
      notificationCenter,
      Unmanaged.passUnretained(self).toOpaque(),
      CFNotificationName(name as CFString),
      nil,
    )
    self.callbacks.removeValue(forKey: name)
  }

  private static let notificationCallback: CFNotificationCallback = { _, observer, name, _, _ in
    guard let observer else { return }
    let manager = Unmanaged<DarwinNotificationManager>.fromOpaque(observer)
      .takeUnretainedValue()
    if let name = name?.rawValue as String?,
       let callback = manager.callbacks[name] {
      callback()
    }
  }
}

private let notifier = LockIsolated(DarwinNotificationManager())
