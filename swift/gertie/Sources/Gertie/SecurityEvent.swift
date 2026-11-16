public enum SecurityEvent: Equatable, Codable, Sendable {
  public enum Severity: Sendable {
    case all
    case medium
    case recommended
  }

  public enum MacApp: String, Codable, Equatable, Sendable {
    case filterSuspendedRemotely
    case filterSuspensionGrantedByAdmin
    case filterSuspensionExpired
    case filterSuspensionEndedEarly
    case systemExtensionChangeRequested
    case systemExtensionStateChanged
    case appQuit
    case appLaunched
    case newMacOsUserCreated
    case macosUserExempted
    case childDisconnected
    case appUpdateSucceeded
    case appUpdateFailedToReplaceSystemExtension
    case advancedSettingsOpened
    case systemClockOrTimeZoneChanged
    case blockedAppLaunchAttempted
    case filteringDisabledDuringOnboarding
  }

  public enum Dashboard: String, Codable, Equatable, Sendable {
    case login
    case loginFailed
    case passwordResetRequested
    case passwordChanged
    case childDeleted
    case iosBlockRuleDeleted
    case childAdded
    case childComputerDeleted
    case monitoringDecreased
    case keyCreated
    case keychainCreated
    case keychainsChanged
    case notificationDeleted
    case blockedAppsChanged
    case unrestrictedAppsChanged
    case alwaysBlockedGroupsChanged
    case alwaysBlockedRulesChanged
  }

  case macApp(MacApp)
  case dashboard(Dashboard)
}

// explicit Comparable: all < medium < recommended (increasing importance)
// the notification filter uses `>=` to include events at or above a threshold,
// e.g. `severity >= .medium` matches medium and recommended events
extension SecurityEvent.Severity: Comparable {
  private var importance: Int {
    switch self {
    case .all: 0
    case .medium: 1
    case .recommended: 2
    }
  }

  public static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.importance < rhs.importance
  }
}

public extension SecurityEvent.Dashboard {
  var toWords: String {
    switch self {
    case .childAdded:
      "Person added"
    case .childDeleted:
      "Person deleted"
    case .childComputerDeleted:
      "Mac disconnected from person"
    case .keyCreated:
      "Key created"
    case .keychainCreated:
      "Keychain created"
    case .keychainsChanged:
      "Keychains changed"
    case .login:
      "Successful login"
    case .loginFailed:
      "Failed login"
    case .monitoringDecreased:
      "Monitoring decreased"
    case .notificationDeleted:
      "Notification deleted"
    case .passwordChanged:
      "Password changed"
    case .passwordResetRequested:
      "Password reset requested"
    case .blockedAppsChanged:
      "Blocked apps changed"
    case .unrestrictedAppsChanged:
      "Unrestricted internet apps changed"
    case .iosBlockRuleDeleted:
      "iOS block rule deleted"
    case .alwaysBlockedGroupsChanged:
      "Always blocked groups changed"
    case .alwaysBlockedRulesChanged:
      "Always blocked custom rules changed"
    }
  }

  var explanation: String {
    switch self {
    case .childAdded:
      "This event occurs when someone adds a person to your Gertrude account. It should occur very rarely, usually during account setup or when starting protection for someone new. Investigate it if it happened without your knowledge."
    case .childDeleted:
      "This event occurs when someone deletes a person from your Gertrude account. It should occur very rarely, when someone no longer needs protection. Investigate it if it happened without your knowledge."
    case .childComputerDeleted:
      "This event occurs when someone disconnects a person's Mac from your Gertrude account. It should occur very rarely, usually when the person no longer uses that Mac or no longer needs protection. Investigate it if it happened without your knowledge."
    case .keyCreated:
      "This event occurs when a new key is added to a keychain, either directly or by accepting an unlock request."
    case .keychainCreated:
      "This event occurs when a new keychain is created."
    case .keychainsChanged:
      "This event occurs when someone changes which keychains are assigned to a person. Investigate it if you didn't make the change."
    case .login:
      "This event occurs whenever someone logs in to your Gertrude account. Investigate it if you don't recognize the login as your own."
    case .loginFailed:
      "This event occurs whenever someone fails to log in to your Gertrude account, usually because of an incorrect password. Investigate it if you don't recognize the attempt as your own."
    case .monitoringDecreased:
      "This event occurs when someone decreases the monitoring level for a person. Investigate it if it happened without your knowledge."
    case .notificationDeleted:
      "This event occurs when someone deletes a notification from your Gertrude account. Investigate it if it happened without your knowledge."
    case .passwordChanged:
      "This event occurs when the password for your Gertrude account is changed. Investigate it if you didn't change your password."
    case .passwordResetRequested:
      "This event occurs when someone requests a password reset for your Gertrude account. Investigate it if you didn't request it."
    case .blockedAppsChanged:
      "This event occurs when someone changes which apps are blocked for a person. Investigate it if you didn't make the change."
    case .unrestrictedAppsChanged:
      "This event occurs when someone changes which apps have unrestricted internet access for a person. Investigate it if you didn't make the change."
    case .iosBlockRuleDeleted:
      "This event occurs when someone deletes an iOS block rule from your Gertrude account. Investigate it if you didn't make the change."
    case .alwaysBlockedGroupsChanged:
      "This event occurs when someone changes which Always Blocked groups apply to a person. Investigate it if you didn't make the change."
    case .alwaysBlockedRulesChanged:
      "This event occurs when someone changes a person's custom Always Blocked rules. Investigate it if you didn't make the change."
    }
  }

