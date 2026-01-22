import ComposableArchitecture
import LibApp
import SwiftUI

public struct AppView: View {
  @Bindable var store: StoreOf<IOSReducer>
  let osMajorVersion: Int

  public init(store: StoreOf<IOSReducer>, osMajorVersion: Int) {
    self.store = store
    self.osMajorVersion = osMajorVersion
  }

  @Environment(\.colorScheme) var cs
  @Environment(\.openURL) var openLink

  public var body: some View {
    Group {
      if let clearCacheStore = self.store.scope(
        state: \.onboarding.clearCache,
        action: \.interactive.onboardingClearCache,
      ) {
        ClearingCacheView(
          store: clearCacheStore,
          clearedMessage: "Done! Previously downloaded GIFs should be gone!",
          clearedBtnLabel: "Next",
        )
        .onAppear { clearCacheStore.send(.onAppear) }
      } else {
        switch self.store.screen {
        case .launching: EmptyView()

        case .onboarding(.happyPath(.hiThere)):
          WelcomeView {
            self.store.send(.interactive(.onboardingBtnTapped(.primary, "Get Started")))
          }
          .onShake {
            #if DEBUG
              self.store.send(.interactive(.receivedShake))
            #endif
          }

        case .onboarding(.happyPath(.timeExpectation)):
          ButtonScreenView(
            text: "The setup usually takes about 5-7 minutes, but in some cases extra steps are required.",
            primary: self.btn(text: "Next", .primary),
          )

        case .onboarding(.happyPath(.confirmChildsDevice)):
          ButtonScreenView(
            text: "Is this the device you want to protect?",
            primary: self.btn(text: "Yes", .primary),
            secondary: self.btn(text: "No", .secondary),
          )

        case .onboarding(.happyPath(.explainMinorOrSupervised)):
          ButtonScreenView(
            text: "Apple only allows Gertrude to do it’s job on two kinds of devices:",
            primary: self.btn(text: "Next", .primary),
            listItems: ["Devices used by children under 18", "Supervised devices"],
          )

        case .onboarding(.happyPath(.confirmMinorDevice)):
          ButtonScreenView(
            text: "Is this a child’s (under 18) device?",
            primary: self.btn(text: "Yes, under 18", .primary),
            secondary: self.btn(text: "No", .secondary),
          )

        case .onboarding(.happyPath(.confirmParentIsOnboarding)):
          ButtonScreenView(
            text: "Are you the parent or guardian?",
            primary: self.btn(text: "Yes", .primary),
            secondary: self.btn(text: "No", .secondary),
          )

        case .onboarding(.happyPath(.confirmInAppleFamily)):
          ButtonScreenView(
            text: "Apple also requires that the child’s device be part of an Apple Family. Is the Apple Account for this device already in an Apple Family?",
            primary: self.btn(text: "Yes, it’s in an Apple Family", .primary),
            secondary: self.btn(text: "No", .secondary),
            tertiary: self.btn(text: "I’m not sure", .tertiary),
          )

        case .onboarding(.happyPath(.explainTwoInstallSteps)):
          ButtonScreenView(
            text: "Next we’ll authorize and install the content filter. It takes TWO steps, both of which are required.",
            primary: self.btn(text: "Next", .primary),
          )

        case .onboarding(.happyPath(.explainAuthWithParentAppleAccount)):
          ButtonScreenView(
            text: "For the first step, you’ll authorize Gertrude to access Screen Time using YOUR Apple ID (the parent/guardian, not the child’s).",
            primary: self.btn(text: "Got it, next", .primary),
          )

        case .onboarding(.happyPath(.dontGetTrickedPreAuth)):
          ButtonScreenView(
            text: "Don’t get tricked! Be sure to click “Continue”, even though it looks like you’re supposed to click “Don’t Allow”.",
            primary: self.btn(text: "Got it, next", .primary, animate: false, async: true),
            image: self.iosVersionImage("AllowScreenTimeAccess"),
          )

        case .onboarding(.happyPath(.explainInstallWithDevicePasscode)):
          ButtonScreenView(
            text: "Great! Half way there. In the next step, use the passcode of THIS DEVICE (the one you’re holding), not your own.",
            primary: self.btn(text: "Got it, next", .primary),
          )

        case .onboarding(.happyPath(.dontGetTrickedPreInstall)):
          ButtonScreenView(
            text: "Again, don’t get tricked! Be sure to click “Allow”, even though it looks like you’re supposed to click “Don’t Allow”.",
            primary: self.btn(text: "Got it, next", .primary, animate: false, async: true),
            image: self.iosVersionImage("AllowContentFilter"),
          )

        case .onboarding(.happyPath(.offerAccountConnect)):
          ButtonScreenView(
            text: self.store.onboarding.connectFeature.offerScreenText ??
              "You can connect this device to a Gertrude parent account for more controls and features.",
            primary: self.btn(
              text: self.store.onboarding.connectFeature.offerScreenSkipBtnText ?? "No thanks",
              .primary,
            ),
            secondary: self.btn(
              text: self.store.onboarding.connectFeature.offerScreenConnectBtnText ??
                "Connect to account",
              .secondary,
              animate: false,
            ),
            tertiary: self.btn(text: "Tell me more", .tertiary),
          )

        case .onboarding(.happyPath(.explainAccountConnect)):
          ButtonScreenView(
            text: self.store.onboarding.connectFeature.explainScreenText ??
              "Connecting to a Gertrude account allows the parent to modify settings remotely after installation, safe-list websites in Safari, and more. It is not required, all the core blocking features will always work without an account or payment.",
            primary: self.btn(text: "Back", .primary),
            secondary: .init(text: "Read the blog post", type: .link(.connect), animate: false),
          )

        case .onboarding(.happyPath(.connectSuccess)):
          ButtonScreenView(
            text: "Success! This device is now connected to your Gertrude parent account.",
            primary: self.btn(text: "Next", .primary),
          )

        case .onboarding(.happyPath(.optOutBlockGroups)):
          ChooseWhatToBlockView(
            deselectedGroups: self.store.disabledBlockGroups,
            onGroupToggle: { self.store.send(.interactive(.blockGroupToggled($0))) },
            onDone: { self.store.send(.interactive(.onboardingBtnTapped(.primary, "Done"))) },
          )

        case .onboarding(.happyPath(.promptClearCache)):
          ButtonScreenView(
            text: "Gertrude is now blocking new content, like when a new and unique search is made for GIFs. But content ALREADY VIEWED will still be visible unless we clear the cache.",
            primary: self.btn(text: "Clear the cache", .primary),
            secondary: self.btn(text: "No need, skip", .secondary),
          )

        case .onboarding(.happyPath(.requestAppStoreRating)):
          ButtonScreenView(
            text: "All set! But, if you’d like to help other parents protect their kids, tap to give us a rating on the App Store.",
            primary: self.btn(text: "Give a rating", .primary),
            secondary: self.btn(text: "Leave a review", .secondary),
            tertiary: self.btn(text: "No thanks", .tertiary),
            screenType: .info,
          )

        case .onboarding(.happyPath(.doneQuit)):
          FinishedView()

        case .onboarding(.authFail(.invalidAccount(.letsFigureThisOut))):
          ButtonScreenView(
            text: "Hmmm... Something didn’t work right, let’s get to the bottom of it.",
            primary: self.btn(text: "Next", .primary),
            screenType: .error,
          )

        case .onboarding(.authFail(.invalidAccount(.confirmInAppleFamily))):
          ButtonScreenView(
            text: "It might be that the Apple Account is not part of an Apple Family. Apple won’t allow the installation if it’s not. Is the Apple Account a member of an Apple Family?",
            primary: self.btn(text: "Yes", .primary),
            secondary: self.btn(text: "No", .secondary),
            tertiary: self.btn(text: "I’m not sure", .tertiary),
            screenType: .error,
          )

        case .onboarding(.authFail(.invalidAccount(.confirmIsMinor))):
          ButtonScreenView(
            text: "Are you sure the birthday on the Apple Account is for someone under 18?\n\nGood to know: Apple does permit the birthday to be changed one time.",
            primary: self.btn(text: "Age is 18 or over", .primary),
            secondary: self.btn(text: "Age is under 18", .secondary),
            screenType: .error,
          )

        case .onboarding(.authFail(.invalidAccount(.unexpected))):
          ButtonScreenView(
            text: "Well gosh, we’re not sure what’s wrong then. Try powering the device off completely, then start the installation again. If you get here again, please contact us for more help using the link below.",
            primary: .init(text: "Contact us", type: .link(.support), animate: false),
            screenType: .error,
          )

        case .onboarding(.authFail(.authCanceled)):
          ButtonScreenView(
            text: "Whoops! Looks like you either clicked the wrong button, or canceled the process mid-way. No problem, we’ll just try again.",
            primary: self.btn(text: "Try again", .primary),
            secondary: .init(text: "Contact us", type: .link(.support), animate: false),
            screenType: .error,
          )

        case .onboarding(.authFail(.restricted)):
          ButtonScreenView(
            text: "A restriction is preventing Gertrude from being installed. Is this device enrolled in mobile device management (MDM) by an organization or school? If so, try again on a device not managed by MDM.",
            primary: .init(text: "Contact support", type: .link(.support), animate: false),
            secondary: self.btn(text: "Start over", .secondary),
            screenType: .error,
          )

        case .onboarding(.authFail(.authConflict)):
          ButtonScreenView(
            text: "We got an error that there was a conflict with another parental controls app. If you know what that might be and can remove it, do so and then try again.",
            primary: self.btn(text: "Done, continue", .primary),
            screenType: .error,
          )

        case .onboarding(.authFail(.networkError)):
          ButtonScreenView(
            text: "Hmmm.. Are you sure you’re connected to the internet? Double-check and try again when you’re online.",
            primary: self.btn(text: "Try again", .primary),
            screenType: .error,
          )

        case .onboarding(.authFail(.passcodeRequired)):
          ButtonScreenView(
            text: "Sorry, Apple won’t let us install unless this device has a passcode set. Go to the Settings app and set one up, then try again.",
            primary: self.btn(text: "Try again", .primary),
            screenType: .error,
          )

        case .onboarding(.authFail(.unexpected)):
          ButtonScreenView(
            text: "Shucks, something went wrong, but we’re not exactly sure what. Please try again, and if you end up here again, contact us for help.",
            primary: self.btn(text: "Try again", .primary),
            secondary: .init(text: "Contact us", type: .link(.support), animate: false),
            screenType: .error,
          )

        case .onboarding(.installFail(.permissionDenied)):
          ButtonScreenView(
            text: "Whoops! Looks like you either clicked the wrong button, or canceled the process mid-way. No problem, we’ll just try again.",
            primary: self.btn(text: "Try again", .primary),
            secondary: .init(text: "Contact us", type: .link(.support), animate: false),
            screenType: .error,
          )

        case .onboarding(.installFail(.other)):
          ButtonScreenView(
            text: "Shucks, something went wrong, but we’re not exactly sure what. Please try again, and if you end up here again, contact us for help.",
            primary: self.btn(text: "Try again", .primary),
            secondary: .init(text: "Contact us", type: .link(.support), animate: false),
            screenType: .error,
          )

        case .onboarding(.onParentDeviceFail):
          ButtonScreenView(
            text: "Gertrude must be installed on the device you want to protect, not on a parent or guardian’s device. Delete the app and start over by installing it on the device you want to protect.",
          )

        case .onboarding(.childIsOnboardingFail):
          ButtonScreenView(
            text: "Setting up Gertrude requires your parent or guardian. Give your device to them so they can finish the setup.",
            primary: self.btn(text: "Done, continue", .primary),
          )

        case .onboarding(.major(.explainHarderButPossible)):
          ButtonScreenView(
            text: "Getting this app working on the device of someone over 18 is harder, but still possible. We’ll walk you through all the steps.",
            primary: self.btn(text: "Next", .primary),
          )

        case .onboarding(.major(.askSelfOrOtherIsOnboarding)):
          ButtonScreenView(
            text: "Is this your device, or are you setting up Gertrude for someone else?",
            primary: self.btn(text: "I’m helping someone else", .secondary),
            secondary: self.btn(text: "This is my device", .tertiary),
            primaryLooksLikeSecondary: true,
          )

        case .onboarding(.major(.askIfOtherIsParent)):
          ButtonScreenView(
            text: "Are you the parent or guardian of the person who owns this device?",
            primary: self.btn(text: "Yes", .primary),
            secondary: self.btn(text: "No", .secondary),
          )

        case .onboarding(.major(.explainFixAccountTypeEasyWay)):
          ButtonScreenView(
            text: "The easiest way to make this work is to get this device signed into an Apple Account that is part of an Apple Family, with a birthday less than 18 years ago. If you can, do that now, then start the installation again, and the setup will be easy.\n\nHow can you do this?",
            primary: self.btn(text: "Done", .primary),
            secondary: self.btn(text: "Is there another way?", .secondary),
            listItems: [
              "Perhaps there is a younger sibling whose account could be used?",
              "Apple does permit changing the birthday one time.",
              "Anyone can create an Apple Family, and invite others to join.",
            ],
          )

        case .onboarding(.major(.askIfOwnsMac)):
          ButtonScreenView(
            text: "Do you own a Mac computer?",
            primary: self.btn(text: "Yes", .primary),
            secondary: self.btn(text: "No", .secondary),
          )

        case .onboarding(.major(.askIfInAppleFamily)),
             .onboarding(.major(.explainAppleFamily)):
          ButtonScreenView(
            text: "Are you in an Apple Family, or could you join one?",
            primary: self.btn(text: "Yes", .primary),
            secondary: self.btn(text: "No", .secondary),
            tertiary: self.btn(text: "What’s an Apple Family?", .tertiary, animate: false),
          )
          .sheet(isPresented: self.explainFamilyPresented) {
            ZStack {
              Color(self.cs, light: .clear, dark: .black).ignoresSafeArea(edges: .all)
              ButtonScreenView(
                text: "An Apple Family group allows sharing of apps and services. There’s no cost, and it’s easy to set one up. You would need someone else to start a group (if they didn’t already have one) and then invite you to join.",
                primary: .init(text: "Instructions", type: .link(.appleFamily), animate: false),
                secondary: self.btn(text: "Continue", .primary, animate: false),
              )
            }
            .presentationDetents([.fraction(0.9)])
          }

        case .onboarding(.appleFamily(.explainRequiredForFiltering)):
          ButtonScreenView(
            text: "Sorry, Apple doesn’t allow a content blocker to be installed on a device that’s not in an Apple Family.",
            primary: self.btn(text: "Next", .primary),
          )

        case .onboarding(.appleFamily(.explainSetupFreeAndEasy)):
          ButtonScreenView(
            text: "Luckily, setting up an Apple family only takes a few minutes, and it’s free.",
            primary: self.btn(text: "Next", .primary),
          )

        case .onboarding(.appleFamily(.howToSetupAppleFamily)):
          ButtonScreenView(
            text: "You’ll need to start the setup on your iPhone or Mac.",
            primary: .init(text: "Instructions", type: .link(.appleFamily), animate: false),
            secondary: .init(
              text: "Send me the info",
              type: .share(URL.appleFamily.absoluteString),
              animate: false,
            ),
            tertiary: self.btn(text: "Done, continue", .tertiary),
          )

        case .onboarding(.appleFamily(.explainWhatIsAppleFamily)):
          ButtonScreenView(
            text: "An Apple Family group allows sharing of apps and services, plus it gives parents additional controls over their kids devices. There’s no cost, and it’s easy to set one up.",
            primary: self.btn(text: "Next", .primary),
          )

        case .onboarding(.appleFamily(.checkIfInAppleFamily)):
          ButtonScreenView(
            text: "You can check if you’re already setup by opening the “Settings” app on this device. If you see a “Family” section right below the Apple Account name and picture, you’re already set.",
            primary: self.btn(text: "Yes, in a family", .primary),
            secondary: self.btn(text: "Not in a family yet", .secondary),
          )

        // supervision setup

        // TODO: superios finalize screen text
        case .onboarding(.supervision(.setup(.harderButPossible))):
          ButtonScreenView(
            text: "Getting this working on a device for someone 18 or older is harder, but we have some options. Let's walk through them.",
            primary: self.btn(text: "Next", .primary),
          )

        // TODO: superios finalize screen text
        case .onboarding(.supervision(.setup(.explainSupervisionConcept))):
          ButtonScreenView(
            text: "The solution is to put your device into \"supervised mode.\" This is a special mode that gives an administrator more control over the device.",
            primary: self.btn(text: "Next", .primary),
          )

        // TODO: superios finalize screen text
        case .onboarding(.supervision(.setup(.explainSupervisionOptions))):
          ButtonScreenView(
            text: "There are two ways to supervise your device: using our Gertrude tool ($10/year, easier), or Apple Configurator (free, but requires erasing your device).",
            primary: self.btn(text: "Next", .primary),
          )

        // TODO: superios finalize screen text
        case .onboarding(.supervision(.setup(.offerWorkaround))):
          ButtonScreenView(
            text: "But wait—there might be an easier way that doesn't require supervision at all.",
            primary: self.btn(text: "Tell me more", .primary),
          )

        // TODO: superios finalize screen text
        case .onboarding(.supervision(.setup(.explainSiblingWorkaround))):
          ButtonScreenView(
            text: "If you have a younger sibling (under 18) whose Apple Account is in your Apple Family, you could sign into their account on this device. Gertrude would then work without supervision.",
            primary: self.btn(text: "That would work for me", .primary),
            secondary: self.btn(text: "What else?", .secondary),
          )

        // TODO: superios finalize screen text
        case .onboarding(.supervision(.setup(.siblingWorkaroundInstructions))):
          ButtonScreenView(
            text: "To switch accounts: Go to Settings, tap your name at the top, scroll down and tap Sign Out. Then sign in with your family member's Apple ID and come back to this app.",
            primary: self.btn(text: "I've switched accounts", .primary),
          )

        // TODO: superios finalize screen text
        case .onboarding(.supervision(.setup(.explainBirthdayWorkaround))):
          ButtonScreenView(
            text: "Apple allows changing your Apple ID birthday one time. If you changed it to under 18, Gertrude would work without supervision.",
            primary: self.btn(text: "That would work for me", .primary),
            secondary: self.btn(text: "Neither works for me", .secondary),
          )

        // TODO: superios finalize screen text
        case .onboarding(.supervision(.setup(.birthdayWorkaroundInstructions))):
          ButtonScreenView(
            text: "To change your birthday: Go to Settings, tap your name, then Personal Information, then Birthday. Change it so you're under 18, then come back to this app.",
            primary: self.btn(text: "I've updated my birthday", .primary),
          )

        // TODO: superios finalize screen text
        case .onboarding(.supervision(.setup(.chooseSupervisionPath))):
          ButtonScreenView(
            text: "Choose how you'd like to supervise your device:",
            primary: self.btn(text: "Use Gertrude tool ($10/yr)", .primary),
            secondary: self.btn(text: "Use Apple Configurator (free)", .secondary),
            listItems: [
              "Gertrude tool: Easier, no device erase, $10/year",
              "Apple Configurator: Free, but requires Mac and device erase",
            ],
          )

        // TODO: superios finalize screen text
        case .onboarding(.supervision(.setup(.appleConfiguratorInstructions))):
          ButtonScreenView(
            text: "We have a tutorial and a step-by-step video to guide you through the Apple Configurator process.",
            primary: .init(text: "Instructions", type: .link(.supervisionTutorial), animate: false),
            secondary: .init(
              text: "Send the link",
              type: .share(URL.supervisionTutorial.absoluteString),
              animate: false,
            ),
          )

        // TODO: superios finalize screen text
        case .onboarding(.supervision(.setup(.askHasProtector))):
          ButtonScreenView(
            text: "Do you have someone who can help manage your device? This could be a parent, spouse, friend, or accountability partner.",
            primary: self.btn(text: "Yes, I have someone", .primary),
            secondary: self.btn(text: "No, I want to manage myself", .secondary),
          )

        // TODO: superios finalize screen text
        case .onboarding(.supervision(.setup(.selfManagementPlaceholder))):
          ButtonScreenView(
            text: "Self-management is coming soon! For now, you'll need someone else to help supervise your device. We're working on a solution for self-management.",
            primary: self.btn(text: "Start over", .primary),
            secondary: .init(text: "Contact support", type: .link(.support), animate: false),
          )

        // TODO: superios finalize screen text
        case .onboarding(.supervision(.setup(.generateSetupCode(let didError)))):
          SpinnerErrorView(
            loadingText: "Generating your setup code...",
            errorText: "Something went wrong generating your setup code. Please try again.",
            isError: didError,
            onRetry: { self.store.send(.interactive(.onboardingBtnTapped(.primary, "Retry"))) },
          )

        // TODO: superios finalize screen text
        case .onboarding(.supervision(.setup(.instructionsForProtector(let code)))):
          InstructionsForProtectorView(
            code: code,
            onNext: { self.store.send(.interactive(.onboardingBtnTapped(.primary, "Next"))) },
          )

        // TODO: superios finalize screen text
        case .onboarding(.supervision(.setup(.waitingForSupervision(let code)))):
          WaitingForSupervisionView(code: code)

        // supervision resume

        case .onboarding(.supervision(.resume(.codeClaimedNotSupervised(let regainedFocus)))):
          ButtonScreenView(
            text: "Hmmm... We're not sure if this device is supervised yet. Open the Settings app and check if it says at the top of the main screen that the device is supervised, then come back here.",
            primary: self.btn(text: "Yes, it says supervised", .primary, disabled: !regainedFocus),
            secondary: self.btn(
              text: "No, I don't see anything",
              .secondary,
              disabled: !regainedFocus,
            ),
            screenType: .question,
            primaryLooksLikeSecondary: true,
          )

        // TODO: superios finalize screen text
        case .onboarding(.supervision(.resume(.retrySupervision))):
          ButtonScreenView(
            text: "No worries. Let's try setting up supervision again.",
            primary: self.btn(text: "Next", .primary),
          )

        // TODO: superios finalize screen text
        case .onboarding(.supervision(.resume(.codeNotClaimed))):
          ButtonScreenView(
            text: "Hmmm... your supervision setup code hasn't been claimed yet. Let's try again.",
            primary: self.btn(text: "Next", .primary),
          )

        // TODO: superios finalize screen text
        case .onboarding(.supervision(.resume(.promptInstallProfile))):
          ButtonScreenView(
            text: "One more step: we need to install a configuration profile to enable content filtering.",
            primary: self.btn(text: "Next", .primary),
          )

        // TODO: superios finalize screen text
        case .onboarding(.supervision(.resume(.explainProfileDownload))):
          ButtonScreenView(
            text: "When the browser opens, tap \"Allow\" to download the profile.",
            primary: self.btn(text: "Got it", .primary),
          )

        case .onboarding(.supervision(.resume(.installingProfile(let profileUrl)))):
          ProfileDownloadView(profileUrl: profileUrl, osMajorVersion: self.osMajorVersion) {
            self.store.send(.interactive(.onboardingBtnTapped(.primary, "Safari dismissed")))
          }

        // TODO: superios finalize screen text + add graphic asset
        case .onboarding(.supervision(.resume(.explainProfileInstall(let regainedFocus)))):
          ButtonScreenView(
            text: "Now, open the Settings app:",
            primary: self.btn(text: "Done, continue", .primary, disabled: !regainedFocus),
            listItems: [
              "Tap \"Profile Downloaded\" at top",
              "Tap \"Install\"",
              "Enter your passcode",
              "Come back to this app",
            ],
          )

        case .onboarding(.supervision(.resume(.verifyingProfileInstall(let didError)))):
          // TODO: superios finalize screen text
          SpinnerErrorView(
            loadingText: "Verifying profile installation...",
            errorText: "Profile not detected. Make sure you installed the profile in Settings.",
            isError: didError,
            onRetry: { self.store.send(.interactive(.onboardingBtnTapped(.primary, "Retry"))) },
          )

        // TODO: superios finalize screen text
        case .onboarding(.supervision(.resume(.profileInstalled))):
          ButtonScreenView(
            text: "Profile installed successfully! Content filtering is now active.",
            primary: self.btn(text: "Next", .primary),
          )

        // TODO: superios finalize screen text
        case .onboarding(.supervision(.resume(.setupComplete))):
          ButtonScreenView(
            text: "You're all set! Gertrude is now protecting your device.",
            primary: self.btn(text: "Done", .primary),
          )

        case .supervisionSuccessFirstLaunch:
          ButtonScreenView(
            text: "Excellent! Looks like you’ve installed Gertrude under Supervised mode. Just a couple steps to get you all set up.",
            primary: self.btn(text: "Next", .primary),
          )

        case .running:
          RunningView(store: self.store)
            .onShake { self.store.send(.interactive(.receivedShake)) }
        }
      }
    }
    .sheet(item: self.$store.scope(
      state: \.destination?.connectAccount,
      action: \.destination.connectAccount,
    )) {
      ConnectingView(
        store: $0,
        infoBlurb: self.store.onboarding.connectFeature.connectAccountSheetInfoBlurb,
      )
    }
    .sheet(item: self.$store.scope(
      state: \.destination?.info,
      action: \.destination.info,
    )) { store in
      InfoView(store: store)
        .onAppear { store.send(.sheetPresented) }
        .onShake { store.send(.receivedShake) }
    }
  }

