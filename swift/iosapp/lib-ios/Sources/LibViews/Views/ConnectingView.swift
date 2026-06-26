import ComposableArchitecture
import Dependencies
import LibApp
import SwiftUI

struct ConnectingView: View {
  @Bindable var store: StoreOf<ConnectAccount>
  @Environment(\.colorScheme) var cs
  let infoBlurb: String?
  let deviceType: String

  var showsBackButton: Bool {
    if case .connected = self.store.state.screen { false } else { true }
  }

  var body: some View {
    ZStack {
      switch self.store.state.screen {
      case .generatingCode:
        GeneratingCodeView()
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

struct GeneratingCodeView: View {
  @Environment(\.colorScheme) var cs
  @State private var showBg = false

  var body: some View {
    ZStack {
      Color(self.cs, light: .violet100, dark: .violet950.opacity(0.4))
        .ignoresSafeArea()
        .opacity(self.showBg ? 1 : 0)
        .onAppear {
          withAnimation(.smooth(duration: 0.5)) {
            self.showBg = true
          }
        }

      VStack(spacing: 24) {
        ProgressView()
          .scaleEffect(1.5)
          .tint(Color(self.cs, light: .violet500, dark: .violet400))

        Text("Generating code...")
          .font(.system(size: 20, weight: .semibold))
          .foregroundStyle(Color(self.cs, light: .black.opacity(0.8), dark: .white.opacity(0.8)))
      }
    }
  }
}

struct ShowCodeView: View {
  @Environment(\.colorScheme) var cs
  @State private var showBg = false
  @State private var iconOffset = Vector(x: 0, y: -20)
  @State private var blurbOffset = Vector(x: 0, y: 20)
  @State private var urlOffset = Vector(x: 0, y: 20)
  @State private var showWaiting = false
  @State private var sendBtnOffset = Vector(x: 0, y: 20)
  @State private var helpBtnOffset = Vector(x: 0, y: 20)

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

      VStack(alignment: .leading, spacing: 16) {
        Image(systemName: "link.circle")
          .font(.system(size: 40, weight: .regular))
          .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
          .swooshIn(tracking: self.$iconOffset, to: .zero, after: .zero, for: .milliseconds(800))
          .frame(maxWidth: .infinity, alignment: .center)

        Spacer()

        Text(
          self.infoBlurb ??
            "Open this link on YOUR phone or computer (not this \(self.deviceType)) to connect to a Gertrude account:",
        )
        .font(.system(size: 18, weight: .medium))
        .swooshIn(tracking: self.$blurbOffset, to: .zero, after: .zero, for: .milliseconds(800))

        Text(self.connectUrl)
          .font(.system(size: 20, weight: .semibold, design: .monospaced))
          .minimumScaleFactor(0.7)
          .lineLimit(1)
          .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet300))
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(.vertical, 8)
          .swooshIn(
            tracking: self.$urlOffset,
            to: .zero,
            after: .milliseconds(100),
            for: .milliseconds(800),
          )

        HStack(spacing: 12) {
          ProgressView()
            .tint(Color(self.cs, light: .violet500, dark: .violet400))
          Text("Watching for connection…")
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(Color(self.cs, light: .violet700, dark: .violet300))
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .opacity(self.showWaiting ? 1 : 0)
        .task {
          try? await Task.sleep(for: .seconds(45))
          withAnimation(.smooth(duration: 0.5)) { self.showWaiting = true }
        }

        Spacer()
          .frame(height: 40)

        BigButton(
          "Send link",
          type: .share(self.connectUrl),
          variant: .primary,
          icon: "square.and.arrow.up",
        )
        .swooshIn(
          tracking: self.$sendBtnOffset,
          to: .zero,
          after: .milliseconds(300),
          for: .milliseconds(800),
        )

        BigButton(
          "Help me connect...",
          type: .link(URL(string: "https://gertrude.app/iosapp-connect-help")!),
          variant: .secondary,
        )
        .swooshIn(
          tracking: self.$helpBtnOffset,
          to: .zero,
          after: .milliseconds(400),
          for: .milliseconds(800),
        )
      }
      .frame(maxWidth: 500)
      .padding(30)
      .padding(.top, 50)
    }
  }
}

struct ConnectedStateView: View {
  @Environment(\.colorScheme) var cs
  @State private var showBg = false
  @State private var iconOffset = Vector(x: 0, y: 20)
  @State private var textOffset = Vector(x: 0, y: 20)

