import Foundation
import IOSAppsRoute

public enum IdentityRead<Value: Sendable>: Sendable {
  case value(Value)
  case absent
  case unknown(Int32)

  public var value: Value? {
    if case .value(let value) = self { value } else { nil }
  }
}

extension IdentityRead: Equatable where Value: Equatable {}

public enum IdentitySlot: String, Sendable, CaseIterable {
  case identity
  case canary
  case appMemory
  case pendingTransition
}

public enum IdentityWrite: Equatable, Sendable {
  case success
  case duplicate
  case failure(Int32)
}

@MainActor
public struct IdentityStorage {
  public var read: (IdentitySlot) -> IdentityRead<Data>
  public var add: (IdentitySlot, Data) -> IdentityWrite
  public var write: (IdentitySlot, Data) -> IdentityWrite
  public var delete: (IdentitySlot) -> IdentityWrite

  public init(
    read: @escaping (IdentitySlot) -> IdentityRead<Data>,
    add: @escaping (IdentitySlot, Data) -> IdentityWrite,
    write: @escaping (IdentitySlot, Data) -> IdentityWrite,
    delete: @escaping (IdentitySlot) -> IdentityWrite,
  ) {
    self.read = read
    self.add = add
    self.write = write
    self.delete = delete
  }

  func readId(_ slot: IdentitySlot) -> IdentityRead<UUID> {
    switch self.read(slot) {
    case .value(let data):
      guard let string = String(data: data, encoding: .utf8),
            let id = UUID(uuidString: string) else { return .absent }
      return .value(id)
    case .absent: return .absent
    case .unknown(let status): return .unknown(status)
    }
  }
}

public struct PendingIdentityTransition: Codable, Equatable, Sendable {
  public var oldDeviceId: UUID
  public var newDeviceId: UUID
  public var kind: ReportIdentityTransition.Kind
  public var proofToken: UUID?

  public init(
    oldDeviceId: UUID,
    newDeviceId: UUID,
    kind: ReportIdentityTransition.Kind,
    proofToken: UUID?,
  ) {
    self.oldDeviceId = oldDeviceId
    self.newDeviceId = newDeviceId
    self.kind = kind
    self.proofToken = proofToken
  }
}
