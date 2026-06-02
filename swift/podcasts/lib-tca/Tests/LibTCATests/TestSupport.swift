import ComposableArchitecture
import Dependencies
import Foundation

@testable import LibTCA

func dictKeychain(
  _ store: LockIsolated<[String: Data]> = .init([:]),
  pincode: Int? = nil,
  installDate: Date? = nil,
  deviceId: UUID? = nil,
  amToken: UUID? = nil,
) -> KeychainClient {
  store.withValue {
    if let pincode {
      $0[KeychainClient.Key.pincode.rawValue] = "\(pincode)".data(using: .utf8)!
    }
    if let installDate {
      $0[KeychainClient.Key.installDate.rawValue] =
        "\(installDate.timeIntervalSince1970)".data(using: .utf8)!
    }
    if let deviceId {
      $0[KeychainClient.Key.deviceId.rawValue] = deviceId.uuidString.data(using: .utf8)!
    }
    if let amToken {
      $0[KeychainClient.Key.amToken.rawValue] = amToken.uuidString.data(using: .utf8)!
    }
  }
  return KeychainClient(
    _load: { key in store.value[key.rawValue] },
    _save: { key, data in store.withValue { $0[key.rawValue] = data } },
    delete: { key in store.withValue { $0[key.rawValue] = nil } },
  )
}

func claimedKeychain(
  token: UUID,
  store: LockIsolated<[String: Data]> = .init([:]),
) -> KeychainClient {
  dictKeychain(
    store,
    pincode: 111_111,
    installDate: .reference,
    deviceId: UUID(),
    amToken: token,
  )
}
