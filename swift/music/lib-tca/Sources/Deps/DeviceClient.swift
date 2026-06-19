import Dependencies
import DependenciesMacros
import Foundation

#if os(iOS)
  import UIKit
#endif

@DependencyClient
struct DeviceClient: Sendable {
  var vendorId: @Sendable () async -> UUID?
  var iOSVersion: @Sendable () async -> String = { "" }
  var modelIdentifier: @Sendable () -> String = { "" }
  var appVersion: @Sendable () -> String = { "0.0.0" }
}

extension DeviceClient {
  func data() async -> (UUID?, String, String, String) {
    await (self.vendorId(), self.iOSVersion(), self.modelIdentifier(), self.appVersion())
  }
}

extension DeviceClient: DependencyKey {
  static var liveValue: DeviceClient {
    .init(
      vendorId: { await frozenVendorId() },
      iOSVersion: {
        #if os(iOS)
          await MainActor.run { UIDevice.current.systemVersion }
        #else
          "18.0.1"
        #endif
      },
      modelIdentifier: getModelIdentifier,
      appVersion: {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
      },
    )
  }
}

extension DependencyValues {
  var device: DeviceClient {
    get { self[DeviceClient.self] }
    set { self[DeviceClient.self] = newValue }
  }
}

@Sendable private func frozenVendorId() async -> UUID? {
  @Dependency(\.keychain) var keychain
  if let stored = keychain.loadDeviceId() {
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
    keychain.save(deviceId: current)
  }
  return current
}

@Sendable private func getModelIdentifier() -> String {
  var systemInfo = utsname()
  uname(&systemInfo)
  let mirror = Mirror(reflecting: systemInfo.machine)
  return mirror.children.reduce("") { identifier, element in
    guard let value = element.value as? Int8, value != 0 else { return identifier }
    return identifier + String(UnicodeScalar(UInt8(value)))
  }
}

#if DEBUG
  extension DeviceClient {
    static let mock = DeviceClient(
      vendorId: { UUID(uuidString: "CAFEBABE-CAFE-BABE-CAFE-BABECAFEBABE") },
      iOSVersion: { "18.3.1" },
      modelIdentifier: { "iPhone16,1" },
      appVersion: { "1.0.0" },
    )
  }
#endif
