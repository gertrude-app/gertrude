import Dependencies
import Foundation
import Gertie

@testable import Api

private let claimCodes = LockIsolated(100_000)

// test db persists between tests, so ensure unique claim codes
func uniqueClaimCode() -> Int {
  claimCodes.withValue { code in
    code += 1
    precondition(code <= 999_999, "exhausted unique 6-digit test claim codes")
    return code
  }
}

extension ApiTestCase {
  @discardableResult
  func createClaim(
    _ intent: ClaimIntent,
    _ deviceId: IOSDevice.Id,
    _ childId: Child.Id? = nil,
    code: Int = uniqueClaimCode(),
    expiresAt: Date = .reference + .days(7),
    claimedAt: Date? = nil,
  ) async throws -> Claim {
    try await self.db.create(Claim(
      code: code,
      intent: intent,
      deviceId: deviceId,
      childId: childId,
      expiresAt: expiresAt,
      claimedAt: claimedAt,
    ))
  }
}

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

extension BlockerApp.ProfileSettings: RandomMocked {
  public static var mock: BlockerApp.ProfileSettings {
    .init(deviceId: .init())
  }

  public static var empty: BlockerApp.ProfileSettings {
    .init(deviceId: .init())
  }

  public static var random: BlockerApp.ProfileSettings {
    .init(deviceId: .init())
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
