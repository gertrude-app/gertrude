import SwiftUI

struct ScreenGradientBackground: ViewModifier {
  @Environment(\.colorScheme) var cs

  @State private var showBg = false

  func body(content: Content) -> some View {
    ZStack {
      Rectangle()
        .fill(
          Gradient(colors: [
            Color(self.cs, light: .violet200, dark: .violet950.opacity(0.7)),
            .clear,
          ]),
        )
        .ignoresSafeArea()
        .opacity(self.showBg ? 1 : 0)
        .onAppear {
          withAnimation(.backgroundFadeSmooth) {
            self.showBg = true
          }
        }

      content
    }
  }
}

extension View {
  func screenGradientBackground() -> some View {
    self.modifier(ScreenGradientBackground())
  }
}
