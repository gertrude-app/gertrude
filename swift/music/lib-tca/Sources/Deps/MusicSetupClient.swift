import Dependencies
import DependenciesMacros
import Foundation

#if canImport(MusicKit)
  import MusicKit
#endif

enum AppleMusicAuthorizationStatus: Equatable, Sendable {
  case authorized
  case denied
  case notDetermined
  case restricted
  case unknown
}

enum AppleMusicSubscriptionStatus: Equatable, Sendable {
  case canPlayCatalogContent
  case permissionDenied
  case privacyAcknowledgementRequired
  case subscriptionRequired(canBecomeSubscriber: Bool)
  case unknown
}

@DependencyClient
struct MusicSetupClient: Sendable {
  var authorizationStatus: @Sendable () async -> AppleMusicAuthorizationStatus = { .unknown }
  var requestAuthorization: @Sendable () async -> AppleMusicAuthorizationStatus = { .unknown }
  var subscriptionStatus: @Sendable () async -> AppleMusicSubscriptionStatus = { .unknown }
}

extension MusicSetupClient: DependencyKey {
  #if os(iOS) && targetEnvironment(simulator)
    static let liveValue = Self.simulator
  #elseif canImport(MusicKit)
    static let liveValue = Self.live
  #else
    static let liveValue = Self.noop
  #endif

  static let testValue = Self.noop
}

extension DependencyValues {
  var musicSetup: MusicSetupClient {
    get { self[MusicSetupClient.self] }
    set { self[MusicSetupClient.self] = newValue }
  }
}

extension MusicSetupClient {
  static let noop = Self(
    authorizationStatus: { .authorized },
    requestAuthorization: { .authorized },
    subscriptionStatus: { .canPlayCatalogContent },
  )

  #if os(iOS) && targetEnvironment(simulator)
    static let simulator = Self.noop
  #endif

  #if canImport(MusicKit)
    static let live = Self(
      authorizationStatus: {
        Self.authorizationStatus(from: MusicAuthorization.currentStatus)
      },
      requestAuthorization: {
        await Self.authorizationStatus(from: MusicAuthorization.request())
      },
      subscriptionStatus: {
        await Self.currentSubscriptionStatus()
      },
    )

    private static func authorizationStatus(
      from status: MusicAuthorization.Status,
    ) -> AppleMusicAuthorizationStatus {
      switch status {
      case .authorized:
        .authorized
      case .denied:
        .denied
      case .notDetermined:
        .notDetermined
      case .restricted:
        .restricted
      @unknown default:
        .unknown
      }
    }

    private static func currentSubscriptionStatus() async -> AppleMusicSubscriptionStatus {
      do {
        let subscription = try await MusicSubscription.current
        guard !subscription.canPlayCatalogContent else {
          return .canPlayCatalogContent
        }
        return .subscriptionRequired(canBecomeSubscriber: subscription.canBecomeSubscriber)
      } catch let error as MusicSubscription.Error {
        switch error {
        case .permissionDenied:
          return .permissionDenied
        case .privacyAcknowledgementRequired:
          return .privacyAcknowledgementRequired
        case .unknown:
          return .unknown
        @unknown default:
          return .unknown
        }
      } catch {
        return .unknown
      }
    }
  #endif
}
