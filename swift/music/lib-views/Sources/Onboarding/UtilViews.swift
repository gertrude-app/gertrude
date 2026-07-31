import SwiftUI

struct ScreenBackground: View {
  @Environment(\.colorScheme) private var colorScheme

  let showBackground: Bool

  var body: some View {
    Rectangle()
      .fill(
        Gradient(colors: [
          Color(self.colorScheme, light: .violet200, dark: .violet950.opacity(0.7)),
          .clear,
        ]),
      )
      .ignoresSafeArea()
      .opacity(self.showBackground ? 1 : 0)
  }
}

struct ScreenGradientBackground: ViewModifier {
  @Environment(\.colorScheme) private var colorScheme
  @State private var showBackground = false

  func body(content: Content) -> some View {
    ZStack {
      ScreenBackground(showBackground: self.showBackground)
        .onAppear {
          withAnimation(.smooth(duration: 0.7)) {
            self.showBackground = true
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
