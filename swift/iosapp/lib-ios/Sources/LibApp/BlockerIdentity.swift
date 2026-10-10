import BlockerRoute
import Dependencies
import DependenciesMacros
import DeviceIdentity
import Foundation
import IOSAppsRoute
import LibClients
import LibCore
import PairQLClient

#if os(iOS)
  import UIKit
#endif

@DependencyClient
public struct BlockerIdentityClient: Sendable {
  public var resolve: @MainActor @Sendable () -> Resolution = { .init() }
  public var report: @MainActor @Sendable () async -> Resolution = { .init() }

  public struct Resolution: Equatable, Sendable {
    public var available: Bool
    public var migrationPending: Bool
    public var needsReport: Bool
    public var identityChanged: Bool

    public init(
      available: Bool = true,
      migrationPending: Bool = false,
      needsReport: Bool = false,
      identityChanged: Bool = false,
    ) {
      self.available = available
      self.migrationPending = migrationPending
      self.needsReport = needsReport
      self.identityChanged = identityChanged
    }
  }
}

extension BlockerIdentityClient: DependencyKey {
  public static var liveValue: Self {
    .init(
      resolve: { BlockerIdentity.shared.resolve() },
      report: { await BlockerIdentity.shared.report() },
    )
  }

  public static var testValue: Self {
    .init(resolve: { .init() }, report: { .init() })
  }
}

public extension DependencyValues {
  var blockerIdentity: BlockerIdentityClient {
    get { self[BlockerIdentityClient.self] }
    set { self[BlockerIdentityClient.self] = newValue }
  }
}

@MainActor
public final class BlockerIdentity {
  static let shared = BlockerIdentity()
  let resolver: IdentityResolver
  private let storage: SharedStorageClient
  private let api: ApiClient

  public static func configureApp() {
    prepareDependencies {
      $0.device.deviceId = { self.shared.resolver.deviceId }
    }
  }

  init(
    storage: IdentityStorage? = nil,
    metadata: (() -> IdentityResolver.Metadata)? = nil,
    report: (@MainActor (ReportIdentityTransition.Input) async throws
      -> ReportIdentityTransition.Output)? = nil,
    telemetry: ((IdentityResolver.Event) -> Void)? = nil,
  ) {
    @Dependency(\.sharedStorage) var sharedStorage
    @Dependency(\.api) var api
    self.storage = sharedStorage
    self.api = api
    let transport = PairQLClient<IOSAppsRoute>(endpoint: { URL(string: .gertrudeApi)! })
    self.resolver = IdentityResolver(
      storage: storage ?? IdentityKeychain(configuration: .init(
        privateAccessGroup: "WFN83LM943.com.netrivet.gertrude-ios.app",
        appMemoryAccount: "com.gertrude.ios.vendorId",
      )).storage,
      hooks: .init(
        metadata: metadata ?? {
          @Dependency(\.device) var device
          return .init(
            app: .blocker,
            modelIdentifier: device.modelIdentifier(),
            iosVersion: Self.osVersion,
            appVersion: device.installedVersion(),
            liveVendorId: Self.liveVendorId,
          )
        },
        proofToken: { sharedStorage.loadAccountConnection()?.token },
        credentialDeviceId: { sharedStorage.loadAccountConnection()?.deviceId },
        clearDeviceBoundState: {
          api.clearAccountConnection()
          try sharedStorage.clearDeviceBoundState()
        },
        markMigration: { try sharedStorage.setMigrationPending(true) },
        migrationPending: sharedStorage.migrationPending,
        applyCredentials: { output in
          let previous = sharedStorage.loadAccountConnection()
          guard let token = output.token, let childId = output.childId else {
            if previous?.deviceId != output.deviceId {
              api.clearAccountConnection()
              sharedStorage.clearAccountConnection()
            }
            return
          }
          sharedStorage.saveAccountConnection(.init(
            childId: childId,
            token: token,
            deviceId: output.deviceId,
            childName: previous?.childId == childId ? previous?.childName ?? "" : "",
            supervised: sharedStorage.migrationPending() ? nil : previous?.supervised,
          ))
        },
        publishIdentity: sharedStorage.saveDeviceIdentity,
        report: report ?? {
          try await transport.call(
            ReportIdentityTransition.self,
            .unauthed(.reportIdentityTransition($0)),
          )
        },
        telemetry: telemetry ?? Self.log,
      ),
    )
  }

  func resolve() -> BlockerIdentityClient.Resolution {
    let outcome = self.resolver.resolveOnForeground()
    let needsReport = switch outcome {
    case .retry, .adopted: true
    default: false
    }
    return self.resolution(needsReport: needsReport)
  }

  func report() async -> BlockerIdentityClient.Resolution {
    let previousId = self.resolver.deviceId
    _ = await self.resolver.reportPendingTransition()
    await self.api.setAccountConnection(self.storage.loadAccountConnection())
    var result = self.resolution(needsReport: false)
    result.identityChanged = previousId != nil && previousId != self.resolver.deviceId
    return result
  }

  private func resolution(needsReport: Bool) -> BlockerIdentityClient.Resolution {
    .init(
      available: self.resolver.deviceId != nil,
      migrationPending: self.storage.migrationPending(),
      needsReport: needsReport,
    )
  }

  private static var osVersion: String {
    let version = ProcessInfo.processInfo.operatingSystemVersion
    return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
  }

  private static var liveVendorId: UUID? {
    #if os(iOS)
      UIDevice.current.identifierForVendor
    #else
      nil
    #endif
  }

  private static func log(_ event: IdentityResolver.Event) {
    let id = switch event {
    case .resolution: "2e78387a"
    case .canaryMismatch: "565caa05"
    case .persistentUnknownRead: "a4f83335"
    case .writeFailed: "204bb316"
    case .invalidPendingTransition: "f45172f1"
    case .reportFailed: "41b907cc"
    case .consumerFailure: "fcc1f378"
    case .childConflictPin: "bfaf49a3"
    }
    LibClients.log(.info, .storage, id, detail: String(describing: event))
  }
}
