typealias OnboardingBtn = IOSReducer.Action.Interactive.OnboardingBtn

extension IOSReducer.Screen {
  func fallbackDestination(from btn: OnboardingBtn) -> Self {
    switch self {
    case .launching:
      .onboarding(.happyPath(.hiThere))
    case .onboarding(let onboarding):
      onboarding.fallbackDestination(from: btn)
    case .supervisionSuccessFirstLaunch:
      .onboarding(.happyPath(.optOutBlockGroups))
    case .running(state: let state):
      .running(state: state)
    }
  }
}

extension IOSReducer.Onboarding {
  func fallbackDestination(from btn: OnboardingBtn) -> IOSReducer.Screen {
    switch self {
    case .appleFamily(let appleFamily):
      appleFamily.fallbackDestination(from: btn)
    case .authFail(let authFail):
      authFail.fallbackDestination(from: btn)
    case .childIsOnboardingFail:
      .onboarding(.happyPath(.hiThere))
    case .happyPath(let happyPath):
      happyPath.fallbackDestination(from: btn)
    case .installFail(let installFail):
      installFail.fallbackDestination(from: btn)
    case .onParentDeviceFail:
      .onboarding(.happyPath(.hiThere))
    case .supervision(let supervision):
      supervision.fallbackDestination(from: btn)
    case .mdmSupervisionExplainer:
      .onboarding(.happyPath(.hiThere))
    }
  }
}

extension IOSReducer.Onboarding.AppleFamily {
  func fallbackDestination(from btn: OnboardingBtn) -> IOSReducer.Screen {
    switch (self, btn) {
    case (.checkIfInAppleFamily, .primary):
      .onboarding(.happyPath(.confirmInAppleFamily))
    case (.checkIfInAppleFamily, _):
      .onboarding(.appleFamily(.explainSetupFreeAndEasy))
    case (.explainRequiredForFiltering, _):
      .onboarding(.appleFamily(.explainSetupFreeAndEasy))
    case (.explainSetupFreeAndEasy, _):
      .onboarding(.appleFamily(.howToSetupAppleFamily))
    case (.explainWhatIsAppleFamily, _):
      .onboarding(.appleFamily(.checkIfInAppleFamily))
    case (.howToSetupAppleFamily, _):
      .onboarding(.happyPath(.confirmInAppleFamily))
    }
  }
}

extension IOSReducer.Onboarding.AuthFail {
  func fallbackDestination(from btn: OnboardingBtn) -> IOSReducer.Screen {
    switch self {
    case .invalidAccount(let invalidAccountScreen):
      invalidAccountScreen.fallbackDestination(from: btn)
    case .networkError, .passcodeRequired, .restricted, .unexpected, .authCanceled, .authConflict:
      .onboarding(.happyPath(.explainTwoInstallSteps))
    }
  }
}

extension IOSReducer.Onboarding.AuthFail.InvalidAccount {
  func fallbackDestination(from btn: OnboardingBtn) -> IOSReducer.Screen {
    switch (self, btn) {
    case (.confirmInAppleFamily, .primary):
      .onboarding(.authFail(.invalidAccount(.confirmIsMinor)))
    case (.confirmInAppleFamily, .secondary):
      .onboarding(.appleFamily(.explainRequiredForFiltering))
    case (.confirmInAppleFamily, _):
      .onboarding(.appleFamily(.checkIfInAppleFamily))
    case (.confirmIsMinor, .primary):
      .onboarding(.supervision(.setup(.explainSupervision)))
    case (.confirmIsMinor, _):
      .onboarding(.authFail(.invalidAccount(.unexpected)))
    case (.letsFigureThisOut, _):
      .onboarding(.authFail(.invalidAccount(.confirmInAppleFamily)))
    case (.unexpected, _):
      .onboarding(.happyPath(.hiThere))
    }
  }
}

extension IOSReducer.Onboarding.InstallFail {
  func fallbackDestination(from btn: OnboardingBtn) -> IOSReducer.Screen {
    switch self {
    case .permissionDenied, .other:
      .onboarding(.happyPath(.explainInstallWithDevicePasscode))
    }
  }
}

