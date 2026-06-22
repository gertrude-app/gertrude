import ClientInterfaces
import Dependencies
import Foundation
import Gertie
import MacAppRoute

extension ApiClient: @retroactive DependencyKey {
  public static let liveValue = Self(
    checkIn: { input in
      try await authed(
        CheckIn_v2.self,
        .checkIn_v2(input),
      )
    },
    clearUserToken: {
      await userToken.setValue(nil)
    },
    confirmOnboardingNotificationCode: { input in
      _ = try await authed(
        ConfirmOnboardingNotificationCode.self,
        .confirmOnboardingNotificationCode(input),
      )
    },
    connectUser: { input in
      try await pairql.call(
        ConnectUser.self,
        unauthed: .connectUser(input),
      )
    },
    createOnboardingAppKeys: { input in
      _ = try await authed(
        CreateOnboardingAppKeys.self,
        .createOnboardingAppKeys(input),
      )
    },
    createOnboardingBlockedApps: { input in
      _ = try await authed(
        CreateOnboardingBlockedApps.self,
        .createOnboardingBlockedApps(input),
      )
    },
    createOnboardingKeychain: { input in
      try await authed(
        CreateOnboardingKeychain.self,
        .createOnboardingKeychain(input),
      ).success
    },
    disableFilterForChild: {
      _ = try await authed(
        DisableFilterForChild.self,
        .disableFilterForChild,
      )
    },
    getOnboardingConfig: {
      try await authed(
        GetOnboardingConfig.self,
        .getOnboardingConfig,
      )
    },
    selectAlwaysBlockedGroups: { input in
      _ = try await authed(
        SelectAlwaysBlockedGroups.self,
        .selectAlwaysBlockedGroups(input),
      )
    },
    selectPublicKeychains: { input in
      _ = try await authed(
        SelectPublicKeychains.self,
        .selectPublicKeychains(input),
      )
    },
    sendOnboardingNotificationCode: { input in
      try await authed(
        SendOnboardingNotificationCode.self,
        .sendOnboardingNotificationCode(input),
      )
    },
    setDowntimeSchedule: { input in
      _ = try await authed(
        SetDowntimeSchedule.self,
        .setDowntimeSchedule(input),
      )
    },
    createKeystrokeLines: { input in
      guard await accountActive.value else { return }
      // always produces `.success` if it doesn't throw
      _ = try await authed(
        CreateKeystrokeLines.self,
        .createKeystrokeLines(input),
      )
    },
    createSuspendFilterRequest: { input in
      guard await accountActive.value else { return .init() }
      return try await authed(
        CreateSuspendFilterRequest_v2.self,
        .createSuspendFilterRequest_v2(input),
      )
    },
    createUnlockRequests: { input in
      guard await accountActive.value else { return [] }
      return try await authed(
        CreateUnlockRequests_v3.self,
        .createUnlockRequests_v3(input),
      )
    },
    getUserToken: {
      await userToken.value
    },
    logFilterEvents: { input in
      guard await accountActive.value else { return }
      _ = try? await authed(
        LogFilterEvents.self,
        .logFilterEvents(input),
      )
    },
    logInterestingEvent: { input in
      _ = try? await pairql.call(
        LogInterestingEvent.self,
        unauthed: .logInterestingEvent(input),
      )
    },
    logSecurityEvent: { input, bufferedToken in
      // sleep allows us to log events possibly before token/account resolved
      if input.event == "appLaunched" {
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
      } else {
        try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
      }
      guard await accountActive.value else { return }
      let currentToken = await userToken.value
      // NB: prefer bufferedToken
      let token = bufferedToken ?? currentToken
      guard token != nil else { return }
      _ = try? await authed(
        LogSecurityEvent.self,
        .logSecurityEvent(input),
        using: token,
      )
    },
    recentAppVersions: {
      try await pairql.call(
        RecentAppVersions.self,
        unauthed: .recentAppVersions,
      )
    },
    reportBrowsers: { input in
      guard await accountActive.value else { return }
      _ = try await authed(
        ReportBrowsers.self,
        .reportBrowsers(input),
      )
    },
    setAccountActive: { await accountActive.setValue($0) },
    setUserToken: { await userToken.setValue($0) },
    trustedNetworkTimestamp: {
      try await pairql.call(
        TrustedTime.self,
        unauthed: .trustedTime,
      )
    },
    uploadAppIcon: { input in
      guard await accountActive.value else { return }
      _ = try await authed(
        UploadAppIcon.self,
        .uploadAppIcon(input),
      )
    },
    uploadScreenshot: { data in
      guard await accountActive.value else { throw Error.accountInactive }
      let signed = try await authed(
        CreateSignedScreenshotUpload_v2.self,
        .createSignedScreenshotUpload_v2(.init(
          width: data.width,
          height: data.height,
          filterSuspended: data.filterSuspended,
          createdAt: data.createdAt,
        )),
      )

      var request = URLRequest(url: signed.uploadUrl, cachePolicy: .reloadIgnoringCacheData)
      request.httpMethod = "PUT"
      request.addValue("image/jpeg", forHTTPHeaderField: "Content-Type")

      try await withCheckedThrowingContinuation {
        (continuation: CheckedContinuation<Void, any Swift.Error>) in
        URLSession.shared.uploadTask(with: request, from: data.image) { data, response, error in
          if let error {
            continuation.resume(throwing: error)
            return
          }
          guard let data, let response else {
            continuation.resume(throwing: Error.missingDataOrResponse)
            return
          }
          continuation.resume()
        }.resume()
      }
    },
  )
}

let accountActive = ActorIsolated<Bool>(true)
let userToken = ActorIsolated<UUID?>(nil)
