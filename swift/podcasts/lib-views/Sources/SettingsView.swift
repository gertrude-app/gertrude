import SwiftUI

public struct SettingsView: View {
  @Environment(\.colorScheme) var cs

  public enum Event: Equatable, Sendable {
    case subscribeNowTapped
    case manageSubscriptionTapped
  }

  public enum SubscriptionStatus: Equatable {
    case trialing(purchasePending: Bool = false)
    case active
    case complimentary
    case unpaid(purchasePending: Bool = false)

    var displayName: String {
      switch self {
      case .trialing: lstr(.settingsSubscriptionStatusFreeTrial)
      case .active: lstr(.settingsSubscriptionStatusActive)
      case .complimentary: lstr(.settingsSubscriptionStatusFreeForever)
      case .unpaid: lstr(.settingsSubscriptionStatusUnpaid)
      }
    }

    var hasPendingPurchase: Bool {
      switch self {
      case .trialing(let purchasePending), .unpaid(let purchasePending):
        purchasePending
      default:
        false
      }
    }

    var isTrialing: Bool {
      if case .trialing = self { true } else { false }
    }

    var isUnpaid: Bool {
      if case .unpaid = self { true } else { false }
    }

    var badgeBgColor: Color {
      switch self {
      case .trialing: Color(red: 0.2, green: 0.4, blue: 0.8)
      case .active: Color(red: 0.2, green: 0.6, blue: 0.3)
      case .complimentary: Color(red: 0.5, green: 0.3, blue: 0.7)
      case .unpaid: Color(red: 0.8, green: 0.2, blue: 0.2)
      }
    }

    var badgeTextColor: Color {
      .white
    }
  }

  let status: SubscriptionStatus
  let expiresAt: Date
  let purchaseInProgress: Bool
  let onEvent: @MainActor @Sendable (Event) -> Void

  public init(
    status: SubscriptionStatus,
    expiresAt: Date,
    purchaseInProgress: Bool = false,
    onEvent: @MainActor @Sendable @escaping (Event) -> Void = { _ in },
  ) {
    self.status = status
    self.expiresAt = expiresAt
    self.purchaseInProgress = purchaseInProgress
    self.onEvent = onEvent
  }

  public var body: some View {
    VStack(spacing: 20) {
      Text(lstr(.settingsTitle))
        .font(.largeTitle)
        .fontWeight(.bold)
        .frame(maxWidth: .infinity, alignment: .leading)

      VStack(spacing: 12) {
        HStack(spacing: 6) {
          Image(systemName: "creditcard")
            .font(.subheadline)
          Text(lstr(.settingsSubscriptionHeader))
            .font(.subheadline)
            .fontWeight(.medium)
        }
        .foregroundColor(Color(self.cs, light: .black.opacity(0.6), dark: .white.opacity(0.6)))
        .frame(maxWidth: .infinity, alignment: .leading)

        VStack(spacing: 12) {
          HStack(alignment: .top) {
            Text(lstr(
              self.status == .complimentary
                ? .settingsSubscriptionLabel
                : .settingsSubscriptionStatus,
            ))
            .font(.headline)
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
              HStack(spacing: 6) {
                if self.status.isTrialing {
                  Image(systemName: "clock")
                    .font(.subheadline)
                } else if self.status == .active {
                  Image(systemName: "checkmark")
                    .font(.subheadline)
                } else if self.status.isUnpaid {
                  Image(systemName: "exclamationmark.triangle")
                    .font(.subheadline)
                }
                Text(self.status.displayName)
                  .font(.subheadline)
                  .fontWeight(.semibold)
              }
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
              .background(self.status.badgeBgColor)
              .foregroundColor(self.status.badgeTextColor)
              .cornerRadius(8)

              if self.status.hasPendingPurchase {
                HStack(spacing: 4) {
                  ProgressView()
                    .scaleEffect(0.7)
                  Text(lstr(.settingsSubscriptionPurchasePending))
                    .font(.caption)
                    .italic()
                }
                .foregroundColor(Color(
                  self.cs,
                  light: .black.opacity(0.5),
                  dark: .white.opacity(0.5),
                ))
              }
            }
          }

          if self.status == .complimentary {
            Text(lstr(.settingsSubscriptionFriendMessage))
              .font(.subheadline)
              .foregroundColor(Color(self.cs, light: .gray, dark: .gray))
              .multilineTextAlignment(.center)
          } else {
            HStack {
              Text(self.expirationLabel)
                .font(.headline)
              Spacer()
              HStack(spacing: 6) {
                Text(self.expirationText)
                  .font(.subheadline)
                  .foregroundColor(Color(
                    self.cs,
                    light: .black.opacity(0.6),
                    dark: .white.opacity(0.6),
                  ))
                if self.status.isTrialing, self.expiresAt.timeIntervalSinceNow < .days(5) {
                  PulsingDot()
                }
              }
            }
          }
        }
        .padding(20)
        .background(Color(self.cs, light: .violet100, dark: .violet900))
        .cornerRadius(12)

        if self.status.isTrialing || self.status.isUnpaid || self.status == .active {
          VStack(spacing: 16) {
            VStack(spacing: 8) {
              Button {
                self.onEvent(
                  self.status == .active
                    ? .manageSubscriptionTapped
                    : .subscribeNowTapped,
                )
              } label: {
                Text(lstr(
                  self.status == .active
                    ? .settingsSubscriptionManageSubscription
                    : .settingsSubscriptionSubscribeNow,
                ))
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                  self.purchaseInProgress
                    ? Color(red: 0.4, green: 0.3, blue: 0.8).opacity(0.5)
                    : Color(red: 0.4, green: 0.3, blue: 0.8),
                )
                .cornerRadius(10)
              }
              .disabled(self.purchaseInProgress)

              if self.purchaseInProgress {
                HStack(spacing: 4) {
                  ProgressView()
                    .scaleEffect(0.7)
                  Text(lstr(.settingsSubscriptionOneMoment))
                    .font(.caption)
                    .italic()
                }
                .foregroundColor(Color(
                  self.cs,
                  light: .black.opacity(0.5),
                  dark: .white.opacity(0.5),
                ))
              } else if self.status != .active {
                Text(lstr(.settingsSubscriptionPrice))
                  .font(.subheadline)
                  .foregroundColor(Color(
                    self.cs,
                    light: .black.opacity(0.6),
                    dark: .white.opacity(0.6),
                  ))
              }
            }

            if self.status.isUnpaid {
              Text(lstr(.settingsSubscriptionUnpaidWarning))
                .font(.subheadline)
                .foregroundColor(Color(red: 0.8, green: 0.2, blue: 0.2))
                .multilineTextAlignment(.center)
            }
          }
        }
      }

