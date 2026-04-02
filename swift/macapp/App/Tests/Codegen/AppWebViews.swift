import Foundation
import Gertie
import TypeScriptInterop

@testable import App

struct AppWebViewStoreTypes: AggregateCodeGenerator {
  var generators: [CodeGenerator] = [
    AppWebViewStore(
      at: "lib/shared-types.ts",
      namedTypes: [
        .init(FilterState.WithRelativeTimes.self, as: "FilterState"),
        .init(AdminAccountStatus.self),
      ],
    ),
    AppWebViewStore(
      at: "MenuBar/menubar-store.ts",
      types: [
        .init(MenuBarFeature.State.View.self, as: "AppState"),
        .init(MenuBarFeature.Action.self, as: "AppEvent"),
      ],
      localAliases: [(FilterState.WithRelativeTimes.self, "FilterState")],
    ),
    AppWebViewStore(
      at: "BlockedRequests/blockedrequests-store.ts",
      namedTypes: [
        .init(BlockedRequestsFeature.State.View.Request.self),
      ],
      types: [
        .init(BlockedRequestsFeature.State.View.self, as: "AppState"),
        .init(BlockedRequestsFeature.Action.View.self, as: "AppEvent"),
      ],
      localAliases: [
        (BlockedRequestsFeature.State.View.Request.self, "Request"),
        (AdminAccountStatus.self, "AdminAccountStatus"),
      ],
    ),
    AppWebViewStore(
      at: "Administrate/administrate-store.ts",
      namedTypes: [
        .init(AdminWindowFeature.Screen.self),
        .init(AdminWindowFeature.State.HealthCheck.self),
        .init(AdminWindowFeature.State.View.ExemptableUser.self),
        .init(AdminWindowFeature.Action.View.HealthCheckAction.self),
        .init(AdminWindowFeature.State.View.Advanced.self, as: "AdvancedState"),
        .init(AdminWindowFeature.Action.View.AdvancedAction.self),
      ],
      types: [
        .init(AdminWindowFeature.State.View.self, as: "AppState"),
        .init(AdminWindowFeature.Action.View.self, as: "AppEvent"),
      ],
      localAliases: [
        (AdminWindowFeature.State.HealthCheck.self, "HealthCheck"),
        (AdminWindowFeature.State.View.Advanced.self, "AdvancedState"),
        (AdminWindowFeature.Action.View.HealthCheckAction.self, "HealthCheckAction"),
        (AdminWindowFeature.Action.View.AdvancedAction.self, "AdvancedAction"),
        (AdminWindowFeature.Screen.self, "Screen"),
        (FilterState.WithRelativeTimes.self, "FilterState"),
        (
          Failable<[AdminWindowFeature.State.View.ExemptableUser]>.self,
          "Failable<ExemptableUser[]>",
        ),
      ],
      globalAliases: [
        (AdminAccountStatus.self, "AdminAccountStatus"),
        (Failable<AdminAccountStatus>.self, "Failable<AdminAccountStatus>"),
      ],
    ),
    AppWebViewStore(
      at: "RequestSuspension/requestsuspension-store.ts",
      types: [
        .init(RequestSuspensionFeature.State.View.self, as: "AppState"),
        .init(RequestSuspensionFeature.Action.View.self, as: "AppEvent"),
      ],
      localAliases: [
        (AdminAccountStatus.self, "AdminAccountStatus"),
      ],
    ),
    AppWebViewStore(
      at: "Onboarding/onboarding-store.ts",
      namedTypes: [
        .init(OnboardingFeature.State.Step.self, as: "OnboardingStep"),
        .init(OnboardingFeature.State.View.OsVersion.self, as: "MacOSVersion"),
        .init(OnboardingFeature.State.MacUser.RemediationStep.self, as: "UserRemediationStep"),
        .init(OnboardingFeature.State.MacUser.self, as: "MacOSUser"),
        .init(DiscoveredApp.self),
      ],
      types: [
        .init(OnboardingFeature.State.View.self, as: "AppState"),
        .init(OnboardingFeature.Action.View.self, as: "AppEvent"),
      ],
      localAliases: [
        (OnboardingFeature.State.Step.self, "OnboardingStep"),
        (OnboardingFeature.State.MacUser.RemediationStep.self, "UserRemediationStep"),
        (OnboardingFeature.State.MacUser.self, "MacOSUser"),
        (DiscoveredApp.self, "DiscoveredApp"),
        (PayloadRequestState<String, String>.self, "RequestState<string>"),
        (RequestState<String>.self, "RequestState"),
      ],
    ),
  ]
}
