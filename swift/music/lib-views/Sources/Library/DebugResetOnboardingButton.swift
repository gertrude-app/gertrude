import SwiftUI

#if DEBUG
  struct DebugResetOnboardingButton: View {
    let onTap: @MainActor @Sendable () -> Void

    var body: some View {
      Button("Reset onboarding", action: self.onTap)
        .font(.system(size: 12, weight: .semibold, design: .rounded))
        .buttonStyle(.bordered)
        .tint(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
    }
  }
#endif
