import ComposableArchitecture
import GertieApp
import GertieTcaFeatures
import GertieUI
import LibApp
import SwiftUI

public struct AppView: View {
  @Bindable var store: StoreOf<IOSReducer>
  let osMajorVersion: Int
  let deviceType: String

  public init(store: StoreOf<IOSReducer>, osMajorVersion: Int, deviceType: String) {
    self.store = store
    self.osMajorVersion = osMajorVersion
    self.deviceType = deviceType
  }

  public var body: some View {
    Group {
      if let clearCacheStore = self.store.scope(
        state: \.onboarding.clearCache,
        action: \.interactive.onboardingClearCache,
      ) {
        ClearingCacheView(
          store: clearCacheStore,
          clearedMessage: "Previously downloaded GIFs should be gone!",
          clearedBtnLabel: "Next",
        )
        .onAppear { clearCacheStore.send(.onAppear) }
      } else if let crossPromoStore = self.store.scope(
        state: \.onboarding.crossPromo,
        action: \.interactive.onboardingCrossPromo,
      ) {
        CrossPromoView(store: crossPromoStore)
      } else if let connectStore = self.store.scope(
        state: \.onboarding.connect,
        action: \.interactive.onboardingConnect,
      ) {
        ConnectingView(
          store: connectStore,
          infoBlurb: self.store.onboarding.connectFeature.connectAccountSheetInfoBlurb,
          deviceType: self.deviceType,
        )
      } else {
        switch self.store.screen {
        case .launching: EmptyView()

        case .onboarding(.happyPath(.hiThere)):
          GertieWelcomeScreen(
            greeting: "Hi there!",
            message: "Gertrude blocks unwanted stuff, like GIFs, from your device.",
            actionTitle: "Get started",
          ) {
            self.store.send(.interactive(.onboardingBtnTapped(.primary, "Get Started")))
          }
          .onShake {
            #if DEBUG
              self.store.send(.interactive(.receivedShake))
            #endif
          }

        case .onboarding(.happyPath(.timeExpectation)):
          GertieActionScreen(
            message: "The setup usually takes about 5-7 minutes, but in some cases extra steps are required.",
            action: self.action(text: "Next", .primary),
            accessibilityIdentifier: "onboarding-screen-time-expectation",
          )

        case .onboarding(.happyPath(.confirmChildsDevice)):
          GertieActionScreen(
            message: "Is this the \(self.deviceType) you want to protect?",
            actions: [
              self.action(text: "Yes", .primary),
              self.action(text: "No", .secondary),
            ],
            accessibilityIdentifier: "onboarding-screen-confirm-childs-device",
          )

        case .onboarding(.happyPath(.explainPermissionDependsOnAge)):
          GertieActionScreen(
            message: "To protect privacy, Apple requires special permission before we can block unwanted internet access. How we get that permission depends on the AGE of the \(self.deviceType) user.",
            action: self.action(text: "Got it, next", .primary),
            accessibilityIdentifier: "onboarding-screen-explain-permission-depends-on-age",
          )

        case .onboarding(.happyPath(.confirmMinorDevice)):
          GertieActionScreen(
            message: "How old is the user of this \(self.deviceType)?",
            actions: [
              self.action(text: "Under 18", .primary, emphasis: .secondary),
              self.action(text: "18 or older", .secondary),
            ],
            accessibilityIdentifier: "onboarding-screen-confirm-minor-device",
          )

        case .onboarding(.happyPath(.confirmParentIsOnboarding)):
          GertieActionScreen(
            message: "Are you the parent or guardian?",
            actions: [
              self.action(text: "Yes", .primary),
              self.action(text: "No", .secondary),
            ],
            accessibilityIdentifier: "onboarding-screen-confirm-parent-is-onboarding",
          )

        case .onboarding(.happyPath(.confirmInAppleFamily)):
          GertieActionScreen(
            message: "Apple also requires that the child’s \(self.deviceType) be part of an Apple Family. Is the Apple Account for this \(self.deviceType) already in an Apple Family?",
            actions: [
              self.action(text: "Yes, it’s in an Apple Family", .primary),
              self.action(text: "No", .secondary),
              self.action(text: "I’m not sure", .tertiary),
            ],
            accessibilityIdentifier: "onboarding-screen-confirm-in-apple-family",
          )

        case .onboarding(.happyPath(.explainTwoInstallSteps)):
          GertieActionScreen(
            message: "Next we’ll authorize and install the content filter. It takes TWO steps, both of which are required.",
            action: self.action(text: "Next", .primary),
            accessibilityIdentifier: "onboarding-screen-explain-two-install-steps",
          )

        case .onboarding(.happyPath(.explainAuthWithParentAppleAccount)):
          GertieActionScreen(
            message: "For the first step, you’ll authorize Gertrude to access Screen Time using YOUR Apple ID (the parent/guardian, not the child’s).",
            action: self.action(text: "Got it, next", .primary),
            accessibilityIdentifier: "onboarding-screen-explain-auth-with-parent-apple-account",
          )

        case .onboarding(.happyPath(.dontGetTrickedPreAuth)):
          GertieActionScreen(
            message: "Don’t get tricked! Be sure to click “Continue”, even though it looks like you’re supposed to click “Don’t Allow”.",
            action: self.action(text: "Got it, next", .primary, behavior: .showProgress),
            accessibilityIdentifier: "onboarding-screen-dont-get-tricked-pre-auth",
            supplementPlacement: .beforeMessage,
          ) {
            OnboardingInstructionImage(
              name: self.iosVersionImage("AllowScreenTimeAccess"),
              accessibilityLabel: "Screen Time permission alert showing the Continue button",
            )
          }

        case .onboarding(.happyPath(.explainInstallWithDevicePasscode)):
          GertieActionScreen(
            message: "Great! Half way there. In the next step, use the passcode of THIS \(self.deviceType.uppercased()) (the one you’re holding), not your own.",
            action: self.action(text: "Got it, next", .primary),
            accessibilityIdentifier: "onboarding-screen-explain-install-with-device-passcode",
          )

        case .onboarding(.happyPath(.dontGetTrickedPreInstall)):
          GertieActionScreen(
            message: "Again, don’t get tricked! Be sure to click “Allow”, even though it looks like you’re supposed to click “Don’t Allow”.",
            action: self.action(text: "Got it, next", .primary, behavior: .showProgress),
            accessibilityIdentifier: "onboarding-screen-dont-get-tricked-pre-install",
            supplementPlacement: .beforeMessage,
          ) {
            OnboardingInstructionImage(
              name: self.iosVersionImage("AllowContentFilter"),
              accessibilityLabel: "Content Filter permission alert showing the Allow button",
            )
          }

        case .onboarding(.happyPath(.offerAccountConnect)):
          GertieActionScreen(
            message: self.store.onboarding.connectFeature.offerScreenText ??
              "You can connect this device to a Gertrude parent account for more controls and features.",
            actions: [
              self.action(
                text: self.store.onboarding.connectFeature.offerScreenConnectBtnText ??
                  "Connect to account",
                .primary,
              ),
              self.action(
                text: self.store.onboarding.connectFeature.offerScreenSkipBtnText ?? "No thanks",
                .secondary,
              ),
              self.action(text: "Tell me more", .tertiary),
            ],
            accessibilityIdentifier: "onboarding-screen-offer-account-connect",
          )

        case .onboarding(.happyPath(.explainAccountConnect)):
          GertieActionScreen(
            message: self.store.onboarding.connectFeature.explainScreenText ??
              "Connecting to a Gertrude account allows the parent to modify settings remotely after installation, safe-list websites in Safari, and more. It is not required, all the core blocking features will always work without an account or payment.",
            actions: [
              self.action(text: "Back", .primary),
              .link("Read the blog post", destination: .connect),
            ],
          )

        case .onboarding(.happyPath(.connectSuccess)):
          AccountConnectionSuccessView(deviceType: self.deviceType) {
            self.store.send(.interactive(.onboardingBtnTapped(.primary, "Next")))
          }

        case .onboarding(.happyPath(.optOutBlockGroups)):
          ChooseWhatToBlockView(
            allGroups: self.store.allBlockGroups,
            disabledGroupIds: self.store.disabledBlockGroupIds,
            onGroupToggle: { self.store.send(.interactive(.blockGroupToggled($0))) },
            onDone: { self.store.send(.interactive(.onboardingBtnTapped(.primary, "Done"))) },
          )

        case .onboarding(.happyPath(.promptClearCache)),
             .onboarding(.supervision(.resume(.promptClearCache))):
          GertieActionScreen(
            message: "Gertrude is now blocking new content, like when a new and unique search is made for GIFs. But content ALREADY VIEWED will still be visible unless we clear the cache.",
            actions: [
              self.action(text: "Clear the cache", .primary),
              self.action(text: "No need, skip", .secondary),
            ],
          )

        case .onboarding(.happyPath(.requestAppStoreRating)):
          GertieActionScreen(
            message: "All set! But, if you’d like to help other parents protect their kids, tap to give us a rating on the App Store.",
            actions: [
              self.action(text: "Give a rating", .primary),
              self.action(text: "Leave a review", .secondary),
              self.action(text: "No thanks", .tertiary),
            ],
          )

        case .onboarding(.happyPath(.doneQuit)):
          GertieResultScreen(
            icon: "party.popper",
            title: "Quit the app, you’re done!",
            message: "Gertrude will keep blocking even when the app is not running.",
          )

        case .onboarding(.authFail(.invalidAccount(.letsFigureThisOut))):
          GertieActionScreen(
            message: "Hmmm... Something didn’t work right, let’s get to the bottom of it.",
            icon: .error,
            action: self.action(text: "Next", .primary),
          )

        case .onboarding(.authFail(.invalidAccount(.confirmInAppleFamily))):
          GertieActionScreen(
            message: "It might be that the Apple Account is not part of an Apple Family. Apple won’t allow the installation if it’s not. Is the Apple Account a member of an Apple Family?",
            icon: .error,
            actions: [
              self.action(text: "Yes", .primary),
              self.action(text: "No", .secondary),
              self.action(text: "I’m not sure", .tertiary),
            ],
          )

        case .onboarding(.authFail(.invalidAccount(.confirmIsMinor))):
          GertieActionScreen(
            message: "Are you sure the birthday on the Apple Account is for someone under 18?\n\nGood to know: Apple does permit the birthday to be changed one time.",
            icon: .error,
            actions: [
              self.action(text: "Age is 18 or over", .primary),
              self.action(text: "Age is under 18", .secondary),
            ],
          )

        case .onboarding(.authFail(.invalidAccount(.unexpected))):
          GertieActionScreen(
            message: "Well gosh, we’re not sure what’s wrong then. Try powering the \(self.deviceType) off completely, then start the installation again. If you get here again, please contact us for more help using the link below.",
            icon: .error,
            action: .link("Contact us", destination: .support),
          )

        case .onboarding(.authFail(.authCanceled)):
          GertieActionScreen(
            message: "Whoops! Looks like you either clicked the wrong button, or canceled the process mid-way. No problem, we’ll just try again.",
            icon: .error,
            actions: [
              self.action(text: "Try again", .primary),
              .link("Contact us", destination: .support),
            ],
          )

        case .onboarding(.authFail(.restricted)):
          GertieActionScreen(
            message: "A restriction is preventing Gertrude from being installed. Is this \(self.deviceType) enrolled in mobile device management (MDM) by an organization or school? If so, try again on a device not managed by MDM.",
            icon: .error,
            actions: [
              .link("Contact support", destination: .support),
              self.action(text: "Start over", .secondary),
            ],
          )

        case .onboarding(.authFail(.authConflict)):
          GertieActionScreen(
            message: "We got an error that there was a conflict with another parental controls app. If you know what that might be and can remove it, do so and then try again.",
            icon: .error,
            action: self.action(text: "Done, continue", .primary),
          )

        case .onboarding(.authFail(.networkError)):
          AuthorizationNetworkErrorView {
            self.store.send(.interactive(.onboardingBtnTapped(.primary, "Try again")))
          }

        case .onboarding(.authFail(.passcodeRequired)):
          GertieActionScreen(
            message: "Sorry, Apple won’t let us install unless this \(self.deviceType) has a passcode set. Go to the Settings app and set one up, then try again.",
            icon: .error,
            action: self.action(text: "Try again", .primary),
          )

        case .onboarding(.authFail(.unexpected)):
          GertieActionScreen(
            message: "Shucks, something went wrong, but we’re not exactly sure what. Please try again, and if you end up here again, contact us for help.",
            icon: .error,
            actions: [
              self.action(text: "Try again", .primary),
              .link("Contact us", destination: .support),
            ],
          )

        case .onboarding(.installFail(.permissionDenied)):
          GertieActionScreen(
            message: "Whoops! Looks like you either clicked the wrong button, or canceled the process mid-way. No problem, we’ll just try again.",
            icon: .error,
            actions: [
              self.action(text: "Try again", .primary),
              .link("Contact us", destination: .support),
            ],
          )

        case .onboarding(.installFail(.other)):
          GertieActionScreen(
            message: "Shucks, something went wrong, but we’re not exactly sure what. Please try again, and if you end up here again, contact us for help.",
            icon: .error,
            actions: [
              self.action(text: "Try again", .primary),
              .link("Contact us", destination: .support),
            ],
          )

        case .onboarding(.onParentDeviceFail):
          GertieActionScreen(
            message: "Gertrude must be installed on the device you want to protect, not on a parent or guardian’s device. Delete the app and start over by installing it on the device you want to protect.",
          )

        case .onboarding(.mdmSupervisionExplainer):
          GertieActionScreen(
            message: "Gertrude’s content filter for adults (18+) requires a supervised device, per Apple’s own rules. This process is not compatible with MDM-managed devices.\n\nTo use this app, you’ll need a personal device that is not managed by an organization.",
            action: self.action(text: "OK", .primary),
          )

        case .onboarding(.childIsOnboardingFail):
          GertieActionScreen(
            message: "Setting up Gertrude requires your parent or guardian. Give your \(self.deviceType) to them so they can finish the setup.",
            action: self.action(text: "Done, continue", .primary),
          )

        case .onboarding(.appleFamily(.explainRequiredForFiltering)):
          GertieActionScreen(
            message: "Sorry, Apple doesn’t allow a content blocker to be installed on a device that’s not in an Apple Family.",
            action: self.action(text: "Next", .primary),
          )

        case .onboarding(.appleFamily(.explainSetupFreeAndEasy)):
          GertieActionScreen(
            message: "Luckily, setting up an Apple family only takes a few minutes, and it’s free.",
            action: self.action(text: "Next", .primary),
          )

        case .onboarding(.appleFamily(.howToSetupAppleFamily)):
          GertieActionScreen(
            message: "You’ll need to start the setup on your iPhone or Mac.",
            actions: [
              .link("Instructions", destination: .appleFamily),
              .share("Send me the info", item: URL.appleFamily.absoluteString),
              self.action(text: "Done, continue", .tertiary),
            ],
          )

        case .onboarding(.appleFamily(.explainWhatIsAppleFamily)):
          GertieActionScreen(
            message: "An Apple Family group allows sharing of apps and services, plus it gives parents additional controls over their kids devices. There’s no cost, and it’s easy to set one up.",
            action: self.action(text: "Next", .primary),
          )

        case .onboarding(.appleFamily(.checkIfInAppleFamily)):
          GertieActionScreen(
            message: "You can check if you’re already setup by opening the Settings app on this \(self.deviceType). If you see a Family section right below the Apple Account name and picture, you’re already set.",
            actions: [
              self.action(text: "Yes, in a family", .primary),
              self.action(text: "Not in a family yet", .secondary),
            ],
          )

        // supervision setup

        case .onboarding(.supervision(.setup(.adultNeedsSupervision))):
          GertieActionScreen(
            message: "Got it, over 18. So for adults, Apple doesn’t allow internet blocking unless the \(self.deviceType) is put into a special mode called SUPERVISED MODE.",
            action: self.action(text: "Tell me more", .primary),
          )

        case .onboarding(.supervision(.setup(.whatIsSupervisedMode))):
          GertieActionScreen(
            message: "Supervised mode was originally designed for devices owned by schools and businesses. It allows access to settings and features that normal devices don’t have.",
            action: self.action(text: "Next", .primary),
          )

        case .onboarding(.supervision(.setup(.supervisedDeviceReassurance))):
          GertieActionScreen(
            message: "Other than allowing access to these extra features and controls, a supervised \(self.deviceType) is the same as any other \(self.deviceType). You get to decide which extra features to use.",
            action: self.action(text: "Next", .primary),
          )

        case .onboarding(.supervision(.setup(.explainSupervision))):
          GertieActionScreen(
            message: "So, to get Gertrude blocking unwanted content for you, we’ll need this \(self.deviceType) to be in supervised mode, which takes a little more up-front setup.",
            action: self.action(text: "Got it, next", .primary),
          )

        case .onboarding(.supervision(.setup(.costAndBranchPoint))):
          GertieActionScreen(
            message: "The easiest way to supervise a device is with a Gertrude account ($10/year).\n\nThere are free alternatives, but they have downsides.",
            actions: [
              self.action(text: "Continue with Gertrude", .primary),
              self.action(text: "Show me the free alternatives", .secondary),
            ],
          )

        case .onboarding(.supervision(.setup(.freeAlternativesHub))):
          FreeAlternativesHubView(
            onBirthdayTapped: {
              self.store.send(.interactive(.onboardingBtnTapped(.primary, "Birthday")))
            },
            onSiblingTapped: {
              self.store.send(.interactive(.onboardingBtnTapped(.secondary, "Sibling")))
            },
            onAppleConfiguratorTapped: {
              self.store.send(.interactive(.onboardingBtnTapped(.tertiary, "Apple Configurator")))
            },
            onGertrudeTapped: {
              self.store.send(.interactive(.onboardingBtnTapped(.quaternary, "Gertrude")))
            },
          )

        case .onboarding(.supervision(.setup(.birthdayAlternativeExplain))):
          GertieActionScreen(
            message: "Apple allows you to change your Apple Account birthday one time. If you change it to make yourself under 18, Gertrude will work without supervision.",
            actions: [
              self.action(text: "What are the downsides?", .primary),
              self.action(text: "Back to alternatives", .secondary),
            ],
          )

        case .onboarding(.supervision(.setup(.birthdayAlternativeCons))):
          GertieActionScreen(
            message: "You’ll be treated as a child in Apple’s system:",
            icon: .error,
            bullets: [
              "You’ll need to be a part of an Apple Family",
              "Purchases may need approval",
              "You can’t be a family organizer",
              "Can be hard to undo later",
            ],
            actions: [
              self.action(text: "This works for me", .primary),
              self.action(text: "Back to alternatives", .secondary),
            ],
          )

        case .onboarding(.supervision(.setup(.birthdayAlternativeInstructions))):
          GertieActionScreen(
            message: "To change your birthday: Go to Settings, tap your name, then Personal Information, then Birthday. Change it so you’re under 18, then come back to this app.",
            action: self.action(text: "I’ve updated my birthday", .primary),
          )

        case .onboarding(.supervision(.setup(.siblingAlternativeExplain))):
          GertieActionScreen(
            message: "If you have a younger sibling (under 18) in your Apple Family, you can sign into their Apple Account on this \(self.deviceType). Gertrude will then work without supervision.",
            actions: [
              self.action(text: "What are the downsides?", .primary),
              self.action(text: "Back to alternatives", .secondary),
            ],
          )

        case .onboarding(.supervision(.setup(.siblingAlternativeCons))):
          GertieActionScreen(
            message: "This \(self.deviceType) becomes your sibling’s in Apple’s eyes:",
            icon: .error,
            bullets: [
              "iMessage and FaceTime use their account",
              "App purchases go to their account",
              "Other data may mix or sync",
            ],
            actions: [
              self.action(text: "This works for me", .primary),
              self.action(text: "Back to alternatives", .secondary),
            ],
          )

        case .onboarding(.supervision(.setup(.siblingAlternativeInstructions))):
          GertieActionScreen(
            message: "To switch accounts: Go to Settings, tap your name at the top, scroll down and tap Sign Out. Then sign in with your sibling’s Apple ID and come back to this app.",
            action: self.action(text: "I’ve switched accounts", .primary),
          )

        case .onboarding(.supervision(.setup(.accountNowUnder18))):
          GertieActionScreen(
            message: "Great! Assuming the account is now set up as under 18, we can proceed with the standard setup.",
            action: self.action(text: "Continue", .primary),
          )

        case .onboarding(.supervision(.setup(.appleConfiguratorExplain))):
          GertieActionScreen(
            message: "You can use Apple’s free tool called Apple Configurator to supervise your own \(self.deviceType). This gives you full control without needing a Gertrude account.",
            actions: [
              self.action(text: "What are the downsides?", .primary),
              self.action(text: "Back to alternatives", .secondary),
            ],
          )

        case .onboarding(.supervision(.setup(.appleConfiguratorCons(let step)))):
          switch step {
          case 1:
            GertieActionScreen(
              message: "This method requires completely erasing this \(self.deviceType). You can restore from a backup afterward, but sometimes a few customizations can be lost.",
              icon: .error,
              actions: [
                self.action(text: "Next", .primary),
                self.action(text: "Back to alternatives", .secondary),
              ],
            )
          case 2:
            GertieActionScreen(
              message: "You’ll need a Mac computer and physical access to this \(self.deviceType) every time you want to make changes to the supervision settings.",
              icon: .error,
              actions: [
                self.action(text: "Next", .primary),
                self.action(text: "Back to alternatives", .secondary),
              ],
            )
          default:
            GertieActionScreen(
              message: "The process takes about an hour, and is slightly technical, compared to ~5 minutes with Gertrude. Ready to proceed?",
              icon: .error,
              actions: [
                .link("Show me how", destination: .supervisionTutorial),
                self.action(text: "Back to alternatives", .secondary),
              ],
            )
          }

        case .onboarding(.supervision(.setup(.explainNeedSomeoneElse))):
          GertieActionScreen(
            message: "A supervised \(self.deviceType) needs someone ELSE to manage it—typically a parent, spouse, or accountability partner. They’ll need to plug this \(self.deviceType) into a computer to get started.",
            actions: [
              self.action(text: "Got it, no problem", .primary),
              self.action(text: "I need to manage myself", .secondary),
            ],
          )

        case .onboarding(.supervision(.setup(.selfManagementPlaceholder))):
          GertieActionScreen(
            message: "Self-management is coming soon! For now, you’ll need someone else to help supervise your \(self.deviceType). We’re working on a solution for self-management.",
            actions: [
              self.action(text: "Start over", .primary),
              .link("Contact support", destination: .support),
            ],
          )

        case .onboarding(.supervision(.setup(.generateSetupCode(let didError)))):
          SpinnerErrorView(
            loadingText: "Generating your setup code...",
            errorTitle: "Couldn’t generate a setup code",
            errorMessage: "Please try again.",
            isError: didError,
            onRetry: { self.store.send(.interactive(.onboardingBtnTapped(.primary, "Retry"))) },
          )

        case .onboarding(.supervision(.setup(.instructionsForProtector(let code)))):
          InstructionsForProtectorView(
            code: code,
            onNext: { self.store.send(.interactive(.onboardingBtnTapped(.primary, "Next"))) },
          )

        case .onboarding(.supervision(.setup(.waitingForSupervision(let code)))):
          WaitingForSupervisionView(code: code)

        // supervision resume

        case .onboarding(.supervision(.resume(.codeClaimedNotSupervised))):
          GertieActionScreen(
            message: "We haven’t been able to confirm that this \(self.deviceType) is supervised yet. To finish, a parent needs to connect this \(self.deviceType) to a computer and complete supervision with the Gertrude supervision tool. Once that’s done, tap below to check again, or contact us if you’re stuck.",
            actions: [
              self.action(text: "Check again", .primary),
              .link("Contact support", destination: .support),
            ],
          )

        case .onboarding(.supervision(.resume(.retrySupervision))):
          GertieActionScreen(
            message: "No worries. Let’s try setting up supervision again.",
            action: self.action(text: "Next", .primary),
          )

        case .onboarding(.supervision(.resume(.codeNotClaimed))):
          GertieActionScreen(
            message: "Hmmm... the supervision setup code hasn’t been claimed by a Gertrude account yet. Let’s try again.",
            action: self.action(text: "Next", .primary),
          )

        case .onboarding(.supervision(.resume(.codeExpired))):
          GertieActionScreen(
            message: "Your supervision setup code is no longer valid. No problem, we can make a fresh one and pick up from there.",
            actions: [
              self.action(text: "Get a new code", .primary),
              self.action(text: "Start over", .secondary),
            ],
          )

        case .onboarding(.supervision(.resume(.profileRemovedRecovery))):
          GertieActionScreen(
            message: "The supervision profile is no longer installed on this \(self.deviceType), preventing Gertrude from doing its job.",
            action: self.action(text: "Reinstall profile", .primary),
          )

        case .onboarding(.supervision(.resume(.promptInstallProfile))):
          GertieActionScreen(
            message: "One more step: we need to install something called a “profile” to allow blocking.",
            action: self.action(text: "Next", .primary),
          )

        case .onboarding(.supervision(.resume(.explainProfileDownload))):
          GertieActionScreen(
            message: "When the mini-browser opens, tap “Allow” to download the profile.",
            action: self.action(text: "Got it", .primary),
          )

        case .onboarding(.supervision(.resume(.installingProfile(let profileUrl)))):
          ProfileDownloadView(profileUrl: profileUrl, osMajorVersion: self.osMajorVersion) {
            self.store.send(.interactive(.onboardingBtnTapped(.primary, "Safari dismissed")))
          }

        case .onboarding(.supervision(.resume(.profileDownloaded))):
          GertieActionScreen(
            message: "Great, profile downloaded! Now we need to install it. You’ll do this in the Settings app—we’ll explain how.",
            action: self.action(text: "Next", .primary),
          )

        case .onboarding(.supervision(.resume(.profileNotRemovableWarning))):
          GertieActionScreen(
            message: "When installing the profile, your \(self.deviceType) will warn you that it can’t be removed. Don’t worry—it can be removed at any time from the Gertrude website.",
            action: self.action(text: "Got it", .primary),
          )

        case .onboarding(.supervision(.resume(.explainProfileInstall(let regainedFocus)))):
          GertieActionScreen(
            message: "Now, open the Settings app:",
            bullets: [
              self.deviceType == "iPad"
                ? "In the left column, tap “Profile Downloaded” near the top"
                : "Tap “Profile Downloaded” near the top",
              "Tap “Install”",
              "Enter your passcode",
              "Come back to this app",
            ],
            action: self.action(text: "Done, continue", .primary, isEnabled: regainedFocus),
          )

        case .onboarding(.supervision(.resume(.verifyingProfileInstall(let didError)))):
          SpinnerErrorView(
            loadingText: "Verifying profile installation...",
            errorTitle: "Profile not detected",
            errorMessage: "Make sure you installed the profile in Settings.",
            isError: didError,
            onRetry: { self.store.send(.interactive(.onboardingBtnTapped(.primary, "Retry"))) },
          )

        case .onboarding(.supervision(.resume(.profileInstalled))):
          ProfileInstalledView {
            self.store.send(.interactive(.onboardingBtnTapped(.primary, "Next")))
          }

        case .onboarding(.supervision(.resume(.websiteWarning(let childName)))):
          GertieActionScreen(
            message: "Because protection is controlled from the website, that also means it’s important that \(childName ?? "the \(self.deviceType) user") doesn’t know the website password.",
            action: self.action(text: "Got it", .primary),
          )

        case .onboarding(.supervision(.resume(.offerScreenTimeAccess))):
          GertieActionScreen(
            message: "We’re working on adding more control for the account holder via Screen Time. If you grant access now, you’ll be able to opt into these new features from the Gertrude website.\n\nFor safety and accountability, make sure there is a 4-digit Screen Time passcode set that only the account holder knows.",
            actions: [
              self.action(text: "Grant Screen Time access", .primary),
              self.action(text: "Not now", .secondary),
            ],
          )

        case .onboarding(.supervision(.resume(.dontGetTrickedPreScreenTime))):
          GertieActionScreen(
            message: "Don’t get tricked! Be sure to click “Continue”, even though it looks like you’re supposed to click “Don’t Allow”.",
            action: self.action(text: "Got it, next", .primary, behavior: .showProgress),
            supplementPlacement: .beforeMessage,
          ) {
            OnboardingInstructionImage(
              name: self.iosVersionImage("AllowScreenTimeAccess"),
              accessibilityLabel: "Screen Time permission alert showing the Continue button",
            )
          }

        case .onboarding(.supervision(.resume(.networkError))):
          SupervisionNetworkErrorView {
            self.store.send(.interactive(.onboardingBtnTapped(.primary, "Try again")))
          }

        case .onboarding(.supervision(.resume(.requiresSubscription))):
          GertieActionScreen(
            message: "A Gertrude subscription is required to use supervision. Have a parent subscribe at parents.gertrude.app, then tap Try Again.",
            icon: .error,
            action: self.action(text: "Try Again", .primary),
          )

        case .supervisionSuccessFirstLaunch:
          SupervisionDetectedView {
            self.store.send(.interactive(.onboardingBtnTapped(.primary, "Next")))
          }

        case .running:
          RunningView(store: self.store)
            .onShake { self.store.send(.interactive(.receivedShake)) }
        }
      }
    }
    .sheet(item: self.$store.scope(
      state: \.destination?.info,
      action: \.destination.info,
    )) { store in
      InfoView(store: store)
        .onAppear { store.send(.sheetPresented) }
        .onShake { store.send(.receivedShake) }
        .pageSheet()
    }
    .sheet(item: self.crossPromoStore(style: .sheet)) { store in
      CrossPromoView(store: store)
    }
    #if os(iOS)
    .fullScreenCover(item: self.crossPromoStore(style: .screen)) { store in
      CrossPromoView(store: store)
    }
    #endif
    .killSwitch(
      store: self.store.scope(state: \.killSwitch, action: \.killSwitch),
      suggestedUpdatesEnabled: self.store.screen.isRunning,
    )
  }