      Spacer()
    }
    .padding(20)
  }

  private var expirationLabel: String {
    switch self.status {
    case .unpaid: lstr(.settingsSubscriptionExpired)
    case .active: lstr(.settingsSubscriptionRenewsAutomatically)
    case .trialing, .complimentary: lstr(.settingsSubscriptionExpires)
    }
  }

  private var expirationText: String {
    let now = Date()
    let interval = self.expiresAt.timeIntervalSince(now)
    let days = Int(interval / 86400)

    if days < 0 {
      let format = lstr(.settingsExpirationDaysAgo)
      return String(format: format, -days)
    } else if days == 0 {
      return lstr(.settingsExpirationToday)
    } else if days == 1 {
      return lstr(.settingsExpirationTomorrow)
    } else {
      let format = lstr(.settingsExpirationInDays)
      return String(format: format, days)
    }
  }
}

// previews

#Preview("Trialing") {
  SettingsView(
    status: .trialing(purchasePending: false),
    expiresAt: Date().addingTimeInterval(.days(25)),
  )
}

#Preview("Trialing (Dark)") {
  SettingsView(
    status: .trialing(purchasePending: false),
    expiresAt: Date().addingTimeInterval(.days(25)),
  )
  .preferredColorScheme(.dark)
}

#Preview("Active") {
  SettingsView(
    status: .active,
    expiresAt: Date().addingTimeInterval(.days(180)),
  )
}

#Preview("Active (Dark)") {
  SettingsView(
    status: .active,
    expiresAt: Date().addingTimeInterval(.days(180)),
  )
  .preferredColorScheme(.dark)
}

#Preview("Complimentary") {
  SettingsView(
    status: .complimentary,
    expiresAt: Date().addingTimeInterval(.days(365)),
  )
}

#Preview("Complimentary (Dark)") {
  SettingsView(
    status: .complimentary,
    expiresAt: Date().addingTimeInterval(.days(365)),
  )
  .preferredColorScheme(.dark)
}

#Preview("Trial Expiring Soon") {
  SettingsView(
    status: .trialing(purchasePending: false),
    expiresAt: Date().addingTimeInterval(.days(3)),
  )
}

#Preview("Trial Expiring Soon (Dark)") {
  SettingsView(
    status: .trialing(purchasePending: false),
    expiresAt: Date().addingTimeInterval(.days(3)),
  )
  .preferredColorScheme(.dark)
}

#Preview("Unpaid") {
  SettingsView(
    status: .unpaid(purchasePending: false),
    expiresAt: Date().addingTimeInterval(.days(-5)),
  )
}

#Preview("Unpaid (Dark)") {
  SettingsView(
    status: .unpaid(purchasePending: false),
    expiresAt: Date().addingTimeInterval(.days(-5)),
  )
  .preferredColorScheme(.dark)
}

#Preview("Trialing (Purchase Pending)") {
  SettingsView(
    status: .trialing(purchasePending: true),
    expiresAt: Date().addingTimeInterval(.days(25)),
  )
}

#Preview("Unpaid (Purchase Pending)") {
  SettingsView(
    status: .unpaid(purchasePending: true),
    expiresAt: Date().addingTimeInterval(.days(-5)),
  )
}

#Preview("Trialing (Purchase In Progress)") {
  SettingsView(
    status: .trialing(purchasePending: false),
    expiresAt: Date().addingTimeInterval(.days(25)),
    purchaseInProgress: true,
  )
}

#Preview("Unpaid (Purchase In Progress)") {
  SettingsView(
    status: .unpaid(purchasePending: false),
    expiresAt: Date().addingTimeInterval(.days(-5)),
    purchaseInProgress: true,
  )
}
