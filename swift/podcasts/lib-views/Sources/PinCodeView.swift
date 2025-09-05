import SwiftUI

public struct PinCodeView: View {
  @Environment(\.colorScheme) var cs

  let mode: Mode
  let onComplete: @Sendable (Int) -> Void
  let onCancel: (() -> Void)?

  public init(
    mode: Mode,
    onComplete: @escaping @Sendable (Int) -> Void,
    onCancel: (() -> Void)? = nil
  ) {
    self.mode = mode
    self.onComplete = onComplete
    self.onCancel = onCancel
  }

  @State private var pin = ""
  @State private var confirmPin = ""
  @State private var showingConfirmation = false
  @State private var errorMessage: String?
  @State private var isShaking = false

  public var body: some View {
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
                .stroke(.tertiary, lineWidth: 1)
            )
        }
      }
      .offset(x: self.isShaking ? 10 : 0)
      .animation(
        .easeInOut(duration: 0.1).repeatCount(4, autoreverses: true),
        value: self.isShaking
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
            Text(self.onCancel != nil ? "Cancel" : "Clear")
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

  private var titleText: String {
    switch self.mode {
    case .set:
      self.showingConfirmation ? "Confirm PIN" : "Set PIN"
    case .verify:
      "Enter PIN"
    }
  }

  private var subtitleText: String? {
    switch self.mode {
    case .set:
      self.showingConfirmation ? "Enter your PIN again to confirm" : "Choose a 6-digit PIN"
    case .verify:
      "Enter your PIN to continue"
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
    } else {
      if self.pin.count < 6 {
        self.pin += digit
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
    case .set:
      if self.showingConfirmation {
        if completedPin == self.pin {
          self.onComplete(Int(completedPin)!)
        } else {
          self.showPinMismatchError()
        }
      } else {
        self.showingConfirmation = true
        self.confirmPin = ""
      }
    case .verify:
      self.onComplete(Int(completedPin)!)
    }
  }

  private func showPinMismatchError() {
    self.errorMessage = "PINs don't match. Try again."
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

  public enum Mode {
    case set
    case verify
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
  PinCodeView(mode: .set, onComplete: { pin in
    print("PIN set: \(pin)")
  }, onCancel: nil)
}

#Preview("Verify PIN") {
  PinCodeView(mode: .verify, onComplete: { pin in
    print("PIN entered: \(pin)")
  }, onCancel: {
    print("Cancelled")
  })
}

#Preview("Set PIN - Dark") {
  PinCodeView(mode: .set, onComplete: { pin in
    print("PIN set: \(pin)")
  }, onCancel: nil)
    .preferredColorScheme(.dark)
}

#Preview("Verify PIN - Dark") {
  PinCodeView(mode: .verify, onComplete: { pin in
    print("PIN entered: \(pin)")
  }, onCancel: {
    print("Cancelled")
  })
  .preferredColorScheme(.dark)
}