  private func crossPromoStore(
    style: CrossPromoStyle,
  ) -> Binding<StoreOf<CrossPromoFeature>?> {
    let base = self.$store.scope(
      state: \.destination?.crossPromo,
      action: \.destination.crossPromo,
    )
    return Binding(
      get: { base.wrappedValue.flatMap { $0.campaign.style == style ? $0 : nil } },
      set: { base.wrappedValue = $0 },
    )
  }

  private func action(
    text: String,
    _ slot: IOSReducer.Action.Interactive.OnboardingBtn,
    emphasis: GertieScreenAction.Emphasis = .automatic,
    behavior: GertieScreenAction.TriggerBehavior = .afterExitAnimation,
    isEnabled: Bool = true,
  ) -> GertieScreenAction {
    .button(
      text,
      emphasis: emphasis,
      isEnabled: isEnabled,
      behavior: behavior,
    ) {
      self.store.send(.interactive(.onboardingBtnTapped(slot, text)))
    }
  }

  private func iosVersionImage(_ baseName: String) -> String {
    self.osMajorVersion >= 26 ? "\(baseName)IOS26" : baseName
  }
}

private struct AccountConnectionSuccessView: View {
  let deviceType: String
  let onNext: @MainActor () -> Void

  var body: some View {
    GertieResultScreen(
      icon: "checkmark.circle.fill",
      title: "Successfully connected!",
      message: "This \(self.deviceType) is now connected to your Gertrude parent account.",
      accessibilityIdentifier: "onboarding-screen-connect-success",
      action: .button("Next", behavior: .afterExitAnimation) {
        self.onNext()
      },
    )
  }
}