  var explainFamilyPresented: Binding<Bool> {
    .init(
      get: { self.store.screen == .onboarding(.major(.explainAppleFamily)) },
      set: { presented in if !presented { self.store.send(.interactive(.sheetDismissed)) } },
    )
  }

  func btn(
    text: String,
    _ type: ButtonType,
    animate: Bool = true,
    async: Bool = false,
    disabled: Bool = false,
  ) -> ButtonScreenView.Config {
    .init(text, animate: animate, asyncAction: async, disabled: disabled) {
      switch type {
      case .primary:
        self.store.send(.interactive(.onboardingBtnTapped(.primary, text)))
      case .secondary:
        self.store.send(.interactive(.onboardingBtnTapped(.secondary, text)))
      case .tertiary:
        self.store.send(.interactive(.onboardingBtnTapped(.tertiary, text)))
      }
    }
  }

  func iosVersionImage(_ baseName: String) -> String {
    self.osMajorVersion >= 26 ? "\(baseName)IOS26" : baseName
  }

  enum ButtonType {
    case primary
    case secondary
    case tertiary
  }
}

extension URL {
  static let support = URL(string: "https://gertrude.app/iosapp-contact")!
  static let connect = URL(string: "https://gertrude.app/iosapp-connect")!
  static let supervisionTutorial = URL(string: "https://gertrude.app/iosapp-supervise")!
  static let appleFamily = URL(string: "https://gertrude.app/iosapp-apple-fam")!
}

