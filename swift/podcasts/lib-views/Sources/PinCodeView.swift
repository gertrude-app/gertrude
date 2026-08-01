import GertieUI
import SwiftUI

public struct PinCodeView: View {
  @Environment(\.colorScheme) var cs

  let mode: Mode
  let onCancel: (@MainActor @Sendable () -> Void)?
  let onPrepHaptics: () -> Void

  public init(
    mode: Mode,
    onCancel: (@MainActor @Sendable () -> Void)? = nil,
    onPrepHaptics: (() -> Void)? = nil,
  ) {
    self.mode = mode
    self.onCancel = onCancel
    self.onPrepHaptics = onPrepHaptics ?? {}
  }

  @State private var pin = ""
  @State private var confirmPin = ""
  @State private var showingConfirmation = false
  @State private var errorMessage: String?
  @State private var isShaking = false
  @State private var currentTime = Date()
  @State private var lockoutTimer: Timer?

  public var body: some View {
    Group {
      if self.isLockedOut {
        self.lockoutView
      } else {
        VStack(spacing: 30) {
          VStack(spacing: 8) {
            Text(self.titleText)
              .font(.system(size: 28, weight: .bold))
              .multilineTextAlignment(.center)

            if let errorMessage = self.errorMessage {
              Text(errorMessage)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
            } else if let subtitle = self.subtitleText {
              Text(subtitle)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }
          }

          HStack(spacing: 16) {
            ForEach(0 ..< 6, id: \.self) { index in
              Circle()
                .fill(self.dotColor(for: index))
                .frame(width: 16, height: 16)
                .overlay(
                  Circle()
                    .stroke(.tertiary, lineWidth: 1),
                )
            }
          }
          .offset(x: self.isShaking ? 10 : 0)
          .animation(
            .easeInOut(duration: 0.1).repeatCount(4, autoreverses: true),
            value: self.isShaking,
          )

          VStack(spacing: 16) {
            ForEach(0 ..< 3, id: \.self) { row in
              HStack(spacing: 16) {
                ForEach(1 ... 3, id: \.self) { col in
                  let number = row * 3 + col
                  NumberButton(String(number)) {
                    self.addDigit(String(number))
                  }
                }
              }
            }

            HStack(spacing: 16) {
              Button {
                if let onCancel = self.onCancel {
                  onCancel()
                } else {
                  self.clearPin()
                }
              } label: {
                Text(self.onCancel != nil ? lstr(.pinCancel) : lstr(.pinClear))
                  .font(.system(size: 18, weight: .medium))
                  .foregroundStyle(.secondary)
                  .frame(width: 80, height: 80)
                  .background(Color(self.cs, light: .violet100, dark: .violet900))
                  .clipShape(Circle())
              }

              NumberButton("0") {
                self.addDigit("0")
              }

              Button {
                self.removeDigit()
              } label: {
                Image(systemName: "delete.backward")
                  .font(.system(size: 24, weight: .medium))
                  .foregroundStyle(.secondary)
                  .frame(width: 80, height: 80)
                  .background(Color(self.cs, light: .violet100, dark: .violet900))
                  .clipShape(Circle())
              }
            }
          }
        }
        .padding(30)
        .onChange(of: self.pin) { _, newPin in
          if newPin.count == 6 {
            self.handlePinComplete(newPin)
          }
        }
        .onChange(of: self.confirmPin) { _, newConfirmPin in
          if newConfirmPin.count == 6 {
            self.handlePinComplete(newConfirmPin)
          }
        }
      }
    }
    .onAppear {
      self.startLockoutTimer()
    }
    .onDisappear {
      self.stopLockoutTimer()
    }
  }

  private var isLockedOut: Bool {
    switch self.mode {
    case .set:
      return false
    case .verify(_, let lockout, _, _):
      guard let lockout else { return false }
      return self.currentTime < lockout
    }
  }

  private var lockoutView: some View {
    VStack(spacing: 24) {
      Spacer()

      if let lockoutMessage = self.lockoutMessage {
        Text(lockoutMessage)
          .font(.system(size: 18, weight: .medium))
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 60)
      }

      Spacer()

      if let onCancel = self.onCancel {
        Button(lstr(.pinCancel), action: onCancel)
          .buttonStyle(.gertieSecondary)
          .padding(.horizontal, 30)
          .padding(.bottom, 30)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(self.cs, light: .white, dark: .black))
  }

  private var lockoutMessage: String? {
    switch self.mode {
    case .set:
      return nil
    case .verify(_, let lockout, _, _):
      guard let lockout else { return "" }
      let timeRemaining = lockout.timeIntervalSince(self.currentTime)
      let minutes = Int(floor(timeRemaining / 60))
      if minutes <= 1 {
        return lstr(.pinLockoutWaitMoment)
      } else {
        let format = lstr(.pinLockoutWaitMinutes)
        return String(format: format, minutes)
      }
    }
  }

  private var titleText: String {
    switch self.mode {
    case .set:
      self.showingConfirmation ? lstr(.pinConfirmPin) : lstr(.pinSetPin)
    case .verify:
      lstr(.pinEnterPin)
    }
  }

