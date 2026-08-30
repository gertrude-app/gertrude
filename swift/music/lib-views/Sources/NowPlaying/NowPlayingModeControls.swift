import SwiftUI

public enum NowPlayingRepeatMode: Equatable, Sendable {
  case collection
  case off
  case track
}

struct NowPlayingModeControls: View {
  let isShuffleEnabled: Bool
  let isInfiniteEnabled: Bool
  let repeatMode: NowPlayingRepeatMode
  let onInfiniteTap: @MainActor @Sendable () -> Void
  let onRepeatTap: @MainActor @Sendable () -> Void
  let onShuffleTap: @MainActor @Sendable () -> Void

  var body: some View {
    HStack(spacing: 24) {
      NowPlayingModeButton(
        systemImage: "shuffle",
        isSelected: self.isShuffleEnabled,
        accessibilityLabel: "Shuffle",
        accessibilityValue: self.isShuffleEnabled ? "On" : "Off",
        action: self.onShuffleTap,
      )

      NowPlayingModeButton(
        systemImage: self.repeatMode.systemImage,
        isSelected: self.repeatMode.isSelected,
        accessibilityLabel: "Repeat",
        accessibilityValue: self.repeatMode.accessibilityValue,
        action: self.onRepeatTap,
      )

      NowPlayingModeButton(
        systemImage: "infinity",
        isSelected: self.isInfiniteEnabled,
        accessibilityLabel: "Infinite Play",
        accessibilityValue: self.isInfiniteEnabled ? "On" : "Off",
        action: self.onInfiniteTap,
      )
    }
    .frame(maxWidth: .infinity, minHeight: 44)
    .sensoryFeedback(.selection, trigger: self.isShuffleEnabled)
    .sensoryFeedback(.selection, trigger: self.isInfiniteEnabled)
    .sensoryFeedback(.selection, trigger: self.repeatMode)
  }
}

private extension NowPlayingRepeatMode {
  var accessibilityValue: String {
    switch self {
    case .collection: "All"
    case .off: "Off"
    case .track: "One"
    }
  }

  var isSelected: Bool {
    self != .off
  }

  var systemImage: String {
    self == .track ? "repeat.1" : "repeat"
  }
}

private struct NowPlayingModeButton: View {
  let systemImage: String
  let isSelected: Bool
  let accessibilityLabel: String
  let accessibilityValue: String
  let action: @MainActor @Sendable () -> Void

  var body: some View {
    Button(action: self.action) {
      Image(systemName: self.systemImage)
        .font(.system(size: 18, weight: .bold))
        .foregroundStyle(
          self.isSelected ? Color.black : Color.white.opacity(0.74),
        )
        .frame(width: 52, height: 36)
        .background(
          self.isSelected ? Color.white : Color.white.opacity(0.12),
          in: Capsule(),
        )
        .contentShape(Capsule())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(self.accessibilityLabel)
    .accessibilityValue(self.accessibilityValue)
    .accessibilityAddTraits(self.isSelected ? .isSelected : [])
  }
}
