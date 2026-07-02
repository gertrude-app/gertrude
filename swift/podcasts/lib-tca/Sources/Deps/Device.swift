import Dependencies
import DependenciesMacros
import Foundation
import GertieApp
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
      modelIdentifier: { IOSDeviceInfo.modelIdentifier() },
    )
  }
}

extension DependencyValues {
  var device: DeviceClient {
    get { self[DeviceClient.self] }
    set { self[DeviceClient.self] = newValue }
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
