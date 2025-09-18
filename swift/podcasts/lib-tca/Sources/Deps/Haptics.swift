import Dependencies
import DependenciesMacros
import Foundation
import LibCore

@DependencyClient
struct HapticsClient: Sendable {
  var impact: @MainActor @Sendable (UIImpactFeedbackGenerator.FeedbackStyle) -> Void
  var notification: @MainActor @Sendable (UINotificationFeedbackGenerator.FeedbackType) -> Void
  var selection: @MainActor @Sendable () -> Void = {}
  var prepare: @MainActor @Sendable () -> Void = {}
}

extension HapticsClient {
  enum ImpactStyle: CaseIterable {
    case light, medium, heavy, soft, rigid
  }

  enum NotificationStyle: CaseIterable {
    case success, warning, error
  }
}

extension HapticsClient: DependencyKey {
  static var liveValue: HapticsClient {
    .init(
      impact: { style in
        UIImpactFeedbackGenerator(style: style).impactOccurred()
      },
      notification: { type in
        UINotificationFeedbackGenerator().notificationOccurred(type)
      },
      selection: {
        UISelectionFeedbackGenerator().selectionChanged()
      },
      prepare: {
        UIImpactFeedbackGenerator().prepare()
        UINotificationFeedbackGenerator().prepare()
        UISelectionFeedbackGenerator().prepare()
      }
    )
  }
}

extension DependencyValues {
  var haptics: HapticsClient {
    get { self[HapticsClient.self] }
    set { self[HapticsClient.self] = newValue }
  }
}