  let childName: String

  var body: some View {
    ZStack {
      Color(self.cs, light: .violet100, dark: .violet950.opacity(0.4))
        .ignoresSafeArea()
        .opacity(self.showBg ? 1 : 0)
        .onAppear {
          withAnimation(.smooth(duration: 0.5)) {
            self.showBg = true
          }
        }

      VStack(spacing: 24) {
        Image(systemName: "checkmark.circle.fill")
          .font(.system(size: 60))
          .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
          .swooshIn(
            tracking: self.$iconOffset,
            to: .zero,
            after: .zero,
            for: .seconds(0.6),
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
          tracking: self.$textOffset,
          to: .zero,
          after: .seconds(0.1),
          for: .seconds(0.6),
        )
      }
      .padding(.horizontal, 30)
    }
  }
}

struct CodeGenerationFailedView: View {
  @Environment(\.colorScheme) var cs
  @State private var showBg = false
  @State private var iconOffset = Vector(x: 0, y: 20)
  @State private var textOffset = Vector(x: 0, y: 20)
  @State private var buttonOffset = Vector(x: 0, y: 20)

  let retry: () -> Void

  var body: some View {
    ZStack {
      Color(self.cs, light: .violet100, dark: .violet950.opacity(0.4))
        .ignoresSafeArea()
        .opacity(self.showBg ? 1 : 0)
        .onAppear {
          withAnimation(.smooth(duration: 0.5)) {
            self.showBg = true
          }
        }

      VStack(spacing: 24) {
        Image(systemName: "xmark.circle.fill")
          .font(.system(size: 60))
          .foregroundStyle(Color(self.cs, light: .red, dark: .red.opacity(0.8)))
          .swooshIn(
            tracking: self.$iconOffset,
            to: .zero,
            after: .zero,
            for: .seconds(0.6),
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
          tracking: self.$textOffset,
          to: .zero,
          after: .seconds(0.1),
          for: .seconds(0.6),
        )

        BigButton("Try again", type: .button { self.retry() })
          .padding(.horizontal, 30)
          .swooshIn(
            tracking: self.$buttonOffset,
            to: .zero,
            after: .seconds(0.2),
            for: .seconds(0.6),
          )
      }
      .padding(.horizontal, 30)
    }
  }
}

#Preview("Generating code") {
  ConnectingView(
    store: .init(initialState: .init(screen: .generatingCode)) {
      ConnectAccount()
    },
    infoBlurb: nil,
    deviceType: "iPhone",
  )
}

#Preview("Showing code") {
  ConnectingView(
    store: .init(initialState: .init(screen: .showingCode(code: 123_456))) {
      ConnectAccount()
    },
    infoBlurb: nil,
    deviceType: "iPhone",
  )
}

#Preview("Showing code (dark)") {
  ConnectingView(
    store: .init(initialState: .init(screen: .showingCode(code: 123_456))) {
      ConnectAccount()
    },
    infoBlurb: nil,
    deviceType: "iPhone",
  )
  .preferredColorScheme(.dark)
}

#Preview("Connected") {
  ConnectingView(
    store: .init(initialState: .init(screen: .connected(childName: "Emma"))) {
      ConnectAccount()
    },
    infoBlurb: nil,
    deviceType: "iPhone",
  )
}

#Preview("Code generation failed") {
  ConnectingView(
    store: .init(initialState: .init(screen: .codeGenerationFailed)) {
      ConnectAccount()
    },
    infoBlurb: nil,
    deviceType: "iPhone",
  )
}
