import ComposableArchitecture
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
            text: "Is this the \(self.deviceType) you want to protect?",
            primary: self.btn(text: "Yes", .primary),
            secondary: self.btn(text: "No", .secondary),
          )

        case .onboarding(.happyPath(.explainPermissionDependsOnAge)):
          ButtonScreenView(
            text: "To protect privacy, Apple requires special permission before we can block unwanted internet access. How we get that permission depends on the AGE of the \(self.deviceType) user.",
            primary: self.btn(text: "Got it, next", .primary),
          )

        case .onboarding(.happyPath(.confirmMinorDevice)):
          ButtonScreenView(
            text: "How old is the user of this \(self.deviceType)?",
            primary: self.btn(text: "Under 18", .primary),
            secondary: self.btn(text: "18 or older", .secondary),
            primaryLooksLikeSecondary: true,
          )

        case .onboarding(.happyPath(.confirmParentIsOnboarding)):
          ButtonScreenView(
            text: "Are you the parent or guardian?",
            primary: self.btn(text: "Yes", .primary),
            secondary: self.btn(text: "No", .secondary),
          )

        case .onboarding(.happyPath(.confirmInAppleFamily)):
          ButtonScreenView(
            text: "Apple also requires that the child’s \(self.deviceType) be part of an Apple Family. Is the Apple Account for this \(self.deviceType) already in an Apple Family?",
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
            text: "Great! Half way there. In the next step, use the passcode of THIS \(self.deviceType.uppercased()) (the one you’re holding), not your own.",
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
            text: "Success! This \(self.deviceType) is now connected to your Gertrude parent account.",
            primary: self.btn(text: "Next", .primary),
          )

        case .onboarding(.happyPath(.optOutBlockGroups)):
          ChooseWhatToBlockView(
            allGroups: self.store.allBlockGroups,
            disabledGroupIds: self.store.disabledBlockGroupIds,
            onGroupToggle: { self.store.send(.interactive(.blockGroupToggled($0))) },
            onDone: { self.store.send(.interactive(.onboardingBtnTapped(.primary, "Done"))) },
          )

        case .onboarding(.happyPath(.promptClearCache)),
             .onboarding(.supervision(.resume(.promptClearCache))):
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
            text: "Well gosh, we’re not sure what’s wrong then. Try powering the \(self.deviceType) off completely, then start the installation again. If you get here again, please contact us for more help using the link below.",
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
            text: "A restriction is preventing Gertrude from being installed. Is this \(self.deviceType) enrolled in mobile device management (MDM) by an organization or school? If so, try again on a device not managed by MDM.",
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
            text: "Sorry, Apple won’t let us install unless this \(self.deviceType) has a passcode set. Go to the Settings app and set one up, then try again.",
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

        case .onboarding(.mdmSupervisionExplainer):
          ButtonScreenView(
            text: "Gertrude’s content filter for adults (18+) requires a supervised device, per Apple’s own rules. This process is not compatible with MDM-managed devices.\n\nTo use this app, you’ll need a personal device that is not managed by an organization.",
            primary: self.btn(text: "OK", .primary),
          )

        case .onboarding(.childIsOnboardingFail):
          ButtonScreenView(
            text: "Setting up Gertrude requires your parent or guardian. Give your \(self.deviceType) to them so they can finish the setup.",
            primary: self.btn(text: "Done, continue", .primary),
          )

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
            text: "You can check if you’re already setup by opening the Settings app on this \(self.deviceType). If you see a Family section right below the Apple Account name and picture, you’re already set.",
            primary: self.btn(text: "Yes, in a family", .primary),
            secondary: self.btn(text: "Not in a family yet", .secondary),
          )

        // supervision setup

        case .onboarding(.supervision(.setup(.adultNeedsSupervision))):
          ButtonScreenView(
            text: "Got it, over 18. So for adults, Apple doesn’t allow internet blocking unless the \(self.deviceType) is put into a special mode called SUPERVISED MODE.",
            primary: self.btn(text: "Tell me more", .primary),
          )

        case .onboarding(.supervision(.setup(.whatIsSupervisedMode))):
          ButtonScreenView(
            text: "Supervised mode was originally designed for devices owned by schools and businesses. It allows access to settings and features that normal devices don’t have.",
            primary: self.btn(text: "Next", .primary),
          )

        case .onboarding(.supervision(.setup(.supervisedDeviceReassurance))):
          ButtonScreenView(
            text: "Other than allowing access to these extra features and controls, a supervised \(self.deviceType) is the same as any other \(self.deviceType). You get to decide which extra features to use.",
            primary: self.btn(text: "Next", .primary),
          )

        case .onboarding(.supervision(.setup(.explainSupervision))):
          ButtonScreenView(
            text: "So, to get Gertrude blocking unwanted content for you, we’ll need this \(self.deviceType) to be in supervised mode, which takes a little more up-front setup.",
            primary: self.btn(text: "Got it, next", .primary),
          )

        case .onboarding(.supervision(.setup(.costAndBranchPoint))):
          ButtonScreenView(
            text: "The easiest way to supervise a device is with a Gertrude account ($10/year).\n\nThere are free alternatives, but they have downsides.",
            primary: self.btn(text: "Continue with Gertrude", .primary),
            secondary: self.btn(text: "Show me the free alternatives", .secondary),
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
          ButtonScreenView(
            text: "Apple allows you to change your Apple Account birthday one time. If you change it to make yourself under 18, Gertrude will work without supervision.",
            primary: self.btn(text: "What are the downsides?", .primary),
            secondary: self.btn(text: "Back to alternatives", .secondary),
          )

        case .onboarding(.supervision(.setup(.birthdayAlternativeCons))):
          ButtonScreenView(
            text: "You’ll be treated as a child in Apple’s system:",
            primary: self.btn(text: "This works for me", .primary),
            secondary: self.btn(text: "Back to alternatives", .secondary),
            listItems: [
              "You’ll need to be a part of an Apple Family",
              "Purchases may need approval",
              "You can’t be a family organizer",
              "Can be hard to undo later",
            ],
            screenType: .error,
          )

        case .onboarding(.supervision(.setup(.birthdayAlternativeInstructions))):
          ButtonScreenView(
            text: "To change your birthday: Go to Settings, tap your name, then Personal Information, then Birthday. Change it so you’re under 18, then come back to this app.",
            primary: self.btn(text: "I’ve updated my birthday", .primary),
          )

        case .onboarding(.supervision(.setup(.siblingAlternativeExplain))):
          ButtonScreenView(
            text: "If you have a younger sibling (under 18) in your Apple Family, you can sign into their Apple Account on this \(self.deviceType). Gertrude will then work without supervision.",
            primary: self.btn(text: "What are the downsides?", .primary),
            secondary: self.btn(text: "Back to alternatives", .secondary),
          )

        case .onboarding(.supervision(.setup(.siblingAlternativeCons))):
          ButtonScreenView(
            text: "This \(self.deviceType) becomes your sibling’s in Apple’s eyes:",
            primary: self.btn(text: "This works for me", .primary),
            secondary: self.btn(text: "Back to alternatives", .secondary),
            listItems: [
              "iMessage and FaceTime use their account",
              "App purchases go to their account",
              "Other data may mix or sync",
            ],
            screenType: .error,
          )

        case .onboarding(.supervision(.setup(.siblingAlternativeInstructions))):
          ButtonScreenView(
            text: "To switch accounts: Go to Settings, tap your name at the top, scroll down and tap Sign Out. Then sign in with your sibling’s Apple ID and come back to this app.",
            primary: self.btn(text: "I’ve switched accounts", .primary),
          )

        case .onboarding(.supervision(.setup(.accountNowUnder18))):
          ButtonScreenView(
            text: "Great! Assuming the account is now set up as under 18, we can proceed with the standard setup.",
            primary: self.btn(text: "Continue", .primary),
          )

        case .onboarding(.supervision(.setup(.appleConfiguratorExplain))):
          ButtonScreenView(
            text: "You can use Apple’s free tool called Apple Configurator to supervise your own \(self.deviceType). This gives you full control without needing a Gertrude account.",
            primary: self.btn(text: "What are the downsides?", .primary),
            secondary: self.btn(text: "Back to alternatives", .secondary),
          )

        case .onboarding(.supervision(.setup(.appleConfiguratorCons(let step)))):
          switch step {
          case 1:
            ButtonScreenView(
              text: "This method requires completely erasing this \(self.deviceType). You can restore from a backup afterward, but sometimes a few customizations can be lost.",
              primary: self.btn(text: "Next", .primary),
              secondary: self.btn(text: "Back to alternatives", .secondary),
              screenType: .error,
            )
          case 2:
            ButtonScreenView(
              text: "You’ll need a Mac computer and physical access to this \(self.deviceType) every time you want to make changes to the supervision settings.",
              primary: self.btn(text: "Next", .primary),
              secondary: self.btn(text: "Back to alternatives", .secondary),
              screenType: .error,
            )
          default:
            ButtonScreenView(
              text: "The process takes about an hour, and is slightly technical, compared to ~5 minutes with Gertrude. Ready to proceed?",
              primary: .init(
                text: "Show me how",
                type: .link(.supervisionTutorial),
                animate: false,
              ),
              secondary: self.btn(text: "Back to alternatives", .secondary),
              screenType: .error,
            )
          }

        case .onboarding(.supervision(.setup(.explainNeedSomeoneElse))):
          ButtonScreenView(
            text: "A supervised \(self.deviceType) needs someone ELSE to manage it—typically a parent, spouse, or accountability partner. They’ll need to plug this \(self.deviceType) into a computer to get started.",
            primary: self.btn(text: "Got it, no problem", .primary),
            secondary: self.btn(text: "I need to manage myself", .secondary),
          )

        case .onboarding(.supervision(.setup(.selfManagementPlaceholder))):
          ButtonScreenView(
            text: "Self-management is coming soon! For now, you’ll need someone else to help supervise your \(self.deviceType). We’re working on a solution for self-management.",
            primary: self.btn(text: "Start over", .primary),
            secondary: .init(text: "Contact support", type: .link(.support), animate: false),
          )

        case .onboarding(.supervision(.setup(.generateSetupCode(let didError)))):
          SpinnerErrorView(
            loadingText: "Generating your setup code...",
            errorText: "Something went wrong generating your setup code. Please try again.",
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

        case .onboarding(.supervision(.resume(.codeClaimedNotSupervised(let regainedFocus)))):
          ButtonScreenView(
            text: "Hmmm... We’re not sure if this \(self.deviceType) is supervised yet. Open the Settings app and check if it says at the top of the main screen that it’s supervised, then come back here.",
            primary: self.btn(text: "Yes, it says supervised", .primary, disabled: !regainedFocus),
            secondary: self.btn(
              text: "No, I don’t see anything",
              .secondary,
              disabled: !regainedFocus,
            ),
            screenType: .question,
            primaryLooksLikeSecondary: true,
          )

        case .onboarding(.supervision(.resume(.retrySupervision))):
          ButtonScreenView(
            text: "No worries. Let’s try setting up supervision again.",
            primary: self.btn(text: "Next", .primary),
          )

        case .onboarding(.supervision(.resume(.codeNotClaimed))):
          ButtonScreenView(
            text: "Hmmm... the supervision setup code hasn’t been claimed by a Gertrude account yet. Let’s try again.",
            primary: self.btn(text: "Next", .primary),
          )

        case .onboarding(.supervision(.resume(.profileRemovedRecovery))):
          ButtonScreenView(
            text: "The supervision profile is no longer installed on this \(self.deviceType), preventing Gertrude from doing its job.",
            primary: self.btn(text: "Reinstall profile", .primary),
          )

        case .onboarding(.supervision(.resume(.promptInstallProfile))):
          ButtonScreenView(
            text: "One more step: we need to install something called a “profile” to allow blocking.",
            primary: self.btn(text: "Next", .primary),
          )

        case .onboarding(.supervision(.resume(.explainProfileDownload))):
          ButtonScreenView(
            text: "When the mini-browser opens, tap “Allow” to download the profile.",
            primary: self.btn(text: "Got it", .primary),
          )

        case .onboarding(.supervision(.resume(.installingProfile(let profileUrl)))):
          ProfileDownloadView(profileUrl: profileUrl, osMajorVersion: self.osMajorVersion) {
            self.store.send(.interactive(.onboardingBtnTapped(.primary, "Safari dismissed")))
          }

        case .onboarding(.supervision(.resume(.profileDownloaded))):
          ButtonScreenView(
            text: "Great, profile downloaded! Now we need to install it. You’ll do this in the Settings app—we’ll explain how.",
            primary: self.btn(text: "Next", .primary),
          )

        case .onboarding(.supervision(.resume(.profileNotRemovableWarning))):
          ButtonScreenView(
            text: "When installing the profile, your \(self.deviceType) will warn you that it can’t be removed. Don’t worry—it can be removed at any time from the Gertrude website.",
            primary: self.btn(text: "Got it", .primary),
          )

        case .onboarding(.supervision(.resume(.explainProfileInstall(let regainedFocus)))):
          ButtonScreenView(
            text: "Now, open the Settings app:",
            primary: self.btn(text: "Done, continue", .primary, disabled: !regainedFocus),
            listItems: [
              self.deviceType == "iPad"
                ? "In the left column, tap “Profile Downloaded” near the top"
                : "Tap “Profile Downloaded” near the top",
              "Tap “Install”",
              "Enter your passcode",
              "Come back to this app",
            ],
          )

        case .onboarding(.supervision(.resume(.verifyingProfileInstall(let didError)))):
          SpinnerErrorView(
            loadingText: "Verifying profile installation...",
            errorText: "Profile not detected. Make sure you installed the profile in Settings.",
            isError: didError,
            onRetry: { self.store.send(.interactive(.onboardingBtnTapped(.primary, "Retry"))) },
          )

        case .onboarding(.supervision(.resume(.profileInstalled))):
          ButtonScreenView(
            text: "Profile installed successfully! Gertrude can now block unwanted content.\n\nFrom the website, the account holder can manage what gets blocked and also remove the supervision.",
            primary: self.btn(text: "Next", .primary),
          )

        case .onboarding(.supervision(.resume(.websiteWarning(let childName)))):
          ButtonScreenView(
            text: "Because protection is controlled from the website, that also means it’s important that \(childName ?? "the \(self.deviceType) user") doesn’t know the website password.",
            primary: self.btn(text: "Got it", .primary),
          )

        case .onboarding(.supervision(.resume(.networkError))):
          ButtonScreenView(
            text: "Couldn’t reach Gertrude’s servers. Please check your internet connection and try again.",
            primary: self.btn(text: "Try again", .primary),
            screenType: .error,
          )

        case .onboarding(.supervision(.resume(.requiresSubscription))):
          ButtonScreenView(
            text: "A Gertrude subscription is required to use supervision. Have a parent subscribe at parents.gertrude.app, then tap Try Again.",
            primary: self.btn(text: "Try Again", .primary),
            screenType: .error,
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
        .pageSheet()
    }
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
    deviceType: "iPhone",
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
