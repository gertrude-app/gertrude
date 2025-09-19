import Dependencies
import DependenciesMacros
import Foundation
import LibCore

@DependencyClient
struct HapticsClient: Sendable {
  var prepare: @MainActor @Sendable () -> Void = {}
  var impact: @MainActor @Sendable (UIImpactFeedbackGenerator.FeedbackStyle) -> Void
  var notification: @MainActor @Sendable (UINotificationFeedbackGenerator.FeedbackType) -> Void
  var selection: @MainActor @Sendable () -> Void = {}
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
      prepare: {
        UIImpactFeedbackGenerator().prepare()
        UINotificationFeedbackGenerator().prepare()
        UISelectionFeedbackGenerator().prepare()
      },
      impact: { style in
        UIImpactFeedbackGenerator(style: style).impactOccurred()
      },
      notification: { type in
        UINotificationFeedbackGenerator().notificationOccurred(type)
      },
      selection: {
        UISelectionFeedbackGenerator().selectionChanged()
      },
    )
  }
}

extension DependencyValues {
  var haptics: HapticsClient {
    get { self[HapticsClient.self] }
    set { self[HapticsClient.self] = newValue }
  }
}
