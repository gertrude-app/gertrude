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

struct WaitingStatus: View {
  @Environment(\.colorScheme) private var colorScheme

  let label: String
  let delay: Duration

  @State private var show = false

  var body: some View {
    HStack(spacing: 8) {
      ProgressView()
        .scaleEffect(0.7)
        .tint(Color(self.colorScheme, light: .violet500, dark: .violet400))
      Text(self.label)
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(Color(self.colorScheme, light: .violet700, dark: .violet300))
    }
    .frame(maxWidth: .infinity, alignment: .center)
    .opacity(self.show ? 1 : 0)
    .task {
      try? await Task.sleep(for: self.delay)
      withAnimation(.smooth(duration: 0.7)) {
        self.show = true
      }
    }
  }
}

struct BaseScreenView<Content: View>: View {
  let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    VStack(spacing: 20) {
      self.content
    }
    .frame(maxWidth: 500)
    .padding(30)
    .screenGradientBackground()
  }
}

struct LoadingScreenView: View {
  @Environment(\.colorScheme) private var colorScheme

  let text: String

  var body: some View {
    BaseScreenView {
      ProgressView()
        .scaleEffect(1.5)
        .tint(Color(self.colorScheme, light: .violet500, dark: .violet400))

      Text(self.text)
        .font(.system(size: 18, weight: .medium))
        .foregroundStyle(Color(self.colorScheme, light: .violet900, dark: .violet100))
        .multilineTextAlignment(.center)
    }
  }
}

#Preview("Loading") {
  LoadingScreenView(text: "Checking setup…")
}
