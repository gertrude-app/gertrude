import Dependencies
import DependenciesMacros
import Foundation
import LibCore

@DependencyClient
public struct GroupDefaultsClient: Sendable {
  public var data: @Sendable (_ forKey: String) -> Data?
  public var setData: @Sendable (_ data: Data, _ forKey: String) -> Void
  public var date: @Sendable (_ forKey: String) -> Date?
  public var setDate: @Sendable (_ date: Date, _ forKey: String) -> Void
  public var remove: @Sendable (_ forKey: String) -> Void
}

extension GroupDefaultsClient: DependencyKey {
  public static var liveValue: GroupDefaultsClient {
    .init(
      data: { UserDefaults.gertrude.data(forKey: $0) },
      setData: { UserDefaults.gertrude.set($0, forKey: $1) },
      date: { UserDefaults.gertrude.object(forKey: $0) as? Date },
      setDate: { UserDefaults.gertrude.set($0, forKey: $1) },
      remove: { UserDefaults.gertrude.removeObject(forKey: $0) },
    )
  }
}

extension GroupDefaultsClient: TestDependencyKey {
  public static let testValue = GroupDefaultsClient()
}

public extension GroupDefaultsClient {
  enum Entry: Sendable, Equatable {
    case data(Data)
    case date(Date)
  }

  static func inMemory(_ store: LockIsolated<[String: Entry]>) -> GroupDefaultsClient {
    .init(
      data: { key in
        if case .data(let data) = store.value[key] { data } else { nil }
      },
      setData: { data, key in
        store.withValue { $0[key] = .data(data) }
      },
      date: { key in
        if case .date(let date) = store.value[key] { date } else { nil }
      },
      setDate: { date, key in
        store.withValue { $0[key] = .date(date) }
      },
      remove: { key in
        store.withValue { $0[key] = nil }
      },
    )
  }
}

public extension DependencyValues {
  var groupDefaults: GroupDefaultsClient {
    get { self[GroupDefaultsClient.self] }
    set { self[GroupDefaultsClient.self] = newValue }
  }
}