  private var subtitleText: String? {
    switch self.mode {
    case .set:
      self.showingConfirmation ? lstr(.pinEnterAgainToConfirm) : lstr(.pinChoose6Digit)
    case .verify:
      lstr(.pinEnterToContinue)
    }
  }

  private func dotColor(for index: Int) -> Color {
    let currentPin = self.showingConfirmation ? self.confirmPin : self.pin
    if index < currentPin.count {
      return Color(self.cs, light: .violet500, dark: .violet400)
    } else {
      return Color.clear
    }
  }

  private func addDigit(_ digit: String) {
    if self.showingConfirmation {
      if self.confirmPin.count < 6 {
        self.confirmPin += digit
      }
      if self.confirmPin.count == 4 {
        self.onPrepHaptics()
      }
    } else {
      if self.pin.count < 6 {
        self.pin += digit
      }
      if self.pin.count == 4 {
        self.onPrepHaptics()
      }
    }

    self.errorMessage = nil
  }

  private func removeDigit() {
    if self.showingConfirmation {
      if !self.confirmPin.isEmpty {
        self.confirmPin.removeLast()
      }
    } else {
      if !self.pin.isEmpty {
        self.pin.removeLast()
      }
    }

    self.errorMessage = nil
  }

  private func clearPin() {
    if self.showingConfirmation {
      self.confirmPin = ""
    } else {
      self.pin = ""
    }
    self.errorMessage = nil
  }

  private func handlePinComplete(_ completedPin: String) {
    switch self.mode {
    case .set(let onComplete, let onConfirmFail):
      if self.showingConfirmation {
        if completedPin == self.pin {
          onComplete(Int(completedPin)!)
        } else {
          onConfirmFail()
          self.showPinMismatchError()
        }
      } else {
        self.showingConfirmation = true
        self.confirmPin = ""
      }
    case .verify(let expectedPin, _, let onVerify, let onFail):
      let enteredPin = Int(completedPin)!
      if enteredPin == expectedPin {
        onVerify()
      } else {
        onFail()
        self.showIncorrectPinError()
      }
    }
  }

  private func showPinMismatchError() {
    self.errorMessage = lstr(.pinDontMatch)
    self.isShaking = true

    Task {
      try? await Task.sleep(for: .milliseconds(500))
      await MainActor.run {
        self.isShaking = false
        self.showingConfirmation = false
        self.pin = ""
        self.confirmPin = ""
      }
    }
  }

  private func showIncorrectPinError() {
    self.errorMessage = lstr(.pinIncorrect)
    self.isShaking = true

    Task {
      try? await Task.sleep(for: .milliseconds(500))
      await MainActor.run {
        self.isShaking = false
        self.pin = ""
        self.confirmPin = ""
      }
    }
  }

  private func startLockoutTimer() {
    guard case .verify(_, let lockout, _, _) = self.mode,
          let lockout,
          lockout > Date() else { return }

    self.lockoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
      Task { @MainActor in
        self.currentTime = Date()

        if self.currentTime >= lockout {
          self.stopLockoutTimer()
        }
      }
    }
  }

  private func stopLockoutTimer() {
    self.lockoutTimer?.invalidate()
    self.lockoutTimer = nil
  }

  public enum Mode {
    case set(
      onComplete: @MainActor @Sendable (Int) -> Void,
      onConfirmFail: () -> Void,
    )
    case verify(
      Int,
      lockout: Date? = nil,
      onVerify: @MainActor @Sendable () -> Void,
      onFail: @MainActor @Sendable () -> Void,
    )
  }
}

private struct NumberButton: View {
  @Environment(\.colorScheme) var cs

  let number: String
  let action: () -> Void

  init(_ number: String, action: @escaping () -> Void) {
    self.number = number
    self.action = action
  }

  var body: some View {
    Button(action: self.action) {
      Text(self.number)
        .font(.system(size: 32, weight: .medium))
        .foregroundStyle(Color(self.cs, light: .black, dark: .white))
        .frame(width: 80, height: 80)
        .background(Color(self.cs, light: .violet100, dark: .violet900))
        .clipShape(Circle())
    }
  }
}

#Preview("Set PIN") {
  PinCodeView(
    mode: .set(onComplete: { _ in }, onConfirmFail: {}),
    onCancel: nil,
  )
}

#Preview("Verify PIN") {
  PinCodeView(
    mode: .verify(123_456, onVerify: {}, onFail: {}),
    onCancel: {},
  )
}

#Preview("Set PIN - Dark") {
  PinCodeView(
    mode: .set(onComplete: { _ in }, onConfirmFail: {}),
    onCancel: nil,
  )
  .preferredColorScheme(.dark)
}

#Preview("Verify PIN - Dark") {
  PinCodeView(
    mode: .verify(123_456, onVerify: {}, onFail: {}),
    onCancel: {},
  )
  .preferredColorScheme(.dark)
}

#Preview("Lockout Screen") {
  PinCodeView(
    mode: .verify(123_456, lockout: .now + .minutes(5), onVerify: {}, onFail: {}),
    onCancel: {},
  )
}

#Preview("Lockout Screen - Dark") {
  PinCodeView(
    mode: .verify(123_456, lockout: .now + .minutes(5), onVerify: {}, onFail: {}),
    onCancel: {},
  )
  .preferredColorScheme(.dark)
}
