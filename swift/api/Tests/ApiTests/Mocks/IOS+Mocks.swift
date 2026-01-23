import Foundation
import Gertie

@testable import Api

extension IOSApp.Device: RandomMocked {
  public static var mock: IOSApp.Device {
    .init(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPhone15,2",
      appVersion: "1.5.0",
      iosVersion: "18.4.0",
    )
  }

  public static var empty: IOSApp.Device {
    .init(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPhone15,2",
      appVersion: "1.5.0",
      iosVersion: "18.4.0",
    )
  }

  public static var random: IOSApp.Device {
    .init(
      id: .init(),
      childId: nil,
      modelIdentifier: Bool.random() ? "iPhone15,2" : "iPad14,1",
      appVersion: "1.5.\(Int.random(in: 0 ... 100))",
      iosVersion: "18.4.\(Int.random(in: 0 ... 100))",
    )
  }
}

extension IOSApp.Supervision: RandomMocked {
  public static var mock: IOSApp.Supervision {
    .init(
      deviceId: .init(),
      claimCode: .random(in: 100_000 ... 999_999),
      claimCodeExpiresAt: .reference + .days(7),
    )
  }

  public static var empty: IOSApp.Supervision {
    .init(
      deviceId: .init(),
      claimCode: 123_456,
      claimCodeExpiresAt: .reference + .days(7),
    )
  }

  public static var random: IOSApp.Supervision {
    .init(
      deviceId: .init(),
      claimCode: .random(in: 100_000 ... 999_999),
      claimCodeExpiresAt: .reference + .days(.random(in: 1 ... 14)),
    )
  }
}