  var severity: SecurityEvent.Severity {
    switch self {
    case .passwordChanged,
         .passwordResetRequested,
         .childDeleted,
         .monitoringDecreased,
         .notificationDeleted,
         .blockedAppsChanged,
         .unrestrictedAppsChanged:
      .recommended
    case .loginFailed,
         .childComputerDeleted,
         .iosBlockRuleDeleted,
         .alwaysBlockedGroupsChanged,
         .alwaysBlockedRulesChanged:
      .medium
    case .login,
         .childAdded,
         .keyCreated,
         .keychainCreated,
         .keychainsChanged:
      .all
    }
  }
}

public extension SecurityEvent.MacApp {
  var toWords: String {
    switch self {
    case .advancedSettingsOpened:
      "Advanced settings opened"
    case .appLaunched:
      "App launched"
    case .appQuit:
      "App quit"
    case .appUpdateFailedToReplaceSystemExtension:
      "App update failed to replace system extension"
    case .appUpdateSucceeded:
      "App update succeeded"
    case .childDisconnected:
      "Mac app disconnected"
    case .filterSuspendedRemotely:
      "Filter suspended remotely"
    case .filterSuspensionEndedEarly:
      "Filter suspension ended early"
    case .filterSuspensionExpired:
      "Filter suspension expired"
    case .filterSuspensionGrantedByAdmin:
      "Filter suspended on the Mac"
    case .macosUserExempted:
      "macOS user exempted"
    case .newMacOsUserCreated:
      "New macOS user created"
    case .systemClockOrTimeZoneChanged:
      "System clock or time zone changed"
    case .systemExtensionChangeRequested:
      "System extension change requested"
    case .systemExtensionStateChanged:
      "System extension state changed"
    case .blockedAppLaunchAttempted:
      "Blocked app launch attempted"
    case .filteringDisabledDuringOnboarding:
      "Internet filtering disabled during onboarding"
    }
  }

  var explanation: String {
    switch self {
    case .advancedSettingsOpened:
      "This event occurs when a macOS admin user opens a hidden, advanced settings area in the Administrate screen. This is unexpected, and usually only happens when Gertrude support has asked you to open it. It should be investigated."
    case .appLaunched:
      "This event occurs when the Gertrude app is launched. Only investigate it if seems to be occuring more than expected."
    case .appQuit:
      "This event occurs when a macOS admin user quits the Gertrude app. On a protected person's Mac this shouldn't happen, and it should be investigated."
    case .appUpdateFailedToReplaceSystemExtension:
      "This is a rare event that occurs when a Gertrude update fails. It isn't an attempt by the protected person to bypass Gertrude, but should be investigated to make sure the filter is working correctly."
    case .appUpdateSucceeded:
      "This event occurs when an upgrade to the Gertrude app finishes successfully. It is normal, but should be infrequent."
    case .childDisconnected:
      "This event occurs when the Gertrude macOS app is disconnected from the person it was protecting. It shouldn't happen unless the app is being uninstalled, or a different person is connected soon after."
    case .filterSuspendedRemotely:
      "This event occurs when a request to suspend the filter is accepted from your Gertrude account. As long as you accepted the request, this event is normal."
    case .filterSuspensionEndedEarly:
      "This event occurs when the protected person ends a filter suspension early. It isn't a safety risk."
    case .filterSuspensionExpired:
      "This event occurs when a filter suspension ends at its scheduled time. It isn't a safety risk."
    case .filterSuspensionGrantedByAdmin:
      "This event occurs when a macOS admin user suspends the filter directly on the Mac. If you didn't do this, it means the protected person suspended the filter themselves."
    case .macosUserExempted:
      "This event occurs when a macOS admin user exempts another macOS user from being filtered by Gertrude. Unless you did this, it should be investigated."
    case .newMacOsUserCreated:
      "This event occurs when a new macOS user is created on the computer. It could represent an attempt to bypass Gertrude, but could also be normal."
    case .systemClockOrTimeZoneChanged:
      "This event occurs when the system clock or time zone is changed. If there is not a legitimate reason for the clock or time zone to have changed, it could represent an attempt to circumvent time-based restrictions in Gertrude and should be investigated."
    case .systemExtensionChangeRequested:
      "This event occurs whenever some action or process within Gertrude happens that requests a change to the state of the system extension (filter). It should be investigated if the request is to stop or uninstall the extension without it immediately being restarted or replaced."
    case .systemExtensionStateChanged:
      "This event occurs when the system extension (filter) state has changed. It should be investigated if the state remains uninstalled or stopped."
    case .blockedAppLaunchAttempted:
      "This event occurs when the protected person tries to open an app you've blocked. It isn't a security risk, since Gertrude won't let the app open, but repeated events show repeated attempts to open blocked apps."
    case .filteringDisabledDuringOnboarding:
      "This event occurs when internet filtering is turned off for a person during setup. This is a legitimate setup option, but should be investigated if you didn't intend to turn filtering off."
    }
  }

  var severity: SecurityEvent.Severity {
    switch self {
    case .childDisconnected,
         .macosUserExempted,
         .newMacOsUserCreated,
         .filterSuspensionGrantedByAdmin,
         .appQuit,
         .appUpdateFailedToReplaceSystemExtension,
         .filteringDisabledDuringOnboarding:
      .recommended
    case .systemExtensionChangeRequested,
         .systemExtensionStateChanged,
         .systemClockOrTimeZoneChanged,
         .blockedAppLaunchAttempted,
         .filterSuspendedRemotely,
         .advancedSettingsOpened:
      .medium
    case
      .filterSuspensionExpired,
      .filterSuspensionEndedEarly,
      .appLaunched,
      .appUpdateSucceeded:
      .all
    }
  }
}