extension IOSReducer.Onboarding.Supervision {
  func fallbackDestination(from btn: OnboardingBtn) -> IOSReducer.Screen {
    switch self {
    case .setup(let setup):
      setup.fallbackDestination(from: btn)
    case .resume(let resume):
      resume.fallbackDestination(from: btn)
    }
  }
}

extension IOSReducer.Onboarding.Supervision.Setup {
  func fallbackDestination(from btn: OnboardingBtn) -> IOSReducer.Screen {
    switch (self, btn) {
    case (.explainSupervision, _):
      .onboarding(.supervision(.setup(.costAndBranchPoint)))
    case (.costAndBranchPoint, .primary):
      .onboarding(.supervision(.setup(.explainNeedSomeoneElse)))
    case (.costAndBranchPoint, _):
      .onboarding(.supervision(.setup(.freeAlternativesHub)))
    case (.freeAlternativesHub, _):
      .onboarding(.supervision(.setup(.explainNeedSomeoneElse)))
    case (.birthdayAlternativeExplain, .primary):
      .onboarding(.supervision(.setup(.birthdayAlternativeCons)))
    case (.birthdayAlternativeExplain, _):
      .onboarding(.supervision(.setup(.freeAlternativesHub)))
    case (.birthdayAlternativeCons, .primary):
      .onboarding(.supervision(.setup(.birthdayAlternativeInstructions)))
    case (.birthdayAlternativeCons, _):
      .onboarding(.supervision(.setup(.freeAlternativesHub)))
    case (.birthdayAlternativeInstructions, _):
      .onboarding(.happyPath(.confirmMinorDevice))
    case (.siblingAlternativeExplain, .primary):
      .onboarding(.supervision(.setup(.siblingAlternativeCons)))
    case (.siblingAlternativeExplain, _):
      .onboarding(.supervision(.setup(.freeAlternativesHub)))
    case (.siblingAlternativeCons, .primary):
      .onboarding(.supervision(.setup(.siblingAlternativeInstructions)))
    case (.siblingAlternativeCons, _):
      .onboarding(.supervision(.setup(.freeAlternativesHub)))
    case (.siblingAlternativeInstructions, _):
      .onboarding(.happyPath(.confirmMinorDevice))
    case (.appleConfiguratorExplain, .primary):
      .onboarding(.supervision(.setup(.appleConfiguratorCons(step: 1))))
    case (.appleConfiguratorExplain, _):
      .onboarding(.supervision(.setup(.freeAlternativesHub)))
    case (.appleConfiguratorCons(_), .secondary):
      .onboarding(.supervision(.setup(.freeAlternativesHub)))
    case (.appleConfiguratorCons(let step), _):
      if step < 3 {
        .onboarding(.supervision(.setup(.appleConfiguratorCons(step: step + 1))))
      } else {
        .onboarding(.happyPath(.hiThere))
      }
    case (.accountNowUnder18, _):
      .onboarding(.happyPath(.confirmParentIsOnboarding))
    case (.explainNeedSomeoneElse, .primary):
      .onboarding(.supervision(.setup(.generateSetupCode())))
    case (.explainNeedSomeoneElse, _):
      .onboarding(.supervision(.setup(.selfManagementPlaceholder)))
    case (.selfManagementPlaceholder, _):
      .onboarding(.happyPath(.hiThere))
    case (.generateSetupCode(_), _):
      .onboarding(.supervision(.setup(.generateSetupCode(didError: true))))
    case (.instructionsForProtector(let code), _):
      .onboarding(.supervision(.setup(.waitingForSupervision(code: code))))
    case (.waitingForSupervision(let code), _):
      .onboarding(.supervision(.setup(.waitingForSupervision(code: code))))
    }
  }
}