private struct ProfileInstalledView: View {
  let onNext: @MainActor () -> Void

  var body: some View {
    GertieResultScreen(
      icon: "checkmark.circle.fill",
      title: "Profile installed successfully!",
      message: "Gertrude can now block unwanted content.\n\nFrom the website, the account holder can manage what gets blocked and also remove the supervision.",
      action: .button("Next", behavior: .afterExitAnimation) {
        self.onNext()
      },
    )
  }
}

private struct SupervisionDetectedView: View {
  let onNext: @MainActor () -> Void

  var body: some View {
    GertieResultScreen(
      icon: "checkmark.circle.fill",
      title: "Excellent!",
      message: "Looks like you’ve installed Gertrude under Supervised mode. Just a couple steps to get you all set up.",
      action: .button("Next", behavior: .afterExitAnimation) {
        self.onNext()
      },
    )
  }
}

private struct AuthorizationNetworkErrorView: View {
  let onRetry: @MainActor () -> Void

  var body: some View {
    GertieResultScreen(
      icon: "xmark.circle.fill",
      tone: .error,
      title: "Couldn’t connect to the internet",
      message: "Double-check your connection and try again when you’re online.",
      action: .button("Try again", behavior: .afterExitAnimation) {
        self.onRetry()
      },
    )
  }
}

