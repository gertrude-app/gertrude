import GertieUI
import SwiftUI

struct FinishedView: View {
  @Environment(\.colorScheme) var cs

  var body: some View {
    VStack(spacing: 0) {
      Spacer()

      Image(systemName: "party.popper")
        .font(.system(size: 40, weight: .regular))
        .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
        .accessibilityHidden(true)
        .swooshIn(
          fromYOffset: 20,
          after: .milliseconds(200),
          animation: .bouncy(duration: 0.5, extraBounce: 0.3),
        )

      Text("Quit the app, you’re done!")
        .font(.system(size: 24, weight: .bold))
        .padding(.bottom, 12)
        .padding(.top, 28)
        .swooshIn(
          fromYOffset: 20,
          after: .milliseconds(300),
          animation: .bouncy(duration: 0.5, extraBounce: 0.3),
        )

      Text("Gertrude will keep blocking even when the app is not running.")
        .font(.system(size: 18, weight: .regular))
        .foregroundStyle(Color(self.cs, light: .black.opacity(0.7), dark: .white.opacity(0.7)))
        .multilineTextAlignment(.center)
        .swooshIn(
          fromYOffset: 20,
          after: .milliseconds(400),
          animation: .bouncy(duration: 0.5, extraBounce: 0.3),
        )

      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.horizontal, 30)
    .gertieScreenBackground()
  }
}

#Preview {
  FinishedView()
}
