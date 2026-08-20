import GertieUI
import SwiftUI

public struct PinResetCodeView: View {
  @Environment(\.colorScheme) var cs
  @FocusState private var isFocused: Bool
  @State private var input: String = ""
  @State private var showBg = false
  @State private var currentTime = Date()
  @State private var lockoutTimer: Timer?

  let lockout: Date?
  let showError: Bool
  let onSubmit: @MainActor @Sendable (Int) -> Void
  let onCancel: @MainActor @Sendable () -> Void

  public init(
    lockout: Date? = nil,
    showError: Bool = false,
    onSubmit: @MainActor @Sendable @escaping (Int) -> Void = { _ in },
    onCancel: @MainActor @Sendable @escaping () -> Void = {},
  ) {
    self.lockout = lockout
    self.showError = showError
    self.onSubmit = onSubmit
    self.onCancel = onCancel
  }

  private var code: Int? {
    guard let code = Int(self.input) else { return nil }
    return code >= 100_000 && code <= 999_999 ? code : nil
  }

  private var isLockedOut: Bool {
    guard let lockout = self.lockout else { return false }
    return self.currentTime < lockout
  }

  public var body: some View {
    ZStack {
      Color(self.cs, light: .violet100, dark: .violet950.opacity(0.4))
        .ignoresSafeArea()
        .opacity(self.showBg ? 1 : 0)
        .onAppear {
          withAnimation(.smooth(duration: 0.5)) { self.showBg = true }
        }

      if self.isLockedOut {
        self.lockoutView
      } else {
        self.entryView
      }
    }
    .onAppear { self.startLockoutTimer() }
    .onDisappear { self.stopLockoutTimer() }
  }

  private var entryView: some View {
    VStack(spacing: 20) {
      Spacer()

      VStack(spacing: 16) {
        Text(lstr(.pinResetTitle))
          .font(.system(size: 28, weight: .bold))
          .multilineTextAlignment(.center)
          .swooshIn(
            fromYOffset: 20,
            animation: .bouncy(duration: 0.6, extraBounce: 0.3),
          )

        Text(lstr(.pinResetSubtitle))
          .font(.system(size: 16, weight: .medium))
          .multilineTextAlignment(.center)
          .foregroundStyle(Color(self.cs, light: .black.opacity(0.8), dark: .white.opacity(0.8)))
          .swooshIn(
            fromYOffset: 20,
            after: .seconds(0.1),
            animation: .bouncy(duration: 0.6, extraBounce: 0.3),
          )
      }
      .padding(.horizontal, 30)

      VStack(spacing: 16) {
        TextField(lstr(.pinResetCodePlaceholder), text: self.$input)
        #if os(iOS)
          .keyboardType(.numberPad)
        #endif
          .focused(self.$isFocused)
          .font(.system(size: 18, weight: .medium))
          .multilineTextAlignment(.center)
          .padding(16)
          .background(Color(self.cs, light: .white, dark: .white.opacity(0.1)))
          .cornerRadius(12)
          .overlay {
            RoundedRectangle(cornerRadius: 12)
              .stroke(
                Color(self.cs, light: .violet300, dark: .violet700.opacity(0.5)),
                lineWidth: 2,
              )
          }
          .swooshIn(
            fromYOffset: 20,
            after: .seconds(0.2),
            animation: .bouncy(duration: 0.6, extraBounce: 0.3),
          )

        if self.showError {
          Text(lstr(.pinResetCodeError))
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(.red)
            .multilineTextAlignment(.center)
        }

        Button(lstr(.pinResetContinue)) {
          self.onSubmit(self.code ?? 0)
          self.input = ""
        }
        .buttonStyle(.gertiePrimary)
        .disabled(self.code == nil)
        .swooshIn(
          fromYOffset: 20,
          after: .seconds(0.3),
          animation: .bouncy(duration: 0.6, extraBounce: 0.3),
        )

        Button(lstr(.pinCancel), action: self.onCancel)
          .buttonStyle(.gertieSecondary)
      }
      .padding(.horizontal, 30)

      Spacer()
    }
    .frame(maxWidth: 500)
    .onAppear { self.isFocused = true }
  }

  private var lockoutView: some View {
    VStack(spacing: 24) {
      Spacer()
      Text(self.lockoutMessage)
        .font(.system(size: 18, weight: .medium))
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 60)
      Spacer()
      Button(lstr(.pinCancel), action: self.onCancel)
        .buttonStyle(.gertieSecondary)
        .padding(.horizontal, 30)
        .padding(.bottom, 30)
    }
    .frame(maxWidth: 500)
  }

  private var lockoutMessage: String {
    guard let lockout = self.lockout else { return "" }
    let minutes = Int(floor(lockout.timeIntervalSince(self.currentTime) / 60))
    if minutes <= 1 {
      return lstr(.pinLockoutWaitMoment)
    } else {
      return String(format: lstr(.pinLockoutWaitMinutes), minutes)
    }
  }

  private func startLockoutTimer() {
    guard let lockout = self.lockout, lockout > Date() else { return }
    self.lockoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
      Task { @MainActor in
        self.currentTime = Date()
        if self.currentTime >= lockout { self.stopLockoutTimer() }
      }
    }
  }

  private func stopLockoutTimer() {
    self.lockoutTimer?.invalidate()
    self.lockoutTimer = nil
  }
}

#Preview("Reset code — idle") {
  PinResetCodeView()
}

#Preview("Reset code — idle (dark)") {
  PinResetCodeView()
    .preferredColorScheme(.dark)
}

#Preview("Reset code — error") {
  PinResetCodeView(showError: true)
}

#Preview("Reset code — lockout") {
  PinResetCodeView(lockout: .now + .minutes(5))
}
