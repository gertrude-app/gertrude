import Dependencies
import DependenciesMacros
import Foundation
import LibCore

@DependencyClient
struct DeviceClient: Sendable {
  var vendorId: @Sendable () async -> UUID?
  var systemVersion: @Sendable () async -> String = { "" }
  var modelIdentifier: @Sendable () -> String = { "" }
}

extension DeviceClient {
  func data() async -> (UUID?, String, String) {
    await (self.vendorId(), self.systemVersion(), self.modelIdentifier())
  }
}

extension DeviceClient: DependencyKey {
  static var liveValue: DeviceClient {
    .init(
      vendorId: { await MainActor.run { UIDevice.current.identifierForVendor } },
      systemVersion: { await MainActor.run { UIDevice.current.systemVersion } },
      modelIdentifier: getModelIdentifier,
    )
  }
}

extension DependencyValues {
  var device: DeviceClient {
    get { self[DeviceClient.self] }
    set { self[DeviceClient.self] = newValue }
  }
}

// NB: currently duplicated, grep: af6ce6fd
private func getModelIdentifier() -> String {
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
      systemVersion: { "18.3.1" },
      modelIdentifier: { "iPhone16,1" },
    )
  }
#endif
