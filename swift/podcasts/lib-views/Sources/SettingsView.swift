import SwiftUI

public struct SettingsView: View {
  @Environment(\.colorScheme) var cs

  public enum Event: Equatable, Sendable {
    case subscribeNowTapped
    case changePinTapped
    case reclaimStorageTapped
  }

  public enum SubscriptionStatus: Equatable {
    case trialing
    case active
    case complimentary
    case unpaid

    var displayName: String {
      switch self {
      case .trialing: lstr(.settingsSubscriptionStatusFreeTrial)
      case .active: lstr(.settingsSubscriptionStatusActive)
      case .complimentary: lstr(.settingsSubscriptionStatusFreeForever)
      case .unpaid: lstr(.settingsSubscriptionStatusUnpaid)
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
  let reclaimableStorageGb: Double?
  let isClaimed: Bool
  let legacyMigrationNag: Bool
  let onEvent: @MainActor @Sendable (Event) -> Void

  public init(
    status: SubscriptionStatus,
    expiresAt: Date,
    reclaimableStorageGb: Double? = nil,
    isClaimed: Bool = false,
    legacyMigrationNag: Bool = false,
    onEvent: @MainActor @Sendable @escaping (Event) -> Void = { _ in },
  ) {
    self.status = status
    self.expiresAt = expiresAt
    self.reclaimableStorageGb = reclaimableStorageGb
    self.isClaimed = isClaimed
    self.legacyMigrationNag = legacyMigrationNag
    self.onEvent = onEvent
  }

  public var body: some View {
    GeometryReader { proxy in
      ScrollView {
        VStack(spacing: 20) {
          Text(lstr(.settingsTitle))
            .font(.largeTitle)
            .fontWeight(.bold)
            .frame(maxWidth: .infinity, alignment: .leading)

          VStack(spacing: 12) {
            HStack(spacing: 6) {
              Image(systemName: "key")
                .font(.subheadline)
              Text(lstr(.settingsSecurityHeader))
                .font(.subheadline)
                .fontWeight(.medium)
            }
            .foregroundColor(Color(self.cs, light: .black.opacity(0.6), dark: .white.opacity(0.6)))
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
              self.onEvent(.changePinTapped)
            } label: {
              HStack {
                Text(lstr(.settingsChangePin))
                  .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                  .font(.subheadline)
                  .foregroundColor(Color(
                    self.cs,
                    light: .black.opacity(0.4),
                    dark: .white.opacity(0.4),
                  ))
              }
              .padding(16)
              .background(Color(self.cs, light: .violet100, dark: .violet900))
              .cornerRadius(12)
            }
            .buttonStyle(.plain)
          }

          if let gb = self.reclaimableStorageGb {
            VStack(spacing: 12) {
              HStack(spacing: 6) {
                Image(systemName: "internaldrive")
                  .font(.subheadline)
                Text(lstr(.settingsStorageHeader))
                  .font(.subheadline)
                  .fontWeight(.medium)
              }
              .foregroundColor(Color(
                self.cs,
                light: .black.opacity(0.6),
                dark: .white.opacity(0.6),
              ))
              .frame(maxWidth: .infinity, alignment: .leading)

              Button {
                self.onEvent(.reclaimStorageTapped)
              } label: {
                HStack {
                  Image(systemName: "trash")
                    .font(.subheadline)
                  Text(String(format: lstr(.settingsStorageReclaim), gb))
                    .font(.headline)
                  Spacer()
                }
                .padding(16)
                .background(Color(self.cs, light: .violet100, dark: .violet900))
                .cornerRadius(12)
              }
              .buttonStyle(.plain)
            }
          }

          VStack(spacing: 12) {
            HStack(spacing: 6) {
              Image(systemName: "person.crop.circle")
                .font(.subheadline)
              Text(lstr(.accountHeader))
                .font(.subheadline)
                .fontWeight(.medium)
            }
            .foregroundColor(Color(self.cs, light: .black.opacity(0.6), dark: .white.opacity(0.6)))
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
              HStack {
                Text(lstr(.accountStatus))
                  .font(.headline)
                Spacer()
                Text(self.isClaimed ? lstr(.accountConnected) : lstr(.accountNotConnected))
                  .font(.subheadline)
                  .fontWeight(.semibold)
                  .foregroundColor(self.connectionColor)
              }

              HStack(alignment: .top) {
                Text(lstr(.accountSubscription))
                  .font(.headline)
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                  Text(self.subscriptionText)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(self.subscriptionColor)
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
                if self.legacyMigrationNag {
                  Text(String(
                    format: lstr(.settingsLegacyExplainer),
                    formatLegacyAccessDate(self.expiresAt, includeYear: false),
                  ))
                  .font(.subheadline)
                  .foregroundColor(Color(
                    self.cs,
                    light: .black.opacity(0.6),
                    dark: .white.opacity(0.6),
                  ))
                  .fixedSize(horizontal: false, vertical: true)
                }
              }
            }
            .padding(20)
            .background(Color(self.cs, light: .violet100, dark: .violet900))
            .cornerRadius(12)

            if self.status.isTrialing || self.status.isUnpaid {
              VStack(spacing: 16) {
                VStack(spacing: 8) {
                  Button {
                    self.onEvent(.subscribeNowTapped)
                  } label: {
                    Text(self.isClaimed ? lstr(.accountCtaSubscribe) : lstr(.accountCtaConnect))
                      .font(.headline)
                      .foregroundColor(.white)
                      .frame(maxWidth: .infinity)
                      .padding(.vertical, 12)
                      .background(Color(red: 0.4, green: 0.3, blue: 0.8))
                      .cornerRadius(10)
                  }

                  Text(lstr(.accountPrice))
                    .font(.subheadline)
                    .foregroundColor(Color(
                      self.cs,
                      light: .black.opacity(0.6),
                      dark: .white.opacity(0.6),
                    ))
                }

                if self.status.isUnpaid {
                  Text(lstr(.settingsSubscriptionUnpaidWarning))
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.8, green: 0.2, blue: 0.2))
                    .multilineTextAlignment(.center)
                }
              }
            }

            if self.legacyMigrationNag {
              Button {
                self.onEvent(.subscribeNowTapped)
              } label: {
                Text(lstr(.accountCtaConnect))
                  .font(.headline)
                  .foregroundColor(.white)
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 12)
                  .background(Color(red: 0.4, green: 0.3, blue: 0.8))
                  .cornerRadius(10)
              }
            }
          }

          Spacer()

          Link(
            lstr(.settingsSubscriptionPrivacy),
            destination: URL(string: "https://gertrude.app/docs/am-privacy")!,
          )
          .font(.caption)
          .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(20)
        .frame(minHeight: proxy.size.height)
      }
    }
  }

  private var connectionColor: Color {
    self.isClaimed
      ? Color(red: 0.2, green: 0.6, blue: 0.3)
      : Color(self.cs, light: .black.opacity(0.5), dark: .white.opacity(0.5))
  }

  private var subscriptionText: String {
    switch self.status {
    case .trialing: lstr(.accountValueFreeTrial)
    case .active: lstr(.accountValueActive)
    case .complimentary: lstr(.accountValueFreeForever)
    case .unpaid: self.isClaimed ? lstr(.accountValueUnpaid) : lstr(.accountValueNone)
    }
  }

  private var subscriptionColor: Color {
    switch self.status {
    case .active, .complimentary: Color(red: 0.2, green: 0.6, blue: 0.3)
    case .trialing: Color(red: 0.2, green: 0.4, blue: 0.8)
    case .unpaid: Color(red: 0.8, green: 0.2, blue: 0.2)
    }
  }

  private var expirationLabel: String {
    if self.legacyMigrationNag {
      return lstr(.settingsSubscriptionActiveUntil)
    }
    switch self.status {
    case .unpaid: return lstr(.settingsSubscriptionExpired)
    case .active, .trialing, .complimentary: return lstr(.settingsSubscriptionExpires)
    }
  }

  private var expirationText: String {
    if self.legacyMigrationNag {
      return formatLegacyAccessDate(self.expiresAt, includeYear: true)
    }
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
    status: .trialing,
    expiresAt: Date().addingTimeInterval(.days(25)),
    reclaimableStorageGb: 2.4,
  )
}

