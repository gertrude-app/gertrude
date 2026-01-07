import Gertie

@testable import Api

extension IOSApp.Device: RandomMocked {
  public static var mock: IOSApp.Device {
    .init(
      childId: .init(),
      vendorId: .init(),
      modelIdentifier: "iPhone15,2",
      appVersion: "1.5.0",
      iosVersion: "18.4.0",
    )
  }

  public static var empty: IOSApp.Device {
    .init(
      childId: .init(),
      vendorId: .init(),
      modelIdentifier: "iPhone15,2",
      appVersion: "1.5.0",
      iosVersion: "18.4.0",
    )
  }

  public static var random: IOSApp.Device {
    .init(
      childId: .init(),
      vendorId: .init(),
      modelIdentifier: Bool.random() ? "iPhone15,2" : "iPad14,1",
      appVersion: "1.5.\(Int.random(in: 0 ... 100))",
      iosVersion: "18.4.\(Int.random(in: 0 ... 100))",
    )
  }
}
