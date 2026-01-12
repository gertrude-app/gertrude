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

extension IOSApp.PendingSupervision: RandomMocked {
  public static var mock: IOSApp.PendingSupervision {
    .init(
      code: 123_456,
      vendorId: .init(),
      modelIdentifier: "iPhone17,1",
      iosVersion: "18.2",
      appVersion: "1.5.0",
      expiresAt: .reference.advanced(by: .days(7)),
    )
  }

  public static var empty: IOSApp.PendingSupervision {
    .init(
      code: 0,
      vendorId: .init(),
      modelIdentifier: "",
      iosVersion: "",
      appVersion: "",
      expiresAt: .reference.advanced(by: .days(7)),
    )
  }

  public static var random: IOSApp.PendingSupervision {
    .init(
      code: Int.random(in: 100_000 ... 999_999),
      vendorId: .init(),
      modelIdentifier: Bool.random() ? "iPhone17,1" : "iPad16,3",
      iosVersion: "26.\(Int.random(in: 0 ... 5))",
      appVersion: "1.\(Int.random(in: 5 ... 10)).0",
      expiresAt: .reference.advanced(by: .days(7)),
    )
  }
}
