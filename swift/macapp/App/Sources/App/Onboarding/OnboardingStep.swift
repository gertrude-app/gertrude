
extension OnboardingFeature.State {
  enum Step: String, Equatable, Codable {
    case welcome

    // wrong install dir
    case wrongInstallDir

    // account
    case confirmGertrudeAccount
    case noGertrudeAccount

    // os user type
    case macosUserAccountType

    // connection
    case getChildConnectionCode
    case connectChild

    // how to use gifs
    case howToUseGifs

    // notifications
    case allowNotifications_start
    case allowNotifications_grant
    case allowNotifications_failed

    // full disk access
    case allowFullDiskAccess_grantAndRestart
    // next two give landing spots for resuming after quit/reopen
    case allowFullDiskAccess_failed
    case allowFullDiskAccess_success

    // screenshots
    case allowScreenshots_required
    case allowScreenshots_grantAndRestart
    // next two give landing spots for resuming after quit/reopen
    case allowScreenshots_failed
    case allowScreenshots_success

    // keylogging
    case allowKeylogging_required
    case allowKeylogging_grant
    case allowKeylogging_failed

    // sys ext
    case installSysExt_explain
    case installSysExt_trick
    case installSysExt_allow
    case installSysExt_failed
    case installSysExt_success

    // opt out of filtering
    case optOutOfFiltering

    // configure downtime
    case configureDowntime

    // app key selection
    case appKeySelection_intro
    case appKeySelection_blockApps
    case appKeySelection_allowInternet

    // keychains
    case aboutPermittingWebsites
    case meetKeychains
    case selectPublicKeychains
    case customKeychains

    // wrap up
    case exemptUsers
    case locateMenuBarIcon
    case viewHealthCheck
    case encourageFilterSuspensions
    case screenTimeConflict
    case finish
  }
}

extension OnboardingFeature.State.Step {
  var primaryFallbackNextStep: Self {
    switch self {
    case .welcome:
      .confirmGertrudeAccount
    case .wrongInstallDir:
      .confirmGertrudeAccount
    case .confirmGertrudeAccount:
      .macosUserAccountType
    case .noGertrudeAccount:
      .macosUserAccountType
    case .macosUserAccountType:
      .getChildConnectionCode
    case .getChildConnectionCode:
      .connectChild
    case .connectChild:
      .howToUseGifs
    case .howToUseGifs:
      .allowNotifications_start
    case .allowNotifications_start:
      .allowNotifications_grant
    case .allowNotifications_grant:
      .allowScreenshots_required
    case .allowNotifications_failed:
      .allowFullDiskAccess_grantAndRestart
    case .allowFullDiskAccess_grantAndRestart:
      .allowFullDiskAccess_success
    case .allowFullDiskAccess_success:
      .allowScreenshots_required
    case .allowFullDiskAccess_failed:
      .allowScreenshots_required
    case .allowScreenshots_required:
      .allowScreenshots_grantAndRestart
    case .allowScreenshots_grantAndRestart:
      .allowScreenshots_success
    case .allowScreenshots_failed:
      .allowKeylogging_required
    case .allowScreenshots_success:
      .allowKeylogging_required
    case .allowKeylogging_required:
      .allowKeylogging_grant
    case .allowKeylogging_grant:
      .installSysExt_explain
    case .allowKeylogging_failed:
      .installSysExt_explain
    case .installSysExt_explain:
      .installSysExt_trick
    case .installSysExt_trick:
      .installSysExt_allow
    case .installSysExt_allow:
      .installSysExt_success
    case .installSysExt_failed:
      .installSysExt_success
    case .installSysExt_success:
      .optOutOfFiltering
    case .optOutOfFiltering:
      .configureDowntime
    case .configureDowntime:
      .appKeySelection_intro
    case .appKeySelection_intro:
      .appKeySelection_blockApps
    case .appKeySelection_blockApps:
      .appKeySelection_allowInternet
    case .appKeySelection_allowInternet:
      .aboutPermittingWebsites
    case .aboutPermittingWebsites:
      .meetKeychains
    case .meetKeychains:
      .selectPublicKeychains
    case .selectPublicKeychains:
      .customKeychains
    case .customKeychains:
      .exemptUsers
    case .exemptUsers:
      .locateMenuBarIcon
    case .locateMenuBarIcon:
      .viewHealthCheck
    case .viewHealthCheck:
      .encourageFilterSuspensions
    case .encourageFilterSuspensions:
      .finish
    case .screenTimeConflict:
      .finish
    case .finish:
      .finish
    }
  }

