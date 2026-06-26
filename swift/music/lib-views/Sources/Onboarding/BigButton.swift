import SwiftUI

struct BigButton: View {
  @Environment(\.colorScheme) private var colorScheme

  var text: String
  var type: ButtonType
  var variant: Variant
  var icon: String?
  var disabled: Bool

  var body: some View {
    switch self.type {
    case .button(let onTap):
      Button {
        if !self.disabled {
          onTap()
        }
      } label: {
        self.label
      }
      .buttonStyle(.plain)
      .disabled(self.disabled)
    case .link(let url):
      Link(destination: url) {
        self.label
      }
      .buttonStyle(.plain)
    case .share(let text):
      ShareLink(item: text) {
        self.label
      }
      .buttonStyle(.plain)
    }
  }

  var label: some View {
    HStack(spacing: 8) {
      Text(self.text)
        .font(.system(size: 18, weight: .semibold))
      if let icon = self.icon {
        Image(systemName: icon)
          .font(.system(size: 16, weight: .semibold))
      }
    }
    .foregroundStyle(self.foregroundColor)
    .padding(.horizontal, 20)
    .padding(.vertical, 14)
    .frame(maxWidth: .infinity)
    .background(self.backgroundColor)
    .clipShape(.rect(cornerRadius: 16, style: .continuous))
    .opacity(self.disabled ? 0.5 : 1)
  }

  init(
    _ text: String,
    type: ButtonType,
    variant: Variant = .primary,
    icon: String? = nil,
    disabled: Bool = false,
  ) {
    self.text = text
    self.type = type
    self.variant = variant
    self.icon = icon
    self.disabled = disabled
  }

  private var backgroundColor: Color {
    switch self.variant {
    case .primary:
      Color(self.colorScheme, light: .violet500, dark: .violet600.opacity(0.9))
    case .secondary:
      Color(self.colorScheme, light: .violet500.opacity(0.1), dark: .violet500.opacity(0.15))
    }
  }

  private var foregroundColor: Color {
    switch self.variant {
    case .primary:
      .white
    case .secondary:
      Color(self.colorScheme, light: .violet500, dark: .violet400)
    }
  }

  enum Variant {
    case primary
    case secondary
  }
}

enum ButtonType: Sendable {
  case button(@MainActor @Sendable () -> Void)
  case link(URL)
  case share(String)
}

#Preview("Buttons") {
  VStack(spacing: 20) {
    BigButton("Continue", type: .button {}, variant: .primary)
    BigButton(
      "Send link",
      type: .share("https://gertrude.app"),
      variant: .secondary,
      icon: "square.and.arrow.up",
    )
    BigButton("Disabled", type: .button {}, disabled: true)
  }
  .padding(20)
}
