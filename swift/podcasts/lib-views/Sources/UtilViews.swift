import SwiftUI

struct BaseScreenView<Content: View>: View {
  @Environment(\.colorScheme) var cs

  let content: Content

  @State private var showBg = false

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
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

      VStack(spacing: 20) {
        self.content
      }
      .frame(maxWidth: 500)
      .padding(30)
    }
  }
}

public struct LoadingScreenView: View {
  @Environment(\.colorScheme) var cs

  let text: String

  public init(text: String) {
    self.text = text
  }

  public var body: some View {
    BaseScreenView {
      ProgressView()
        .scaleEffect(1.5)
        .tint(Color(self.cs, light: .violet500, dark: .violet400))

      Text(self.text)
        .font(.system(size: 18, weight: .medium))
        .foregroundStyle(Color(self.cs, light: .violet900, dark: .violet100))
        .multilineTextAlignment(.center)
    }
  }
}

public struct ErrorView: View {
  @Environment(\.colorScheme) var cs

  let text: String

  public init(text: String) {
    self.text = text
  }

  public var body: some View {
    BaseScreenView {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 40, weight: .regular))
        .foregroundStyle(Color(self.cs, light: .fuchsia700, dark: .violet100))

      Text(self.text)
        .font(.system(size: 18, weight: .medium))
        .foregroundStyle(Color(self.cs, light: .violet900, dark: .violet100))
        .multilineTextAlignment(.center)
    }
  }
}

#Preview("Loading") {
  LoadingScreenView(text: "Loading podcast feed...")
}

#Preview("Loading - Long text") {
  LoadingScreenView(
    text: "Please wait while we fetch and validate your podcast feed. This may take a moment.",
  )
}

#Preview("Error") {
  ErrorView(text: "Adding show failed. Please try again.")
}

#Preview("Error - Long text") {
  ErrorView(
    text: "Unable to connect to the podcast server. Please check your internet connection and try again.",
  )
}
