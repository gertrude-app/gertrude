import ComposableArchitecture
import Dependencies
import DeviceIdentity
import Foundation
import IOSAppsRoute
import SQLiteData

@testable import LibTCA

func loggedEvents() -> [Event] {
  dep(\.db).tryRead { try Event.all.fetchAll($0) }.sorted { $0.id < $1.id }
}

func loggedEventIds() -> [String] {
  loggedEvents().compactMap(\.apiId)
}

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

public extension Date {
  static let epoch = Date(timeIntervalSince1970: 0)
  static let reference = Date(timeIntervalSinceReferenceDate: 0)
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

@MainActor
final class PodcastIdentityFixture {
  let values = LockIsolated<[String: Data]>([:])
  let failedWrites = LockIsolated<Set<KeychainClient.Key>>([])
  let failedReads = LockIsolated<Set<KeychainClient.Key>>([])
  var slots: [IdentitySlot: Data] = [:]
  var unknown: IdentitySlot?
  var failedSlot: IdentitySlot?
  var deleteReceiptFails = false
  var reportFails = false
  var clearState: (() throws -> Void)?
  var clearFails = false
  var clears = 0
  var requests: [ReportIdentityTransition.Input] = []
  var reason = ReportIdentityTransition.Reason.normal
  var returnToken = true
  var legacyReports: [(UUID, UUID)] = []

  init() {
    self.set(.appMemory, UUID(1))
    self.set(.identity, UUID(2))
    self.set(.canary, UUID(2))
    self.keychain.save(amToken: UUID(3))
  }

  var keychain: KeychainClient {
    var client = dictKeychain(self.values)
    let read = client._load
    let write = client._save
    client._load = { [failedReads] key in
      if failedReads.value.contains(key) { throw CancellationError() }
      return try read(key)
    }
    client._save = { [failedWrites] key, data in
      if failedWrites.value.contains(key) { throw CancellationError() }
      try write(key, data)
    }
    return client
  }

  func set(_ slot: IdentitySlot, _ id: UUID) {
    self.slots[slot] = Data(id.uuidString.utf8)
  }

  func id(_ slot: IdentitySlot) -> UUID? {
    self.slots[slot].flatMap { String(data: $0, encoding: .utf8) }.flatMap(UUID.init(uuidString:))
  }

  func identity() -> PodcastIdentity {
    withDependencies {
      $0.uuid = .constant(UUID(6))
    } operation: {
      PodcastIdentity(
        keychain: self.keychain,
        storage: .init(
          read: { slot in
            if self.unknown == slot { return .unknown(-25308) }
            return self.slots[slot].map(IdentityRead.value) ?? .absent
          },
          add: { slot, data in
            if self.failedSlot == slot { return .failure(-50) }
            if self.slots[slot] != nil { return .duplicate }
            self.slots[slot] = data
            return .success
          },
          write: { slot, data in
            if self.failedSlot == slot { return .failure(-50) }
            self.slots[slot] = data
            return .success
          },
          delete: { slot in
            if self.deleteReceiptFails, slot == .pendingTransition { return .failure(-50) }
            self.slots[slot] = nil
            return .success
          },
        ),
        metadata: {
          .init(
            app: .podcasts,
            modelIdentifier: "iPhone16,1",
            iosVersion: "26.6",
            appVersion: "1.6.4",
            liveVendorId: UUID(7),
          )
        },
        clearState: {
          if self.clearFails { throw CancellationError() }
          try self.clearState?()
          self.clears += 1
        },
        report: { input in
          self.requests.append(input)
          if self.reportFails { throw URLError(.notConnectedToInternet) }
          return .init(
            deviceId: input.newDeviceId, reason: self.reason,
            childId: self.returnToken ? UUID(5) : nil,
            token: self.returnToken ? UUID(4) : nil,
          )
        },
        migrateLegacy: { old, new in
          self.legacyReports.append((old, new))
          if self.reportFails { throw URLError(.notConnectedToInternet) }
        },
        telemetry: { _ in },
      )
    }
  }
}