private struct SupervisionNetworkErrorView: View {
  let onRetry: @MainActor () -> Void

  var body: some View {
    GertieResultScreen(
      icon: "xmark.circle.fill",
      tone: .error,
      title: "Couldn’t reach Gertrude",
      message: "Please check your internet connection and try again.",
      action: .button("Try again", behavior: .afterExitAnimation) {
        self.onRetry()
      },
    )
  }
}

private struct OnboardingInstructionImage: View {
  @Environment(\.gertieActionScreenLayout) private var layout

  let name: String
  let accessibilityLabel: String

  @ViewBuilder var body: some View {
    switch self.layout {
    case .regular:
      Image(self.name)
        .scaleEffect(self.name.contains("IOS26") ? 1.25 : 1.0)
        .frame(maxWidth: .infinity)
        .padding(.bottom, 50)
        .accessibilityLabel(Text(verbatim: self.accessibilityLabel))
    case .compact:
      Image(self.name)
        .resizable()
        .scaledToFit()
        .frame(
          maxWidth: .infinity,
          maxHeight: self.name.contains("IOS26") ? 260 : 300,
        )
        .padding(.bottom, 8)
        .accessibilityLabel(Text(verbatim: self.accessibilityLabel))
    }
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
    store: Store(initialState: IOSReducer.State(
      screen: .onboarding(.happyPath(.hiThere)),
    )) {
      IOSReducer()
    },
    osMajorVersion: 26,
    deviceType: "iPhone",
  )
}