#Preview {
  AppView(
    store: Store(initialState: IOSReducer.State()) {
      IOSReducer()
    },
    osMajorVersion: 26,
  )
}

#Preview("Profile Flow: Prompt Install") {
  AppView(
    store: Store(initialState: IOSReducer.State(
      screen: .onboarding(.supervision(.resume(.promptInstallProfile))),
    )) {
      IOSReducer()
    },
    osMajorVersion: 26,
  )
}

#Preview("Profile Flow: Explain Download") {
  AppView(
    store: Store(initialState: IOSReducer.State(
      screen: .onboarding(.supervision(.resume(.explainProfileDownload))),
    )) {
      IOSReducer()
    },
    osMajorVersion: 26,
  )
}

#Preview("Profile Flow: Installing") {
  AppView(
    store: Store(initialState: IOSReducer.State(
      screen: .onboarding(.supervision(.resume(.installingProfile(
        profileUrl: URL(string: "https://api.gertrude.app/ios-device-profile/test-id")!,
      )))),
    )) {
      IOSReducer()
    },
    osMajorVersion: 26,
  )
}

#Preview("Profile Flow: Explain Install") {
  AppView(
    store: Store(initialState: IOSReducer.State(
      screen: .onboarding(.supervision(.resume(.explainProfileInstall()))),
    )) {
      IOSReducer()
    },
    osMajorVersion: 26,
  )
}

#Preview("Profile Flow: Verifying") {
  AppView(
    store: Store(initialState: IOSReducer.State(
      screen: .onboarding(.supervision(.resume(.verifyingProfileInstall()))),
    )) {
      IOSReducer()
    },
    osMajorVersion: 26,
  )
}

#Preview("Profile Flow: Verifying Error") {
  AppView(
    store: Store(initialState: IOSReducer.State(
      screen: .onboarding(.supervision(.resume(.verifyingProfileInstall(didError: true)))),
    )) {
      IOSReducer()
    },
    osMajorVersion: 26,
  )
}