extension IOSReducer.Onboarding.Supervision.Resume {
  func fallbackDestination(from btn: OnboardingBtn) -> IOSReducer.Screen {
    switch (self, btn) {
    case (.codeNotClaimed(let code), _):
      .onboarding(.supervision(.setup(.instructionsForProtector(code: code))))
    case (.codeClaimedNotSupervised(_), .primary):
      .onboarding(.supervision(.resume(.promptInstallProfile)))
    case (.codeClaimedNotSupervised(_), _):
      .onboarding(.supervision(.setup(.explainNeedSomeoneElse)))
    case (.retrySupervision, _):
      .onboarding(.supervision(.setup(.explainNeedSomeoneElse)))
    case (.promptInstallProfile, _):
      .onboarding(.supervision(.resume(.explainProfileDownload)))
    case (.explainProfileDownload, _):
      .onboarding(.supervision(.resume(.promptInstallProfile)))
    case (.installingProfile(_), _):
      .onboarding(.supervision(.resume(.profileNotRemovableWarning)))
    case (.profileNotRemovableWarning, _):
      .onboarding(.supervision(.resume(.explainProfileInstall())))
    case (.explainProfileInstall, _):
      .onboarding(.supervision(.resume(.verifyingProfileInstall())))
    case (.verifyingProfileInstall(didError: _), _):
      .onboarding(.supervision(.resume(.explainProfileInstall())))
    case (.profileInstalled, _):
      .onboarding(.supervision(.resume(.promptClearCache)))
    case (.promptClearCache, _):
      .onboarding(.happyPath(.requestAppStoreRating))
    case (.networkError, _):
      .onboarding(.supervision(.resume(.networkError)))
    }
  }
}

extension IOSReducer.Onboarding.HappyPath {
  func fallbackDestination(from btn: OnboardingBtn) -> IOSReducer.Screen {
    switch (self, btn) {
    case (.confirmChildsDevice, .primary):
      .onboarding(.happyPath(.explainMinorOrSupervised))
    case (.confirmChildsDevice, _):
      .onboarding(.onParentDeviceFail)
    case (.confirmInAppleFamily, .primary):
      .onboarding(.happyPath(.explainTwoInstallSteps))
    case (.confirmInAppleFamily, .secondary):
      .onboarding(.appleFamily(.explainRequiredForFiltering))
    case (.confirmInAppleFamily, _):
      .onboarding(.appleFamily(.explainWhatIsAppleFamily))
    case (.confirmMinorDevice, .primary):
      .onboarding(.happyPath(.confirmParentIsOnboarding))
    case (.confirmMinorDevice, _):
      .onboarding(.supervision(.setup(.explainSupervision)))
    case (.confirmParentIsOnboarding, .primary):
      .onboarding(.happyPath(.confirmInAppleFamily))
    case (.confirmParentIsOnboarding, _):
      .onboarding(.childIsOnboardingFail)
    case (.doneQuit, _):
      .running(state: .notConnected)
    case (.dontGetTrickedPreAuth, _):
      .onboarding(.happyPath(.explainAuthWithParentAppleAccount))
    case (.dontGetTrickedPreInstall, _):
      .onboarding(.happyPath(.explainInstallWithDevicePasscode))
    case (.explainAuthWithParentAppleAccount, _):
      .onboarding(.happyPath(.dontGetTrickedPreAuth))
    case (.explainInstallWithDevicePasscode, _):
      .onboarding(.happyPath(.dontGetTrickedPreInstall))
    case (.explainMinorOrSupervised, _):
      .onboarding(.happyPath(.confirmMinorDevice))
    case (.explainTwoInstallSteps, _):
      .onboarding(.happyPath(.explainAuthWithParentAppleAccount))
    case (.hiThere, _):
      .onboarding(.happyPath(.timeExpectation))
    case (.optOutBlockGroups, _):
      .onboarding(.happyPath(.explainTwoInstallSteps))
    case (.promptClearCache, _):
      .onboarding(.happyPath(.requestAppStoreRating))
    case (.requestAppStoreRating, _):
      .onboarding(.happyPath(.doneQuit))
    case (.timeExpectation, _):
      .onboarding(.happyPath(.confirmChildsDevice))
    case (.offerAccountConnect, _):
      .onboarding(.happyPath(.optOutBlockGroups))
    case (.explainAccountConnect, _):
      .onboarding(.happyPath(.optOutBlockGroups))
    case (.connectSuccess, _):
      .onboarding(.happyPath(.promptClearCache))
    }
  }
}
