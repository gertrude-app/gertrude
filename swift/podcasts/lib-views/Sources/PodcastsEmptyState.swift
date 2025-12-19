import SwiftUI

public struct PodcastsEmptyState: View {
  @Environment(\.colorScheme) var cs

  let onAddShowTap: @MainActor @Sendable () -> Void

  public init(onAddShowTap: @MainActor @escaping @Sendable () -> Void) {
    self.onAddShowTap = onAddShowTap
  }

  public var body: some View {
    VStack(spacing: 24) {
      Spacer()

      Image(systemName: "waveform.and.mic")
        .font(.system(size: 64, weight: .light))
        .foregroundStyle(Color(self.cs, light: .violet300, dark: .violet700))

      VStack(spacing: 12) {
        Text(lstr(.showsEmptyTitle))
          .font(.system(size: 28, weight: .bold))
          .foregroundStyle(Color(self.cs, light: .violet950, dark: .violet100))

        Text(lstr(.showsEmptyMessage))
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet400))
          .multilineTextAlignment(.center)
          .padding(.horizontal, 40)
      }

      Spacer()

      BigButton(
        lstr(.showsAddShow),
        type: .button(self.onAddShowTap),
        variant: .primary,
        icon: "plus",
      )
      .padding(.horizontal, 30)
      .padding(.bottom, 30)
    }
  }
}

#Preview {
  PodcastsEmptyState(onAddShowTap: {})
}

#Preview("(Dark)") {
  PodcastsEmptyState(onAddShowTap: {})
    .preferredColorScheme(.dark)
}
