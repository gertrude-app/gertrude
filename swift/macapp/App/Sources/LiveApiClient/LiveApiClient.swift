import ClientInterfaces
import Dependencies
import Foundation
import Gertie
import MacAppRoute

extension ApiClient: @retroactive DependencyKey {
  public static let liveValue = Self(
    checkIn: { input in
      try await output(
        from: CheckIn_v2.self,
        with: .checkIn_v2(input),
      )
    },
    clearUserToken: {
      await userToken.setValue(nil)
    },
    connectUser: { input in
      try await output(
        from: ConnectUser.self,
        withUnauthed: .connectUser(input),
      )
    },
    createOnboardingAppKeys: { input in
      _ = try await output(
        from: CreateOnboardingAppKeys.self,
        with: .createOnboardingAppKeys(input),
      )
    },
    createOnboardingBlockedApps: { input in
      _ = try await output(
        from: CreateOnboardingBlockedApps.self,
        with: .createOnboardingBlockedApps(input),
      )
    },
    disableFilterForChild: {
      _ = try await output(
        from: DisableFilterForChild.self,
        with: .disableFilterForChild,
      )
    },
    createKeystrokeLines: { input in
      guard await accountActive.value else { return }
      // always produces `.success` if it doesn't throw
      _ = try await output(
        from: CreateKeystrokeLines.self,
        with: .createKeystrokeLines(input),
      )
    },
    createSuspendFilterRequest: { input in
      guard await accountActive.value else { return .init() }
      return try await output(
        from: CreateSuspendFilterRequest_v2.self,
        with: .createSuspendFilterRequest_v2(input),
      )
    },
    createUnlockRequests: { input in
      guard await accountActive.value else { return [] }
      return try await output(
        from: CreateUnlockRequests_v3.self,
        with: .createUnlockRequests_v3(input),
      )
    },
    getUserToken: {
      await userToken.value
    },
    logFilterEvents: { input in
      guard await accountActive.value else { return }
      _ = try? await output(
        from: LogFilterEvents.self,
        with: .logFilterEvents(input),
      )
    },
    logInterestingEvent: { input in
      _ = try? await output(
        from: LogInterestingEvent.self,
        withUnauthed: .logInterestingEvent(input),
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
      _ = try? await output(
        from: LogSecurityEvent.self,
        with: .logSecurityEvent(input),
        using: token,
      )
    },
    recentAppVersions: {
      try await output(
        from: RecentAppVersions.self,
        withUnauthed: .recentAppVersions,
      )
    },
    reportBrowsers: { input in
      guard await accountActive.value else { return }
      _ = try await output(
        from: ReportBrowsers.self,
        with: .reportBrowsers(input),
      )
    },
    setAccountActive: { await accountActive.setValue($0) },
    setUserToken: { await userToken.setValue($0) },
    trustedNetworkTimestamp: {
      try await output(
        from: TrustedTime.self,
        withUnauthed: .trustedTime,
      )
    },
    uploadAppIcon: { input in
      guard await accountActive.value else { return }
      _ = try await output(
        from: UploadAppIcon.self,
        with: .uploadAppIcon(input),
      )
    },
    uploadScreenshot: { data in
      guard await accountActive.value else { throw Error.accountInactive }
      let signed = try await output(
        from: CreateSignedScreenshotUpload_v2.self,
        with: .createSignedScreenshotUpload_v2(.init(
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
