import ComposableArchitecture
import Foundation
import XExpect

public extension Task where Success == Never, Failure == Never {
  static func repeatYield(count: Int = 10) async {
    for _ in 1 ... count {
      await Task<Void, Never>.detached(priority: .background) { await Task.yield() }.value
    }
  }
}

public typealias TestStoreOf<R: Reducer> = TestStore<R.State, R.Action>

public extension UUID {
  static let deadbeef = UUID(uuidString: "deadbeef-dead-beef-dead-beefdeadbeef")!
  static let zeros = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
  static let ones = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
  static let twos = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

  init(_ intValue: Int) {
    self.init(uuidString: "00000000-0000-0000-0000-\(String(format: "%012x", intValue))")!
  }
}

extension UUID: @retroactive ExpressibleByIntegerLiteral {
  public init(integerLiteral value: Int) {
    self.init(value)
  }
}

public extension Date {
  static let epoch = Date(timeIntervalSince1970: 0)
}

public struct ControllingNow {
  public let generator: DateGenerator
  private let elapsed: LockIsolated<Int>
  private let scheduler: TestSchedulerOf<DispatchQueue>?

  init(
    generator: DateGenerator,
    elapsed: LockIsolated<Int>,
    scheduler: TestSchedulerOf<DispatchQueue>? = nil,
  ) {
    self.generator = generator
    self.elapsed = elapsed
    self.scheduler = scheduler
  }

  public init(
    starting start: Date = Date(),
    with scheduler: TestSchedulerOf<DispatchQueue>? = nil,
  ) {
    let elapsed = LockIsolated<Int>(0)
    self.init(
      generator: .init {
        start.advanced(by: Double(elapsed.value))
      },
      elapsed: elapsed,
      scheduler: scheduler,
    )
  }

  /// advance the time, but not the scheduler.
  /// this simulates when the computer is asleep, when timers spun up
  /// by mainQueue.sleep(for:) are suspended (because i can't use ContinuousClock)
  /// but real wall-clock time is advancing
  public func simulateComputerSleep(seconds advance: Int) {
    let current = self.elapsed.value
    self.elapsed.setValue(current + advance)
  }

  public func advance(seconds advance: Int) async {
    let current = self.elapsed.value
    self.elapsed.setValue(current + advance)
    if let scheduler {
      await scheduler.advance(by: .seconds(advance))
    }
  }
}

public func expect<T: Equatable>(
  _ isolated: ActorIsolated<T>,
  file: StaticString = #filePath,
  line: UInt = #line,
) async -> EquatableExpectation<T> {
  await EquatableExpectation(value: isolated.value, file: file, filePath: file, line: line)
}

public func expect<T: Equatable>(
  _ isolated: LockIsolated<T>,
  file: StaticString = #filePath,
  line: UInt = #line,
) -> EquatableExpectation<T> {
  EquatableExpectation(value: isolated.value, file: file, filePath: file, line: line)
}

public struct TestErr: Equatable, Error, LocalizedError {
  public let msg: String
  public var errorDescription: String? { self.msg }
  public init(_ msg: String) { self.msg = msg }
}

public extension TestStore {
  var deps: DependencyValues {
    get { dependencies }
    set { dependencies = newValue }
  }
}

public extension ActorIsolated where Value: RangeReplaceableCollection {
  func append(_ newElement: Value.Element) async {
    value.append(newElement)
  }
}

public extension LockIsolated where Value: RangeReplaceableCollection {
  func append(_ newElement: Value.Element) {
    withValue { $0.append(newElement) }
  }
}

public let IS_CI = ProcessInfo.processInfo.environment["CI"] != nil

public func makeTLSClientHello(
  serverName: String?,
  sessionId: Data = Data(),
  serverNameTrailingBytes: Data = Data(),
) -> Data {
  var clientHello = Data()
  clientHello.append(contentsOf: [0x03, 0x03])
  clientHello.append(Data(repeating: 0x11, count: 32))
  clientHello.append(UInt8(sessionId.count))
  clientHello.append(sessionId)
  clientHello.append(contentsOf: [0x00, 0x02])
  clientHello.append(contentsOf: [0x13, 0x01])
  clientHello.append(0x01)
  clientHello.append(0x00)

  var extensions = Data()
  if let serverName {
    let hostname = Data(serverName.utf8)
    var serverNameExtension = Data()
    let listLength = UInt16(1 + 2 + hostname.count + serverNameTrailingBytes.count)
    serverNameExtension.append(tlsUInt16Bytes(listLength))
    serverNameExtension.append(0x00)
    serverNameExtension.append(tlsUInt16Bytes(UInt16(hostname.count)))
    serverNameExtension.append(hostname)
    serverNameExtension.append(serverNameTrailingBytes)

    extensions.append(tlsUInt16Bytes(0x0000))
    extensions.append(tlsUInt16Bytes(UInt16(serverNameExtension.count)))
    extensions.append(serverNameExtension)
  }

  clientHello.append(tlsUInt16Bytes(UInt16(extensions.count)))
  clientHello.append(extensions)

  var handshake = Data([0x01])
  handshake.append(tlsUInt24Bytes(clientHello.count))
  handshake.append(clientHello)

  var record = Data([0x16, 0x03, 0x01])
  record.append(tlsUInt16Bytes(UInt16(handshake.count)))
  record.append(handshake)
  return record
}

private func tlsUInt16Bytes(_ value: UInt16) -> Data {
  Data([UInt8((value >> 8) & 0xFF), UInt8(value & 0xFF)])
}

private func tlsUInt24Bytes(_ value: Int) -> Data {
  Data([
    UInt8((value >> 16) & 0xFF),
    UInt8((value >> 8) & 0xFF),
    UInt8(value & 0xFF),
  ])
}

// if/when tuples become Sendable, this, `Three`, and `Four` can be removed
public struct Both<A, B> {
  public var a: A
  public var b: B
  public init(_ a: A, _ b: B) {
    self.a = a
    self.b = b
  }
}

public struct Three<A, B, C> {
  public var a: A
  public var b: B
  public var c: C
  public init(_ a: A, _ b: B, _ c: C) {
    self.a = a
    self.b = b
    self.c = c
  }
}

public struct Four<A, B, C, D> {
  public var a: A
  public var b: B
  public var c: C
  public var d: D
  public init(_ a: A, _ b: B, _ c: C, _ d: D) {
    self.a = a
    self.b = b
    self.c = c
    self.d = d
  }
}

extension Both: Sendable where A: Sendable, B: Sendable {}
extension Both: Equatable where A: Equatable, B: Equatable {}
extension Three: Sendable where A: Sendable, B: Sendable, C: Sendable {}
extension Three: Equatable where A: Equatable, B: Equatable, C: Equatable {}
extension Four: Sendable where A: Sendable, B: Sendable, C: Sendable, D: Sendable {}
extension Four: Equatable where A: Equatable, B: Equatable, C: Equatable, D: Equatable {}
