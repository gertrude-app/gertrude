import Combine
import Dependencies
import Network
import XCore

struct NetworkClient: Sendable {
  var isConnected: @Sendable () -> Bool
  var connectionChanges: @Sendable () -> AnyPublisher<Bool, Never>
}

extension NetworkClient {
  static func live(queue: DispatchQueue = .global(qos: .background)) -> Self {
    let monitor = NWPathMonitor()
    let subject = Mutex(CurrentValueSubject<Bool, Never>(true))

    monitor.pathUpdateHandler = { path in
      subject.withLock {
        $0.send(path.status == .satisfied)
      }
    }

    monitor.start(queue: queue)

    return NetworkClient(
      isConnected: { subject.withLock { $0.value } },
      connectionChanges: {
        subject.withLock { subject in
          subject
            .handleEvents()
            .removeDuplicates()
            .eraseToAnyPublisher()
        }
      },
    )
  }
}

extension DependencyValues {
  var network: NetworkClient {
    get { self[NetworkClient.self] }
    set { self[NetworkClient.self] = newValue }
  }
}

extension NetworkClient: DependencyKey {
  static let liveValue: NetworkClient = .live
  static let testValue: NetworkClient = .connected
}

extension NetworkClient {
  static let live = NetworkClient.live()
  static let mock = NetworkClient.connected

  static let connected = NetworkClient(
    isConnected: { true },
    connectionChanges: {
      CurrentValueSubject<Bool, Never>(true).eraseToAnyPublisher()
    },
  )

  static let notConnected = NetworkClient(
    isConnected: { false },
    connectionChanges: {
      CurrentValueSubject<Bool, Never>(false).eraseToAnyPublisher()
    },
  )
}
