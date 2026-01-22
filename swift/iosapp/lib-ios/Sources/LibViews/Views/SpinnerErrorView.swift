import SwiftUI

struct SpinnerErrorView: View {
  @Environment(\.colorScheme) var cs

  let loadingText: String
  let errorText: String
  let isError: Bool
  let onRetry: () -> Void

  @State private var showBg = false

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
          withAnimation(.smooth(duration: 0.7)) {
            self.showBg = true
          }
        }

      VStack(spacing: 24) {
        Spacer()

        if self.isError {
          Image(systemName: "exclamationmark.triangle")
            .font(.system(size: 50, weight: .light))
            .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))

          Text(self.errorText)
            .font(.system(size: 18, weight: .medium))
            .multilineTextAlignment(.center)

          BigButton("Try again", type: .button { self.onRetry() }, variant: .primary)
            .padding(.top, 12)
        } else {
          ProgressView()
            .scaleEffect(1.5)
            .tint(Color(self.cs, light: .violet500, dark: .violet400))

          Text(self.loadingText)
            .font(.system(size: 18, weight: .medium))
        }

        Spacer()
      }
      .frame(maxWidth: 500)
      .padding(30)
    }
  }
}

struct SpinnerView: View {
  @Environment(\.colorScheme) var cs

  let text: String

  @State private var showBg = false

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
          withAnimation(.smooth(duration: 0.7)) {
            self.showBg = true
          }
        }

      VStack(spacing: 24) {
        Spacer()

        ProgressView()
          .scaleEffect(1.5)
          .tint(Color(self.cs, light: .violet500, dark: .violet400))

        Text(self.text)
          .font(.system(size: 18, weight: .medium))

        Spacer()
      }
      .frame(maxWidth: 500)
      .padding(30)
    }
  }
}

#Preview("SpinnerView") {
  SpinnerView(text: "Loading...")
}

#Preview("SpinnerErrorView - Loading") {
  SpinnerErrorView(
    loadingText: "Doing something...",
    errorText: "Something went wrong.",
    isError: false,
    onRetry: {},
  )
}

#Preview("SpinnerErrorView - Error") {
  SpinnerErrorView(
    loadingText: "Doing something...",
    errorText: "Something went wrong.",
    isError: true,
    onRetry: {},
  )
}
