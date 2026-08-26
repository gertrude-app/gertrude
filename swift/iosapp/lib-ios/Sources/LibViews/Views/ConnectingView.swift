import ComposableArchitecture
import GertieUI
import LibApp
import SwiftUI

struct ConnectingView: View {
  @Bindable var store: StoreOf<ConnectAccount>
  @Environment(\.colorScheme) private var cs
  let infoBlurb: String?
  let deviceType: String

  var body: some View {
    ZStack {
      switch self.store.state.screen {
      case .generatingCode:
        GertieLoadingScreen(message: "Generating code...")
          .transition(.opacity)
      case .showingCode(code: let code):
        ShowCodeView(code: code, infoBlurb: self.infoBlurb, deviceType: self.deviceType)
          .transition(.opacity)
      case .codeGenerationFailed:
        CodeGenerationFailedView { self.store.send(.retryTapped) }
          .transition(.opacity)
      }
    }
    .animation(.smooth(duration: 0.4), value: self.store.state.screen)
    .overlay(alignment: .topLeading) {
      Button {
        self.store.send(.cancelTapped)
      } label: {
        Image(systemName: "chevron.left")
          .font(.system(size: 18, weight: .semibold))
          .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet300))
          .padding(12)
      }
      .padding(.leading, 8)
      .padding(.top, 8)
    }
    .onAppear { self.store.send(.onAppear) }
  }
}

struct ShowCodeView: View {
  @Environment(\.colorScheme) private var cs
  @State private var showWaiting = false

  let code: Int
  let infoBlurb: String?
  let deviceType: String

  var codeString: String {
    String(format: "%06d", self.code)
  }

  var connectUrl: String {
    "https://gertrude.app/b/\(self.codeString)"
  }

  var body: some View {
    GertieActionScreen(
      message: self.infoBlurb ??
        "Open this link on YOUR phone or computer (not this \(self.deviceType)) to connect to a Gertrude account:",
      icon: .system("link.circle"),
      actions: [
        .share("Send link", item: self.connectUrl),
        .link(
          "Help me connect...",
          destination: URL(string: "https://gertrude.app/help/iphone-ipad/get-connection-code")!,
        ),
      ],
      supplementPlacement: .afterMessage,
    ) {
      VStack(spacing: 16) {
        Text(self.connectUrl)
          .font(.system(size: 20, weight: .semibold, design: .monospaced))
          .minimumScaleFactor(0.7)
          .lineLimit(1)
          .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet300))
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(.vertical, 8)

        GertieWaitingStatus(
          label: "Watching for connection…",
          delay: .zero,
        )
        .opacity(self.showWaiting ? 1 : 0)
        .accessibilityHidden(!self.showWaiting)
        .delayedTask(for: .seconds(45)) {
          withAnimation(.smooth(duration: 0.5)) {
            self.showWaiting = true
          }
        }
      }
    }
  }
}

struct CodeGenerationFailedView: View {
  let retry: () -> Void

  var body: some View {
    GertieResultScreen(
      icon: "xmark.circle.fill",
      tone: .error,
      title: "Couldn't generate a code",
      message: "Please check your internet connection and try again.",
      action: .button("Try again") {
        self.retry()
      },
    )
  }
}

#Preview("Generating code") {
  ConnectingView(
    store: .init(initialState: .init(screen: .generatingCode)) {
      EmptyReducer()
    },
    infoBlurb: nil,
    deviceType: "iPhone",
  )
}

#Preview("Showing code") {
  ConnectingView(
    store: .init(initialState: .init(screen: .showingCode(code: 123_456))) {
      EmptyReducer()
    },
    infoBlurb: nil,
    deviceType: "iPhone",
  )
}

#Preview("Showing code (dark)") {
  ConnectingView(
    store: .init(initialState: .init(screen: .showingCode(code: 123_456))) {
      EmptyReducer()
    },
    infoBlurb: nil,
    deviceType: "iPhone",
  )
  .preferredColorScheme(.dark)
}

#Preview("Code generation failed") {
  ConnectingView(
    store: .init(initialState: .init(screen: .codeGenerationFailed)) {
      EmptyReducer()
    },
    infoBlurb: nil,
    deviceType: "iPhone",
  )
}
