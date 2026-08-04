import ComposableArchitecture
import GertieUI
import LibApp
import SwiftUI

struct ConnectingView: View {
  @Bindable var store: StoreOf<ConnectAccount>
  @Environment(\.colorScheme) private var cs
  let infoBlurb: String?
  let deviceType: String

  var showsBackButton: Bool {
    if case .connected = self.store.state.screen { false } else { true }
  }

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
      case .connected(childName: let childName):
        ConnectedStateView(childName: childName)
          .transition(.opacity)
      }
    }
    .animation(.smooth(duration: 0.4), value: self.store.state.screen)
    .overlay(alignment: .topLeading) {
      if self.showsBackButton {
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
    VStack(alignment: .leading, spacing: 16) {
      Image(systemName: "link.circle")
        .font(.system(size: 40, weight: .regular))
        .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
        .accessibilityHidden(true)
        .frame(maxWidth: .infinity, alignment: .center)
        .swooshIn(fromYOffset: -20)

      Spacer()

      Text(
        self.infoBlurb ??
          "Open this link on YOUR phone or computer (not this \(self.deviceType)) to connect to a Gertrude account:",
      )
      .font(.system(size: 18, weight: .medium))
      .swooshIn(fromYOffset: 20)

      Text(self.connectUrl)
        .font(.system(size: 20, weight: .semibold, design: .monospaced))
        .minimumScaleFactor(0.7)
        .lineLimit(1)
        .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet300))
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 8)
        .swooshIn(fromYOffset: 20, after: .milliseconds(100))

      GertieWaitingStatus(
        label: "Watching for connection…",
        delay: .zero,
      )
      .opacity(self.showWaiting ? 1 : 0)
      .accessibilityHidden(!self.showWaiting)
      .task {
        do {
          try await Task.sleep(for: .seconds(45))
        } catch {
          return
        }
        guard !Task.isCancelled else { return }
        withAnimation(.smooth(duration: 0.5)) {
          self.showWaiting = true
        }
      }

      Spacer()
        .frame(height: 40)

      ShareLink(item: self.connectUrl) {
        HStack(spacing: 8) {
          Text("Send link")
          Image(systemName: "square.and.arrow.up")
        }
      }
      .buttonStyle(.gertiePrimary)
      .swooshIn(fromYOffset: 20, after: .milliseconds(300))

      Link(destination: URL(string: "https://gertrude.app/iosapp-connect-help")!) {
        Text("Help me connect...")
      }
      .buttonStyle(.gertieSecondary)
      .swooshIn(fromYOffset: 20, after: .milliseconds(400))
    }
    .frame(maxWidth: 500)
    .padding(30)
    .padding(.top, 50)
    .gertieScreenBackground()
  }
}

struct ConnectedStateView: View {
  @Environment(\.colorScheme) private var cs

  let childName: String

  var body: some View {
    VStack(spacing: 24) {
      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 60, weight: .regular))
        .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
        .accessibilityHidden(true)
        .swooshIn(
          fromYOffset: 20,
          animation: .bouncy(duration: 0.6, extraBounce: 0.3),
        )

      VStack(spacing: 8) {
        Text("Successfully connected!")
          .font(.system(size: 24, weight: .bold))
          .multilineTextAlignment(.center)

        Text("This device is now connected to ***\(self.childName)***")
          .font(.system(size: 16, weight: .regular))
          .foregroundStyle(Color(self.cs, light: .black.opacity(0.8), dark: .white.opacity(0.8)))
          .multilineTextAlignment(.center)
      }
      .swooshIn(
        fromYOffset: 20,
        after: .milliseconds(100),
        animation: .bouncy(duration: 0.6, extraBounce: 0.3),
      )
      .accessibilityIdentifier("connect-account-success")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.horizontal, 30)
    .gertieScreenBackground()
  }
}

struct CodeGenerationFailedView: View {
  @Environment(\.colorScheme) private var cs

  let retry: () -> Void

  var body: some View {
    VStack(spacing: 24) {
      Image(systemName: "xmark.circle.fill")
        .font(.system(size: 60, weight: .regular))
        .foregroundStyle(Color(self.cs, light: .red, dark: .red.opacity(0.8)))
        .accessibilityHidden(true)
        .swooshIn(
          fromYOffset: 20,
          animation: .bouncy(duration: 0.6, extraBounce: 0.3),
        )

      VStack(spacing: 8) {
        Text("Couldn't generate a code")
          .font(.system(size: 24, weight: .bold))
          .multilineTextAlignment(.center)

        Text("Please check your internet connection and try again.")
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(Color(self.cs, light: .black.opacity(0.8), dark: .white.opacity(0.8)))
          .multilineTextAlignment(.center)
      }
      .swooshIn(
        fromYOffset: 20,
        after: .milliseconds(100),
        animation: .bouncy(duration: 0.6, extraBounce: 0.3),
      )

      Button("Try again") {
        self.retry()
      }
      .buttonStyle(.gertiePrimary)
      .padding(.horizontal, 30)
      .swooshIn(
        fromYOffset: 20,
        after: .milliseconds(200),
        animation: .bouncy(duration: 0.6, extraBounce: 0.3),
      )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.horizontal, 30)
    .gertieScreenBackground()
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

#Preview("Connected") {
  ConnectingView(
    store: .init(initialState: .init(screen: .connected(childName: "Emma"))) {
      EmptyReducer()
    },
    infoBlurb: nil,
    deviceType: "iPhone",
  )
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
