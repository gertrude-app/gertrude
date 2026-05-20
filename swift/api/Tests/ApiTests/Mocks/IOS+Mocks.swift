import Foundation
import Gertie

@testable import Api

extension IOSDevice: RandomMocked {
  public static var mock: IOSDevice {
    .init(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.4.0",
    )
  }

  public static var empty: IOSDevice {
    .init(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.4.0",
    )
  }

  public static var random: IOSDevice {
    .init(
      id: .init(),
      childId: nil,
      modelIdentifier: Bool.random() ? "iPhone15,2" : "iPad14,1",
      iosVersion: "18.4.\(Int.random(in: 0 ... 100))",
    )
  }
}

extension BlockerApp.Install: RandomMocked {
  public static var mock: BlockerApp.Install {
    .init(deviceId: .init(), appVersion: "1.5.0")
  }

  public static var empty: BlockerApp.Install {
    .init(deviceId: .init(), appVersion: "1.5.0")
  }

  public static var random: BlockerApp.Install {
    .init(deviceId: .init(), appVersion: "1.5.\(Int.random(in: 0 ... 100))")
  }
}

extension BlockerApp.Supervision: RandomMocked {
  public static var mock: BlockerApp.Supervision {
    .init(deviceId: .init())
  }

  public static var empty: BlockerApp.Supervision {
    .init(deviceId: .init())
  }

  public static var random: BlockerApp.Supervision {
    .init(deviceId: .init())
  }
}

extension PodcastApp.Install: RandomMocked {
  public static var mock: PodcastApp.Install {
    .init(deviceId: .init(), appVersion: "2.0.0")
  }

  public static var empty: PodcastApp.Install {
    .init(deviceId: .init(), appVersion: "2.0.0")
  }

  public static var random: PodcastApp.Install {
    .init(deviceId: .init(), appVersion: "2.0.\(Int.random(in: 0 ... 100))")
  }
}

extension PodcastApp.Token: RandomMocked {
  public static var mock: PodcastApp.Token {
    .init(installId: .init())
  }

  public static var empty: PodcastApp.Token {
    .init(installId: .init())
  }

  public static var random: PodcastApp.Token {
    .init(installId: .init())
  }
}