#Preview("Trialing (Dark)") {
  SettingsView(
    status: .trialing,
    expiresAt: Date().addingTimeInterval(.days(25)),
    reclaimableStorageGb: 2.4,
  )
  .preferredColorScheme(.dark)
}

#Preview("Active") {
  SettingsView(
    status: .active,
    expiresAt: Date().addingTimeInterval(.days(180)),
    reclaimableStorageGb: 2.4,
    isClaimed: true,
  )
}

#Preview("Active (Dark)") {
  SettingsView(
    status: .active,
    expiresAt: Date().addingTimeInterval(.days(180)),
    reclaimableStorageGb: 2.4,
    isClaimed: true,
  )
  .preferredColorScheme(.dark)
}

#Preview("Complimentary") {
  SettingsView(
    status: .complimentary,
    expiresAt: Date().addingTimeInterval(.days(365)),
    reclaimableStorageGb: 2.4,
    isClaimed: true,
  )
}

#Preview("Complimentary (Dark)") {
  SettingsView(
    status: .complimentary,
    expiresAt: Date().addingTimeInterval(.days(365)),
    reclaimableStorageGb: 2.4,
    isClaimed: true,
  )
  .preferredColorScheme(.dark)
}

#Preview("Legacy Nag") {
  SettingsView(
    status: .active,
    expiresAt: Date().addingTimeInterval(.days(58)),
    reclaimableStorageGb: 2.4,
    legacyMigrationNag: true,
  )
}

#Preview("Trial Expiring Soon") {
  SettingsView(
    status: .trialing,
    expiresAt: Date().addingTimeInterval(.days(3)),
    reclaimableStorageGb: 2.4,
  )
}

#Preview("Trial Expiring Soon (Dark)") {
  SettingsView(
    status: .trialing,
    expiresAt: Date().addingTimeInterval(.days(3)),
    reclaimableStorageGb: 2.4,
  )
  .preferredColorScheme(.dark)
}

#Preview("Unpaid — Unclaimed") {
  SettingsView(
    status: .unpaid,
    expiresAt: Date().addingTimeInterval(.days(-5)),
    reclaimableStorageGb: 2.4,
  )
}

#Preview("Unpaid — Unclaimed (Dark)") {
  SettingsView(
    status: .unpaid,
    expiresAt: Date().addingTimeInterval(.days(-5)),
    reclaimableStorageGb: 2.4,
  )
  .preferredColorScheme(.dark)
}

#Preview("Unpaid — Claimed") {
  SettingsView(
    status: .unpaid,
    expiresAt: Date().addingTimeInterval(.days(-5)),
    reclaimableStorageGb: 2.4,
    isClaimed: true,
  )
}

#Preview("Unpaid — Claimed (Dark)") {
  SettingsView(
    status: .unpaid,
    expiresAt: Date().addingTimeInterval(.days(-5)),
    reclaimableStorageGb: 2.4,
    isClaimed: true,
  )
  .preferredColorScheme(.dark)
}