#Preview("Instruction image regular", traits: .fixedLayout(width: 390, height: 844)) {
  GertieActionScreen(
    message: "Don’t get tricked! Be sure to click “Continue”, even though it looks like you’re supposed to click “Don’t Allow”.",
    action: .button("Got it, next") {},
    supplementPlacement: .beforeMessage,
  ) {
    OnboardingInstructionImage(
      name: "AllowScreenTimeAccessIOS26",
      accessibilityLabel: "Screen Time permission alert showing the Continue button",
    )
  }
}

#Preview("Instruction image compact", traits: .fixedLayout(width: 375, height: 667)) {
  GertieActionScreen(
    message: "Don’t get tricked! Be sure to click “Continue”, even though it looks like you’re supposed to click “Don’t Allow”.",
    action: .button("Got it, next") {},
    supplementPlacement: .beforeMessage,
  ) {
    OnboardingInstructionImage(
      name: "AllowScreenTimeAccessIOS26",
      accessibilityLabel: "Screen Time permission alert showing the Continue button",
    )
  }
}

#Preview("Instruction image accessibility text") {
  GertieActionScreen(
    message: "Don’t get tricked! Be sure to click “Continue”, even though it looks like you’re supposed to click “Don’t Allow”.",
    action: .button("Got it, next") {},
    supplementPlacement: .beforeMessage,
  ) {
    OnboardingInstructionImage(
      name: "AllowScreenTimeAccessIOS26",
      accessibilityLabel: "Screen Time permission alert showing the Continue button",
    )
  }
  .environment(\.dynamicTypeSize, .accessibility2)
}

