import Combine
import Dependencies
import DependenciesMacros
import Foundation

#if os(iOS)
  import UIKit
#endif

@DependencyClient
public struct DeviceClient: Sendable {
  public var type: @MainActor @Sendable () async -> DeviceType = { .iPhone }
  public var iOSVersion: @MainActor @Sendable () async -> String = { "18.0.1" }
  public var deviceId: @MainActor @Sendable () async -> UUID? = { nil }
  public var modelIdentifier: @Sendable () -> String = { "iPhone15,2" }
  public var installedVersion: @Sendable () -> String = { "0.0.0" }
  public var data: @MainActor @Sendable () async -> Data = {
    .init(type: .iPhone, iOSVersion: "18.0.1", deviceId: nil, modelIdentifier: "iPhone15,2")
  }

  public var batteryLevel: @MainActor @Sendable () async -> BatteryLevel = { .unknown }
  public var clearCache: @Sendable (Int?) -> AnyPublisher<ClearCacheUpdate, Never> = { _ in
    AnyPublisher(Empty())
  }

  public var deleteCacheFillDir: @Sendable () async -> Void = {}
  public var availableDiskSpaceInBytes: @Sendable () -> Int? = { nil }
}

public extension DeviceClient {
  enum BatteryLevel: Sendable, Equatable {
    case unknown
    /// 0.0 - 1.0
    case level(Float)

    public var isLow: Bool {
      switch self {
      case .unknown: false
      case .level(let level): level < 0.4
      }
    }
  }

  enum ClearCacheUpdate: Sendable, Equatable {
    case bytesCleared(Int)
    case finished
    case errorCouldNotCreateDir
  }

  struct Data: Sendable {
    public var type: DeviceType
    public var iOSVersion: String
    public var deviceId: UUID?
    public var modelIdentifier: String

    public init(type: DeviceType, iOSVersion: String, deviceId: UUID?, modelIdentifier: String) {
      self.type = type
      self.iOSVersion = iOSVersion
      self.deviceId = deviceId
      self.modelIdentifier = modelIdentifier
    }
  }
}

extension DeviceClient: DependencyKey {
  #if os(iOS)
    public static var liveValue: DeviceClient {
      DeviceClient(
        type: { await MainActor.run {
          UIDevice.current.userInterfaceIdiom == .pad ? .iPad : .iPhone
        }},
        iOSVersion: { await MainActor.run {
          UIDevice.current.systemVersion
        }},
        deviceId: {
          await getFrozenVendorId()
        },
        modelIdentifier: getModelIdentifier,
        installedVersion: {
          Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        },
        data: {
          let deviceId = await getFrozenVendorId()
          let modelIdentifier = getModelIdentifier()
          return await MainActor.run { .init(
            type: UIDevice.current.userInterfaceIdiom == .pad ? .iPad : .iPhone,
            iOSVersion: UIDevice.current.systemVersion,
            deviceId: deviceId,
            modelIdentifier: modelIdentifier,
          ) }
        },
        batteryLevel: { @MainActor in
          UIDevice.current.isBatteryMonitoringEnabled = true
          let level = UIDevice.current.batteryLevel
          UIDevice.current.isBatteryMonitoringEnabled = false
          return switch level {
          case 0.0 ... 1.0: .level(level)
          default: .unknown
          }
        },
        clearCache: doClearCache,
        deleteCacheFillDir: { try? FileManager.default.removeItem(at: .fillDir) },
        availableDiskSpaceInBytes: getAvailableDiskSpaceInBytes,
      )
    }
  #else
    public static let liveValue = DeviceClient(
      type: { .iPhone },
      iOSVersion: { "18.0.1" },
      deviceId: { .init() },
      modelIdentifier: { "iPhone15,2" },
      installedVersion: { "0.0.0" },
      data: { .init(
        type: .iPhone,
        iOSVersion: "18.0.1",
        deviceId: .init(),
        modelIdentifier: "iPhone15,2",
      ) },
      batteryLevel: { .level(0.9) },
      clearCache: { _ in AnyPublisher(Empty()) },
      deleteCacheFillDir: {},
      availableDiskSpaceInBytes: { 1_000_000_000 },
    )
  #endif
}

extension DeviceClient: TestDependencyKey {
  public static var testValue: DeviceClient {
    var client = DeviceClient()
    client.deviceId = { nil }
    return client
  }
}

#if DEBUG
  public extension DeviceClient {
    static let mock = DeviceClient(
      type: { .iPhone },
      iOSVersion: { "18.3.1" },
      deviceId: { UUID(42) },
      modelIdentifier: { "iPhone15,2" },
      installedVersion: { "1.0.0" },
      data: { .init(
        type: .iPhone,
        iOSVersion: "18.3.1",
        deviceId: UUID(42),
        modelIdentifier: "iPhone15,2",
      ) },
      batteryLevel: { .level(0.85) },
      clearCache: { _ in AnyPublisher(Empty()) },
      deleteCacheFillDir: {},
      availableDiskSpaceInBytes: { 500_000_000 },
    )
  }
#endif

@Sendable func getFrozenVendorId() async -> UUID? {
  @Dependency(\.keychain) var keychain
  if let stored = keychain.loadVendorId() {
    return stored
  }
  let current: UUID? = await MainActor.run {
    #if os(iOS)
      UIDevice.current.identifierForVendor
    #else
      UUID()
    #endif
  }
  if let current {
    keychain.save(vendorId: current)
  }
  return current
}

// NB: currently duplicated, grep: af6ce6fd
@Sendable func getModelIdentifier() -> String {
  var systemInfo = utsname()
  uname(&systemInfo)
  let mirror = Mirror(reflecting: systemInfo.machine)
  let identifier = mirror.children.reduce("") { identifier, element in
    guard let value = element.value as? Int8, value != 0 else { return identifier }
    return identifier + String(UnicodeScalar(UInt8(value)))
  }
  return identifier
}

@Sendable func getAvailableDiskSpaceInBytes() -> Int? {
  let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
  if let vals = try? url?.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
     let space = vals.volumeAvailableCapacityForImportantUsage {
    return space > Int.max ? nil : Int(space)
  }
  return nil
}

public enum DeviceType: String, Sendable {
  case iPhone
  case iPad
}

public extension DependencyValues {
  var device: DeviceClient {
    get { self[DeviceClient.self] }
    set { self[DeviceClient.self] = newValue }
  }
}

public extension Duration {
  static func minutes(_ value: Int) -> Duration {
    .seconds(Double(value) * 60.0)
  }
}
