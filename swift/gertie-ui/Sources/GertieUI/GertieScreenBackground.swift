import SwiftUI

public extension View {
  func gertieScreenBackground() -> some View {
    self.modifier(GertieScreenBackgroundModifier())
  }
}

struct GertieScreenBackground: View {
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    Color(self.colorScheme, light: .white, dark: .black)
      .overlay {
        LinearGradient(
          colors: [
            Color(
              self.colorScheme,
              light: .violet200,
              dark: .violet950.opacity(0.7),
            ),
            .clear,
          ],
          startPoint: .top,
          endPoint: .bottom,
        )
      }
  }
}

private struct GertieScreenBackgroundModifier: ViewModifier {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var isVisible = false

  func body(content: Content) -> some View {
    ZStack {
      GertieScreenBackground()
        .opacity(self.isVisible ? 1 : 0)
        .ignoresSafeArea()

      content
    }
    .task(id: self.reduceMotion) {
      guard !self.isVisible else { return }
      guard !self.reduceMotion else {
        self.isVisible = true
        return
      }

      withAnimation(.smooth(duration: 0.4)) {
        self.isVisible = true
      }
    }
  }
}