#Preview("Account connected") {
  AccountConnectionSuccessView(deviceType: "iPhone") {}
}

#Preview("Authorization network error") {
  AuthorizationNetworkErrorView {}
}

#Preview("Supervision network error") {
  SupervisionNetworkErrorView {}
}

#Preview("Supervision detected") {
  SupervisionDetectedView {}
}

#Preview("Profile Flow: Installed") {
  ProfileInstalledView {}
}

#Preview("Profile Flow: Prompt Install") {
  AppView(
    store: Store(initialState: IOSReducer.State(
      screen: .onboarding(.supervision(.resume(.promptInstallProfile))),
    )) {
      IOSReducer()
    },
    osMajorVersion: 26,
    deviceType: "iPhone",
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
    deviceType: "iPhone",
  )
}

#Preview("Profile Flow: Installing") {
  AppView(
    store: Store(initialState: IOSReducer.State(
      screen: .onboarding(.supervision(.resume(.installingProfile(
        profileUrl: URL(
          string: "https://gertrude-dev.nyc3.digitaloceanspaces.com/super.mobileconfig",
        )!,
      )))),
    )) {
      IOSReducer()
    },
    osMajorVersion: 26,
    deviceType: "iPhone",
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
    deviceType: "iPhone",
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
    deviceType: "iPhone",
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
    deviceType: "iPhone",
  )
}