  var secondaryFallbackNextStep: Self {
    switch self {
    case .welcome:
      .welcome
    case .wrongInstallDir:
      .welcome
    case .confirmGertrudeAccount:
      .welcome
    case .noGertrudeAccount:
      .confirmGertrudeAccount
    case .macosUserAccountType:
      .confirmGertrudeAccount
    case .getChildConnectionCode:
      .macosUserAccountType
    case .connectChild:
      .getChildConnectionCode
    case .howToUseGifs:
      .connectChild
    case .allowNotifications_start:
      .howToUseGifs
    case .allowNotifications_grant:
      .allowNotifications_start
    case .allowNotifications_failed:
      .allowNotifications_grant
    case .allowFullDiskAccess_grantAndRestart:
      .allowNotifications_start
    case .allowFullDiskAccess_failed:
      .allowFullDiskAccess_grantAndRestart
    case .allowFullDiskAccess_success:
      .allowFullDiskAccess_grantAndRestart
    case .allowScreenshots_required:
      .allowFullDiskAccess_grantAndRestart
    case .allowScreenshots_grantAndRestart:
      .allowScreenshots_required
    case .allowScreenshots_failed:
      .allowScreenshots_required
    case .allowScreenshots_success:
      .allowScreenshots_grantAndRestart
    case .allowKeylogging_required:
      .allowScreenshots_required
    case .allowKeylogging_grant:
      .allowKeylogging_required
    case .allowKeylogging_failed:
      .allowKeylogging_required
    case .installSysExt_explain:
      .allowKeylogging_required
    case .installSysExt_trick:
      .installSysExt_explain
    case .installSysExt_allow:
      .installSysExt_trick
    case .installSysExt_failed:
      .installSysExt_explain
    case .installSysExt_success:
      .installSysExt_explain
    case .optOutOfFiltering:
      .installSysExt_success
    case .configureDowntime:
      .optOutOfFiltering
    case .appKeySelection_intro:
      .configureDowntime
    case .appKeySelection_blockApps:
      .appKeySelection_intro
    case .appKeySelection_allowInternet:
      .appKeySelection_blockApps
    case .aboutPermittingWebsites:
      .appKeySelection_allowInternet
    case .meetKeychains:
      .aboutPermittingWebsites
    case .selectPublicKeychains:
      .meetKeychains
    case .customKeychains:
      .selectPublicKeychains
    case .exemptUsers:
      .installSysExt_explain
    case .locateMenuBarIcon:
      .installSysExt_explain
    case .viewHealthCheck:
      .locateMenuBarIcon
    case .encourageFilterSuspensions:
      .viewHealthCheck
    case .screenTimeConflict:
      .encourageFilterSuspensions
    case .finish:
      .encourageFilterSuspensions
    }
  }
}

extension OnboardingFeature.State.Step: Comparable {
  static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.asInt < rhs.asInt
  }

  private var asInt: Int {
    switch self {
    case .welcome: 10
    case .wrongInstallDir: 20
    case .confirmGertrudeAccount: 30
    case .noGertrudeAccount: 40
    case .macosUserAccountType: 50
    case .getChildConnectionCode: 60
    case .connectChild: 70
    case .howToUseGifs: 80
    case .allowNotifications_start: 90
    case .allowNotifications_grant: 100
    case .allowNotifications_failed: 110
    case .allowFullDiskAccess_grantAndRestart: 120
    case .allowFullDiskAccess_failed: 130
    case .allowFullDiskAccess_success: 140
    case .allowScreenshots_required: 150
    case .allowScreenshots_grantAndRestart: 160
    case .allowScreenshots_failed: 170
    case .allowScreenshots_success: 180
    case .allowKeylogging_required: 190
    case .allowKeylogging_grant: 200
    case .allowKeylogging_failed: 210
    case .installSysExt_explain: 220
    case .installSysExt_trick: 230
    case .installSysExt_allow: 240
    case .installSysExt_failed: 250
    case .installSysExt_success: 260
    case .optOutOfFiltering: 270
    case .configureDowntime: 280
    case .appKeySelection_intro: 290
    case .appKeySelection_blockApps: 300
    case .appKeySelection_allowInternet: 310
    case .aboutPermittingWebsites: 312
    case .meetKeychains: 314
    case .selectPublicKeychains: 316
    case .customKeychains: 318
    case .exemptUsers: 320
    case .locateMenuBarIcon: 330
    case .viewHealthCheck: 340
    case .encourageFilterSuspensions: 350
    case .screenTimeConflict: 360
    case .finish: 380
    }
  }
}
